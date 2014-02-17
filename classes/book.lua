local plain = SILE.require("classes/plain");
local book = std.tree.clone(plain);
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value = 1, display = "arabic" };
if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end

book:declareFrame("r",    {left = "8.3%",            right = "86%",            top = "11.6%",       bottom = "83.3%"        });
book:declareFrame("l",    {left = "100% - right(r)", right = "100% - left(r)", top = "top(r)",      bottom = "bottom(r)"    });
book:declareFrame("folio",{left = "left(r)",         right = "right(r)",       top = "bottom(r)+3%",bottom = "bottom(r)+5%" });
book:declareFrame("lRH",  {left = "left(l)",         right = "right(l)",       top = "top(l) - 8%", bottom = "top(l)-3%"    });
book:declareFrame("rRH",  {left = "left(r)",         right = "right(r)",       top = "top(r) - 8%", bottom = "top(r)-3%"    });

book.pageTemplate.firstContentFrame = book.pageTemplate.frames["r"];

book.newPage = function()
  if (book.pageTemplate.firstContentFrame.id == "r") then
  --   if (SILE.scratch.headers.right) then
  --     SILE.typesetNaturally(SILE.getFrame("rRH"), SILE.scratch.headers.right);
  --   end
    book.pageTemplate.firstContentFrame = book.pageTemplate.frames["l"];
  else 
  --   if (SILE.scratch.headers.left) then
  --     SILE.typesetNaturally(SILE.getFrame("lRH"), SILE.scratch.headers.left);
  --   end
  book.pageTemplate.firstContentFrame = book.pageTemplate.frames["r"];
  end
  plain:newPage();
  return book.pageTemplate.firstContentFrame;
end;

SILE.registerCommand("left-running-head", function(options, content)
  local pi = SILE.documentState.documentClass.state.parindent
  SILE.documentState.documentClass.state.parindent = { width= SILE.length.new({length = 0, stretch= 0, shrink= 0})}
  SILE.process(content)
  SILE.scratch.headers.left = SILE.typesetter.state.nodes;
  SILE.typesetter.state.nodes = {}
  SILE.documentState.documentClass.state.parindent = pi
end);
SILE.registerCommand("right-running-head", function(options, content)
  local pi = SILE.documentState.documentClass.state.parindent
  SILE.documentState.documentClass.state.parindent = { width= SILE.length.new({length = 0, stretch= 0, shrink= 0})}  
  SILE.process(content);
  SILE.scratch.headers.right = SILE.typesetter.state.nodes;
  SILE.typesetter.state.nodes = {}
  SILE.documentState.documentClass.state.parindent = pi  
end);

return book