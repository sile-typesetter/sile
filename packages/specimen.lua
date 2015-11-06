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