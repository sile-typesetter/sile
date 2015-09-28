-- Thanks to Tom Milo of Decotype for challenging me to implement
-- Uyghur support, providing the methodology and basic algorithms,
-- and preventing me from leaving the Granshan 2015 conference until
-- I had most of this working.

-- Uyghur is Turkish, right?
SILE.languageSupport.loadLanguage("tr")
SILE.hyphenator.languages["ug"] = {}
SILE.hyphenator.languages["ug"].patterns = SILE.hyphenator.languages["tr"].patterns

require("char-def")

local transliteration = {
  -- I'm going to pretend that normalisation isn't a problem
  { al = "ئا", la = "a", lapa = "^a"},
  { al = "ا", la = "a"},
  { al = "ب", la = "b"} ,
  { al = "پ", la = "p"} ,
  { al = "ت", la = "t"} ,
  { al = "ج", la = "c"} ,
  { al = "چ", la = "ç"} ,
  { al = "د", la = "d"} ,
  { al = "ر", la = "r"} ,
  { al = "ژ", la = "j"} ,
  { al = "ز", la = "z"} ,
  { al = "ش", la = "ş"} ,
  { al = "س", la = "s"} ,
  { al = "غ", la = "ğ"} ,
  { al = "ف", la = "f"} ,
  { al = "ق", la = "q"} ,
  { al = "ك", la = "k"} ,
  { al = "گ", la = "g"} ,
  { al = "ڭ", la = "ġ"} ,
  { al = "ل", la = "l"} ,
  { al = "م", la = "m"} ,
  { al = "ن", la = "n"},
  { al = "ھ", la = "h"},
  { al = "ۋ", la = "w"},
  { al = "ئې", la = "e", lapa = "^e"},
  { al = "ې", la = "e"},
  { al = "ئە", la = "ä", lapa = "^ä"},
  { al = "ە", la = "ä"} ,
  { al = "ئى", la = "i", lapa = "^i"},
  { al = "ى", la = "i"},
  { al = "ي", la = "y"},
  { al = "ئو", la = "o", lapa = "^o"},
  { al = "و", la = "o"},
  { al = "ئۇ", la = "u", lapa = "^u"},
  { al = "ۇ", la = "u"},
  { al = "ئۆ", la = "ö", lapa = "^ö"},
  { al = "ۆ", la = "ö"},
  { al = "ئۈ", la = "ü", lapa = "^ü"},
  { al = "ۈ", la = "ü"},
  { al = "خ", la = "x"}
}

arabicToLatin = function(s)
  for i = 1,#transliteration do
    s = s:gsub(transliteration[i].al, transliteration[i].la)
  end
  return s
end
latinToArabic = function(s)
  for i = 1,#transliteration do
    s = s:lower():gsub(transliteration[i].lapa or transliteration[i].la, transliteration[i].al)
  end
  return s
end

local zwj = "‍"

SILE.tokenizers.ug = function(text)
  return coroutine.wrap(function ()
  local state = SILE.font.loadDefaults({})
  for token in SILE.tokenizers.unicode(arabicToLatin(text)) do
    if (token.separator) then
      coroutine.yield(token)
    else
      local nodes = SILE.shaper:subItemize(token.string, state)
      for i= 1,#nodes do
        if nodes[i]:isUnshaped() then
          local s = SILE.hyphenate( nodes[i]:shape() )
          if #s == 1 then
          else
            local last
            for j = #s,1,-1 do
              if s[j]:isDiscretionary() then
                last = j
                break
              end
            end
            local before = {}
            local after = {}
            for j = 1,last-1 do
              before[j] = s[j].text
            end
            for j = last+1,#s do
              after[#after+1] = s[j].text
            end
            local beforetext = latinToArabic(table.concat(before,""))
            local aftertext = latinToArabic(table.concat(after,""))
            local normal = SILE.shaper:createNnodes(beforetext..aftertext, state)
            local bt = SU.splitUtf8(beforetext)
            local jointype = characters.data[SU.codepoint(bt[#bt])] and characters.data[SU.codepoint(bt[#bt])].arabic
            local joinable = jointype == "d"
            local d = SILE.nodefactory.newDiscretionary({
              replacement = normal,
              prebreak = SILE.shaper:createNnodes(beforetext..zwj.."-", state),
              postbreak = SILE.shaper:createNnodes((joinable and zwj or "")..aftertext, state)
            })
              coroutine.yield({ node = SILE.nodefactory.zeroHbox })
              coroutine.yield({ node = d })
          end
        else
          coroutine.yield({ node = nodes[i]})
        end
      end
    end
  end
  end)
end