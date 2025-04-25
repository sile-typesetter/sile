--- bible document class.
-- @use classes.bible

local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "bible"

class.defaultFrameset = {
   content = {
      left = "8.3%pw",
      right = "86%pw",
      top = "11.6%ph",
      bottom = "top(footnotes)",
   },
   folio = {
      left = "left(content)",
      right = "right(content)",
      top = "bottom(footnotes)+3%ph",
      bottom = "bottom(footnotes)+5%ph",
   },
   runningHead = {
      left = "left(content)",
      right = "right(content)",
      top = "top(content) - 8%ph",
      bottom = "top(content)-3%ph",
   },
   footnotes = {
      left = "left(content)",
      right = "right(content)",
      height = "0",
      bottom = "83.3%ph",
   },
}

function class:singleColumnMaster ()
   self:defineMaster({
      id = "right",
      firstContentFrame = self.firstContentFrame,
      frames = self.defaultFrameset,
   })
   self:loadPackage("twoside", {
      oddPageMaster = "right",
      evenPageMaster = "left",
   })
   self:loadPackage("footnotes", {
      insertInto = "footnotes",
      stealFrom = { "content" },
   })
end

function class:twoColumnMaster ()
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
            bottom = "top(contentA)",
         },
         contentA = {
            left = "8.3%pw",
            right = "left(gutter)",
            top = "bottom(title)",
            bottom = "top(footnotesA)",
            next = "contentB",
            balanced = true,
         },
         contentB = {
            left = "right(gutter)",
            width = "width(contentA)",
            right = "86%pw",
            top = "bottom(title)",
            bottom = "top(footnotesB)",
            balanced = true,
         },
         gutter = {
            left = "right(contentA)",
            right = "left(contentB)",
            width = self.options.gutter,
         },
         folio = {
            left = "left(contentA)",
            right = "right(contentB)",
            top = "bottom(footnotesB)+3%ph",
            bottom = "bottom(footnotesB)+5%ph",
         },
         runningHead = {
            left = "left(contentA)",
            right = "right(contentB)",
            top = "top(contentA)-8%ph",
            bottom = "top(contentA)-3%ph",
         },
         footnotesA = {
            left = "left(contentA)",
            right = "right(contentA)",
            height = "0",
            bottom = "83.3%ph",
         },
         footnotesB = {
            left = "left(contentB)",
            right = "right(contentB)",
            height = "0",
            bottom = "83.3%ph",
         },
      },
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
            bottom = "top(contentA)",
         },
         contentA = {
            left = "14%pw",
            right = "left(gutter)",
            top = "bottom(title)",
            bottom = "top(footnotesA)",
            next = "contentB",
            balanced = true,
         },
         contentB = {
            left = "right(gutter)",
            width = "width(contentA)",
            right = "91.7%pw",
            top = "bottom(title)",
            bottom = "top(footnotesB)",
            balanced = true,
         },
         gutter = {
            left = "right(contentA)",
            right = "left(contentB)",
            width = self.options.gutter,
         },
         folio = {
            left = "left(contentA)",
            right = "right(contentB)",
            top = "bottom(footnotesB)+3%ph",
            bottom = "bottom(footnotesB)+5%ph",
         },
         runningHead = {
            left = "left(contentA)",
            right = "right(contentB)",
            top = "top(contentA)-8%ph",
            bottom = "top(contentA)-3%ph",
         },
         footnotesA = {
            left = "left(contentA)",
            right = "right(contentA)",
            height = "0",
            bottom = "83.3%ph",
         },
         footnotesB = {
            left = "left(contentB)",
            right = "right(contentB)",
            height = "0",
            bottom = "83.3%ph",
         },
      },
   })
   -- Later we'll have an option for two fn frames
   self:loadPackage("footnotes", { insertInto = "footnotesB", stealFrom = { "contentB" } })
   -- self:loadPackage("balanced-frames")
end

local _twocolumns
local _gutterwidth

