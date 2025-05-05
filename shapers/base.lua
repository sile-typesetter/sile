--- SILE shaper class.
-- @interfaces shapers

-- local smallTokenSize = 20 -- Small words will be cached
-- local shapeCache = {}
-- local _key = function (options)
--   return table.concat({ options.family;options.language;options.script;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.variations;options.direction;options.filename }, ";")
-- end

local function shapespace (spacewidth)
   spacewidth = SU.cast("measurement", spacewidth)
   -- In some scripts with word-level kerning, glue can be negative.
   -- Use absolute value to ensure stretch and shrink work as expected.
   local abs_length = math.abs(spacewidth:tonumber())
   local length, stretch, shrink = abs_length, 0, 0
   if SILE.settings:get("shaper.variablespaces") then
      length = spacewidth * SILE.settings:get("shaper.spaceenlargementfactor")
      stretch = abs_length * SILE.settings:get("shaper.spacestretchfactor")
      shrink = abs_length * SILE.settings:get("shaper.spaceshrinkfactor")
   end
   return SILE.types.length(length, stretch, shrink)
end

local shaper = pl.class()
shaper.type = "shaper"
shaper._name = "base"

function shaper:_init ()
   SU._avoid_base_class_use(self)
   -- Function for testing shaping in the repl
   -- TODO, figure out a way to explicitly register things in the repl env
   _G["makenodes"] = function (token, options)
      return SILE.shaper:createNnodes(token, SILE.font.loadDefaults(options or {}))
   end
   self:_declareBaseSettings()
   self:declareSettings()
end

function shaper:declareSettings () end

function shaper:_declareBaseSettings ()
   SILE.settings:declare({
      parameter = "shaper.variablespaces",
      type = "boolean",
      default = true,
   })
   SILE.settings:declare({
      parameter = "shaper.spaceenlargementfactor",
      type = "number or integer",
      default = 1,
   })
   SILE.settings:declare({
      parameter = "shaper.spacestretchfactor",
      type = "number or integer",
      default = 1 / 2,
   })
   SILE.settings:declare({
      parameter = "shaper.spaceshrinkfactor",
      type = "number or integer",
      default = 1 / 3,
   })
   SILE.settings:declare({
      parameter = "shaper.tracking",
      type = "number or nil",
      default = nil,
   })
end

-- Return the length of a space character
-- with a particular set of font options,
-- giving preference to document.spaceskip
-- Caching this has no significant speedup
function shaper:measureSpace (options)
   local ss = SILE.settings:get("document.spaceskip")
   if ss then
      SILE.settings:temporarily(function ()
         SILE.settings:set("font.size", options.size)
         SILE.settings:set("font.family", options.family)
         SILE.settings:set("font.filename", options.filename)
         ss = ss:absolute()
      end)
      return ss
   end
   local items, width = self:shapeToken(" ", options)
   if not width and not items[1] then
      SU.warn("Could not measure the width of a space")
      return SILE.types.length()
   end
   return shapespace(width and width.length or items[1].width)
end

function shaper:measureChar (char)
   local options = SILE.font.loadDefaults({})
   options.tracking = SILE.settings:get("shaper.tracking")
   local items = self:shapeToken(char, options)
   if items and #items > 0 then
      local measurements = {
         width = 0,
         height = 0,
         depth = 0,
      }
      for _, item in ipairs(items) do
         measurements.width = measurements.width + item.width
         measurements.height = math.max(measurements.height, item.height)
         measurements.depth = math.max(measurements.depth, item.depth)
      end
      return measurements, items[1].gid ~= 0
   else
      SU.error("Unable to measure character", char)
   end
end

-- Given a text and some font options, return a bunch of boxes
function shaper:shapeToken (_, _)
   SU.error("Abstract function shapeToken called", true)
end

-- Given font options, select a font. We will handle
-- caching here. Returns an arbitrary, implementation-specific
-- object (ie a PAL for Pango, font number for libtexpdf, ...)
function shaper:getFace ()
   SU.error("Abstract function getFace called", true)
end

function shaper:addShapedGlyphToNnodeValue (_, _)
   SU.error("Abstract function addShapedGlyphToNnodeValue called", true)
end

function shaper:preAddNodes (_, _) end

function shaper:createNnodes (token, options)
   options.tracking = SILE.settings:get("shaper.tracking")
   local items, _ = self:shapeToken(token, options)
   if #items < 1 then
      return {}
   end
   local lang = options.language
   SILE.languageSupport.loadLanguage(lang)
   local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
   local nodes = {}
   for node in nodeMaker(options):iterator(items, token) do
      table.insert(nodes, node)
   end
   return nodes
end

function shaper:formNnode (contents, token, options)
   local nnodeContents = {}
   -- local glyphs = {}
   local totalWidth = 0
   local totalDepth = 0
   local totalHeight = 0
   -- local glyphNames = {}
   local nnodeValue = { text = token, options = options, glyphString = {} }
   SILE.shaper:preAddNodes(contents, nnodeValue)
   local orthogonal = false
   if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
      if options.direction == "LTR" then
         orthogonal = true
      end
   else
      if options.direction == "TTB" then
         orthogonal = true
      end
   end
   for i = 1, #contents do
      local glyph = contents[i]
      if (options.direction == "TTB") ~= orthogonal then
         if glyph.width > totalHeight then
            totalHeight = glyph.width
         end
         totalWidth = totalWidth + glyph.height
      else
         if glyph.depth > totalDepth then
            totalDepth = glyph.depth
         end
         if glyph.height > totalHeight then
            totalHeight = glyph.height
         end
         totalWidth = totalWidth + glyph.width
      end
      self:addShapedGlyphToNnodeValue(nnodeValue, glyph)
   end
   table.insert(
      nnodeContents,
      SILE.types.node.hbox({
         depth = totalDepth,
         height = totalHeight,
         orthogonal = orthogonal,
         width = SILE.types.length(totalWidth),
         value = nnodeValue,
      })
   )
   return SILE.types.node.nnode({
      nodes = nnodeContents,
      text = token,
      orthogonal = orthogonal,
      options = options,
      language = options.language,
   })
end

function shaper:makeSpaceNode (options, item)
   local width
   if SILE.settings:get("shaper.variablespaces") then
      width = shapespace(item.width)
   else
      width = SILE.shaper:measureSpace(options)
   end
   return SILE.types.node.glue(width)
end

function shaper:debugVersions () end

return shaper
