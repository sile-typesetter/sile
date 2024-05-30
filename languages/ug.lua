-- Thanks to Tom Milo of Decotype for challenging me to implement
-- Uyghur support, providing the methodology and basic algorithms,
-- and preventing me from leaving the Granshan 2015 conference until
-- I had most of this working.

-- Uyghur is Turkish, right?
SILE.languageSupport.loadLanguage("tr")

local chardata = require("char-def")

SILE.settings:declare({
   parameter = "languages.ug.hyphenoffset",
   help = "Space added between text and hyphen",
   type = "glue or nil",
   default = SILE.nodefactory.glue("1pt"),
})

local transliteration = {
   -- I'm going to pretend that normalisation isn't a problem
   { al = "ئا", la = "a", lapa = "^a" },
   { al = "ا", la = "a" },
   { al = "ب", la = "b" },
   { al = "پ", la = "p" },
   { al = "ت", la = "t" },
   { al = "ج", la = "c" },
   { al = "چ", la = "ç" },
   { al = "د", la = "d" },
   { al = "ر", la = "r" },
   { al = "ژ", la = "j" },
   { al = "ز", la = "z" },
   { al = "ش", la = "ş" },
   { al = "س", la = "s" },
   { al = "غ", la = "ğ" },
   { al = "ف", la = "f" },
   { al = "ق", la = "q" },
   { al = "ك", la = "k" },
   { al = "گ", la = "g" },
   { al = "ڭ", la = "ġ" },
   { al = "ل", la = "l" },
   { al = "م", la = "m" },
   { al = "ن", la = "n" },
   { al = "ھ", la = "h" },
   { al = "ۋ", la = "w" },
   { al = "ئې", la = "e", lapa = "^e" },
   { al = "ې", la = "e" },
   { al = "ئە", la = "ä", lapa = "^ä" },
   { al = "ە", la = "ä" },
   { al = "ئى", la = "i", lapa = "^i" },
   { al = "ى", la = "i" },
   { al = "ي", la = "y" },
   { al = "ئو", la = "o", lapa = "^o" },
   { al = "و", la = "o" },
   { al = "ئۇ", la = "u", lapa = "^u" },
   { al = "ۇ", la = "u" },
   { al = "ئۆ", la = "ö", lapa = "^ö" },
   { al = "ۆ", la = "ö" },
   { al = "ئۈ", la = "ü", lapa = "^ü" },
   { al = "ۈ", la = "ü" },
   { al = "خ", la = "x" },
}

local arabicToLatin = function (s)
   for i = 1, #transliteration do
      s = s:gsub(transliteration[i].al, transliteration[i].la)
   end
   return s
end

local latinToArabic = function (s, useLapa)
   for i = 1, #transliteration do
      if useLapa then
         s = s:lower():gsub(transliteration[i].lapa or transliteration[i].la, transliteration[i].al)
      elseif not transliteration[i].lapa then
         s = s:lower():gsub(transliteration[i].la, transliteration[i].al)
      end
   end
   return s
end

local zwj = SU.utf8charfromcodepoint("U+200D")
-- local zwnj = SU.utf8charfromcodepoint("U+200C")

-- local dropLast = function(t)
--   local bt = SU.splitUtf8(t)
--   local n = ""
--   for i = 1,#bt-1 do n = n..bt[i] end
--   return n
-- end

-- local dropFirst = function(t)
--   local bt = SU.splitUtf8(t)
--   local n = ""
--   for i = 2,#bt do n = n..bt[i] end
--   return n
-- end

local lastjoinable = function (t)
   t = SU.splitUtf8(t)
   local last = t[#t]
   local jointype = chardata[SU.codepoint(last)] and chardata[SU.codepoint(last)].arabic
   local joinable = jointype == "d" or jointype == "l"
   return joinable
end

-- local firstjoinable = function (t)
--   local t = SU.splitUtf8(t)
--   local first = t[1]
--   local jointype = chardata[SU.codepoint(first)] and chardata[SU.codepoint(first)].arabic
--   local joinable = jointype == "d" or jointype=="r"
--   return joinable
-- end

-- function debugUyghur(word)
--   SILE.languageSupport.loadLanguage("ug")
--   print(SILE.showHyphenationPoints(word,"ug"))
--   local items = SILE._hyphenate(SILE.hyphenators["ug"],word)
--   print(reorderHyphenations(items,true))
-- end

SILE.hyphenator.languages.ug = function (n)
   local latin = arabicToLatin(n.text)
   SU.debug("uyghur", "Original:", n.text, "->", latin, "->")
   local state = n.options
   -- Make "Turkish" nodes
   local newoptions = pl.tablex.deepcopy(n.options)
   newoptions.language = "lt"
   if not SILE.hyphenators.lt then
      SILE.hyphenate(SILE.shaper:createNnodes(latin, newoptions))
   end
   local items = SILE._hyphenate(SILE.hyphenators["lt"], latin)
   if #items == 1 then
      SU.debug("uyghur", latin, "No hyphenation points")
      return { n }
   end
   -- Choose 1. Aim to split in middle.
   SU.debug("uyghur", function ()
      return SU.concat(items, "/") .. " -> "
   end)
   local splitpoint = math.ceil(#items / 2)
   local nitems = { "", "" }
   for i = 1, #items do
      if i <= splitpoint then
         nitems[1] = nitems[1] .. items[i]
      else
         nitems[2] = nitems[2] .. items[i]
      end
   end
   items = nitems
   SU.debug("uyghur", items[1], "/", items[2])
   state.language = "ug"
   items[1] = latinToArabic(items[1])
   items[2] = latinToArabic(items[2])
   local hyphen = SILE.settings:get("font.hyphenchar")
   local prebreak = SILE.shaper:createNnodes(items[1] .. (lastjoinable(items[1]) and zwj or ""), state)
   if SILE.settings:get("languages.ug.hyphenoffset") then
      local w = SILE.settings:get("languages.ug.hyphenoffset").width
      prebreak[#prebreak + 1] = SILE.nodefactory.kern({ width = w })
   end
   local hnodes = SILE.shaper:createNnodes(hyphen, state)
   prebreak[#prebreak + 1] = hnodes[1]
   local postbreak = SILE.shaper:createNnodes((lastjoinable(items[1]) and zwj or "") .. items[2], state)
   local d = SILE.nodefactory.discretionary({
      replacement = { n },
      prebreak = prebreak,
      postbreak = postbreak,
   })
   return { SILE.nodefactory.zerohbox(), d }
end
