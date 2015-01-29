local plain = SILE.require("classes/plain");
local book = plain { id = "book" };
book:loadPackage("masters")
book:defineMaster({ id = "right", firstContentFrame = "content", frames = {
  content = {left = "8.3%", right = "86%", top = "11.6%", bottom = "top(footnotes)" },
  folio = {left = "left(content)", right = "right(content)", top = "bottom(footnotes)+3%",bottom = "bottom(footnotes)+5%" },
  runningHead = {left = "left(content)", right = "right(content)", top = "top(content) - 8%", bottom = "top(content)-3%" },
  footnotes = { left="left(content)", right = "right(content)", height = "0", bottom="83.3%"}
}})
book:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" });
book:mirrorMaster("right", "left")

book:loadPackage("tableofcontents")

if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end

book.pageTemplate = SILE.scratch.masters["right"]
book.init = function(self)
  book:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = {"content"} } )
  return plain.init(self)
end

book.newPage = function(self)
  book:switchPage()
  return plain.newPage(self)
end

book.finish = function ()
  book:writeToc()
  return plain:finish()
end

book.endPage = function(self)
  book:outputInsertions()
  book:moveTocNodes()
  book:newPageInfo()

  if (book:oddPage() and SILE.scratch.headers.right) then
    SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
      SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
      -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
      SILE.process(SILE.scratch.headers.right)
      SILE.call("par")
    end)
  elseif (not(book:oddPage()) and SILE.scratch.headers.left) then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
        SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
        -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
        SILE.process(SILE.scratch.headers.left)
        SILE.call("par")
      end)
  end

  return plain.endPage(book);
end;

SILE.registerCommand("left-running-head", function(options, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.left = function () closure(content) end
end, "Text to appear on the top of the left page");

SILE.registerCommand("right-running-head", function(options, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.right = function () closure(content) end
end, "Text to appear on the top of the right page");

SILE.registerCommand("chapter", function (options, content)
  SILE.call("open-double-page")
  SILE.call("noindent")
  SILE.scratch.headers.right = nil
  SILE.Commands["set-counter"]({id = "section", value = 0});
  SILE.Commands["set-counter"]({id = "footnote", value = 1});
  SILE.Commands["increment-counter"]({id = "chapter"})
  SILE.Commands["book:chapterfont"]({}, {"Chapter "..SILE.formatCounter(SILE.scratch.counters.chapter)});
  SILE.typesetter:leaveHmode()
  SILE.Commands["book:chapterfont"]({}, content);
  SILE.Commands["left-running-head"]({}, content)
  SILE.call("tocentry", {level = 1}, content)
  SILE.call("bigskip")
  SILE.call("nofoliosthispage")
end, "Begin a new chapter");

SILE.registerCommand("section", function (options, content)
  SILE.typesetter:leaveHmode()
  SILE.call("goodbreak")  
  SILE.call("noindent")
  SILE.call("set-counter", {id="subsection", value=0 })
  SILE.call("increment-counter", {id="section" })
  SILE.call("bigskip")
  SILE.Commands["book:sectionfont"]({}, function()
    SILE.call("show-counter", {id ="chapter"})
    SILE.typesetter:typeset(".")
    SILE.call("show-counter", {id="section"})
    SILE.typesetter:typeset(" ")
    SILE.process(content)
  end)
  SILE.call("tocentry", {level = 2}, content)
  if not SILE.scratch.counters.folio.off then
    SILE.Commands["right-running-head"]({}, function()
      SILE.call("rightalign", {}, function ()
        SILE.settings.temporarily(function()
          SILE.settings.set("font.style", "italic")
          SILE.call("show-counter", {id ="chapter"})
          SILE.typesetter:typeset(".")
          SILE.call("show-counter", {id="section"})
          SILE.typesetter:typeset(" ")
          SILE.process(content)
        end)
      end)
    end);
  end
  SILE.call("novbreak")
  SILE.call("bigskip")
  SILE.call("novbreak")
end, "Begin a new section")

SILE.registerCommand("subsection", function (options, content)
  SILE.typesetter:leaveHmode()
  SILE.call("goodbreak")
  SILE.call("noindent")
  SILE.call("increment-counter", {id="subsection" })
  SILE.call("medskip")
  SILE.Commands["book:subsectionfont"]({}, function()
    SILE.call("show-counter", {id ="chapter"})
    SILE.typesetter:typeset(".")
    SILE.call("show-counter", {id="section"})
    SILE.typesetter:typeset(".")
    SILE.call("show-counter", {id="subsection"})
    SILE.typesetter:typeset(" ")
    SILE.process(content)
  end)
  SILE.typesetter:leaveHmode()
  SILE.call("novbreak")
  SILE.call("medskip")
  SILE.call("novbreak")
end, "Begin a new subsection")

SILE.registerCommand("book:chapterfont", function (options, content)
  SILE.settings.temporarily(function()
    SILE.Commands["font"]({weight=800, size="22pt"}, content)
  end)
end)
SILE.registerCommand("book:sectionfont", function (options, content)
  SILE.settings.temporarily(function()
    SILE.Commands["font"]({weight=800, size="15pt"}, content)
  end)
end)

SILE.registerCommand("book:subsectionfont", function (options, content)
  SILE.settings.temporarily(function()
    SILE.Commands["font"]({weight=800, size="12pt"}, content)
  end)
end)
SILE.registerCommand("open-double-page", function() 
  SILE.typesetter:leaveHmode();
  SILE.Commands["supereject"]();
  if book:oddPage() then
    SILE.typesetter:typeset("")
    SILE.typesetter:leaveHmode();
    SILE.Commands["supereject"]();
  end

end)
return book