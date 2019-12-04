local oldMakeSpaceNode = SILE.shaper.makeSpaceNode
local ot = SILE.require("core/opentype-parser")

local getSuggestions = function (options)
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  if not font.jstf then return nil end
  local scriptRecord = font.jstf[options.script] or font.jstf["DFLT"]
  if not scriptRecord then return nil end
  local suggestions = scriptRecord.languages[options.language] or scriptRecord.defaultJstfLangSysTable
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
  if not suggestions then return oldMakeSpaceNode(self,options,item) end
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
    options.spaceWidth =  SILE.length.new({
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
    return (SILE.nodefactory.newGlue({ width = spaceWidth }))
  else
    return oldMakeSpaceNode(self,options,item)
  end
end
