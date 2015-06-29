
if not SILE.shapers then SILE.shapers = { } end
local hb = require("justenoughharfbuzz")
SILE.require("core/base-shaper")

local substwarnings = {}
SILE.shapers.harfbuzz = SILE.shapers.base {
  shapeToken = function (self, text, options)
    local face = SILE.font.cache(options, self.getFace)
    if not face then
      SU.error("Could not find requested font "..options.." or any suitable substitutes")
    end
    if face.family ~= options.font and not substwarnings[options.font] then
      substwarnings[options.font] = true
      SU.warn("Font '"..options.font.."' not available, falling back to '"..face.family.."'")
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
    SU.debug("fonts", "Resolved font family "..opts.font.." -> "..(face and face.filename))
    return face
  end,
  preAddNodes = function(self, items, nnodeValue) -- Check for complex nodes
    for i=1,#items do
      if items[i].y_offset then
        nnodeValue.complex = true; break
      end
    end
  end,
  addShapedGlyphToNnodeValue = function (self, nnodevalue, shapedglyph)
    if nnodevalue.complex then

      if not nnodevalue.items then nnodevalue.items = {} end
      nnodevalue.items[#nnodevalue.items+1] = shapedglyph
      return
    end
    if not nnodevalue.glyphString then nnodevalue.glyphString = {} end
    if not nnodevalue.glyphNames then nnodevalue.glyphNames = {} end
    table.insert(nnodevalue.glyphString, shapedglyph.codepoint)
    table.insert(nnodevalue.glyphNames, shapedglyph.name)
  end
}

SILE.shaper = SILE.shapers.harfbuzz
