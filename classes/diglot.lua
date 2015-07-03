local plain = SILE.require("classes/plain");
local diglot = std.tree.clone(plain);
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value = 1, display = "arabic" };
diglot:declareFrame("a",    {left = "8.3%",            right = "48%",            top = "11.6%",       bottom = "80%"        });
diglot:declareFrame("b",    {left = "52%",             right = "100% - left(a)", top = "top(a)",      bottom = "bottom(a)"    });
diglot:declareFrame("folio",{left = "left(a)",         right = "right(b)",       top = "bottom(a)+3%",bottom = "bottom(a)+8%" });

diglot:loadPackage("parallel", { frames = { left = "a", right = "b" } })

return diglot
