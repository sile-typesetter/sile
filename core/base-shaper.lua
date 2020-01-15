if not SILE.shapers then SILE.shapers = { } end

-- local smallTokenSize = 20 -- Small words will be cached
-- local shapeCache = {}
-- local _key = function (options)
--   return table.concat({ options.family;options.language;options.script;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.direction;options.filename }, ";")
-- end

SILE.settings.declare({ name = "shaper.variablespaces", type = "boolean", default = true })
SILE.settings.declare({ name = "shaper.spaceenlargementfactor", type = "number or integer", default = 1.2 })
SILE.settings.declare({ name = "shaper.spacestretchfactor", type = "number or integer", default = 1/2 })
SILE.settings.declare({ name = "shaper.spaceshrinkfactor", type = "number or integer", default = 1/3 })

-- Function for testing shaping in the repl
-- luacheck: ignore makenodes
makenodes = function (token, options)
  return SILE.shaper:createNnodes(token, SILE.font.loadDefaults(options or {}))
end

local function shapespace (spacewidth)
  spacewidth = SU.cast("measurement", spacewidth)
  local length = spacewidth * SILE.settings.get("shaper.spaceenlargementfactor")
  local stretch = spacewidth * SILE.settings.get("shaper.spacestretchfactor")
  local shrink = spacewidth * SILE.settings.get("shaper.spaceshrinkfactor")
  return SILE.length(length, stretch, shrink)
end

SILE.shapers.base = pl.class({

    -- Return the length of a space character
    -- with a particular set of font options,
    -- giving preference to document.spaceskip
    -- Caching this has no significant speedup
    measureSpace = function (self, options)
      local ss = SILE.settings.get("document.spaceskip")
      if ss then
        SILE.settings.temporarily(function ()
          SILE.settings.set("font.size", options.size)
          SILE.settings.set("font.family", options.family)
          SILE.settings.set("font.filename", options.filename)
          ss = ss:absolute()
        end)
        return ss
      end
      local items, width = self:shapeToken(" ", options)
      if not width and not items[1] then
        SU.warn("Could not measure the width of a space")
        return SILE.length()
      end
      return shapespace(width and width.length or items[1].width)
    end,

    measureChar = function (self, char)
      local options = SILE.font.loadDefaults({})
      local items = self:shapeToken(char, options)
      return { height = items[1].height, width = items[1].width }
    end,

    -- Given a text and some font options, return a bunch of boxes
    shapeToken = function (_, _, _)
      SU.error("Abstract function shapeToken called", true)
    end,

    -- Given font options, select a font. We will handle
    -- caching here. Returns an arbitrary, implementation-specific
    -- object (ie a PAL for Pango, font number for libtexpdf, ...)
    getFace = function (_)
      SU.error("Abstract function getFace called", true)
    end,

    addShapedGlyphToNnodeValue = function (_, _, _)
      SU.error("Abstract function addShapedGlyphToNnodeValue called", true)
    end,

    preAddNodes = function (_, _, _)
    end,

    createNnodes = function (self, token, options)
      local items, _ = self:shapeToken(token, options)
      if #items < 1 then return {} end
      local lang = options.language
      SILE.languageSupport.loadLanguage(lang)
      local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
      local nodes = {}
      for node in nodeMaker(options):iterator(items, token) do
        table.insert(nodes, node)
      end
      return nodes
    end,

    formNnode = function (self, contents, token, options)
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
        if options.direction == "LTR" then misfit = true end
      else
        if options.direction == "TTB" then misfit = true end
      end
      for i = 1, #contents do
        local glyph = contents[i]
        if (options.direction == "TTB") ~= misfit then
          if glyph.width > totalHeight then totalHeight = glyph.width end
          totalWidth = totalWidth + glyph.height
        else
          if glyph.depth > totalDepth then totalDepth = glyph.depth end
          if glyph.height > totalHeight then totalHeight = glyph.height end
          totalWidth = totalWidth + glyph.width
        end
        self:addShapedGlyphToNnodeValue(nnodeValue, glyph)
      end
      table.insert(nnodeContents, SILE.nodefactory.hbox({
            depth = totalDepth,
            height = totalHeight,
            misfit = misfit,
            width = SILE.length(totalWidth),
            value = nnodeValue
        }))
      return SILE.nodefactory.nnode({
          nodes = nnodeContents,
          text = token,
          misfit = misfit,
          options = options,
          language = options.language
        })
    end,

    makeSpaceNode = function (_, options, item)
      local width
      if SILE.settings.get("shaper.variablespaces") then
        width = shapespace(item.width)
      else
        width = SILE.shaper:measureSpace(options)
      end
      return SILE.nodefactory.glue(width)
    end

  })
