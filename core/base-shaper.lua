if not SILE.shapers then SILE.shapers = { } end

SILE.settings.declare({
  name = "shaper.spacepattern",
  type = "string",
  default = "%s+",
  help = "The Lua pattern used for splitting words on spaces"
})

SILE.shapers.base = std.object {

  -- Return the length of a space character
  -- with a particular set of font options,
  -- giving preference to document.spaceskip

  -- Caching this has no significant speedup
  measureSpace = function(self, options)
    local ss = SILE.settings.get("document.spaceskip")
    if ss then return ss end
    local i,w = self:shapeToken(" ", options)
    local spacewidth
    if w then spacewidth = w.length
    else
      if not i[1] then return SILE.length.new() end
      spacewidth = i[1].width
    end
    return SILE.length.new({
      length = spacewidth * 1.2,
      shrink = spacewidth/3,
      stretch = spacewidth /2
    }) -- XXX all rather arbitrary
  end,

  measureDim = function (self, char)
    local options = SILE.font.loadDefaults({})
    local i = self:shapeToken(char, options)
    if char == "x" then
      return i[1].height
    else
      return i[1].width
    end
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
    if SILE.typesetter.frame:writingDirection() == "TTB" then
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

  makeSpaceNode = function(self, options)
    return SILE.nodefactory.newGlue({ width = SILE.shaper:measureSpace(options) })
  end
}