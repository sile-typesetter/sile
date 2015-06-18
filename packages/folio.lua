-- Folios class
SILE.require("packages/counters");
SILE.scratch.counters.folio = { value= 1, display= "arabic" };

SILE.registerCommand("folios", function () SILE.scratch.counters.folio.off = false end)
SILE.registerCommand("nofolios", function () SILE.scratch.counters.folio.off = true end)
SILE.registerCommand("nofoliosthispage", function () SILE.scratch.counters.folio.off = 2 end)

return {
  init = function () end,
  exports = {
    outputFolio = function (this, frame)
      if not frame then frame = "folio" end
      if SILE.scratch.counters.folio.off then
        if SILE.scratch.counters.folio.off == 2 then
          SILE.scratch.counters.folio.off = false
        end
        SILE.scratch.counters.folio.value = SILE.scratch.counters.folio.value + 1
        return 
      end
      io.write("["..SILE.formatCounter(SILE.scratch.counters.folio).."] ");
      local f = SILE.getFrame("folio");
      if (f) then
        SILE.typesetNaturally(f, function()
          SILE.settings.pushState()
          SILE.settings.reset()
          SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
          SILE.call("hss")
          SILE.typesetter:typeset(SILE.formatCounter(SILE.scratch.counters.folio))
          SILE.call("hss")
          SILE.settings.popState()
        end)
      end
      SILE.scratch.counters.folio.value = SILE.scratch.counters.folio.value + 1
    end
  }
}
