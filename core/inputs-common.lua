SILE.inputs.common = {
  init = function(doc, tree)
    local dclass = tree.attr.class or "plain"
    tree.attr.papersize = tree.attr.papersize or "a4"
    SILE.documentState.documentClass = SILE.require(dclass, "classes")
    for k,v in pairs(tree.attr) do
      if SILE.documentState.documentClass.options[k] then
        SILE.documentState.documentClass.options[k](v)
      end
    end

    -- Prepend the dirname of the input file to the Lua search path
    local dirname = SILE.masterFilename:match("(.-)[^%/]+$")
    package.path = dirname.."?;"..dirname.."?.lua;"..package.path

    if not SILE.outputFilename and SILE.masterFilename then
      -- TODO: This hack works on *nix systems because /dev/stdout is usable as
      -- a filename to refer to STDOUT. Libtexpdf works fine with this, but it's
      -- not going to work on Windows quite the same way. Normal filnames will
      -- still work but explicitly using piped streams won't.
      if SILE.masterFilename == "-" then
        SILE.outputFilename = "/dev/stdout"
      else
        SILE.outputFilename = SILE.masterFilename..".pdf"
      end
    end
    local ff = SILE.documentState.documentClass:init()
    SILE.typesetter:init(ff)
  end
}

local function debugAST(ast,level)
  local out = string.rep("  ", 1+level)
  if level == 0 then SU.debug("ast", "["..SILE.currentlyProcessingFile) end
  if type(ast) == "function" then SU.debug("ast",out.."(function)") end
  if not ast then SU.error("SILE.process called with nil", 1) end
  for i=1, #ast do
    content = ast[i]
    if type(content) == "string" then
      SU.debug("ast",out.."["..content.."]")
    elseif SILE.Commands[content.tag] then
      local attrs = table.nitems(content.attr) > 0 and content.attr or ""
      SU.debug("ast",out.."\\"..content.tag..attrs)
      if (#content>=1) then debugAST(content,level+1) end
    elseif content.id == "texlike_stuff" or (not content.tag and not content.id) then
      debugAST(content,level+1)
    else
      SU.debug("ast",out.."?\\"..(content.tag or content.id))
    end
  end
  if level == 0 then SU.debug("ast", "]") end
end

SILE.process = function(input)
  if not input then SU.error("SILE.process called with nil", 1) end
  if type(input) == "function" then return input() end
  if SU.debugging("ast") then
    debugAST(input,0)
  end
  for i=1, #input do
    SILE.currentCommand = input[i]
    content = input[i]
    if type(content) == "string" then
      SILE.typesetter:typeset(content)
    elseif SILE.Commands[content.tag] then
      SILE.Commands[content.tag](content.attr,content)
    elseif content.id == "texlike_stuff" or (not content.tag and not content.id) then
      SILE.process(content)
    else
      SU.error("Unknown command "..(content.tag or content.id))
    end
  end
end

-- Just a simple one-level find. We're not reimplementing XPath here.
SILE.findInTree = function (tree, tag)
  for i=1, #tree do
    if type(tree[i]) == "string" then
    elseif tree[i].tag == tag then
      return tree[i]
    end
  end
end
