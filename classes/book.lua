local plain = SILE.require("classes/plain");
local book = plain { id = "book" };

book:declareFrame("r",    {left = "8.3%",            right = "86%",            top = "11.6%",       bottom = "top(footnotes)"        });
book:declareFrame("folio",{left = "left(r)",         right = "right(r)",       top = "bottom(footnotes)+3%",bottom = "bottom(footnotes)+5%" });
book:declareFrame("rRH",  {left = "left(r)",         right = "right(r)",       top = "top(r) - 8%", bottom = "top(r)-3%"    });
book:declareFrame("footnotes", { left="left(r)", right = "right(r)", height = "0", bottom="83.3%"})
book.pageTemplate.firstContentFrame = book.pageTemplate.frames["r"];

book:loadPackage("twoside", { oddPageFrameID = "r", evenPageFrameID = "l" });
book:declareMirroredFrame("l","r")
book:declareMirroredFrame("lRH","rRH")

if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end

book.init = function()
  book:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = {"r";"l"} } )
  return plain:init()
end

book.endPage = function()
  if (book:oddPage()) then
    book:declareFrame("folio",     { left="left(r)", right = "right(r)", top = "bottom(footnotes)+3%", bottom = "bottom(footnotes)+5%" });
    book:declareFrame("footnotes", { left="left(r)", right = "right(r)", height = "0", bottom="83.3%"})

    if (SILE.scratch.headers.right) then
      SILE.typesetNaturally(SILE.getFrame("rRH"), function()
        SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
        SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
        SILE.process(SILE.scratch.headers.right)
      end)
    end
  else 
    book:declareFrame("folio",     { left="left(l)", right = "right(l)", top = "bottom(footnotes)+3%", bottom = "bottom(footnotes)+5%" });
    book:declareFrame("footnotes", { left="left(l)", right = "right(l)", height = "0", bottom="83.3%"})

    if (SILE.scratch.headers.left) then
      SILE.typesetNaturally(SILE.getFrame("lRH"), function()
        SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
        SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
        SILE.process(SILE.scratch.headers.left)
      end)
    end
  end
  book:outputInsertions()
  book:switchPage();

  return plain.endPage(book);
end;

SILE.registerCommand("left-running-head", function(options, content)
  SILE.scratch.headers.left = content
end, "Text to appear on the top of the left page");

SILE.registerCommand("right-running-head", function(options, content)
  SILE.scratch.headers.right = content
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
  SILE.Commands["left-running-head"]({}, content);
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
  if not SILE.scratch.counters.folio.off then
    SILE.Commands["right-running-head"]({}, function()
      SILE.call("hss")
      SILE.settings.temporarily(function()
        SILE.settings.set("font.style", "italic")
        SILE.call("show-counter", {id ="chapter"})
        SILE.typesetter:typeset(".")
        SILE.call("show-counter", {id="section"})
        SILE.typesetter:typeset(" ")
        SILE.process(content)
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