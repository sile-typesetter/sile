local plain = SILE.require("classes/plain");
local diglot = std.tree.clone(plain);
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value = 1, display = "arabic" };
SILE.scratch.diglot = {}
diglot:declareFrame("a",    {left = "8.3%",            right = "48%",            top = "11.6%",       bottom = "80%"        });
diglot:declareFrame("b",    {left = "52%",             right = "100% - left(a)", top = "top(a)",      bottom = "bottom(a)"    });
diglot:declareFrame("folio",{left = "left(a)",         right = "right(b)",       top = "bottom(a)+3%",bottom = "bottom(a)+8%" });
diglot.leftTypesetter = SILE.defaultTypesetter {};
diglot.rightTypesetter = SILE.defaultTypesetter {};
diglot.rightTypesetter.other = diglot.leftTypesetter
diglot.leftTypesetter.other = diglot.rightTypesetter

local sync =   function()
  local lVbox = SILE.pagebuilder.collateVboxes(diglot.leftTypesetter.state.outputQueue)
  local rVbox = SILE.pagebuilder.collateVboxes(diglot.rightTypesetter.state.outputQueue)
  if (rVbox.height > lVbox.height) then
    diglot.leftTypesetter:pushVglue({ height = rVbox.height - lVbox.height })
  elseif (rVbox.height < lVbox.height) then
    diglot.rightTypesetter:pushVglue({ height = lVbox.height - rVbox.height })
  end
  diglot.rightTypesetter:leaveHmode();
  diglot.leftTypesetter:leaveHmode();
  SILE.settings.set("typesetter.parseppattern", "\n\n+")
end

diglot.finish = function(self)
  table.insert(SILE.typesetter.other.state.outputQueue, SILE.nodefactory.vfillGlue)
  SILE.typesetter.other:chuck()
  plain.finish(self)
end

diglot.endPage = function(self)
  SILE.typesetter.other:leaveHmode(1)
  plain.endPage(self)
end

diglot.newPage = function(self)
  plain.newPage(self)
  if SILE.typesetter == diglot.leftTypesetter then
    SILE.typesetter.other:initFrame(SILE.getFrame("b"))
    return SILE.getFrame("a")
  else
    SILE.typesetter.other:initFrame(SILE.getFrame("a"))
    return SILE.getFrame("b")
  end
end

diglot.init = function(self)
  diglot.leftTypesetter:init(SILE.getFrame("a"))
  diglot.rightTypesetter:init(SILE.getFrame("b"))
  return SILE.baseClass.init(self)
end

SILE.registerCommand("leftfont", function(options, content)
  SILE.scratch.diglot.leftfont = options
end, "Set the font for the left side")

SILE.registerCommand("rightfont", function(options, content)
  SILE.scratch.diglot.rightfont = options
end, "Set the font for the right side")

SILE.registerCommand("left", function(options, content)
  SILE.settings.set("typesetter.parseppattern", -1)
  SILE.typesetter = diglot.leftTypesetter;
  SILE.Commands["font"](SILE.scratch.diglot.leftfont, {})
end, "Begin entering text on the left side")

SILE.registerCommand("right", function(options, content)
  SILE.settings.set("typesetter.parseppattern", -1)  
  SILE.typesetter = diglot.rightTypesetter;
  SILE.Commands["font"](SILE.scratch.diglot.rightfont, {})
end, "Begin entering text on the right side")


SILE.registerCommand("sync", sync, "Ensure that left and right sides are balanced")

return diglot