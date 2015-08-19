
if not SILE.shapers then SILE.shapers = { } end
local hb = require("justenoughharfbuzz")
SILE.require("core/base-shaper")

local substwarnings = {}
local usedfonts = {}
SILE.shapers.harfbuzz = SILE.shapers.base {
  shapeToken = function (self, text, options)
    local face = SILE.font.cache(options, self.getFace)
    if not face then
      SU.error("Could not find requested font "..options.." or any suitable substitutes")
    end
    if not(options.filename) and face.family ~= options.font and not substwarnings[options.font] then
      substwarnings[options.font] = true
      SU.warn("Font '"..options.font.."' not available, falling back to '"..face.family.."'")
    end
    if face.filename then usedfonts[face.filename] = true end
    return { hb._shape(text,
                      face.data,
                      face.index,
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
    local fh = io.open(face.filename) or SU.error("Can't open "..face.filename)
    face.data = fh:read("*all")
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
  end,
  debugVersions = function()
    local ot = SILE.require("core/opentype-parser")
    print("Harfbuzz version: "..hb.version())
    print("Fonts used:")
    for k,_ in pairs(usedfonts) do
      local fh = io.open(k)
      local font = ot.parseFont(fh)
      local version
      if font.names and font.names[5] then
        for l,v in pairs(font.names[5]) do version = v[1]; break end
      end
      print(k,version)
    end
  end
}

SILE.shaper = SILE.shapers.harfbuzz
