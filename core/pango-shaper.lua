local lgi = require("lgi");
require "string"
local pango = lgi.Pango
local fm = lgi.PangoCairo.FontMap.get_default()
local pango_context = lgi.Pango.FontMap.create_context(fm)

SILE.shapers = { pango= {} }

SILE.settings.declare({
  name = "shaper.spacepattern", 
  type = "string",
  default = "%s+",
  help = "The Lua pattern used for splitting words on spaces"
})

local pango_itemize = pango.itemize
local function itemize(s, pal)
  return pango_itemize(pango_context, s, 0, s:len(), pal)
end

local pango_shape = pango.shape
local function shape(s, item)
  local pgs = pango.GlyphString.new()
  pango_shape(s:sub(item.offset + 1), item.length, item.analysis, pgs)
  return pgs
end

local getPal
do
  local cache = {}
  function getPal(options)
    if options.language then
      pango_context:set_language(pango.Language.from_string(options.language))
    end

    local pal = options.pal
    if pal then return pal end

    local hash = std.string.pickle(options)
    pal = cache[hash]
    if pal then return pal end

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
      pal:insert(pango.Attribute.style_new(options.style == "italic" and pango.Style.ITALIC or pango.Style.NORMAL))
    end
    if options.variant then
      pal:insert(pango.Attribute.variant_new(options.variant == "smallcaps" and pango.Variant.SMALL_CAPS or pango.Variant.NORMAL))
    end
    cache[hash] = pal
    return pal
  end
end

local measureSpace
do
  local cache = {}
  function measureSpace(pal)
    local length = SILE.settings.get("document.spaceskip")
    if length then return length end

    length = cache[pal]
    if length then return length end

    local item = itemize(" ", pal)[1]
    local g = (shape(" ", item).glyphs)[1]
    local width = g.geometry.width / 1024
    length = SILE.length.new({ length = width * 1.2, shrink = width/3, stretch = width /2 }) -- XXX
    cache[pal] = length
    return length
  end
end

do
  local cache = {}
  function SILE.shapers.pango.measureDim(char)
    local pal = getPal(SILE.font.loadDefaults({}))

    if not cache[pal] then cache[pal] = {} end

    local width = cache[pal][char]
    if width then return width end

    local item = itemize(char, pal)[1]
    local g = (shape(char, item).glyphs)[1]
    if char == "x" then 
      local font = item.analysis.font
      local rect = font:get_glyph_extents(g.glyph)
      width = -rect.y/1024
    else
      width = g.geometry.width / 1024
    end
    cache[pal][char] = width
    return width
  end
end

function SILE.shapers.pango.shape(text, options)
  if not options then options = {} end
  options = SILE.font.loadDefaults(options)

  local pal = getPal(options)
  local nodes = {}
  local gluewidth = measureSpace(pal)
  for token in SU.gtoke(text, SILE.settings.get("shaper.spacepattern")) do
    if (token.separator) then
      table.insert(nodes, SILE.nodefactory.newGlue({ width = gluewidth }))
    else
      local items = itemize(token.string, pal)
      local nnode = {}
      for i in pairs(items) do
        local pgs = shape(token.string, items[i])
        -- Sum the glyphs in this string
        local depth, height = 0,0
        local font = items[i].analysis.font
        for g in pairs(pgs.glyphs) do
          local rect = font:get_glyph_extents(pgs.glyphs[g].glyph)
          local desc = rect.y + rect.height
          local asc  = -rect.y 
          if desc > depth then depth = desc end
          if asc > height then height = asc end
        end
        table.insert(nnode, SILE.nodefactory.newHbox({ 
          depth = depth / 1024,
          height= height / 1024,
          width = SILE.length.new({ length= pgs:get_width() / 1024 }),
          value = {font = font, glyphString = pgs, options = options }
        }))
      end
      table.insert(nodes, SILE.nodefactory.newNnode({ 
        nodes = nnode,
        text = token.string,
        pal = pal,
        options = options,
        language = options.language
      }))
    end
  end
  return nodes
end


SILE.shaper = SILE.shapers.pango

-- 
-- local s = "ltr שָׁוְא ltr"
-- inspect = require "inspect"
-- 

-- for i in pairs(items) do
--   local offset = items[i].offset
--   local length = items[i].length
--   local analysis = items[i].analysis
--   local pgs = pango.GlyphString.new()
--   pango.shape(string.sub(s,1+offset), length, analysis, pgs)
--   return pgs
--   cr:move_to(x, 50)
--   cr:show_glyph_string(analysis.font, pgs)
--   x = x + pgs:get_width()/1024
--   print(x)
-- end
