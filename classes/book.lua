local plain = SILE.require("classes/plain");
local book = plain { id = "book" };

book:declareFrame("r",    {left = "8.3%",            right = "86%",            top = "11.6%",       bottom = "83.3%"        });
book:declareFrame("l",    {left = "100% - right(r)", right = "100% - left(r)", top = "top(r)",      bottom = "bottom(r)"    });
book:declareFrame("folio",{left = "left(r)",         right = "right(r)",       top = "bottom(footnotes)+3%",bottom = "bottom(footnotes)+5%" });
book:declareFrame("lRH",  {left = "left(l)",         right = "right(l)",       top = "top(l) - 8%", bottom = "top(l)-3%"    });
book:declareFrame("rRH",  {left = "left(r)",         right = "right(r)",       top = "top(r) - 8%", bottom = "top(r)-3%"    });
book:declareFrame("footnotes", { left="left(r)", right = "right(r)", top = "bottom(r)", bottom="bottom(r)"})
book.pageTemplate.firstContentFrame = book.pageTemplate.frames["r"];

book:loadPackage("twoside", { oddPageFrameID = "r", evenPageFrameID = "l" });

if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end

book.init = function()
  book:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = {"r";"l"} } )
  return plain:init()
end

book.endPage = function()
  book:outputInsertions()

  if (book:oddPage()) then
    book:declareFrame("footnotes", { left="left(l)", right = "right(l)", top = "bottom(r)", bottom="83.3%"})

    if (SILE.scratch.headers.right) then
      SILE.typesetNaturally(SILE.getFrame("rRH"), SILE.scratch.headers.right);
    end
  else 
    book:declareFrame("footnotes", { left="left(r)", right = "right(r)", top = "bottom(r)", bottom="83.3%"})

    if (SILE.scratch.headers.left) then
      SILE.typesetNaturally(SILE.getFrame("lRH"), SILE.scratch.headers.left);
    end
  end
  book:switchPage();

  return plain.endPage(book);
end;

SILE.registerCommand("left-running-head", function(options, content)
  SILE.settings.temporarily(function()
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.typesetter:pushState()
    SILE.process(content)
    SILE.scratch.headers.left = SILE.typesetter.state.nodes;
    SILE.typesetter:popState()
  end);
end, "Text to appear on the top of the left page");
SILE.registerCommand("right-running-head", function(options, content)
  SILE.settings.temporarily(function()
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.typesetter:pushState()
    SILE.process(content)
    SILE.scratch.headers.right = SILE.typesetter.state.nodes;
    SILE.typesetter:popState()
  end);
end, "Text to appear on the top of the right page");

return book