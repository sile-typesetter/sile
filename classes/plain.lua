plain = SU.deepCopy(SILE.baseClass);
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value= 1, display= "arabic" };

plain.pageTemplate.frames = {
  a = SILE.newFrame({ left = "5%", right = "95%", top = "5%", bottom = "90%", id = "a" }),
  folio = SILE.newFrame({left = "5%", right = "95%", top = "92%", bottom = "97%", id = "folio"})
};
plain.pageTemplate.firstContentFrame = plain.pageTemplate.frames["a"];

plain.newPage = function()
  io.write("["..SILE.formatCounter(SILE.scratch.counters.folio).."] ");
  local f = SILE.getFrame("folio");
  if (f) then
    local nodes = SILE.shaper.shape(SILE.formatCounter(SILE.scratch.counters.folio))
    table.insert(nodes, 1,
      SILE.nodefactory.newGlue({ width=SILE.length.new({length = 0, stretch= 10000 })})
      )
    table.insert(nodes, 1,
      SILE.nodefactory.newHbox({ width=SILE.length.new({length = 0}), value = {glyph=0}})
      )    

    table.insert(nodes,
      SILE.nodefactory.newGlue({ width=SILE.length.new({length = 0, stretch= 10000 })})
    )
    SILE.typesetNaturally(f, nodes)
  end
  SILE.scratch.counters.folio.value = SILE.scratch.counters.folio.value + 1
  return SILE.baseClass:newPage();
end

return plain;