local punct = function(c) return c >= 0x3000 and c <= 0x303f end
local hiragana = function(c) return c >= 0x3040 and c <= 0x309f end
local katakana = function(c) return c >= 0x30a0 and c <= 0x30ff end
local kana = function(c) return hiragana(c) or katakana(c) end
local kanji = function(c) return c >= 0x4e00 and c <= 0x9fcc end
local japanese = function(c) return punct(c) or kana(c) or kanji(c) end

SILE.settings.declare({
  name = "language.ja.intrakanjiskip",
  type = "Glue or nil",
  default = SILE.nodefactory.newGlue("0 plus .4pt minus .4pt"),
  help = "Glue added between two kanji"
})

SILE.settings.declare({
  name = "language.ja.doublepunctskip",
  type = "Glue or nil",
  default = SILE.nodefactory.newGlue("-0.5em"),
  help = "Glue added between two Japanese punctuation"
})

-- Kinsoku shori taimu!
local uchar
local cannotStart = {}
local cannotEnd = {}
for uchar in string.gmatch(
  ")]｝〕〉》」』】〙〗〟’”｠»ヽヾーァィゥェォッャュョヮヵヶぁぃぅぇぉっゃゅょゎゕゖㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ々〻‐゠–〜 ?!‼⁇⁈⁉・、:;,。.",
  "([%z\1-\127\194-\244][\128-\191]*)") do
  cannotStart[SU.codepoint(uchar)] = 1
end
for uchar in string.gmatch(
  "([｛〔〈《「『【〘〖〝‘“｟«",
  "([%z\1-\127\194-\244][\128-\191]*)") do
  cannotEnd[SU.codepoint(uchar)] = 1
end

local intracodepointglue = function(l,r)
  if l <= 0x3000 and r <= 0x3000 then return nil end
  if kanji(l) and kanji(r) then return SILE.settings.get("language.ja.intrakanjiskip") end
  if punct(l) and punct(r) then return SILE.settings.get("language.ja.doublepunctskip") end
  -- Is this an adequate kinsoku shori? We may need to split out an intracodepointpenalty as well
  if cannotEnd[l] or cannotStart[r] then return nil end
  if japanese(l) and japanese(r) then return SILE.settings.get("language.ja.intrakanjiskip") end
end

SILE.tokenizers.ja = function(string)
  return coroutine.wrap(function()
    local lastcp = -1
    local space = SILE.settings.get("shaper.spacepattern")
    for uchar in string.gmatch(string, "([%z\1-\127\194-\244][\128-\191]*)") do
      if string.match(uchar, space) then
        coroutine.yield({separator = uchar})
      else
        local g = intracodepointglue(lastcp, SU.codepoint(uchar))
        if g then coroutine.yield({ node = g }) end
        coroutine.yield({ string = uchar })
      end
      lastcp = SU.codepoint(uchar)
    end
  end)
end
