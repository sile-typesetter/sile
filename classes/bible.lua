local plain = SILE.require("classes/plain");
local bible = plain { id = "bible", base = plain };
if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end


function bible:singleColumnMaster()
  self:defineMaster({ id = "right", firstContentFrame = "content", frames = {
    content = {left = "8.3%", right = "86%", top = "11.6%", bottom = "top(footnotes)" },
    folio = {left = "left(content)", right = "right(content)", top = "bottom(footnotes)+3%",bottom = "bottom(footnotes)+5%" },
    runningHead = {left = "left(content)", right = "right(content)", top = "top(content) - 8%", bottom = "top(content)-3%" },
    footnotes = { left="left(content)", right = "right(content)", height = "0", bottom="83.3%"}
  }})
  self:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = {"content"} } )
end

function bible:twoColumnMaster()
  local gutterWidth = self.options.gutter or "3%"
  self:defineMaster({ id = "right", firstContentFrame = "contentA", frames = {
    contentA = {left = "8.3%", right = "left(gutter)", top = "11.6%", bottom = "top(footnotes)", next = "contentB" },
    contentB = {left = "right(gutter)", width="width(contentA)", right = "86%", top = "11.6%", bottom = "top(footnotes)" },
    gutter = { left = "right(contentA)", right = "left(contentB)", width = gutterWidth },
    folio = {left = "left(contentA)", right = "right(contentB)", top = "bottom(footnotes)+3%",bottom = "bottom(footnotes)+5%" },
    runningHead = {left = "left(contentA)", right = "right(contentB)", top = "top(contentA) - 8%", bottom = "top(contentA)-3%" },
    footnotes = { left="left(contentA)", right = "right(contentB)", height = "0", bottom="83.3%"}
  }})
  -- Later we'll have an option for two fn frames
  self:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = {"contentA", "contentB"} } )
end

local _twocolumns
bible.options.twocolumns = function (g)
  if g then _twocolumns = g end
  return _twocolumns
end

function bible:init()
  self:loadPackage("masters")
  self:loadPackage("infonode")
  self:loadPackage("chapterverse")
  if self.options.twocolumns() then 
    self:twoColumnMaster()
    SILE.settings.set("linebreak.tolerance", 9000)
  else
    self:singleColumnMaster()
  end
  self:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" });
  self:mirrorMaster("right", "left")
  -- mirrorMaster is not clever enough to handle two-column layouts,
  -- and it mirrors them!
  if self.options.twocolumns() then
    SILE.scratch.masters.left.firstContentFrame = SILE.scratch.masters.left.frames.contentB
    SILE.scratch.masters.left.frames.contentB.next = "contentA"
    SILE.scratch.masters.left.frames.contentA.next = nil
  end
  return plain.init(self)
end

bible.newPage = function(self)
  self:switchPage()
  self:newPageInfo()  
  return plain.newPage(self)
end

bible.finish = function (self)
  --bible:writeToc()
  return plain.finish(self)
end

bible.endPage = function(self)
  self:outputInsertions()
  if (self:oddPage() and SILE.scratch.headers.right) then
    SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
      SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
      SILE.settings.set("document.lskip", SILE.nodefactory.zeroGlue)
      SILE.settings.set("document.rskip", SILE.nodefactory.zeroGlue)
      -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
      SILE.process(SILE.scratch.headers.right)
      SILE.call("par")
    end)
  elseif (not(self:oddPage()) and SILE.scratch.headers.left) then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
        SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
        SILE.settings.set("document.lskip", SILE.nodefactory.zeroGlue)
        SILE.settings.set("document.rskip", SILE.nodefactory.zeroGlue)
          -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
        SILE.process(SILE.scratch.headers.left)
        SILE.call("par")
      end)
  end
  return plain.endPage(self);
end;


SILE.registerCommand("left-running-head", function(options, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.left = function () closure(content) end
end, "Text to appear on the top of the left page");

SILE.registerCommand("right-running-head", function(options, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.right = function () closure(content) end
end, "Text to appear on the top of the right page");


SILE.registerCommand("chapter", function (o,c)
  local ch = o.id:match("%d+")
  SILE.call("bible:chapter-head", o, {"Chapter "..ch})
  SILE.call("save-chapter-number", o, {o.id})
  SILE.process(c)
end)

SILE.registerCommand("verse-number", function (o,c)
  SILE.call("indent")
  SILE.call("bible:verse-number", o, c)
  SILE.call("save-verse-number", o, c)
  SILE.call("left-running-head", {}, function ()
    SILE.settings.temporarily(function()
      SILE.settings.set("document.lskip", SILE.nodefactory.zeroGlue)
      SILE.settings.set("document.rskip", SILE.nodefactory.zeroGlue)
      -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
      SILE.call("font", {size="10pt", family="Gentium"}, function ()
        SILE.call("first-reference")
        SILE.call("hfill")
        SILE.call("font", {style="italic"}, SILE.scratch.theChapter)
      end)
      SILE.typesetter:leaveHmode()
    end)
  end)
  SILE.call("right-running-head", {}, function ()
    SILE.settings.temporarily(function()
      SILE.settings.set("document.lskip", SILE.nodefactory.zeroGlue)
      SILE.settings.set("document.rskip", SILE.nodefactory.zeroGlue)      
      SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
      SILE.call("font", {size="10pt", family="Gentium"}, function ()
        SILE.call("font", {style="italic"}, SILE.scratch.theChapter)
        SILE.call("hfill")
        SILE.call("last-reference")
      end)
      SILE.typesetter:leaveHmode()
    end)
  end)    
end)

return bible