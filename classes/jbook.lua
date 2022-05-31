local book = require("classes.book")
local jplain = require("classes.jplain")

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
  if self._legacy and not self._deprecated then return self:_deprecator(jbook) end
  book._init(self, options)
  jplain._j_common(self)
  return self
end

jbook.declareOptions = jplain.declareOptions

jbook.setOptions = jplain.setOptions

return jbook