function class:_init (options)
   plain._init(self, options)
   self:loadPackage("masters")
   self:loadPackage("infonode")
   self:loadPackage("chapterverse")
   self:registerPostinit(function (self_)
      if self_.options.twocolumns then
         self_:twoColumnMaster()
         self.settings:set("linebreak.tolerance", 9000)
      else
         self_:singleColumnMaster()
      end
   end)
end

function class:endPage ()
   if self:oddPage() and SILE.scratch.headers.right then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
         self.settings:set("current.parindent", SILE.types.node.glue())
         self.settings:set("document.lskip", SILE.types.node.glue())
         self.settings:set("document.rskip", SILE.types.node.glue())
         -- self.settings:set("typesetter.parfillskip", SILE.types.node.glue())
         SILE.process(SILE.scratch.headers.right)
         SILE.call("par")
      end)
   elseif not (self:oddPage()) and SILE.scratch.headers.left then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
         self.settings:set("current.parindent", SILE.types.node.glue())
         self.settings:set("document.lskip", SILE.types.node.glue())
         self.settings:set("document.rskip", SILE.types.node.glue())
         -- self.settings:set("typesetter.parfillskip", SILE.types.node.glue())
         SILE.process(SILE.scratch.headers.left)
         SILE.call("par")
      end)
   end
   return plain.endPage(self)
end

function class:declareOptions ()
   plain.declareOptions(self)
   self:declareOption("twocolumns", function (_, value)
      if value then
         _twocolumns = value
      end
      return _twocolumns
   end)
   self:declareOption("gutter", function (_, value)
      if value then
         _gutterwidth = value
      end
      return _gutterwidth
   end)
end

function class:setOptions (options)
   options.twocolumns = options.twocolumns or false
   options.gutter = options.gutter or "3%pw"
   plain.setOptions(self, options)
end

function class:registerCommands ()
   plain.registerCommands(self)

   self:registerCommand("left-running-head", function (_, content)
      local closure = self.settings:wrap()
      SILE.scratch.headers.left = function ()
         closure(content)
      end
   end, "Text to appear on the top of the left page")

   self:registerCommand("right-running-head", function (_, content)
      local closure = self.settings:wrap()
      SILE.scratch.headers.right = function ()
         closure(content)
      end
   end, "Text to appear on the top of the right page")

   self:registerCommand("chapter", function (options, content)
      local ch = options.id:match("%d+")
      SILE.call("bible:chapter-head", options, { "Chapter " .. ch })
      SILE.call("save-chapter-number", options, { options.id })
      SILE.process(content)
   end)

   self:registerCommand("verse-number", function (options, content)
      SILE.call("indent")
      SILE.call("bible:verse-number", options, content)
      SILE.call("save-verse-number", options, content)
      SILE.call("left-running-head", {}, function ()
         self.settings:temporarily(function ()
            self.settings:set("document.lskip", SILE.types.node.glue())
            self.settings:set("document.rskip", SILE.types.node.glue())
            -- self.settings:set("typesetter.parfillskip", SILE.types.node.glue())
            SILE.call("font", { size = "10pt", family = "Gentium" }, function ()
               SILE.call("first-reference")
               SILE.call("hfill")
               SILE.call("font", { style = "italic" }, SILE.scratch.theChapter)
            end)
            SILE.typesetter:leaveHmode()
         end)
      end)
      SILE.call("right-running-head", {}, function ()
         self.settings:temporarily(function ()
            self.settings:set("document.lskip", SILE.types.node.glue())
            self.settings:set("document.rskip", SILE.types.node.glue())
            self.settings:set("typesetter.parfillskip", SILE.types.node.glue())
            SILE.call("font", { size = "10pt", family = "Gentium" }, function ()
               -- SILE.call("font", { style = "italic" }, SILE.scratch.theChapter)
               SILE.call("hfill")
               SILE.call("last-reference")
            end)
            SILE.typesetter:leaveHmode()
         end)
      end)
   end)
end

return class
