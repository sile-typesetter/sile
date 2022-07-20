local book = require("classes.book")

local markdown = pl.class(book)
markdown._name = "markdown"

function markdown:_init (options)
  book._init(self, options)
  self:loadPackage("url")
  self:loadPackage("image")
  self:loadPackage("svg")
  self:loadPackage("rules")
  self:loadPackage("lists")
  self:loadPackage("ptable")
  -- self:loadPackage("textsubsuper") -- FIXME later, for now provide fallbacks below...
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
    SILE.call("img", { src = content.src })
  end)

end

return markdown
