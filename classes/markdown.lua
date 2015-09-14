-- You will need my lunamark fork from https://github.com/simoncozens/lunamark
-- for the AST writer.

SILE.inputs.markdown = {
  order = 2,
  appropriate = function(fn, sniff)
    return fn:match("md$") or fn:match("markdown$")
  end,
  process = function (fn)
    local lunamark = require("lunamark")
    local reader = lunamark.reader.markdown
    local writer = lunamark.writer.ast.new()
    local fh = io.open(fn)
    local inp = fh:read("*all")
    local parse = reader.new(writer)
    local t = parse(inp)
    t = { [1] = t, id = "document", attr = { class = "markdown", papersize = "a4" }}
    SILE.inputs.common.init(fn, t)
    SILE.process(t[1])
  end
}

SILE.require("packages/verbatim")
local book = SILE.require("classes/book")

SILE.registerCommand("sect1", function(options, content)
  SILE.call("chapter", options, content)
end)

SILE.registerCommand("sect2", function(options, content)
  SILE.call("section", options, content)
end)

SILE.registerCommand("sect3", function(options, content)
  SILE.call("subsection", options, content)
end)

SILE.registerCommand("strong", function(options, content)
  SILE.call("em", options, content)
end)

SILE.registerCommand("emphasis", function(options, content)
  SILE.call("em", options, content)
end)


SILE.registerCommand("bulletlist", function(options, content)
  SILE.process(content)
end)

SILE.registerCommand("code", function(options, content)
  SILE.settings.temporarily(function()
    SILE.call("verbatim:font")
    SILE.process(content)
    SILE.typesetter:typeset(" ")
  end)
end)

SILE.registerCommand("link", function(options, content)
  -- SILE.settings.temporarily(function()
    -- SILE.call("verbatim:font")
    SILE.process(content)
  -- end)
end)


return book