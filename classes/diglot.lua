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

diglot.newPage = function()
  diglot.rightTypesetter:leaveHmode(1);
  diglot.leftTypesetter:leaveHmode(1);
  diglot.leftTypesetter:init(diglot.pageTemplate.frames["a"])
  diglot.rightTypesetter:init(diglot.pageTemplate.frames["b"])
  plain:newPage()
  SILE.typesetter = diglot.rightTypesetter
  return diglot.pageTemplate.frames["a"]
end

diglot.finish = function(self)
  diglot.leftTypesetter.frame = diglot.pageTemplate.frames["a"]
  diglot.rightTypesetter.frame = diglot.pageTemplate.frames["b"]
  diglot.leftTypesetter:chuck()
  diglot.rightTypesetter:chuck()
  diglot:endPage()
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
  if (not SILE.typesetter.frame) then 
    SILE.typesetter:init(diglot.pageTemplate.frames["a"]) 
  end
  SILE.Commands["font"](SILE.scratch.diglot.leftfont, {})
end, "Begin entering text on the left side")

SILE.registerCommand("right", function(options, content)
  SILE.settings.set("typesetter.parseppattern", -1)  
  SILE.typesetter = diglot.rightTypesetter;
  if (not SILE.typesetter.frame) then 
    SILE.typesetter:init(diglot.pageTemplate.frames["b"]) 
  end
  SILE.Commands["font"](SILE.scratch.diglot.rightfont, {})
end, "Begin entering text on the right side")


SILE.registerCommand("sync", sync, "Ensure that left and right sides are balanced")

return diglot