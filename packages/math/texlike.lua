local atoms = require("packages.math.atoms")
local syms = require("packages.math.unicode-symbols")
local bits = require("core.parserbits")

local epnf = require("epnf")
local lpeg = require("lpeg")

local operatorDict = syms.operatorDict
local symbols = syms.symbols

-- Grammar to parse TeX-like math
-- luacheck: push ignore
-- stylua: ignore start
---@diagnostic disable: undefined-global, unused-local, lowercase-global
local mathGrammar = function (_ENV)
   local _ = WS^0
   local eol = S"\r\n"
   local digit = R("09")
   local natural = (
      -- TeX doesn't really knows what a number in a formula is.
      -- It handles any sequence of "ordinary" characters, including period(s):
      -- See for instance The TeXbook, p. 132.
      -- When later converting to MathML, we'll ideally want <mn>0.0123</mn>
      -- instead of, say, <mn>0</mn><mo>.</mo><mn>0123</mn> (not only wrong
      -- in essence, but also taking the risk of using a <mo> operator, then
      -- considered as a punctuation, thus inserting a space)
      -- We cannot be general, but checking MathJax and TeMML's behavior, they
      -- are not general either in this regard.
         digit^0 * P(".")^-1 * digit^1 + -- Decimal number (ex: 1.23, 0.23, .23)
         digit^1 -- Integer (digits only, ex: 123)
      ) / tostring
   local pos_natural = R("19") * digit^0 / tonumber

   -- \left and \right delimiters = The TeXbook p. 148.
   -- Characters with a delcode in TeX: The TeXbook p. 341
   -- These are for use in \left...\right pairs.
   -- We add the period (null delimiter) from p. 149-150.
   -- We don't include the backslash here and handle it just after.
   local delcode = S"([</|)]>."
   -- Left/right is followed by a delimiter with delcode, or a command.
   -- We use the delcode or backslash as terminator: commands such as
   -- \rightarrow must still be allowed.
   local leftright = function (s) return P(s) * (delcode + P"\\") end

   local ctrl_word = R("AZ", "az")^1
   local ctrl_symbol = P(1) - S"{}\\"
   local ctrl_sequence_name = C(ctrl_word + ctrl_symbol) - leftright("left") - leftright("right") / 1
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
   local sileID = C(bits.identifier + P(1)) / 1
   local mathMLID = (utf8code - S"\\{}%")^1 / function (...)
         local ret = ""
         local t = {...}
         for _,b in ipairs(t) do
         ret = ret .. b
         end
         return ret
      end
   local group = P"{" * V"mathlist" * (P"}" + E("`}` expected"))
   -- Simple amsmath-like \text command (no embedded math)
   local textgroup = P"{" * C((1-P"}")^1) * (P"}" + E("`}` expected"))
   -- TeX \left...\right group
   local delim =
      -- Delimiter with delcode
      C(delcode) / function (d)
         if d ~= "." then
            return {
               id = "atom",
               d
            }
         end
         return nil
      end
      -- Delimiter as escaped \{ or \}
      + P"\\" * C(S"{}") / function (d)
         return {
            id = "atom",
            d
         }
      end
      -- Delimiter as command ex. \langle
      + P"\\" * C(ctrl_sequence_name) / 1 / function (cmd)
         return {
            id = "command",
            command = cmd
         }
      end

      local leftrightgroup = P"\\left" * delim * V"mathlist" * P"\\right" * delim
         / function (left, subformula, right)
            if not left and not right then
               -- No delimiters, return the subformula as-is
               return subformula
            end
            -- Rewrap the subformula in a flagged mathlist
            local mrow = {
               id = "mathlist",
               options = {},
               is_paired_explicit = true, -- Internal flag
               subformula
            }
            if left then
               table.insert(mrow, 1, left)
            end
            if right then
               table.insert(mrow, right)
            end
            return mrow
         end

   local element_no_infix =
      leftrightgroup + -- Important: before command
      V"def" +
      V"text" + -- Important: before command
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
      local t = {...}; return t[1], t[#t]
   end
   local list = Cf(Ct"" * pair^0, rawset)
   local parameters = (
         P"[" *
         list *
         P"]"
      )^-1 / function (a)
            return type(a)=="table" and a or {}
         end
   local dim2_arg_inner = Ct(V"mathlist" * (P"&" * V"mathlist")^0) /
      function (t)
         t.id = "mathlist"
         return t
      end
   local dim2_arg =
      Cg(P"{" *
         dim2_arg_inner *
         (P"\\\\" * dim2_arg_inner)^1 *
         (P"}" + E("`}` expected"))
         ) / function (...)
            local t = {...}
            -- Remove the last mathlist if empty. This way,
            -- `inner1 \\ inner2 \\` is the same as `inner1 \\ inner2`.
            if not t[#t][1] or not t[#t][1][1] then table.remove(t) end
            return pl.utils.unpack(t)
         end

   local dim2_arg_inner = Ct(V"mathlist" * (P"&" * V"mathlist")^0) /
      function (t)
         t.id = "mathlist"
         return t
      end
   local dim2_arg =
      Cg(P"{" *
         dim2_arg_inner *
         (P"\\\\" * dim2_arg_inner)^1 *
         (P"}" + E("`}` expected"))
         ) / function (...)
         local t = {...}
         -- Remove the last mathlist if empty. This way,
         -- `inner1 \\ inner2 \\` is the same as `inner1 \\ inner2`.
         if not t[#t][1] or not t[#t][1][1] then table.remove(t) end
         return pl.utils.unpack(t)
         end

   -- TeX uses the regular asterisk (* = U+002A) in superscripts or subscript:
   -- The TeXbook exercice 18.32 (p. 179, 330) for instance.
   -- Fonts usually have the asterisk raised too high, so using the Unicode
   -- asterisk operator U+2217 looks better (= \ast in TeX).
   local astop = P"*" / luautf8.char(0x2217)
   -- TeX interprets apostrophes as primes in math mode:
   -- The TeXbook p. 130 expands ' to ^\prime commands and repeats the \prime
   -- for multiple apostrophes.
   -- The TeXbook p. 134: "Then there is the character ', which we know is used
   -- as an abbreviation for \prime superscripts."
   -- (So we are really sure superscript primes are really the intended meaning.)
   -- Here we use the Unicode characters for primes, but the intent is the same.
   local primes = (
         P"''''" / luautf8.char(0x2057) + -- quadruple prime
         P"'''" / luautf8.char(0x2034) + -- triple prime
         P"''" / luautf8.char(0x2033) + -- double prime
         P"'" / luautf8.char(0x2032) -- prime
      ) / function (s)
            return { id="atom", s }
         end
   local primes_sup = (
         primes * _ * P"^" * _ * element_no_infix / function (p, e)
            -- Combine the prime with the superscript in the same mathlist
            if e.id == "mathlist" then
               table.insert(e, 1, p)
               return e
            end
            return { id="mathlist", p, e }
         end
         + primes -- or standalone primes
      )

   START "math"
   math = V"mathlist" * EOF"Unexpected character at end of math code"
   mathlist = (comment + (WS * _) + element)^0
   supsub = element_no_infix * _ * primes_sup                  * _ *  P"_" * _ * element_no_infix +
            element_no_infix * _ * P"^" * _ * element_no_infix * _ *  P"_" * _ * element_no_infix
   subsup = element_no_infix * _ * P"_" * _ * element_no_infix * primes_sup +
            element_no_infix * _ * P"_" * _ * element_no_infix * _ * P"^" * _ * element_no_infix
   sup =  element_no_infix * _ * primes_sup +
          element_no_infix * _ * P"^" * _ * element_no_infix
   sub = element_no_infix * _ * P"_" * _ * element_no_infix
   atom = natural + astop + C(utf8code - S"\\{}%^_&'") +
      (P"\\{" + P"\\}") / function (s) return string.sub(s, -1) end
   text = (
         P"\\text" *
         Cg(parameters, "options") *
         textgroup
      )
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
-- stylua: ignore end
---@diagnostic enable: undefined-global, unused-local, lowercase-global

local mathParser = epnf.define(mathGrammar)

local commands = {}

-- A command type is a type for each argument it takes: either string or MathML
-- tree. If a command has no type, it is assumed to take only trees.
-- Tags like <mi>, <mo>, <mn> take a string, and this needs to be propagated in
-- commands that use them.

local objType = {
   tree = 1,
   str = 2,
}

local function inferArgTypes_aux (accumulator, typeRequired, body)
   if type(body) == "table" then
      if body.id == "argument" then
         local ret = accumulator
         table.insert(ret, body.index, typeRequired)
         return ret
      elseif body.id == "command" then
         if commands[body.command] then
            local cmdArgTypes = commands[body.command][1]
            if #cmdArgTypes ~= #body then
               SU.error(
                  "Wrong number of arguments ("
                     .. #body
                     .. ") for command "
                     .. body.command
                     .. " (should be "
                     .. #cmdArgTypes
                     .. ")"
               )
            else
               for i = 1, #cmdArgTypes do
                  accumulator = inferArgTypes_aux(accumulator, cmdArgTypes[i], body[i])
               end
            end
            return accumulator
         elseif body.command == "mi" or body.command == "mo" or body.command == "mn" then
            if #body ~= 1 then
               SU.error("Wrong number of arguments (" .. #body .. ") for command " .. body.command .. " (should be 1)")
            end
            accumulator = inferArgTypes_aux(accumulator, objType.str, body[1])
            return accumulator
         else
            -- Not a macro, recurse on children assuming tree type for all
            -- arguments
            for _, child in ipairs(body) do
               accumulator = inferArgTypes_aux(accumulator, objType.tree, child)
            end
            return accumulator
         end
      elseif body.id == "atom" then
         return accumulator
      else
         -- Simply recurse on children
         for _, child in ipairs(body) do
            accumulator = inferArgTypes_aux(accumulator, typeRequired, child)
         end
         return accumulator
      end
   else
      SU.error("invalid argument to inferArgTypes_aux")
   end
end

local inferArgTypes = function (body)
   return inferArgTypes_aux({}, objType.tree, body)
end

local function registerCommand (name, argTypes, func)
   commands[name] = { argTypes, func }
end

-- Computes func(func(... func(init, k1, v1), k2, v2)..., k_n, v_n), i.e. applies
-- func on every key-value pair in the table. Keys with numeric indices are
-- processed in order. This is an important property for MathML compilation below.
local function fold_pairs (func, table)
   local accumulator = {}
   for k, v in pl.utils.kpairs(table) do
      accumulator = func(v, k, accumulator)
   end
   for i, v in ipairs(table) do
      accumulator = func(v, i, accumulator)
   end
   return accumulator
end

local function forall (pred, list)
   for _, x in ipairs(list) do
      if not pred(x) then
         return false
      end
   end
   return true
end

local compileToStr = function (argEnv, mathlist)
   if #mathlist == 1 and mathlist.id == "atom" then
      -- List is a single atom
      return mathlist[1]
   elseif #mathlist == 1 and mathlist[1].id == "argument" then
      return argEnv[mathlist[1].index]
   elseif mathlist.id == "argument" then
      return argEnv[mathlist.index]
   else
      local ret = ""
      for _, elt in ipairs(mathlist) do
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

local function isOperatorKind (tree, typeOfAtom)
   if not tree then
      return false -- safeguard
   end
   if tree.command ~= "mo" then
      return false
   end
   -- Case \mo[atom=xxx]{ops}
   -- E.g. \mo[atom=op]{lim}
   if tree.options and tree.options.atom then
      return atoms.types[tree.options.atom] == typeOfAtom
   end
   -- Case \mo{ops} where ops is registered with the resquested type
   -- E.g. \mo{∑) or \sum
   if tree[1] and operatorDict[tree[1]] and operatorDict[tree[1]].atom then
      return operatorDict[tree[1]].atom == typeOfAtom
   end
   return false
end

local function isMoveableLimits (tree)
   if tree.command ~= "mo" then
      return false
   end
   if tree.options and SU.boolean(tree.options.movablelimits, false) then
      return true
   end
   if tree[1] and operatorDict[tree[1]] and operatorDict[tree[1]].forms then
      -- Leap of faith: We have not idea yet which form the operator will take
      -- in the final MathML.
      -- In the MathML operator dictionary, some operators have a movablelimits
      -- in some forms and not in others.
      -- Ex. \Join (U+2A1D) and \bigtriangleleft (U+2A1E) have it prefix but not
      -- infix, for some unspecified reason (?).
      -- Assume that if at least one form has movablelimits, the operator is
      -- considered to have movablelimits "in general".
      for _, form in pairs(operatorDict[tree[1]].forms) do
         if SU.boolean(form.movablelimits, false) then
            return true
         end
      end
   end
   return false
end
local function isCloseOperator (tree)
   return isOperatorKind(tree, atoms.types.close)
end
local function isOpeningOperator (tree)
   return isOperatorKind(tree, atoms.types.open)
end

local function isAccentSymbol (symbol)
   return operatorDict[symbol] and operatorDict[symbol].atom == atoms.types.accent
end

local function compileToMathML_aux (_, arg_env, tree)
   if type(tree) == "string" then
      return tree
   end
   local function compile_and_insert (child, key, accumulator)
      if type(key) ~= "number" then
         accumulator[key] = child
         return accumulator
      -- Compile all children, except if this node is a macro definition (no
      -- evaluation "under lambda") or the application of a registered macro
      -- (since evaluating the nodes depends on the macro's signature, it is more
      -- complex and done below)..
      elseif tree.id == "def" or (tree.id == "command" and commands[tree.command]) then
         -- Conserve unevaluated child
         table.insert(accumulator, child)
      else
         -- Compile next child
         local comp = compileToMathML_aux(nil, arg_env, child)
         if comp then
            if comp.id == "wrapper" then
               -- Insert all children of the wrapper node
               for _, inner_child in ipairs(comp) do
                  table.insert(accumulator, inner_child)
               end
            else
               table.insert(accumulator, comp)
            end
         end
      end
      return accumulator
   end
   tree = fold_pairs(compile_and_insert, tree)
   if tree.id == "math" then
      tree.command = "math"
      -- If the outermost `mrow` contains only other `mrow`s, remove it
      -- (allowing vertical stacking).
      if forall(function (c)
         return c.command == "mrow"
      end, tree[1]) then
         tree[1].command = "math"
         return tree[1]
      end
   elseif tree.id == "mathlist" then
      -- Turn mathlist into `mrow` except if it has exactly one `mtr` or `mtd`
      -- child.
      -- Note that `def`s have already been compiled away at this point.
      if #tree == 1 then
         if tree[1].command == "mtr" or tree[1].command == "mtd" then
            return tree[1]
         else
            tree.command = "mrow"
         end
      elseif tree.is_paired_explicit then
         -- We already did the re-wrapping of open/close delimiters in the parser
         -- via \left...\right, doing it would not harm but would add an extra mrow,
         -- which we can avoid directly to keep the tree minimal.
         -- N.B. We could have used the same flag, but it's easier to debug this way.
         tree.is_paired = true
         tree.is_paired_explicit = nil
         tree.command = "mrow"
      else
         -- Re-wrap content from opening to closing operator in an implicit mrow,
         -- so stretchy operators apply to the correct span of content.
         local children = {}
         local stack = {}
         for _, child in ipairs(tree) do
            if isOpeningOperator(child) then
               table.insert(stack, children)
               local mrow = {
                  command = "mrow",
                  is_paired = true, -- Internal flag to mark this re-wrapped mrow
                  options = {},
                  child,
               }
               table.insert(children, mrow)
               children = mrow
            elseif isCloseOperator(child) then
               table.insert(children, child)
               if #stack > 0 then
                  children = table.remove(stack)
               end
            elseif
               (child.command == "msubsup" or child.command == "msub" or child.command == "msup")
               and isCloseOperator(child[1]) -- child[1] is the base
            then
               if #stack > 0 then
                  -- Special case for closing operator with sub/superscript:
                  -- (....)^i must be interpreted as {(....)}^i, not as (...{)}^i
                  -- Push the closing operator into the mrow
                  table.insert(children, child[1])
                  -- Move the mrow into the msubsup, replacing the closing operator
                  child[1] = children
                  -- And insert the msubsup into the parent
                  children = table.remove(stack)
                  children[#children] = child
               else
                  table.insert(children, child)
               end
            else
               table.insert(children, child)
            end
         end
         tree = #stack > 0 and stack[1] or children
         tree.command = "mrow"
      end
   elseif tree.id == "atom" then
      local codepoints = {}
      for _, cp in luautf8.codes(tree[1]) do
         table.insert(codepoints, cp)
      end
      local cp = codepoints[1]
      if
         #codepoints == 1
         and ( -- If length of UTF-8 string is 1
            cp >= SU.codepoint("A") and cp <= SU.codepoint("Z")
            or cp >= SU.codepoint("a") and cp <= SU.codepoint("z")
            or cp >= SU.codepoint("Α") and cp <= SU.codepoint("Ω")
            or cp >= SU.codepoint("α") and cp <= SU.codepoint("ω")
            or cp == SU.codepoint("ϑ")
            or cp == SU.codepoint("ϕ")
            or cp == SU.codepoint("ϰ")
            or cp == SU.codepoint("ϱ")
            or cp == SU.codepoint("ϖ")
            or cp == SU.codepoint("ϵ")
         )
      then
         tree.command = "mi"
      elseif lpeg.match(lpeg.R("09") ^ 1, tree[1]) then
         tree.command = "mn"
      else
         tree.command = "mo"
      end
      tree.options = {}
   -- Translate TeX-like sub/superscripts to `munderover` or `msubsup`,
   -- depending on whether the base is an operator with moveable limits.
   elseif tree.id == "sup" and isMoveableLimits(tree[1]) then
      tree.command = "mover"
   elseif tree.id == "sub" and isMoveableLimits(tree[1]) then
      tree.command = "munder"
   elseif tree.id == "subsup" and isMoveableLimits(tree[1]) then
      tree.command = "munderover"
   elseif tree.id == "supsub" and isMoveableLimits(tree[1]) then
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
      registerCommand(commandName, argTypes, function (compiledArgs)
         return compileToMathML_aux(nil, compiledArgs, tree[1])
      end)
      return nil
   elseif tree.id == "text" then
      tree.command = "mtext"
   elseif tree.id == "command" and commands[tree.command] then
      local argTypes = commands[tree.command][1]
      local cmdFun = commands[tree.command][2]
      local applicationTree = tree
      local cmdName = tree.command
      if #applicationTree ~= #argTypes then
         SU.error(
            "Wrong number of arguments ("
               .. #applicationTree
               .. ") for command "
               .. cmdName
               .. " (should be "
               .. #argTypes
               .. ")"
         )
      end
      -- Compile every argument
      local compiledArgs = {}
      for i, arg in pairs(applicationTree) do
         if type(i) == "number" then
            if argTypes[i] == objType.tree then
               table.insert(compiledArgs, compileToMathML_aux(nil, arg_env, arg))
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
      local res = cmdFun(compiledArgs)
      if res.command == "mrow" then
         -- Mark the outer mrow to be unwrapped in the parent
         res.id = "wrapper"
      end
      return res
   elseif tree.id == "command" and symbols[tree.command] then
      local atom = { id = "atom", [1] = symbols[tree.command] }
      if isAccentSymbol(symbols[tree.command]) and #tree > 0 then
         -- LaTeX-style accents \vec{v} = <mover accent="true"><mi>v</mi><mo>→</mo></mover>
         local accent = {
            id = "command",
            command = "mover",
            options = {
               accent = "true",
            },
         }
         accent[1] = compileToMathML_aux(nil, arg_env, tree[1])
         accent[2] = compileToMathML_aux(nil, arg_env, atom)
         tree = accent
      elseif #tree > 0 then
         -- Play cool with LaTeX-style commands that don't take arguments:
         -- Edge case for non-accent symbols so we don't loose bracketed groups
         -- that might have been seen as command arguments.
         -- Ex. \langle{x}\rangle (without space after \langle)
         local sym = compileToMathML_aux(nil, arg_env, atom)
         -- Compile all children in-place
         for i, child in ipairs(tree) do
            tree[i] = compileToMathML_aux(nil, arg_env, child)
         end
         -- Insert symbol at the beginning,
         -- And add a wrapper mrow to be unwrapped in the parent.
         table.insert(tree, 1, sym)
         tree.command = "mrow"
         tree.id = "wrapper"
      else
         tree = compileToMathML_aux(nil, arg_env, atom)
      end
   elseif tree.id == "argument" then
      if arg_env[tree.index] then
         return arg_env[tree.index]
      else
         SU.error("Argument #" .. tree.index .. " has escaped its scope (probably not fully applied command).")
      end
   end
   tree.id = nil
   return tree
end

local function printMathML (tree)
   if type(tree) == "string" then
      return tree
   end
   local result = "\\" .. tree.command
   if tree.options then
      local options = {}
      for k, v in pairs(tree.options) do
         table.insert(options, k .. "=" .. tostring(v))
      end
      if #options > 0 then
         result = result .. "[" .. table.concat(options, ", ") .. "]"
      end
   end
   if #tree > 0 then
      result = result .. "{"
      for _, child in ipairs(tree) do
         result = result .. printMathML(child)
      end
      result = result .. "}"
   end
   return result
end

local function compileToMathML (_, arg_env, tree)
   local result = compileToMathML_aux(_, arg_env, tree)
   SU.debug("texmath", function ()
      return "Resulting MathML: " .. printMathML(result)
   end)
   return result
end

local function convertTexlike (_, content)
   local ret = epnf.parsestring(mathParser, content[1])
   SU.debug("texmath", function ()
      return "Parsed TeX math: " .. pl.pretty.write(ret)
   end)
   return ret
end

registerCommand("mi", { [1] = objType.str }, function (x)
   return x
end)
registerCommand("mo", { [1] = objType.str }, function (x)
   return x
end)
registerCommand("mn", { [1] = objType.str }, function (x)
   return x
end)

compileToMathML(
   nil,
   {},
   convertTexlike(nil, {
      [==[
  \def{frac}{\mfrac{#1}{#2}}
  \def{sqrt}{\msqrt{#1}}
  \def{bi}{\mi[mathvariant=bold-italic]{#1}}
  \def{dsi}{\mi[mathvariant=double-struck]{#1}}
  \def{vec}{\mover[accent=true]{#1}{\rightarrow}}

  % From amsmath:
  \def{to}{\mo[atom=bin]{→}}
  \def{lim}{\mo[atom=op, movablelimits=true]{lim}}
  \def{gcd}{\mo[atom=op, movablelimits=true]{gcd}}
  \def{sup}{\mo[atom=op, movablelimits=true]{sup}}
  \def{inf}{\mo[atom=op, movablelimits=true]{inf}}
  \def{max}{\mo[atom=op, movablelimits=true]{max}}
  \def{min}{\mo[atom=op, movablelimits=true]{min}}
  % Those use U+202F NARROW NO-BREAK SPACE in their names
  \def{limsup}{\mo[atom=op, movablelimits=true]{lim sup}}
  \def{liminf}{\mo[atom=op, movablelimits=true]{lim inf}}
  \def{projlim}{\mo[atom=op, movablelimits=true]{proj lim}}
  \def{injlim}{\mo[atom=op, movablelimits=true]{inj lim}}

  % Other pre-defined operators from the TeXbook, p. 162:
  % TeX of course defines them with \mathop, so we use atom=op here.
  % MathML would use a <mi> here.
  % But we use a <mo> so the atom type is handled
  \def{arccos}{\mo[atom=op]{arccos}}
  \def{arcsin}{\mo[atom=op]{arcsin}}
  \def{arctan}{\mo[atom=op]{arctan}}
  \def{arg}{\mo[atom=op]{arg}}
  \def{cos}{\mo[atom=op]{cos}}
  \def{cosh}{\mo[atom=op]{cosh}}
  \def{cot}{\mo[atom=op]{cot}}
  \def{coth}{\mo[atom=op]{coth}}
  \def{csc}{\mo[atom=op]{csc}}
  \def{deg}{\mo[atom=op]{deg}}
  \def{det}{\mo[atom=op]{det}}
  \def{dim}{\mo[atom=op]{dim}}
  \def{exp}{\mo[atom=op]{exp}}
  \def{hom}{\mo[atom=op]{hom}}
  \def{ker}{\mo[atom=op]{ker}}
  \def{lg}{\mo[atom=op]{lg}}
  \def{ln}{\mo[atom=op]{ln}}
  \def{log}{\mo[atom=op]{log}}
  \def{Pr}{\mo[atom=op]{Pr}}
  \def{sec}{\mo[atom=op]{sec}}
  \def{sin}{\mo[atom=op]{sin}}
  \def{sinh}{\mo[atom=op]{sinh}}
  \def{tan}{\mo[atom=op]{tan}}
  \def{tanh}{\mo[atom=op]{tanh}}

  % Standard spaces gleaned from plain TeX
  \def{thinspace}{\mspace[width=thin]}
  \def{negthinspace}{\mspace[width=-thin]}
  \def{,}{\thinspace}
  \def{!}{\negthinspace}
  \def{medspace}{\mspace[width=med]}
  \def{negmedspace}{\mspace[width=-med]}
  \def{>}{\medspace}
  \def{thickspace}{\mspace[width=thick]}
  \def{negthickspace}{\mspace[width=-thick]}
  \def{;}{\thickspace}
  \def{enspace}{\mspace[width=1en]}
  \def{enskip}{\enspace}
  \def{quad}{\mspace[width=1em]}
  \def{qquad}{\mspace[width=2em]}

  % MathML says a single-character identifier must be in italic by default.
  % TeX however has the following Greek capital macros rendered in upright shape.
  % It so common that you've probably never seen Γ(x) written with an italic gamma.
  \def{Gamma}{\mi[mathvariant=normal]{Γ}}
  \def{Delta}{\mi[mathvariant=normal]{Δ}}
  \def{Theta}{\mi[mathvariant=normal]{Θ}}
  \def{Lambda}{\mi[mathvariant=normal]{Λ}}
  \def{Xi}{\mi[mathvariant=normal]{Ξ}}
  \def{Pi}{\mi[mathvariant=normal]{Π}}
  \def{Sigma}{\mi[mathvariant=normal]{Σ}}
  \def{Upsilon}{\mi[mathvariant=normal]{Υ}}
  \def{Phi}{\mi[mathvariant=normal]{Φ}}
  \def{Psi}{\mi[mathvariant=normal]{Ψ}}
  \def{Omega}{\mi[mathvariant=normal]{Ω}}
  % Some calligraphic (script), fraktur, double-struck styles:
  % Convenience for compatibility with LaTeX.
  \def{mathcal}{\mi[mathvariant=script]{#1}}
  \def{mathfrak}{\mi[mathvariant=fraktur]{#1}}
  \def{mathbb}{\mi[mathvariant=double-struck]{#1}}
  % Some style-switching commands for compatibility with LaTeX math.
  % Caveat emptor: LaTeX would allow these to apply to a whole formula.
  % We can't do that in MathML, as mathvariant applies to token elements only.
  % Also note that LaTeX and related packages may have many more such commands.
  % We only provide a few common ('historical') ones here.
  \def{mathrm}{\mi[mathvariant=normal]{#1}}
  \def{mathbf}{\mi[mathvariant=bold]{#1}}
  \def{mathit}{\mi[mathvariant=italic]{#1}}
  \def{mathsf}{\mi[mathvariant=sans-serif]{#1}}
  \def{mathtt}{\mi[mathvariant=monospace]{#1}}

  % Modulus operator forms
  % See Michael Downes & Barbara Beeton, "Short Math Guide for LaTeX"
  % American Mathematical Society (v2.0, 2017), §7.1 p. 18
  \def{bmod}{\mo[atom=bin]{mod}}
  \def{pmod}{\quad(\mo[atom=ord]{mod}\>#1)}
  \def{mod}{\quad \mo[atom=ord]{mod}\>#1}
  \def{pod}{\quad(#1)}

  % Phantom commands from TeX/LaTeX
  \def{phantom}{\mphantom{#1}}
  \def{hphantom}{\mpadded[height=0, depth=0]{\mphantom{#1}}}
  \def{vphantom}{\mpadded[width=0]{\mphantom{#1}}}
]==],
   })
)

return { convertTexlike, compileToMathML }
