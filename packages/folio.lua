-- Folios class
SILE.require("packages/counters")
SILE.scratch.counters.folio = { value = 1, display = "arabic" }

SILE.registerCommand("folios", function () SILE.scratch.counters.folio.off = false end)
SILE.registerCommand("nofolios", function () SILE.scratch.counters.folio.off = true end)
SILE.registerCommand("nofoliosthispage", function () SILE.scratch.counters.folio.off = 2 end)
SILE.registerCommand("foliostyle", function (options, content)
  SILE.call("center", {}, content)
end)

return {
  init = function () end,
  exports = {
    outputFolio = function (this, frame)
      if not frame then frame = "folio" end
      io.stderr:write("[" .. SILE.formatCounter(SILE.scratch.counters.folio) .. "] ")
      if SILE.scratch.counters.folio.off then
        if SILE.scratch.counters.folio.off == 2 then
          SILE.scratch.counters.folio.off = false
        end
      else
        local folioFrame = SILE.getFrame(frame)
        if (folioFrame) then
          SILE.typesetNaturally(folioFrame, function ()
            SILE.settings.pushState()
            SILE.settings.reset()
            SILE.call("foliostyle", {}, { SILE.formatCounter(SILE.scratch.counters.folio) })
            SILE.typesetter:leaveHmode()
            SILE.settings.popState()
          end)
        end
      end
      SILE.scratch.counters.folio.value = SILE.scratch.counters.folio.value + 1
    end
  }
}
