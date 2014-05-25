-- Folios class
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value= 1, display= "arabic" };

return {
  init = function () end,
  exports = {
    outputFolio = function (this, frame) 
      if not frame then frame = "folio" end
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
    end
  }
}