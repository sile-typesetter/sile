local metrics = require("fontmetrics")

SILE.registerCommand("repertoire", function(o,c)
  local columns = o.columns or 5
  local ot = SILE.require("core/opentype-parser")
  local options = SILE.font.loadDefaults({})
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  local maxg = font.maxp.numGlyphs
  local em = SILE.toPoints("1em")
  for i = 1,maxg-1 do
    wd = metrics.glyphwidth(i, face.data, face.index)
    SILE.typesetter:pushHbox({
      height= SILE.length.new({ length = 1.2 * options.size  }),
      width= SILE.length.new({ length = wd * options.size }),
      depth= 0,
      value= { options = options, glyphString =  { i } },
    })
    SILE.typesetter:pushGlue(((1-wd)*options.size).."pt plus 1pt minus 1pt")
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

SILE.registerCommand("set-to-width", function(options,content)
  local width = SILE.length.parse(SU.required(options, "width", "set to width")):absolute()
  local fontOptions = SILE.font.loadDefaults({})
  for line in SU.gtoke(content[1],"\n+") do
    if line.string then
      local tokens = SILE.shaper:shapeToken(line.string,fontOptions)
      local w = 0
      for j= 1,#tokens do w = w + tokens[j].width end
      local ratio = width.length / w
      SILE.call("font", {size = fontOptions.size * ratio}, function()
        SILE.process({line.string})
        SILE.call("par")
      end)
    end
  end
end)