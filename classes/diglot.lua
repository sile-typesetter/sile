local plain = SILE.require("plain", "classes")
local diglot = plain { id = "diglot" }

function diglot:init ()
  SILE.require("packages/counters")
  SILE.scratch.counters.folio = { value = 1, display = "arabic" }
  self:declareFrame("a",    { left = "8.3%pw",  right = "48%pw",          top = "11.6%ph",        bottom = "80%ph"          })
  self:declareFrame("b",    { left = "52%pw",   right = "100%pw-left(a)", top = "top(a)",         bottom = "bottom(a)"      })
  self:declareFrame("folio",{ left = "left(a)", right = "right(b)",       top = "bottom(a)+3%ph", bottom = "bottom(a)+8%ph" })
  self:loadPackage("parallel", { frames = { left = "a", right = "b" } })
  return plain.init(self)
end

return diglot
