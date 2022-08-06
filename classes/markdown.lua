local book = require("classes.book")
local class = pl.class(book)
class._name = "markdown"

function class:_init (options)
  book._init(self, options)
  self:loadPackage("markdown")
  return self
end

return class
