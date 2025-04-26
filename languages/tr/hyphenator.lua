local base = require("languages.base-hyphenator")

local hyphenator = pl.class(base)
hyphenator._name = "tr"

function hyphenator:hyphenateSegments (node, segments, j)
   local hyphenChar, replacement
   local maybeNextApostrophe = #segments > j and luautf8.match(segments[j + 1], "^['’]")
   if maybeNextApostrophe then
      segments[j + 1] = luautf8.gsub(segments[j + 1], "^['’]", "")
      if self.settings:get("languages.tr.replaceApostropheAtHyphenation") then
         hyphenChar = self.settings:get("font.hyphenchar")
      else
         hyphenChar = maybeNextApostrophe
         replacement = SILE.shaper:createNnodes(maybeNextApostrophe, node.options)
      end
   else
      hyphenChar = self.settings:get("font.hyphenchar")
   end
   local hyphen = SILE.shaper:createNnodes(hyphenChar, node.options)
   return SILE.types.node.discretionary({ replacement = replacement, prebreak = hyphen }), segments
end

return hyphenator
