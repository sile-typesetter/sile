plain = SU.deepCopy(SILE.baseClass);
--SILE.require("packages/counters");
--SILE.scratch.counters.folio = { value= 1, display= "arabic" };

plain.pageTemplate.frames = {
  a = SILE.newFrame({ left = "5%", right = "95%", top = "5%", bottom = "90%", id = "a" }),
  folio = SILE.newFrame({left = "5%", right = "95%", top = "92%", bottom = "97%", id = "folio"})
};
plain.pageTemplate.firstContentFrame = plain.pageTemplate.frames["a"];

local c = 1
plain.newPage = function()
  -- io.write("["+SILE.formatCounter(SILE.scratch.counters.folio)+"] ");
  io.write("["..c.."] ");
  c = c + 1
-- //   var f = SILE.getFrame("folio");
-- //   if (f) {
-- //     SILE.typesetNaturally(f,
-- //       [
-- //         SILE.nodefactory.newHbox({ width: 0, value: {glyph: 0} }),
-- //         SILE.nodefactory.newGlue({ width:0, stretch: 10000 }),
-- //       ].concat(SILE.shaper.shape(SILE.formatCounter(SILE.scratch.counters.folio))).concat([
-- //         SILE.nodefactory.newGlue({ width:0, stretch: 10000 }),
-- //       ])
-- //     )
-- //   }
-- //   SILE.scratch.counters.folio.value++;
  return SILE.baseClass:newPage();
end

return plain;