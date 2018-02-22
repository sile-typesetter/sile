if not SILE.shapers then SILE.shapers = { } end

local smallTokenSize = 20 -- Small words will be cached
local shapeCache = {}
local _key = function(options)
  return table.concat({options.family;options.language;options.script;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.direction;options.filename},";")
end

SILE.settings.declare({name = "shaper.variablespaces", type = "integer", default = 1})
SILE.settings.declare({name = "shaper.spaceenlargementfactor", type = "number or integer", default = 1.2})
SILE.settings.declare({name = "shaper.spaceshrinkfactor", type = "number or integer", default = 1/3})
SILE.settings.declare({name = "shaper.spacestretchfactor", type = "number or integer", default = 1/2})

-- Function for testing shaping in the repl
makenodes = function(s,o)
  return SILE.shaper:createNnodes(s, SILE.font.loadDefaults(o or {}))
end

SILE.shapers.base = std.object {

  -- Return the length of a space character
  -- with a particular set of font options,
  -- giving preference to document.spaceskip

  -- Caching this has no significant speedup
  measureSpace = function(self, options)
    local ss = SILE.settings.get("document.spaceskip")
    if ss then
      SILE.settings.temporarily(function()
        SILE.settings.set("font.size", options.size)
        SILE.settings.set("font.family", options.family)
        ss = ss:absolute()
      end)
      return ss
    end
    local i,w = self:shapeToken(" ", options)
    local spacewidth
    if w then spacewidth = w.length
    else
      if not i[1] then return SILE.length.new() end
      spacewidth = i[1].width
    end
    return SILE.length.new({
      length = spacewidth * SILE.settings.get("shaper.spaceenlargementfactor"),
      shrink = spacewidth * SILE.settings.get("shaper.spaceshrinkfactor"),
      stretch = spacewidth * SILE.settings.get("shaper.spacestretchfactor")
    })
  end,

  measureChar = function (self, char)
    local options = SILE.font.loadDefaults({})
    local i = self:shapeToken(char, options)
    return { height = i[1].height, width = i[1].width }
  end,


  -- Given a text and some font options, return a bunch of boxes
  shapeToken = function(self, text, options)
    SU.error("Abstract function shapeToken called", true)
  end,

  -- Given font options, select a font. We will handle
  -- caching here. Returns an arbitrary, implementation-specific
  -- object (ie a PAL for Pango, font number for libtexpdf, ...)
  getFace = function(options)
    SU.error("Abstract function getFace called", true)
  end,

  addShapedGlyphToNnodeValue = function (self, nnodevalue, shapedglyph)
    SU.error("Abstract function addShapedGlyphToNnodeValue called", true)
  end,

  preAddNodes = function(self, items, nnodeValue)
  end,

  createNnodes = function (self, token, options)
    local items, width = self:shapeToken(token, options)
    if #items < 1 then return {} end

    local lang = options.language
    SILE.languageSupport.loadLanguage(lang)
    local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
    local nodes = {}
    for node in (nodeMaker { options=options }):iterator(items, token) do
      nodes[#nodes+1] = node
    end
    return nodes
  end,

  formNnode = function (self, contents, token, options)
    local nnodeContents = {}
    local glyphs = {}
    local totalWidth = 0
    local depth = 0
    local height = 0
    local glyphNames = {}
    local nnodeValue = { text = token, options = options, glyphString = {} }
    SILE.shaper:preAddNodes(contents, nnodeValue)
    for i = 1,#contents do local glyph = contents[i]
      if glyph.depth > depth then depth = glyph.depth end
      if glyph.height > height then height = glyph.height end
      totalWidth = totalWidth + glyph.width
      self:addShapedGlyphToNnodeValue(nnodeValue, glyph)
    end
    local misfit = false
    if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
      if options.direction == "LTR" then misfit = true end
    else
      if options.direction == "TTB" then misfit = true end
    end
    table.insert(nnodeContents, SILE.nodefactory.newHbox({
      depth = depth,
      height = height,
      misfit = misfit,
      width = width or SILE.length.new({ length = totalWidth }),
      value = nnodeValue
    }))
    return SILE.nodefactory.newNnode({
      nodes = nnodeContents,
      text = token,
      misfit = misfit,
      options = options,
      language = options.language
    })
  end,

  makeSpaceNode = function(self, options, item)
    if SILE.settings.get("shaper.variablespaces") == 1 then
      spacewidth = item.width
      w = SILE.length.new({
        length = spacewidth * SILE.settings.get("shaper.spaceenlargementfactor"),
        shrink = spacewidth * SILE.settings.get("shaper.spaceshrinkfactor"),
        stretch = spacewidth * SILE.settings.get("shaper.spacestretchfactor")
      })
      return (SILE.nodefactory.newGlue({ width = w }))
    else
      return SILE.nodefactory.newGlue({ width = SILE.shaper:measureSpace(options) })
    end
  end
}
