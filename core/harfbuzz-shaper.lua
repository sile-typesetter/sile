
if not SILE.shapers then SILE.shapers = { } end
local hb = require("justenoughharfbuzz")

-- XXX This shouldn't be in the shaper. But still...

local fontconfig

if not pcall(function () fontconfig = require("macfonts") end) then
  fontconfig = require("justenoughfontconfig")
end

SILE.require("core/base-shaper")

local smallTokenSize = 20 -- Small words will be cached
local shapeCache = {}
local _key = function(options,text)
  return table.concat({text,options.family;options.language;options.script;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.direction;options.filename},";")
end

local substwarnings = {}
local usedfonts = {}
SILE.shapers.harfbuzz = SILE.shapers.base {
  shapeToken = function (self, text, options)
    if #text < smallTokenSize then local v = shapeCache[_key(options,text)]; if v then return v end end
    if #text <1 then return {} end -- work around segfault in HB < 1.0.4
    local face = SILE.font.cache(options, self.getFace)
    if not face then
      SU.error("Could not find requested font "..options.." or any suitable substitutes")
    end
    if not(options.filename) and face.family ~= options.family and not substwarnings[options.family] then
      substwarnings[options.family] = true
      SU.warn("Font '"..options.family.."' not available, falling back to '"..face.family.."'")
    end
    usedfonts[face] = true
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
    local face = fontconfig._face(opts)
    SU.debug("fonts", "Resolved font family "..opts.family.." -> "..(face and face.filename))
    if not face.filename then SU.error("Couldn't find face "..opts.family) end
    local fh,e = io.open(face.filename, "rb")
    if e then SU.error("Can't open "..e) end
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
    table.insert(nnodevalue.glyphString, shapedglyph.gid)
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
    for face,_ in pairs(usedfonts) do
      local font = ot.parseFont(face)
      local version = "Unknown version"
      if font and font.names and font.names[5] then
        for l,v in pairs(font.names[5]) do version = v[1]; break end
      end
      print(face.filename..":"..face.index, version)
    end
  end
}

SILE.shaper = SILE.shapers.harfbuzz
