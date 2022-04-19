local plain = SILE.require("plain", "classes")
local bible = plain { id = "bible" }

if not SILE.scratch.headers then SILE.scratch.headers = {} end

bible.defaultFrameset = {
  content = {
    left = "8.3%pw",
    right = "86%pw",
    top = "11.6%ph",
    bottom = "top(footnotes)"
  },
  folio = {
    left = "left(content)",
    right = "right(content)",
    top = "bottom(footnotes)+3%ph",
    bottom = "bottom(footnotes)+5%ph"
  },
  runningHead = {
    left = "left(content)",
    right = "right(content)",
    top = "top(content) - 8%ph",
    bottom = "top(content)-3%ph"
  },
  footnotes = {
    left = "left(content)",
    right = "right(content)",
    height = "0",
    bottom = "83.3%ph"
  }
}

function bible:singleColumnMaster()
  self:defineMaster({
    id = "right",
    firstContentFrame = self.firstContentFrame,
    frames = self.defaultFrameset
  })
  self:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" })
  self:mirrorMaster("right", "left")
  self:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = { "content" } })
end

function bible:twoColumnMaster()
  local gutterWidth = self.options.gutter or "3%pw"
  self.firstContentFrame = "contentA"
  self:defineMaster({
      id = "right",
      firstContentFrame = "contentA",
      frames = {
        title = {
          left = "left(contentA)",
          right = "right(contentB)",
          top = "11.6%ph",
          height = "0",
          bottom = "top(contentA)"
        },
        contentA = {
          left = "8.3%pw",
          right = "left(gutter)",
          top = "bottom(title)",
          bottom = "top(footnotesA)",
          next = "contentB",
          balanced = true
        },
        contentB = {
          left = "right(gutter)",
          width ="width(contentA)",
          right = "86%pw",
          top = "bottom(title)",
          bottom = "top(footnotesB)",
          balanced = true
        },
        gutter = {
          left = "right(contentA)",
          right = "left(contentB)",
          width = gutterWidth
        },
        folio = {
          left = "left(contentA)",
          right = "right(contentB)",
          top = "bottom(footnotesB)+3%ph",
          bottom = "bottom(footnotesB)+5%ph"
        },
        runningHead = {
          left = "left(contentA)",
          right = "right(contentB)",
          top = "top(contentA)-8%ph",
          bottom = "top(contentA)-3%ph"
        },
        footnotesA = {
          left =  "left(contentA)",
          right = "right(contentA)",
          height = "0",
          bottom = "83.3%ph"
        },
        footnotesB = {
          left = "left(contentB)",
          right = "right(contentB)",
          height = "0",
          bottom = "83.3%ph"
        },
      }
    })
  self:defineMaster({
      id = "left",
      firstContentFrame = "contentA",
      frames = {
        title = {
          left = "left(contentA)",
          right = "right(contentB)",
          top = "11.6%ph",
          height = "0",
          bottom = "top(contentA)"
        },
        contentA = {
          left = "14%pw",
          right = "left(gutter)",
          top = "bottom(title)",
          bottom = "top(footnotesA)",
          next = "contentB",
          balanced = true
        },
        contentB = {
          left = "right(gutter)",
          width = "width(contentA)",
          right = "91.7%pw",
          top = "bottom(title)",
          bottom = "top(footnotesB)",
          balanced = true
        },
        gutter = {
          left = "right(contentA)",
          right = "left(contentB)",
          width = gutterWidth
        },
        folio = {
          left = "left(contentA)",
          right = "right(contentB)",
          top = "bottom(footnotesB)+3%ph",
          bottom = "bottom(footnotesB)+5%ph"
        },
        runningHead = {
          left = "left(contentA)",
          right = "right(contentB)",
          top = "top(contentA)-8%ph",
          bottom = "top(contentA)-3%ph"
        },
        footnotesA = {
          left = "left(contentA)",
          right = "right(contentA)",
          height = "0",
          bottom = "83.3%ph"
        },
        footnotesB = {
          left = "left(contentB)",
          right = "right(contentB)",
          height = "0",
          bottom = "83.3%ph"
        },
      }
    })
  -- Later we'll have an option for two fn frames
  self:loadPackage("footnotes", { insertInto = "footnotesB", stealFrom = { "contentB" } })
  -- self:loadPackage("balanced-frames")
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
  self:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" })
  self.pageTemplate = SILE.scratch.masters["right"]
  return plain.init(self)
end

bible.newPage = function (self)
  self:switchPage()
  self:newPageInfo()
  return plain.newPage(self)
end

bible.finish = function (self)
  return plain.finish(self)
end

bible.endPage = function (self)
  if (self:oddPage() and SILE.scratch.headers.right) then
    SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
      SILE.settings.set("current.parindent", SILE.nodefactory.glue())
      SILE.settings.set("document.lskip", SILE.nodefactory.glue())
      SILE.settings.set("document.rskip", SILE.nodefactory.glue())
      -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.process(SILE.scratch.headers.right)
      SILE.call("par")
    end)
  elseif (not(self:oddPage()) and SILE.scratch.headers.left) then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
        SILE.settings.set("current.parindent", SILE.nodefactory.glue())
        SILE.settings.set("document.lskip", SILE.nodefactory.glue())
        SILE.settings.set("document.rskip", SILE.nodefactory.glue())
          -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
        SILE.process(SILE.scratch.headers.left)
        SILE.call("par")
      end)
  end
  return plain.endPage(self)
end

SILE.registerCommand("left-running-head", function (_, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.left = function () closure(content) end
end, "Text to appear on the top of the left page")

SILE.registerCommand("right-running-head", function (_, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.right = function () closure(content) end
end, "Text to appear on the top of the right page")

SILE.registerCommand("chapter", function (options, content)
  local ch = options.id:match("%d+")
  SILE.call("bible:chapter-head", options, {"Chapter " .. ch})
  SILE.call("save-chapter-number", options, {options.id})
  SILE.process(content)
end)

SILE.registerCommand("verse-number", function (options, content)
  SILE.call("indent")
  SILE.call("bible:verse-number", options, content)
  SILE.call("save-verse-number", options, content)
  SILE.call("left-running-head", {}, function ()
    SILE.settings.temporarily(function ()
      SILE.settings.set("document.lskip", SILE.nodefactory.glue())
      SILE.settings.set("document.rskip", SILE.nodefactory.glue())
      -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.call("font", { size = "10pt", family = "Gentium" }, function ()
        SILE.call("first-reference")
        SILE.call("hfill")
        SILE.call("font", { style = "italic" }, SILE.scratch.theChapter)
      end)
      SILE.typesetter:leaveHmode()
    end)
  end)
  SILE.call("right-running-head", {}, function ()
    SILE.settings.temporarily(function ()
      SILE.settings.set("document.lskip", SILE.nodefactory.glue())
      SILE.settings.set("document.rskip", SILE.nodefactory.glue())
      SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.call("font", { size = "10pt", family = "Gentium" }, function ()
        -- SILE.call("font", { style = "italic" }, SILE.scratch.theChapter)
        SILE.call("hfill")
        SILE.call("last-reference")
      end)
      SILE.typesetter:leaveHmode()
    end)
  end)
end)

return bible
