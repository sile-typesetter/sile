local plain = SILE.require("plain", "classes")
local diglot = std.tree.clone(plain)
SILE.require("packages/counters")
SILE.scratch.counters.folio = { value = 1, display = "arabic" }
diglot:declareFrame("a",    { left = "8.3%pw",  right = "48%pw",          top = "11.6%ph",        bottom = "80%ph"          })
diglot:declareFrame("b",    { left = "52%pw",   right = "100%pw-left(a)", top = "top(a)",         bottom = "bottom(a)"      })
diglot:declareFrame("folio",{ left = "left(a)", right = "right(b)",       top = "bottom(a)+3%ph", bottom = "bottom(a)+8%ph" })

diglot:loadPackage("parallel", { frames = { left = "a", right = "b" } })

return diglot
