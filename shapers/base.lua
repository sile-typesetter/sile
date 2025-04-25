--- SILE shaper class.
-- @interfaces shapers

local module = require("types.module")
local shaper = pl.class(module)
shaper.type = "shaper"

-- local smallTokenSize = 20 -- Small words will be cached
-- local shapeCache = {}
-- local _key = function (options)
--   return table.concat({ options.family;options.language;options.script;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.variations;options.direction;options.filename }, ";")
-- end

function shaper:_init ()
   -- Function for testing shaping in the repl
   -- TODO, figure out a way to explicitly register things in the repl env
   _G["makenodes"] = function (token, options)
      return SILE.shaper:createNnodes(token, SILE.font.loadDefaults(options or {}))
   end
   module._init(self)
end

function shaper:_declareSettings ()
   self.settings:declare({
      parameter = "shaper.variablespaces",
      type = "boolean",
      default = true,
   })
   self.settings:declare({
      parameter = "shaper.spaceenlargementfactor",
      type = "number or integer",
      default = 1,
   })
   self.settings:declare({
      parameter = "shaper.spacestretchfactor",
      type = "number or integer",
      default = 1 / 2,
   })
   self.settings:declare({
      parameter = "shaper.spaceshrinkfactor",
      type = "number or integer",
      default = 1 / 3,
   })
   self.settings:declare({
      parameter = "shaper.tracking",
      type = "number or nil",
      default = nil,
   })
end

function shaper:_shapespace (spacewidth)
   spacewidth = SU.cast("measurement", spacewidth)
   -- In some scripts with word-level kerning, glue can be negative.
   -- Use absolute value to ensure stretch and shrink work as expected.
   local abs_length = math.abs(spacewidth:tonumber())
   local length, stretch, shrink = abs_length, 0, 0
   if self.settings:get("shaper.variablespaces") then
      length = spacewidth * self.settings:get("shaper.spaceenlargementfactor")
      stretch = abs_length * self.settings:get("shaper.spacestretchfactor")
      shrink = abs_length * self.settings:get("shaper.spaceshrinkfactor")
   end
   return SILE.types.length(length, stretch, shrink)
end

-- Return the length of a space character
-- with a particular set of font options,
-- giving preference to document.spaceskip
-- Caching this has no significant speedup
function shaper:measureSpace (options)
   local ss = self.settings:get("document.spaceskip")
   if ss then
      self.settings:temporarily(function ()
         self.settings:set("font.size", options.size)
         self.settings:set("font.family", options.family)
         self.settings:set("font.filename", options.filename)
         ss = ss:absolute()
      end)
      return ss
   end
   local items, width = self:shapeToken(" ", options)
   if not width and not items[1] then
      SU.warn("Could not measure the width of a space")
      return SILE.types.length()
   end
   return self:_shapespace(width and width.length or items[1].width)
end

function shaper:measureChar (char)
   local options = SILE.font.loadDefaults({})
   options.tracking = self.settings:get("shaper.tracking")
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

-- TODO: Refactor so this isn't needed when the font module is refactored
function shaper:_getFaceCallback ()
   return function (options)
      return self:getFace(options)
   end
end

function shaper:addShapedGlyphToNnodeValue (_, _)
   SU.error("Abstract function addShapedGlyphToNnodeValue called", true)
end

function shaper:preAddNodes (_, _) end

function shaper:createNnodes (token, options)
   options.tracking = self.settings:get("shaper.tracking")
   local items, _ = self:shapeToken(token, options)
   if #items < 1 then
      return {}
   end
   -- TODO this shouldn't need a private interface to a different module type
   local language = SILE.typesetter:_cacheLanguage(options.language)
   local nodes = {}
   local nodemaker = language:nodemaker(options)
   for node in nodemaker:iterator(items, token) do
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
   local misfit = false
   if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
      if options.direction == "LTR" then
         misfit = true
      end
   else
      if options.direction == "TTB" then
         misfit = true
      end
   end
   for i = 1, #contents do
      local glyph = contents[i]
      if (options.direction == "TTB") ~= misfit then
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
         misfit = misfit,
         width = SILE.types.length(totalWidth),
         value = nnodeValue,
      })
   )
   return SILE.types.node.nnode({
      nodes = nnodeContents,
      text = token,
      misfit = misfit,
      options = options,
      language = options.language,
   })
end

function shaper:makeSpaceNode (options, item)
   local width
   if self.settings:get("shaper.variablespaces") then
      width = self:_shapespace(item.width)
   else
      width = SILE.shaper:measureSpace(options)
   end
   return SILE.types.node.glue(width)
end

function shaper:debugVersions () end

return shaper
