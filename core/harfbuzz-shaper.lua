
if not SILE.shapers then SILE.shapers = { } end
local hb = require("justenoughharfbuzz")
SILE.require("core/base-shaper")

local smallTokenSize = 20 -- Small words will be cached
local shapeCache = {}
local _key = function(options,text)
  return table.concat({text,options.font;options.language;options.script;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.direction;options.filename},";")
end

local substwarnings = {}
local usedfonts = {}
SILE.shapers.harfbuzz = SILE.shapers.base {
  shapeToken = function (self, text, options)
    if #text < smallTokenSize then local v = shapeCache[_key(options,text)]; if v then return v end end
    local face = SILE.font.cache(options, self.getFace)
    if not face then
      SU.error("Could not find requested font "..options.." or any suitable substitutes")
    end
    if not(options.filename) and face.family ~= options.font and not substwarnings[options.font] then
      substwarnings[options.font] = true
      SU.warn("Font '"..options.font.."' not available, falling back to '"..face.family.."'")
    end
    if face.filename then usedfonts[face.filename] = true end
    local items = { hb._shape(text,
                      face.data,
                      face.index,
                      options.script,
                      options.direction,
                      options.language,
                      options.size,
                      options.features
            ) }
    for i = 1,#items do
      local e = (i == #items) and #text or items[i+1].index
      items[i].text = text:sub(items[i].index+1, e) -- Lua strings are 1-indexed
    end
    if #text < smallTokenSize then shapeCache[_key(options,text)] = items end
    return items
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
      if items[i].y_offset or items[i].x_offset or items[i].width ~= items[i].glyphAdvance then
        nnodeValue.complex = true; break
      end
    end
  end,
  addShapedGlyphToNnodeValue = function (self, nnodevalue, shapedglyph)
    if nnodevalue.complex then

      if not nnodevalue.items then nnodevalue.items = {} end
      nnodevalue.items[#nnodevalue.items+1] = shapedglyph
    end
    if not nnodevalue.glyphString then nnodevalue.glyphString = {} end
    if not nnodevalue.glyphNames then nnodevalue.glyphNames = {} end
    table.insert(nnodevalue.glyphString, shapedglyph.codepoint)
    table.insert(nnodevalue.glyphNames, shapedglyph.name)
  end,
  debugVersions = function()
    local ot = SILE.require("core/opentype-parser")
    print("Harfbuzz version: "..hb.version())
    print("Shapers enabled: ".. table.concat({hb.shapers()}, ", "))
    pcall( function () icu = require("justenoughicu") end)
    if icu then
      print("ICU support enabled")
    end
    print("")
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
