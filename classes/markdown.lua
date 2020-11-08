-- You will need my lunamark fork from https://github.com/simoncozens/lunamark
-- for the AST writer.

SILE.inputs.markdown = {
  order = 2,
  appropriate = function (fn, _)
    return fn:match("md$") or fn:match("markdown$")
  end,
  process = function (data)
    local lunamark = require("lunamark")
    local reader = lunamark.reader.markdown
    local writer = lunamark.writer.ast.new()
    local parse = reader.new(writer)
    local t = parse(data)
    t = { [1] = t, id = "document", options = { class = "markdown" }}
    -- SILE.inputs.common.init(fn, t)
    SILE.process(t[1])
  end
}

SILE.require("packages/url")
SILE.require("packages/image")

local book = SILE.require("book", "classes")
local markdown = book { id = "markdown" }

function markdown:init ()
  return book.init(self)
end

SILE.registerCommand("sect1", function (options, content)
  SILE.call("chapter", options, content)
end)

SILE.registerCommand("sect2", function (options, content)
  SILE.call("section", options, content)
end)

SILE.registerCommand("sect3", function (options, content)
  SILE.call("subsection", options, content)
end)

SILE.registerCommand("emphasis", function (options, content)
  SILE.call("em", options, content)
end)

SILE.registerCommand("paragraph", function (_, content)
  SILE.process(content)
  SILE.call("par")
end)

SILE.registerCommand("bulletlist", function (_, content)
  SILE.process(content)
end)

SILE.registerCommand("link", function (_, content)
    SILE.call("verbatim:font", {}, content)
end)

SILE.registerCommand("image", function (_, content)
  SILE.call("img", {src=content.src})
end)

return markdown
