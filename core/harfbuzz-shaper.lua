local hb = require("justenoughharfbuzz")
local icu = require("justenoughicu")
local bitshim = require("bitshim")

if not SILE.shapers then SILE.shapers = { } end

SILE.settings.declare({
  parameter = "harfbuzz.subshapers",
  type = "string or nil",
  default = "",
  help = "Comma-separated shaper list to pass to Harfbuzz"
})

SILE.require("core/base-shaper")

local smallTokenSize = 20 -- Small words will be cached
local shapeCache = {}
local _key = function (options, text)
  return table.concat({ text, options.tracking or "1", options.family, options.language, options.script, options.size, ("%d"):format(options.weight), options.style, options.variant, options.features, options.direction, options.filename}, ";")
end

local substwarnings = {}
local usedfonts = {}

SILE.shapers.harfbuzz = pl.class({
    _base = SILE.shapers.base,

    shapeToken = function (self, text, options)
      local items
      if #text < smallTokenSize then items = shapeCache[_key(options, text)]; if items then return items end end
      local face = SILE.font.cache(options, self.getFace)
      if self:checkHBProblems(text, face) then return {} end
      if not face then
        SU.error("Could not find requested font "..options.." or any suitable substitutes")
      end
      if not(options.filename) and face.family ~= options.family and not substwarnings[options.family] then
        substwarnings[options.family] = true
        SU.warn("Font family '"..options.family.."' not available, falling back to '"..face.family.."'")
      end
      usedfonts[face] = true
      items = { hb._shape(text,
          face.data,
          face.index,
          options.script,
          options.direction,
          options.language,
          options.size,
          options.features,
          SILE.settings.get("harfbuzz.subshapers") or ""
        ) }
      for i = 1, #items do
        local j = (i == #items) and #text or items[i+1].index
        items[i].text = text:sub(items[i].index+1, j) -- Lua strings are 1-indexed
        if options.tracking then
          items[i].width = items[i].width * options.tracking
        end
      end
      if #text < smallTokenSize then shapeCache[_key(options, text)] = items end
      return items
    end,

    getFace = function (opts)
      local face = SILE.fontManager:face(opts)
      SU.debug("fonts", "Resolved font family '"..opts.family.."' -> "..(face and face.filename))
      if not face or not face.filename then SU.error("Couldn't find face '"..opts.family.."'") end
      if SILE.makeDeps then SILE.makeDeps:add(face.filename) end
      if bitshim.rshift(face.index, 16) ~= 0 then
        SU.warn("GX feature in '"..opts.family.."' is not supported, fallback to regular font face.")
        face.index = bitshim.band(face.index, 0xff)
      end
      local fh, err = io.open(face.filename, "rb")
      if err then SU.error("Can't open font file '"..face.filename.."': "..err) end
      face.data = fh:read("*all")
      return face
    end,

    preAddNodes = function (_, items, nnodeValue) -- Check for complex nodes
      for i = 1, #items do
        if items[i].y_offset or items[i].x_offset or items[i].width ~= items[i].glyphAdvance then
          nnodeValue.complex = true; break
        end
      end
    end,

    addShapedGlyphToNnodeValue = function (_, nnodevalue, shapedglyph)
      if nnodevalue.complex then

        if not nnodevalue.items then nnodevalue.items = {} end
        nnodevalue.items[#nnodevalue.items+1] = shapedglyph
      end
      if not nnodevalue.glyphString then nnodevalue.glyphString = {} end
      if not nnodevalue.glyphNames then nnodevalue.glyphNames = {} end
      table.insert(nnodevalue.glyphString, shapedglyph.gid)
      table.insert(nnodevalue.glyphNames, shapedglyph.name)
    end,

    debugVersions = function ()
      local ot = SILE.require("core/opentype-parser")
      print("Harfbuzz version: "..hb.version())
      print("Shapers enabled: ".. table.concat({ hb.shapers() }, ", "))
      if icu then
        print("ICU support enabled")
      end
      print("")
      print("Fonts used:")
      for face, _ in pairs(usedfonts) do
        local font = ot.parseFont(face)
        local version = "Unknown version"
        if font and font.names and font.names[5] then
          -- luacheck: ignore 512
          -- (It's OK to grab the first version we find in the name table)
          for _, v in pairs(font.names[5]) do version = v[1]; break end
        end
        print(face.filename..":"..face.index, version)
      end
    end,

    checkHBProblems = function (_, text, face)
      if hb.version_lessthan(1, 0, 4) and #text < 1 then
        return true
      end
      if hb.version_lessthan(2, 3, 0)
        and hb.get_table(face.data, face.index, "CFF "):len() > 0
        and not substwarnings["CFF "] then
        SILE.status.unsupported = true
        SU.warn("Vertical spacing of CFF fonts may be subtly inconsistent between systems. Upgrade to Harfbuzz 2.3.0 if you need absolute consistency.")
        substwarnings["CFF "] = true
      end
      return false
    end

  })

SILE.shaper = SILE.shapers.harfbuzz()
