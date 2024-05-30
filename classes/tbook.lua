--- tbook document class.
-- @use classes.tbook

local book = require("classes.book")
local tplain = require("classes.tplain")

local class = pl.class(book)
class._name = "tbook"

class.defaultFrameset = {
   runningHead = {
      left = "left(content) + 9pt",
      right = "right(content) - 9pt",
      height = "20pt",
      bottom = "top(content)-9pt",
   },
   content = {
      left = "8.3%pw",
      top = "12%ph",
      gridsize = 10,
      linegap = 7,
      linelength = 40,
      linecount = 35,
   },
   folio = {
      left = "left(content)",
      right = "right(content)",
      top = "bottom(footnotes)+3%ph",
      bottom = "bottom(footnotes)+5%ph",
   },
   footnotes = {
      left = "left(content)",
      right = "right(content)",
      height = "0",
      bottom = "83.3%ph",
   },
}

function class:_init (options)
   book._init(self, options)
   tplain._t_common(self)
   return self
end

class.declareOptions = tplain.declareOptions

class.setOptions = tplain.setOptions

return class
