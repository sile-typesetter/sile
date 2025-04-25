local base = require("languages.base-hyphenator")

local hyphenator = pl.class(base)
hyphenator._name = "ca"

function hyphenator:hyphenateSegments (node, segments, j)
   -- punt volat (middle dot) cancels when hyphenated
   -- Catalan typists may use a punt volat or precomposed characters.
   -- The shaper might behave differently depending on the font, so we need to
   -- be consistent here with the typist's choice.
   local hyphenChar = SILE.settings:get("font.hyphenchar")
   local replacement, hyphen
   if luautf8.find(segments[j], "ŀ$") then -- U+0140
      segments[j] = luautf8.sub(segments[j], 1, -2)
      replacement = SILE.shaper:createNnodes("ŀ", node.options)
      hyphen = SILE.shaper:createNnodes("l" .. hyphenChar, node.options)
   elseif luautf8.find(segments[j], "Ŀ$") then -- U+013F
      segments[j] = luautf8.sub(segments[j], 1, -2)
      replacement = SILE.shaper:createNnodes("Ŀ", node.options)
      hyphen = SILE.shaper:createNnodes("L" .. hyphenChar, node.options)
   elseif luautf8.find(segments[j], "l·$") then -- l + U+00B7
      segments[j] = luautf8.sub(segments[j], 1, -3)
      replacement = SILE.shaper:createNnodes("l·", node.options)
      hyphen = SILE.shaper:createNnodes("l" .. hyphenChar, node.options)
   elseif luautf8.find(segments[j], "L·$") then -- L + U+00B7
      segments[j] = luautf8.sub(segments[j], 1, -3)
      replacement = SILE.shaper:createNnodes("L·", node.options)
      hyphen = SILE.shaper:createNnodes("L" .. hyphenChar, node.options)
   else
      hyphen = SILE.shaper:createNnodes(hyphenChar, node.options)
   end
   local discretionary = SILE.types.node.discretionary({ replacement = replacement, prebreak = hyphen })
   return discretionary, segments
end

return hyphenator
