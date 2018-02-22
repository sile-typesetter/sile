-- Thanks to Tom Milo of Decotype for challenging me to implement
-- Uyghur support, providing the methodology and basic algorithms,
-- and preventing me from leaving the Granshan 2015 conference until
-- I had most of this working.

-- Uyghur is Turkish, right?
SILE.languageSupport.loadLanguage("tr")
SILE.hyphenator.languages["ug"] = {}
SILE.hyphenator.languages["ug"].patterns = SILE.hyphenator.languages["tr"].patterns

require("char-def")
local chardata  = characters.data

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
latinToArabic = function(s, useLapa)
  for i = 1,#transliteration do
    if useLapa then
      s = s:lower():gsub(transliteration[i].lapa or transliteration[i].la, transliteration[i].al)
    elseif not transliteration[i].lapa then
      s = s:lower():gsub(transliteration[i].la, transliteration[i].al)
    end
  end
  return s
end

local zwj = "‍"

local dropLast = function(t)
  local bt = SU.splitUtf8(t)
  local n = ""
  for i = 1,#bt-1 do n = n..bt[i] end
  return n
end

local dropFirst = function(t)
  local bt = SU.splitUtf8(t)
  local n = ""
  for i = 2,#bt do n = n..bt[i] end
  return n
end

local reorderHyphenations = function(t)
  local new = {}
  new[1] = t[1]
  for i = 2,#t do
    local prev = t[i-1]
    local this = t[i]
    if #prev > 1 then
      local uprev = SU.splitUtf8(prev)
      lastOfPrev = uprev[#uprev]
      new[#new] = dropLast(new[#new])
    else
      lastOfPrev = ""
    end
    if #this > 1 then
      firstOfThis = SU.splitUtf8(this)[1]
      this = dropFirst(this)
    end
    new[#new+1] = lastOfPrev..firstOfThis
    new[#new+1] = this
  end

  for i = 1,#new do
    new[i] = latinToArabic(new[i], i==1)
    if i > 1 then
      local beforetext = new[i-1]
      local bt = SU.splitUtf8(beforetext)
      local jointype = characters.data[SU.codepoint(bt[#bt])] and characters.data[SU.codepoint(bt[#bt])].arabic
      local joinable = jointype == "d"

      new[i-1] = new[i-1] .. zwj
      if joinable then
        new[i] = zwj..new[i]
      end
    end
  end
  return new
end

SILE.hyphenator.languages.ug = function(n)
  local latin = arabicToLatin(n.text)
  local state = n.options
  -- Make "Turkish" nodes
  newoptions = std.tree.clone(n.options)
  newoptions.origlanguage = n.options.language
  newoptions.language = "tr"
  if not _hyphenators.tr then
    SILE.hyphenate(SILE.shaper:createNnodes(latin, newoptions))
  end
  local items = _hyphenate(_hyphenators["tr"],latin)
  if #items == 1 then return {n} end
  items = reorderHyphenations(items)
  newitems = {}
  state.language = "ar"
  for i = 1,#items do
    local normal = SILE.shaper:createNnodes(items[i], state)
    local prebreak = SILE.shaper:createNnodes(items[i].."-", state)
    local postbreak = SILE.shaper:createNnodes((joinable and zwj or "")..aftertext, state)
    local d = SILE.nodefactory.newDiscretionary({
            replacement = normal,
            prebreak = prebreak,
            -- postbreak = postbreak
          })
      newitems[#newitems+1] = SILE.nodefactory.zeroHbox
      newitems[#newitems+1] = d
  end
  return newitems
end