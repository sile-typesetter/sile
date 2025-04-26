-- This shaper package is deprecated and should only be used as an
-- example of how to create alternative shaper backends, in comparison
-- with the harfbuzz shaper.
local lgi = require("lgi")
require("string")
local pango = lgi.Pango
local fm = lgi.PangoCairo.FontMap.get_default()
local pango_context = lgi.Pango.FontMap.create_context(fm)

local base = require("shapers.base")

local palcache = {}

local function _shape (text, item)
   local offset = item.offset
   local length = item.length
   local analysis = item.analysis
   local pgs = pango.GlyphString.new()
   pango.shape(string.sub(text, 1 + offset), length, analysis, pgs)
   return pgs
end

local shaper = pl.class(base)
shaper._name = "pango"

function shaper:getFace (options)
   if not options then
      SU.deprecated("shaper.getFace()", "shaper:getFace()", "0.16.0", "0.17.0")
      return shaper:getFace(self)
   end
   local pal
   if options.pal then
      return options.pal
   end
   local p = pl.pretty.write(options, "")
   if palcache[p] then
      return palcache[p]
   else
      pal = pango.AttrList.new()
      if options.language then
         pal:insert(pango.Attribute.language_new(pango.Language.from_string(options.language)))
      end
      if options.font then
         pal:insert(pango.Attribute.family_new(options.font))
      end
      if options.weight then
         pal:insert(pango.Attribute.weight_new(tonumber(options.weight)))
      end
      if options.size then
         pal:insert(pango.Attribute.size_new(options.size * 1024 * 0.75))
      end -- I don't know why 0.75
      if options.style then
         pal:insert(
            pango.Attribute.style_new(options.style:lower() == "italic" and pango.Style.ITALIC or pango.Style.NORMAL)
         )
      end
      if options.variant then
         pal:insert(
            pango.Attribute.variant_new(
               options.variant:lower() == "smallcaps" and pango.Variant.SMALL_CAPS or pango.Variant.NORMAL
            )
         )
      end
   end
   if options.language then
      pango_context:set_language(pango.Language.from_string(options.language))
   end
   palcache[p] = pal
   return pal
end

function shaper:shapeToken (text, options)
   local pal = SILE.font.cache(options, self:_getFaceCallback())
   local rv = {}
   local items = pango.itemize(pango_context, text, 0, string.len(text), pal, nil)
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

function shaper:addShapedGlyphToNnodeValue (nnodevalue, shapedglyph)
   nnodevalue.pgs = shapedglyph.pgs
   nnodevalue.font = shapedglyph.font
end

return shaper
