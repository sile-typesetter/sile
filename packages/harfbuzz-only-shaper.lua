local bidi = require("packages/bidi")
SILE.shapers.harfbuzzOnly = SILE.shapers.harfbuzz {
  itemize = function(self, nodelist, text)
    local options = SILE.font.loadDefaults({})
    local n = { nodes = { SILE.nodefactory.newUnshaped({ text = text, options= options}) }}
    bidi.reorder(n, SILE.typesetter)
    table.append(nodelist, n.nodes)
  end,
  createNnodes = function (self, token, options)
    local items, width = self:shapeToken(token, options)
    if #items < 1 then return {} end
    local nnodeContents, glyphs, totalWidth, depth, height, glyphNames, nnodeValue
    local nnodes = {}
    local function resetNode()
      nnodeValue = { options = options, glyphString = {}, complex = true }
      glyphNames = {}
      glyphs = {}
      totalWidth = 0
      nnodeContents = {}
      depth = 0
      height = 0
    end
    resetNode()

    local thisNnode = function ()
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
      if #nnodeValue.glyphString > 0 then
        local startP = nnodeContents[1].value.items[1].index
        local endP = nnodeContents[#nnodeContents].value.items
        endP = endP[#endP].index
        if endP < startP then startP, endP = endP, startP end
        endP = endP + #(SU.utf8charat(token, endP))
        text = token:sub(startP, endP)
        else text = ""
      end
      return SILE.nodefactory.newNnode({
        nodes = nnodeContents,
        text = text,
        misfit = misfit,
        options = options,
        language = options.language
      })
    end

    local addNode = function(n)
      if not n:isGlue() then
        if not(nnodeValue.items and #nnodeValue.items > 0) then return end
      end
      if options.direction == "RTL" then
        -- Nodes coming out in the opposite order
        table.insert(nnodes,1,n)
      else nnodes[#nnodes+1] = n end
    end

    for i = 1,#items do
      local glyph = items[i]
      if glyph.name == "space" then
        addNode(thisNnode())
        resetNode()
        local ss = SILE.settings.get("document.spaceskip")
        addNode(SILE.nodefactory.newGlue({ width = ss or SILE.length.new({
          length = glyph.width,
          shrink = glyph.width/2,
          stretch = glyph.width/3
        }) }))
      else
        if glyph.depth > depth then depth = glyph.depth end
        if glyph.height > height then height = glyph.height end
        totalWidth = totalWidth + glyph.width
        self:addShapedGlyphToNnodeValue(nnodeValue, glyph)
      end
    end
    addNode(thisNnode())
    return nnodes
  end
}

SILE.shaper = SILE.shapers.harfbuzzOnly
SILE.typesetter.boxUpNodes = SILE.defaultTypesetter.boxUpNodes -- bidi off