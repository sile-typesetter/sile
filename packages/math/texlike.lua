local epnf = require("epnf")
local lpeg = require("lpeg")
local syms = require("packages.math.unicode-symbols")
require("core.parserbits")

local atomType = syms.atomType
local symbolDefaults = syms.symbolDefaults
local symbols = syms.symbols

-- Grammar to parse TeX-like math
-- luacheck: push ignore
local mathGrammar = function(_ENV)
  local _ = WS^0
  local eol = S"\r\n"
  local digit = R("09")
  local natural = digit^1 / tostring
  local pos_natural = R("19") * digit^0 / tonumber
  local ctrl_word = R("AZ", "az")^1
  local ctrl_symbol = P(1) - S"{}\\"
  local ctrl_sequence_name = C(ctrl_word + ctrl_symbol) / 1
  local comment = (
      P"%" *
      P(1-eol)^0 *
      eol^-1
    )
  local utf8cont = R("\128\191")
  local utf8code = lpeg.R("\0\127")
    + lpeg.R("\194\223") * utf8cont
    + lpeg.R("\224\239") * utf8cont * utf8cont
    + lpeg.R("\240\244") * utf8cont * utf8cont * utf8cont
  -- Identifiers inside \mo and \mi tags
  local sileID = C(SILE.inputs.TeXlike.identifier + P(1)) / 1
  local mathMLID = (utf8code - S"\\{}%")^1 / function(...)
    local ret = ""
    local t = {...}
    for _,b in ipairs(t) do
      ret = ret .. b
    end
    return ret
  end
  local group = P"{" * V"mathlist" * (P"}" + E("`}` expected"))
  local element_no_infix =
    V"def" +
    V"command" +
    group +
    V"argument" +
    V"atom"
  local element =
    V"supsub" +
    V"subsup" +
    V"sup" +
    V"sub" +
    element_no_infix
  local sep = S",;" * _
  local quotedString = (P'"' * C((1-P'"')^1) * P'"')
  local value = ( quotedString + (1-S",;]")^1 )
  local pair = Cg(sileID * _ * "=" * _ * C(value)) * sep^-1 / function (...)
    local t = {...}; return t[1], t[#t] end
  local list = Cf(Ct"" * pair^0, rawset)
  local parameters = (
      P"[" *
      list *
      P"]"
    )^-1 / function (a) return type(a)=="table" and a or {} end

  local dim2_arg_inner = Ct(V"mathlist" * (P"&" * V"mathlist")^0) /
    function(t)
      t.id = "mathlist"
      return t
    end
  local dim2_arg =
    Cg(P"{" *
       dim2_arg_inner *
       (P"\\\\" * dim2_arg_inner)^1 *
       (P"}" + E("`}` expected"))
      ) / function(...)
        local t = {...}
        -- Remove the last mathlist if empty. This way,
        -- `inner1 \\ inner2 \\` is the same as `inner1 \\ inner2`.
        if not t[#t][1] or not t[#t][1][1] then table.remove(t) end
        return table.unpack(t)
      end

  START "texlike_math"
  texlike_math = V"mathlist" * EOF"Unexpected character at end of math code"
  mathlist = (comment + (WS * _) + element)^0
  supsub = element_no_infix * _ * P"^" * _ * element_no_infix * _ *
    P"_" * _ * element_no_infix
  subsup = element_no_infix * _ * P"_" * _ * element_no_infix * _ *
    P"^" * _ * element_no_infix
  sup = element_no_infix * _ * P"^" * _ * element_no_infix
  sub = element_no_infix * _ * P"_" * _ * element_no_infix
  atom = natural + C(utf8code - S"\\{}%^_&") +
    (P"\\{" + P"\\}") / function(s) return string.sub(s, -1) end
  command = (
      P"\\" *
      Cg(ctrl_sequence_name, "command") *
      Cg(parameters, "options") *
      (dim2_arg + group^0)
    )
  def = P"\\def" * _ * P"{" *
    Cg(ctrl_sequence_name, "command-name") * P"}" * _ *
    --P"[" * Cg(digit^1, "arity") * P"]" * _ *
    P"{" * V"mathlist" * P"}"
  argument = P"#" * Cg(pos_natural, "index")
end
-- luacheck: pop

local mathParser = epnf.define(mathGrammar)

local commands = {}

-- A command type is a type for each argument it takes: either string or MathML
-- tree. If a command has no type, it is assumed to take only trees.
-- Tags like <mi>, <mo>, <mn> take a string, and this needs to be propagated in
-- commands that use them.

local objType = {
  tree = 1,
  str = 2
}

local function inferArgTypes_aux(acc, typeRequired, body)
  if type(body) == "table" then
    if body.id == "argument" then
      local ret = acc
      table.insert(ret, body.index, typeRequired)
      return ret
    elseif body.id == "command" then
      if commands[body.command] then
        local cmdArgTypes = commands[body.command][1]
        if #cmdArgTypes ~= #body then
          SU.error("Wrong number of arguments (" .. #body ..
            ") for command " .. body.command .. " (should be " ..
            #cmdArgTypes .. ")")
        else
          for i = 1, #cmdArgTypes do
            acc = inferArgTypes_aux(acc, cmdArgTypes[i], body[i])
          end
        end
        return acc
      elseif body.command == "mi" or body.command == "mo" or body.command == "mn" then
        if #body ~= 1 then
          SU.error("Wrong number of arguments ("..#body..") for command "..
            body.command.." (should be 1)")
        end
        acc = inferArgTypes_aux(acc, objType.str, body[1])
        return acc
      else
        -- Not a macro, recurse on children assuming tree type for all
        -- arguments
        for _, child in ipairs(body) do
          acc = inferArgTypes_aux(acc, objType.tree, child)
        end
        return acc
      end
    elseif body.id == "atom" then
      return acc
    else
      -- Simply recurse on children
      for _, child in ipairs(body) do
        acc = inferArgTypes_aux(acc, typeRequired, child)
      end
      return acc
    end
  else SU.error("invalid argument to inferArgTypes_aux") end
end

local inferArgTypes = function(body)
  return inferArgTypes_aux({}, objType.tree, body)
end

local function registerCommand(name, argTypes, fun)
  commands[name] = {argTypes, fun}
end

local function fold_pairs(fun, init, table)
  local acc = init
  for k,x in pairs(table) do
    acc = fun(acc, k, x)
  end
  return acc
end

local function forall(pred, list)
  for _,x in ipairs(list) do
    if not pred(x) then return false end
  end
  return true
end

local compileToStr = function(argEnv, mathlist)
  if #mathlist == 1 and mathlist.id == "atom" then
    -- List is a single atom
    return mathlist[1]
  elseif #mathlist == 1 and mathlist[1].id == "argument" then
    return argEnv[mathlist[1].index]
  elseif mathlist.id == "argument" then
    return argEnv[mathlist.index]
  else
    local ret = ""
    for _,elt in ipairs(mathlist) do
      if elt.id == "atom" then
        ret = ret .. elt[1]
      elseif elt.id == "command" and symbols[elt.command] then
        ret = ret .. symbols[elt.command]
      else
        SU.error("Encountered non-character token in command that takes a string")
      end
    end
    return ret
  end
end

local function compileToMathML(arg_env, tree)
  if type(tree) == "string" then return tree end
  tree = fold_pairs(function(acc, key, child)
    if type(key) ~= "number" then
      acc[key] = child
      return acc
    -- Compile all children, except if this node is a macro definition (no
    -- evaluation "under lambda") or the application of a registered macro
    -- (since evaluating the nodes depends on the macro's signature, it is more
    -- complex and done below)..
    elseif tree.id == "def" or (tree.id == "command" and commands[tree.command]) then
      -- Conserve unevaluated children.
      table.insert(acc, child)
    else
      -- Compile all children.
      local comp = compileToMathML(arg_env, child)
      if comp then table.insert(acc, comp) end
    end
    return acc
  end, {}, tree)
  if tree.id == "texlike_math" then
    tree.command = "math"
    -- If the outermost `mrow` contains only other `mrow`s, remove it
    -- (allowing vertical stacking).
    if forall(function(c) return c.command == "mrow" end, tree[1]) then
      tree[1].command = "math"
      return tree[1]
    end
  elseif tree.id == "mathlist" then
    -- Turn mathlist into `mrow` except if it has exactly one `mtr` or `mtd`
    -- child.
    -- Note that `def`s have already been compiled away at this point.
    if #tree == 1 and (tree[1].command == "mtr" or tree[1].command == "mtd") then
      return tree[1]
    else tree.command = "mrow" end
    tree.command = "mrow"
  elseif tree.id == "atom" then
    local codepoints = {}
    for _, cp in luautf8.codes(tree[1]) do
      table.insert(codepoints, cp)
    end
    local cp = codepoints[1]
    if #codepoints == 1 and ( -- If length of UTF-8 string is 1
       cp >= SU.codepoint("A") and cp <= SU.codepoint("Z") or
       cp >= SU.codepoint("a") and cp <= SU.codepoint("z") or
       cp >= SU.codepoint("Α") and cp <= SU.codepoint("Ω") or
       cp >= SU.codepoint("α") and cp <= SU.codepoint("ω")
    ) then
        tree.command = "mi"
    elseif lpeg.match(lpeg.R("09")^1, tree[1]) then
      tree.command = "mn"
    else
      tree.command = "mo"
    end
    tree.options = {}
  -- Translate TeX-like sub/superscripts to `munderover` or `msubsup`,
  -- depending on whether the base is a big operator
  elseif tree.id == "sup" and tree[1].command == "mo"
      and tree[1].atomType == atomType.bigOperator then
    tree.command = "mover"
  elseif tree.id == "sub" and tree[1].command == "mo"
      and symbolDefaults[tree[1][1]].atomType == atomType.bigOperator then
      tree.command = "munder"
  elseif tree.id == "subsup" and tree[1].command == "mo"
      and symbolDefaults[tree[1][1]].atomType == atomType.bigOperator then
    tree.command = "munderover"
  elseif tree.id == "supsub" and tree[1].command == "mo"
      and symbolDefaults[tree[1][1]].atomType == atomType.bigOperator then
    tree.command = "munderover"
    local tmp = tree[2]
    tree[2] = tree[3]
    tree[3] = tmp
  elseif tree.id == "sup" then
    tree.command = "msup"
  elseif tree.id == "sub" then
      tree.command = "msub"
  elseif tree.id == "subsup" then
    tree.command = "msubsup"
  elseif tree.id == "supsub" then
    tree.command = "msubsup"
    local tmp = tree[2]
    tree[2] = tree[3]
    tree[3] = tmp
  elseif tree.id == "def" then
    local commandName = tree["command-name"]
    local argTypes = inferArgTypes(tree[1])
    registerCommand(commandName, argTypes, function(compiledArgs)
      return compileToMathML(compiledArgs, tree[1])
    end)
    return nil
  elseif tree.id == "command" and commands[tree.command] then
    local argTypes = commands[tree.command][1]
    local cmdFun = commands[tree.command][2]
    local applicationTree = tree
    local cmdName = tree.command
    if #applicationTree ~= #argTypes then
      SU.error("Wrong number of arguments (" .. #applicationTree ..
        ") for command " .. cmdName .. " (should be " ..
        #argTypes .. ")")
    end
    -- Compile every argument
    local compiledArgs = {}
    for i,arg in pairs(applicationTree) do
      if type(i) == "number" then
        if argTypes[i] == objType.tree then
          table.insert(compiledArgs, compileToMathML(arg_env, arg))
        else
          local x = compileToStr(arg_env, arg)
          table.insert(compiledArgs, x)
        end
      else
        -- Not an argument but an attribute. Add it to the compiled
        -- argument tree as-is
        compiledArgs[i] = applicationTree[i]
      end
    end
    return cmdFun(compiledArgs)
  elseif tree.id == "command" and symbols[tree.command] then
    local atom = {id = "atom", [1] = symbols[tree.command]}
    tree = compileToMathML(arg_env, atom)
  elseif tree.id == "argument" then
    if arg_env[tree.index] then
      return arg_env[tree.index]
    else
      SU.error("Argument #"..tree.index.." has escaped its scope (probably not fully applied command).")
    end
  end
  tree.id = nil
  SU.debug("texmath", "Resulting MathML:\n" .. tostring(tree))
  return tree
end

local function convertTexlike(content)
  local ret = epnf.parsestring(mathParser, content[1])
  SU.debug("texmath", "parsed TeX math:\n" .. tostring(ret))
  return ret
end

registerCommand("mi", {[1]=objType.str}, function(x) return x end)
registerCommand("mo", {[1]=objType.str}, function(x) return x end)
registerCommand("mn", {[1]=objType.str}, function(x) return x end)

compileToMathML({}, convertTexlike({[==[
  \def{frac}{\mfrac{#1}{#2}}
  \def{bi}{\mi[mathvariant=bold-italic]{#1}}
  \def{dsi}{\mi[mathvariant=double-struck]{#1}}
]==]}))

return {
  convertTexlike = convertTexlike,
  compileToMathML = compileToMathML,
  registerCommand = registerCommand,
}
