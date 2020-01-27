local oldMakeSpaceNode = SILE.shaper.makeSpaceNode
local ot = SILE.require("core/opentype-parser")
local metrics = require("fontmetrics")

local fontSuggestionsCache = {}

local _key = function (options)
  return table.concat({ options.family;("%g"):format(options.size);("%d"):format(options.weight);options.style;options.variant;options.features;options.direction;options.filename }, ";")
end

local getSuggestions = function (options)
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  key = _key(options)
  if fontSuggestionsCache[key] then return fontSuggestionsCache[key] end
  local font = ot.parseFont(face)
  if not font.jstf then return nil end
  local scriptRecord = font.jstf[options.script] or font.jstf["DFLT"]
  if not scriptRecord then return nil end
  local suggestions = scriptRecord.languages[options.language] or scriptRecord.defaultJstfLangSysTable
  fontSuggestionsCache[key] = suggestions
  return suggestions
end

local getUpem = function (options)
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  return font.head.unitsPerEm
end

local findValue = function(lookups, gid)
  for j = 1,#lookups do
    local lookup = lookups[j]
    for k = 1,#lookup.subtables do
      local subtable = lookup.subtables[k]
      if subtable.coverage[gid] then
        return subtable.valueRecord.xAdvance
      end
    end
  end
  return nil
end

local getSpaceWidth = function(options)
  if options.spaceWidth then return options.spaceWidth end
  local suggestions = getSuggestions(options)
  local upem = getUpem(options)
  if not suggestions then
    spaceNode = oldMakeSpaceNode(self,options,item)
    SU.debug("opentype-justification", "No  "..options.spaceWidth)

  end
  local items, width = SILE.shaper:shapeToken(" ", options)
  local gid = items[1].gid
  local widthU = math.floor(items[1].width * upem / options.size)
  SU.debug("opentype-justification", "Space glyph is in font is "..widthU.." units")
  local maxStretch = nil
  local maxShrink = nil
  for i = 1,#suggestions do
      local suggestion = suggestions[i]
      if suggestion.extensionJstfMax  then
        local stretch = findValue(suggestion.extensionJstfMax, gid)
        if stretch then
          SU.debug("opentype-justification", "extensionJstfMax for space is "..stretch.." units")
          maxStretch = stretch / upem * options.size
        end
      end
      if suggestion.shrinkageJstfMax  then
        local shrink = findValue(suggestion.shrinkageJstfMax, gid)
        if shrink then
          SU.debug("opentype-justification", "shrinkageJstfMax for space is "..shrink.." units")
          maxShrink = shrink / upem * options.size
        end
      end
  end
  if maxStretch or maxShrink then
    options.spaceWidth =  SILE.length({
      length = items[1].width,
      shrink = items[1].width - maxShrink,
      stretch = maxStretch - items[1].width
    })
    SU.debug("opentype-justification", "Setting space width to "..options.spaceWidth)
    return options.spaceWidth
  end
  return nil
end

SILE.shaper.makeSpaceNode = function (self, options, item)
  local spaceWidth = getSpaceWidth(options)
  if spaceWidth then
    return (SILE.nodefactory.glue(spaceWidth))
  else
    return oldMakeSpaceNode(self,options,item)
  end
end

local nnodeMaker = SILE.shaper.createNnodes

local function mapUsedGIDs(node)
  usedGids = {}
  for _, subnode in ipairs(node.nodes) do
    for _, gid in ipairs(subnode.value.glyphString) do
      usedGids[gid] = true
    end
  end
  return usedGids
end

local function lookupsApply(node, lookups, options)
  if not node:isNnode() then return {} end
  local gidsUsed = mapUsedGIDs(node)
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  local lookupsWhichApply = {}
  for _, lid in ipairs(lookups) do
    local lookup = font.gsub[lid]
    for src,dst in pairs(lookup) do
      if gidsUsed[src] then
        SU.debug("opentype-justification", "Node contains ",src," which is in lookup ",lid)
        lookupsWhichApply[#lookupsWhichApply+1] = lookup
      end
    end
  end
  return lookupsWhichApply
end

local applyLookups = function (lookups, node, face, options)
  node2 = std.tree.clone(node)
  widthDiff = SILE.length.new({})
  for _, subnode in ipairs(node2.nodes) do
    if subnode.value.items then
      subnode.value.items = SU.map(function (item)
        local oldWidth = item.width
        for _,l in ipairs(lookups) do
          if l[item.gid] then item.gid = l[item.gid] end
        end
        item.width = metrics.glyphwidth(item.gid, face.data, face.index)  * options.size
        local thisWidthDiff = (item.width - oldWidth)
        item.glyphAdvance = item.glyphAdvance + thisWidthDiff
        widthDiff = widthDiff + thisWidthDiff
        subnode.width = subnode.width + thisWidthDiff
        return item
      end, subnode.value.items)
    else
      subnode.value.glyphString = SU.map(function (ingid)
        local oldWidth = metrics.glyphwidth(ingid, face.data, face.index)  * options.size
        for _,l in ipairs(lookups) do
          if l[ingid] then
            local newWidth = metrics.glyphwidth(l[ingid], face.data, face.index)  * options.size
            widthDiff = widthDiff + (newWidth - oldWidth)
            subnode.width = subnode.width + (newWidth - oldWidth)
            return l[ingid]
          end
        end
        return ingid
      end, subnode.value.glyphString)
    end
  end
  node2.width = node2.width + widthDiff
  node2.penalty = 500
  return SILE.nodefactory.newAlternative({
    options = {node, node2},
    selected = 1
  })
end

SILE.shaper.createNnodes = function (self,text, options)
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local suggestions = getSuggestions(options)
  local nnodes = nnodeMaker(self,text,options)
  if not suggestions then return nnodes end
  for _, suggestion in pairs(suggestions) do
    if #suggestion.extensionEnableGSUB > 0 then
      for i, node in pairs(nnodes) do
        local lookupsWhichApply = lookupsApply(node, suggestion.extensionEnableGSUB, options)
        if #lookupsWhichApply > 0 then
          nnodes[i] = applyLookups(lookupsWhichApply, node, face, options)
        end
      end
    end
  end
  return nnodes
end
