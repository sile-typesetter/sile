SILE.registerCommand("repertoire", function(o,c)
  local columns = o.columns or 5
  local ot = SILE.require("core/opentype-parser")
  local options = SILE.font.loadDefaults({})
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local fh = io.open(face.filename)
  local font = ot.parseFont(fh)
  local maxg = font.maxp.numGlyphs
  local em = SILE.toPoints("1em")
  for i = 1,maxg-1 do
    SILE.typesetter:pushHbox({
      height= SILE.length.new({ length = em * 1.2 }),
      width= SILE.length.new({ length = em /2 }),
      depth= 0,
      value= { options = options, glyphString =  { i } },
    })
    SILE.typesetter:typeset(" ")
    SILE.typesetter:pushPenalty({penalty = 0})
  end
end)

SILE.registerCommand("pangrams", function (o,c)
  pg = {
    "Sphinx of black quartz, judge my vow!",
    "The five boxing wizards jump quickly.",
    "Five quacking zephyrs jolt my wax bed.",
    "Pack my box with five dozen liquor jugs.",
    "Grumpy wizards make toxic brew for the evil queen and jack.",
    "Voix ambiguë d’un cœur qui au zéphyr préfère les jattes de kiwi.",
  }
  for i = 1, #pg do
    SILE.typesetter:typeset(pg[i] .. " ")
  end
  SILE.call("bigskip")
end)