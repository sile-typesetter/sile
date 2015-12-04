local hb = require("justenoughharfbuzz")
local vstruct = require("vstruct")

local function parse_colr(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)

  local version = vstruct.readvals(">u2", fd)
  if version ~= 0 then return end

  local colr = {}

  local header = vstruct.read(">nBases:u2 oBases:u4 oLayers:u4 nLayers:u2", fd)
  local bases = vstruct.read(">@" .. header.oBases .. " " .. header.nBases .. "*{gid:u2 firstLayer:u2 nLayers:u2}", fd)
  local layers = vstruct.read(">@" .. header.oLayers .. " " .. header.nLayers .. "*{gid:u2 paletteIndex:u2}", fd);

  for i = 1, #bases do
    local base = bases[i]
    colr[base.gid] = {}
    for j = base.firstLayer + 1, base.firstLayer + base.nLayers do
      table.insert(colr[base.gid], layers[j])
    end
  end

  return colr
end

local function parse_cpal(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)

  local version = vstruct.readvals(">u2", fd)
  if version > 1 then return end

  local cpal = {}

  local header = vstruct.read(">nPalettesEntries:u2 nPalettes:u2 nColors:u2 oFirstColor:u4", fd)
  local colorIndices = vstruct.read("> " .. header.nPalettes .. "*u2", fd)
  local colors = vstruct.read(">@" .. header.oFirstColor .. " " .. header.nColors .. "*{b:u1 g:u1 r:u1 a:u1}", fd)

  for i = 1, header.nPalettes do
    local first = colorIndices[i] + 1
    local palette = {}
    for j = 1, header.nPalettesEntries do
      local color = colors[j]
      for k, v in pairs(color) do
        color[k] = v / 255
      end
      table.insert(palette, color)
    end
    table.insert(cpal, palette)
  end

  return cpal
end

SILE.shapers.harfbuzzWithColor = SILE.shapers.harfbuzz {
  shapeToken = function (self, text, options)
    if not options.font then return {} end
    local face = SILE.font.cache(options, SILE.shaper.getFace)
    -- XXX: cache this
    local colr = parse_colr(hb.get_table(face.data, face.index, "COLR"))
    local cpal = parse_cpal(hb.get_table(face.data, face.index, "CPAL"))

    local items = SILE.shapers.harfbuzz:shapeToken(text, options)
    if colr and cpal then
      local newItems = {}
      for i = 1, #items do
        local layers = colr[items[i].gid]
        if layers then
          for j = 1, #layers do
            local item = items[i]
            local layer = layers[j]
            local width = 0
            local text = ""
            if j == #layers then
              width = item.width
              text = item.text
            end
            -- XXX: handle multiple palette, add a font option?
            local color = cpal[1][layer.paletteIndex + 1]
            local newItem = {
              -- XXX: what is the name used for?
           -- name = "",
              gid = layer.gid,
              glyphAdvance = item.glyphAdvance,
              width = width,
              height= item.height,
              depth = item.depth,
              index = item.index,
              text = text,
              color = color,
            }
            newItems[#newItems+1] = newItem
          end
        else
          newItems[#newItems+1] = items[i]
        end
      end
      return newItems
    end
    return items
  end,
  createNnodes = function (self, token, options)
    local items, width = self:shapeToken(token, options)
    if #items < 1 then return {} end

    local lang = options.language
    SILE.languageSupport.loadLanguage(lang)
    local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
    local run = { [1] = {slice = {}, color = items[1].color, chunk = "" } }
    for i = 1,#items do
      if items[i].color ~= run[#run].color then
        run[#run+1] = { slice = {}, chunk = "", color = items[i].color }
        if i <#items then
          run[#run].color = items[i].color
        end
      end
      run[#run].chunk = run[#run].chunk .. items[i].text
      run[#run].slice[#(run[#run].slice)+1] = items[i]
    end
    local nodes = {}
    for i=1,#run do
      options = std.tree.clone(options)
      if run[i].color then
        nodes[#nodes+1] = SILE.nodefactory.newHbox({
          outputYourself= function () SILE.outputter:pushColor(run[i].color) end
        })
      end
      for node in (nodeMaker { options=options }):iterator(run[i].slice, run[i].chunk) do
        nodes[#nodes+1] = node
      end
      if run[i].color then
        nodes[#nodes+1] = SILE.nodefactory.newHbox({
          outputYourself= function () SILE.outputter:popColor() end
        })
      end
    end
    return nodes
  end,
}

SILE.shaper = SILE.shapers.harfbuzzWithColor
