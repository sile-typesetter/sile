SILE.inputs.common = {
  init = function(fn, t)
    local dclass = t.attr.class or "plain"
    t.attr.papersize = t.attr.papersize or "a4"
    SILE.documentState.documentClass = SILE.require("classes/"..dclass)
    for k,v in pairs(t.attr) do
      if SILE.documentState.documentClass.options[k] then
        SILE.documentState.documentClass.options[k](v)
      end
    end

    -- Prepend the dirname of the input file to the Lua search path
    local dirname = SILE.masterFilename:match("(.-)[^%/]+$")
    package.path = dirname.."?;"..dirname.."?.lua;"..package.path

    if not SILE.outputFilename and SILE.masterFilename then
      SILE.outputFilename = string.gsub(SILE.masterFilename,"%..-$", "").. ".pdf"
    end
    local ff = SILE.documentState.documentClass:init()
    SILE.typesetter:init(ff)
  end
}

SILE.process = function(input)
  if type(input) == "function" then return input() end
  for i=1, #input do
    SILE.currentCommand = input[i]
    content = input[i]
    if type(content) == "string" then
      SILE.typesetter:typeset(content)
    elseif SILE.Commands[content.tag] then
      SILE.Commands[content.tag](content.attr,content)
    elseif content.id == "stuff" or (not content.tag and not content.id) then
      SILE.process(content)
    else
      SU.error("Unknown command "..(content.tag or content.id))
    end
  end
end

-- Just a simple one-level find. We're not reimplementing XPath here.
SILE.findInTree = function (t, tag)
  for i=1, #t do
    if type(t[i]) == "string" then
    elseif t[i].tag == tag then
      return t[i]
    end
  end
end
