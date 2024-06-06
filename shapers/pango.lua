-- This shaper package is deprecated and should only be used as an
-- example of how to create alternative shaper backends, in comparison
-- with the harfbuzz shaper.
local lgi = require("lgi")
require("string")
local pangolgi = lgi.Pango
local fm = lgi.PangoCairo.FontMap.get_default()
local pango_context = lgi.Pango.FontMap.create_context(fm)

local base = require("shapers.base")

local palcache = {}

local function _shape (text, item)
   local offset = item.offset
   local length = item.length
   local analysis = item.analysis
   local pgs = pangolgi.GlyphString.new()
   pangolgi.shape(string.sub(text, 1 + offset), length, analysis, pgs)
   return pgs
end

local shaper = pl.class(base)
shaper._name = "pango"

-- TODO: refactor so method accepts self
function shaper.getFace (options)
   local pal
   if options.pal then
      return options.pal
   end
   local p = pl.pretty.write(options, "")
   if palcache[p] then
      return palcache[p]
   else
      pal = pangolgi.AttrList.new()
      if options.language then
         pal:insert(pangolgi.Attribute.language_new(pangolgi.Language.from_string(options.language)))
      end
      if options.font then
         pal:insert(pangolgi.Attribute.family_new(options.font))
      end
      if options.weight then
         pal:insert(pangolgi.Attribute.weight_new(tonumber(options.weight)))
      end
      if options.size then
         pal:insert(pangolgi.Attribute.size_new(options.size * 1024 * 0.75))
      end -- I don't know why 0.75
      if options.style then
         pal:insert(
            pangolgi.Attribute.style_new(
               options.style:lower() == "italic" and pangolgi.Style.ITALIC or pangolgi.Style.NORMAL
            )
         )
      end
      if options.variant then
         pal:insert(
            pangolgi.Attribute.variant_new(
               options.variant:lower() == "smallcaps" and pangolgi.Variant.SMALL_CAPS or pangolgi.Variant.NORMAL
            )
         )
      end
   end
   if options.language then
      pango_context:set_language(pangolgi.Language.from_string(options.language))
   end
   palcache[p] = pal
   return pal
end

function shaper:shapeToken (text, options)
   local pal = SILE.font.cache(options, self.getFace)
   local rv = {}
   local items = pangolgi.itemize(pango_context, text, 0, string.len(text), pal, nil)
   local twidth = SILE.types.length()
   for i = 1, #items do
      local item = items[i]
      local pgs = _shape(text, item)
      -- local text = string.sub(text,1+items[i].offset, items[i].length)
      -- local depth, height = 0,0
      local font = items[i].analysis.font
      twidth = twidth + pgs:get_width() / 1024
      for g in pairs(pgs.glyphs) do
         local rect = font:get_glyph_extents(pgs.glyphs[g].glyph)
         table.insert(rv, {
            height = -rect.y / 1024,
            depth = (rect.y + rect.height) / 1024,
            width = rect.width / 1024,
            glyph = pgs.glyphs[g].glyph,
            pgs = pgs,
            font = font,
            -- text = text
         })
      end
   end
   return rv, twidth
end

function shaper.addShapedGlyphToNnodeValue (_, nnodevalue, shapedglyph)
   nnodevalue.pgs = shapedglyph.pgs
   nnodevalue.font = shapedglyph.font
end

return shaper
