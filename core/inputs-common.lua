SILE.inputs.common = {

  init = function (_, tree)
    local class = tree.options.class or "plain"
    local constructor = require("classes."..class)
    -- Shim legacy stdlib based classes (most shim work done by here)
    if constructor._deprecated then
      if constructor._base._deprecated then
        SU.error("Double inheritance of legacy classes detected. I (Caleb) spent "
               .."*way too much* time making the shim work for one level, I'm "
               .."not going here. Convert your classes already.")
      end
    end
    SILE.documentState.documentClass = constructor:_init(tree.options)
    -- Prepend the dirname of the input file to the Lua search path
    local dirname = SILE.masterFilename:match("(.-)[^%/]+$")
    package.path = dirname.."?;"..dirname.."?.lua;"..package.path
  end
}

local function debugAST(ast, level)
  if not ast then SU.error("debugAST called with nil", true) end
  local out = string.rep("  ", 1+level)
  if level == 0 then SU.debug("ast", "["..SILE.currentlyProcessingFile) end
  if type(ast) == "function" then SU.debug("ast", out.."(function)") end
  for i=1, #ast do
    local content = ast[i]
    if type(content) == "string" then
      SU.debug("ast", out.."["..content.."]")
    elseif SILE.Commands[content.command] then
      local options = pl.tablex.size(content.options) > 0 and content.options or ""
      SU.debug("ast", out.."\\"..content.command..options)
      if (#content>=1) then debugAST(content, level+1) end
    elseif content.id == "texlike_stuff" or (not content.command and not content.id) then
      debugAST(content, level+1)
    else
      SU.debug("ast", out.."?\\"..(content.command or content.id))
    end
  end
  if level == 0 then SU.debug("ast", "]") end
end

SILE.process = function (input)
  if not input then return end
  if type(input) == "function" then return input() end
  if SU.debugging("ast") then
    debugAST(input, 0)
  end
  for i=1, #input do
    local content = input[i]
    if type(content) == "string" then
      SILE.typesetter:typeset(content)
    elseif type(content) == "function" then
      content()
    elseif SILE.Commands[content.command] then
      SILE.call(content.command, content.options, content)
    elseif content.id == "texlike_stuff" or (not content.command and not content.id) then
      local pId = SILE.traceStack:pushContent(content, "texlike_stuff")
      SILE.process(content)
      SILE.traceStack:pop(pId)
    else
      local pId = SILE.traceStack:pushContent(content)
      SU.error("Unknown command "..(content.command or content.id))
      SILE.traceStack:pop(pId)
    end
  end
end

-- Just a simple one-level find. We're not reimplementing XPath here.
SILE.findInTree = function (tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return tree[i]
    end
  end
end
