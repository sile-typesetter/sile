local plain = SILE.require("classes/plain");
local diglot = std.tree.clone(plain);
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value = 1, display = "arabic" };
SILE.scratch.diglot = {}
if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end

diglot:declareFrame("a",    {left = "8.3%",            right = "48%",            top = "11.6%",       bottom = "80%"        });
diglot:declareFrame("b",    {left = "52%",             right = "100% - left(a)", top = "top(a)",      bottom = "bottom(a)"    });
diglot:declareFrame("folio",{left = "left(a)",         right = "right(b)",       top = "bottom(a)+3%",bottom = "bottom(a)+5%" });

diglot.pageTemplate.firstContentFrame = diglot.pageTemplate.frames["a"];
diglot.leftTypesetter = SILE.defaultTypesetter {};
diglot.rightTypesetter = SILE.defaultTypesetter {};
diglot.leftTypesetter.parSepPattern= -1
diglot.rightTypesetter.parSepPattern= -1

local sync =   function()
  if (diglot.rightTypesetter.state.cursorY > diglot.leftTypesetter.state.cursorY) then
    diglot.leftTypesetter:pushVglue({ height = diglot.rightTypesetter.state.cursorY - diglot.leftTypesetter.state.cursorY })
  elseif (diglot.rightTypesetter.state.cursorY < diglot.leftTypesetter.state.cursorY) then
    diglot.rightTypesetter:pushVglue({ height = diglot.leftTypesetter.state.cursorY - diglot.rightTypesetter.state.cursorY })
  end

  diglot.rightTypesetter:leaveHmode(1);
  diglot.leftTypesetter:leaveHmode();
  diglot.rightTypesetter:shipOut(0,1)
  diglot.leftTypesetter:shipOut(0,1)

  diglot.rightTypesetter:pushBack()
  diglot.leftTypesetter:pushBack()
end

diglot.newPage = function()
  diglot.rightTypesetter:leaveHmode(1);
  diglot.leftTypesetter:leaveHmode(1);
  diglot.leftTypesetter:init(diglot.pageTemplate.frames["a"])
  diglot.rightTypesetter:init(diglot.pageTemplate.frames["b"])
  SILE.typesetter = diglot.leftTypesetter;
  plain.newPage()
  return diglot.pageTemplate.frames["a"]
end

SILE.registerCommand("leftfont", function(options, content)
  SILE.scratch.diglot.leftfont = options
end)

SILE.registerCommand("rightfont", function(options, content)
  SILE.scratch.diglot.rightfont = options
end)

SILE.registerCommand("left", function(options, content)
  SILE.typesetter = diglot.leftTypesetter;
  if (not SILE.typesetter.frame) then 
    SILE.typesetter:init(diglot.pageTemplate.frames["a"]) 
  end
  SILE.Commands["font"](SILE.scratch.diglot.leftfont, {})
end)

SILE.registerCommand("right", function(options, content)
  SILE.typesetter = diglot.rightTypesetter;
  if (not SILE.typesetter.frame) then 
    SILE.typesetter:init(diglot.pageTemplate.frames["b"]) 
  end
  SILE.Commands["font"](SILE.scratch.diglot.rightfont, {})
end)


SILE.registerCommand("sync", sync)

return diglot