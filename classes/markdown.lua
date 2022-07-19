-- You will need my lunamark fork from https://github.com/simoncozens/lunamark
-- for the AST writer.

local book = require("classes.book")
local markdown = pl.class(book)
markdown._name = "markdown"

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

function markdown:_init (options)
  book._init(self, options)
  self:loadPackage("url")
  self:loadPackage("image")
  return self
end

function markdown:registerCommands ()

  book.registerCommands(self)

  self:registerCommand("sect1", function (options, content)
    SILE.call("chapter", options, content)
  end)

  self:registerCommand("sect2", function (options, content)
    SILE.call("section", options, content)
  end)

  self:registerCommand("sect3", function (options, content)
    SILE.call("subsection", options, content)
  end)

  self:registerCommand("emphasis", function (options, content)
    SILE.call("em", options, content)
  end)

  self:registerCommand("paragraph", function (_, content)
    SILE.process(content)
    SILE.call("par")
  end)

  self:registerCommand("bulletlist", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("link", function (_, content)
      SILE.call("verbatim:font", {}, content)
  end)

  self:registerCommand("image", function (_, content)
    SILE.call("img", {src=content.src})
  end)

end

return markdown
