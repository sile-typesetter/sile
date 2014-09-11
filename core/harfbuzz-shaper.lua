
if not SILE.shapers then SILE.shapers = { harfbuzz = {} } end

SILE.settings.declare({
  name = "shaper.spacepattern", 
  type = "string",
  default = "%s+",
  help = "The Lua pattern used for splitting words on spaces"
})

SILE.shapers.harfbuzz = require("justenoughharfbuzz")

local function measureSpace( options )
  local ss = SILE.settings.get("document.spaceskip") 
  if ss then return ss end
  local i = { SILE.shapers.harfbuzz._shape(" ") }
  local spacewidth = i[1].width
  return SILE.length.new({ length = spacewidth * 1.2, shrink = spacewidth/3, stretch = spacewidth /2 }) -- XXX
end

function SILE.shapers.harfbuzz.measureDim(char)
  local options = SILE.font.loadDefaults({})
  local i = { SILE.shapers.harfbuzz._shape(char, options) }
  if char == "x" then 
    return i[1].height
  else
    return i[1].width
  end
end 

function SILE.shapers.harfbuzz.shape(text, options)
  if not options then options = {} end
  options = SILE.font.loadDefaults(options)
  local nodes = {}
  local gluewidth = measureSpace(options)
  for token in SU.gtoke(text, SILE.settings.get("shaper.spacepattern")) do
    if (token.separator) then
      table.insert(nodes, SILE.nodefactory.newGlue({ width = gluewidth }))
    else
      local items = { SILE.shapers.harfbuzz._shape(token.string, options) }
      local glyphs = {}
      local totalWidth = 0
      local depth = 0
      local height = 0
      local nnode = {}
      for i = 1,#items do local glyph = items[i]
        if glyph.depth > depth then depth = glyph.depth end
        if glyph.height > height then height = glyph.height end
        totalWidth = totalWidth + glyph.width
        table.insert(glyphs, glyph.codepoint)
      end
      table.insert(nnode, SILE.nodefactory.newHbox({ 
        depth = depth,
        height= height,
        width = SILE.length.new({ length = totalWidth }),
        value = {glyphString = glyphs, options = options }
      }))
      table.insert(nodes, SILE.nodefactory.newNnode({ 
        nodes = nnode,
        text = token.string,
        options = options,
        language = options.language
      }))
    end
  end
  return nodes
end

SILE.shaper = SILE.shapers.harfbuzz