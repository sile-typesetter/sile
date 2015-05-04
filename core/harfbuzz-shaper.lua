
if not SILE.shapers then SILE.shapers = { } end
local hb = require("justenoughharfbuzz")
SILE.require("core/base-shaper")

SILE.shapers.harfbuzz = SILE.shapers.base {
  shapeToken = function (self, text, options)
    local face = SILE.font.cache(options, self.getFace)
    if not face then 
      SU.error("Could not find requested font "..options.." or any suitable substitutes")
    end
    return { hb._shape(text,
                      face.face,
                      options.script, 
                      options.direction,
                      options.language, 
                      options.size, 
                      options.features
            ) }
  end,
  getFace = function(opts)
    local face = hb._face(opts)
    SU.debug("fonts", "Resolved font family "..opts.font.." -> "..face.filename)
    return face
  end,
  addShapedGlyphToNnodeValue = function (self, nnodevalue, shapedglyph)
    if not nnodevalue.glyphString then nnodevalue.glyphs = {} end
    if not nnodevalue.glyphNames then nnodevalue.glyphNames = {} end
    table.insert(nnodevalue.glyphString, shapedglyph.codepoint)
    table.insert(nnodevalue.glyphNames, shapedglyph.name)
  end
}

SILE.shaper = SILE.shapers.harfbuzz
