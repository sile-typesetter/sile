--- diglot document class.
-- @use classes.diglot

local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "diglot"

function class:_init (options)
   plain._init(self, options)
   self:loadPackage("counters")

   self:registerPostinit(function ()
      SILE.scratch.counters.folio = { value = 1, display = "arabic" }
   end)

	self:declareFrame("a", {
		left = "2.5%pw",
		right = "47.5%pw",
		top = "3.5%ph",
		bottom = "85%ph",
	})
	self:declareFrame("b", {
		left = "52.5%pw",
		right = "100%pw-left(a)",
		top = "top(a)",
		bottom = "bottom(a)",
	})
	self:declareFrame("c", {
		left = "left(a)",
		right = "right(a)",
		top = "bottom(a)",
		bottom = "bottom(a)+10%ph", -- Adjust as needed for footnote space
	})
	self:declareFrame("d", {
		left = "left(b)",
		right = "right(b)",
		top = "bottom(b)",
		bottom = "bottom(b)+10%ph", -- Adjust as needed for footnote space
	})
	self:declareFrame("folio", {
		left = "left(a)",
		right = "right(b)",
		top = "bottom(c)+1.5%ph",
		bottom = "bottom(c)+4.75%ph",
	})
   self:loadPackage("parallel", {
      frames = {
         left = "a",
         right = "b",
      },
   })
end

return class
