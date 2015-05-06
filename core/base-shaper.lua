if not SILE.shapers then SILE.shapers = { } end

SILE.tokenizers.default = function(text)
  return SU.gtoke(text, SILE.settings.get("shaper.spacepattern"))
end

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

  itemize = function(self, nodelist, text)
    for token in SU.gtoke(text, "-") do
      local t2= token.separator and token.separator or token.string
      local newNodes = SILE.shaper:shape(t2)
      for i=1,#newNodes do
        nodelist[#(nodelist)+1] = newNodes[i]
        if token.separator then
          nodelist[#(nodelist)+1] = SILE.nodefactory.newPenalty({ value = SILE.settings.get("linebreak.hyphenPenalty") })
        end
      end
    end
  end,

  tokenize = function(self, text, options)
    -- Do language-specific tokenization
    pcall(function () SILE.require("languages/"..options.language) end)
    local tokenizer = SILE.tokenizers[options.language]
    if not tokenizer then
      tokenizer = SILE.tokenizers.default
    end
    return tokenizer(text)
  end,

  shape = function(self, text, options)
    if not options then options = {} end
    options = SILE.font.loadDefaults(options)
    local nodes = {}
    if (type(self) ~= "table") then SU.error("shape called incorrectly", true) end
    local gluewidth = self:measureSpace(options)
    for token in self:tokenize(text,options) do
      if (token.separator) then
        table.insert(nodes, SILE.nodefactory.newGlue({ width = gluewidth }))
      elseif (token.node) then
        table.insert(nodes, token.node)
      else
        nnodes = self:createNnodes(token.string, options)
        for i= 1,#nnodes do
          nodes[#nodes+1] = nnodes[i]
        end
      end
    end
    return nodes
  end,

  addShapedGlyphToNnodeValue = function (self, nnodevalue, shapedglyph)
    SU.error("Abstract function addShapedGlyphToNnodeValue called", true)
  end,

  createNnodes = function (self, token, options)
    local items, width = self:shapeToken(token, options)
    local nnodeContents = {}
    local glyphs = {}
    local totalWidth = 0
    local depth = 0
    local height = 0
    local glyphNames = {}
    local nnodeValue = { text = token, options = options, glyphString = {} }
    for i = 1,#items do local glyph = items[i]        
      if glyph.depth > depth then depth = glyph.depth end
      if glyph.height > height then height = glyph.height end
      totalWidth = totalWidth + glyph.width
      self:addShapedGlyphToNnodeValue(nnodeValue, glyph)
    end
    table.insert(nnodeContents, SILE.nodefactory.newHbox({ 
      depth = depth,
      height= height,
      width = width or SILE.length.new({ length = totalWidth }),
      value = nnodeValue
    }))
    -- Why does the nnode contain only one hbox?
    return { SILE.nodefactory.newNnode({ 
      nodes = nnodeContents,
      text = token,
      options = options,
      language = options.language
    }) }
  end
}