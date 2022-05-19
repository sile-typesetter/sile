local book = require("classes.book")
local jbook = pl.class(book)
jbook._name = "jbook"

jbook.defaultFrameset = {
  runningHead = {
    left = "left(content) + 9pt",
    right = "right(content) - 9pt",
    height = "20pt",
    bottom = "top(content)-9pt"
  },
  content = {
    left = "8.3%pw",
    top = "12%ph",
    gridsize = 10,
    linegap = 7,
    linelength = 40,
    linecount = 35
  },
  folio = {
    left = "left(content)",
    right = "right(content)",
    top = "bottom(footnotes)+3%ph",
    bottom = "bottom(footnotes)+5%ph"
  },
  footnotes = {
    left="left(content)",
    right = "right(content)",
    height = "0",
    bottom="83.3%ph"
  }
}

function jbook:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(book) end
  if not options then options = {} end
  options.layout = options.layout or "yoko"
  self:declareOption("layout", function (_, value)
    if value then
      self.layout = value
      if value == "tate" then self:loadPackage("tate") end
    end
    return self.layout
  end)
  book._init(self, options)
  self:registerPostinit(function ()
      SILE.call("bidi-off")
    end)
  SILE.languageSupport.loadLanguage("ja")
  self:loadPackage("hanmenkyoshi")
  self.defaultFrameset.content.tate = self.options.layout == "tate"
  self:declareHanmenFrame("content", self.defaultFrameset.content)
  SILE.settings:set("document.parindent", SILE.nodefactory.glue("10pt"))
  -- Avoid calling this (yet) if we're the parent of some child class
  if self._name == "jbook" then self:post_init() end
  return self
end

return jbook
