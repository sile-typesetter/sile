local book = require("classes.book")
local class = pl.class(book)
class._name = "markdown"

function markdown:_init (options)
  book._init(self, options)
  self:loadPackage("markdown")
  return self
end

function markdown:registerCommands ()
  book.registerCommands(self)
end

return class
