local plain = SILE.require("plain", "classes")
local perseus = plain { id = "perseus" }

SILE.scratch.perseus = {}

function perseus:init ()
  self:declareFrame("a",    { left = "8.3%pw",          right = "48%pw",            top = "11.6%ph",        bottom = "80%ph",         next="b" });
  self:declareFrame("b",    { left = "52%pw",           right = "100%pw - left(a)", top = "top(a)",         bottom = "bottom(a)"               });
  self:declareFrame("folio",{ left = "left(a)",         right = "right(b)",         top = "bottom(a)+3%ph", bottom = "bottom(a)+8%ph"          });
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames["a"];
  return plain.init(self)
end

SILE.registerCommand("lexicalEntry", function (_, content)
  SILE.call("noindent")
  local pos = SILE.findInTree(content, "posContainer")
  if not pos then return end
  local senses = SILE.findInTree(pos, "senses")
  if not senses[1] then return end
  SILE.process(content)
  SILE.typesetter:typeset(".")

  SILE.call("par")
  SILE.call("smallskip")
end)

SILE.registerCommand("senses", function (_, content)
  SILE.scratch.perseus.senseNo = 0
  SILE.process(content)
end)

SILE.registerCommand("senseContainer", function (_, content)
  SILE.scratch.perseus.senseNo = SILE.scratch.perseus.senseNo + 1
  SILE.typesetter:typeset(SILE.scratch.perseus.senseNo .. ". ")
  SILE.process(content)
end)

SILE.registerCommand("authorContainer", function (_, content)
  local auth = SILE.findInTree(content, "author")
  if not auth then return end
  local name = SILE.findInTree(auth, "name")
  if name and name[1] ~= "NULL" then
    SILE.call("font", { style = "italic" }, function ()
      SILE.typesetter:typeset("("..name[1]..")")
    end)
  end
end)

return perseus
