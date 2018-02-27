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

local lastjoinable = function (t)
  local t = SU.splitUtf8(t)
  local last = t[#t]
  local jointype = characters.data[SU.codepoint(last)] and characters.data[SU.codepoint(last)].arabic
  local joinable = jointype == "d" or jointype == "l"
  return joinable
end

local reorderHyphenations = function(t, debug)
  local new = t
  -- new[1] = t[1]
  -- for i = 2,#t do
  --   local prev = t[i-1]
  --   local this = t[i]
  --   local firstOfThis = ""
  --   if #prev > 1 then
  --     local uprev = SU.splitUtf8(prev)
  --     lastOfPrev = uprev[#uprev]
  --     new[#new] = dropLast(new[#new])
  --   else
  --     lastOfPrev = ""
  --   end
  --   if #this > 1 then
  --     firstOfThis = SU.splitUtf8(this)[1]
  --     this = dropFirst(this)
  --   end
  --   new[#new+1] = lastOfPrev..firstOfThis
  --   new[#new+1] = this
  -- end

  -- -- Drop empties.
  -- local new2 = {}
  -- for i =1,#new do if #new[i] > 0 then new2[#new2+1] = new[i] end end
  -- new = new2

  -- if debug then return new end

  for i = 1,#new do
    new[i] = latinToArabic(new[i], i==1)
    local first = SU.splitUtf8(new[i])[1]
    local thisjointype = characters.data[SU.codepoint(first)] and characters.data[SU.codepoint(first)].arabic
    local thisjoinable = thisjointype == "d" or thisjointype == "r"

    if i > 1 then
      local beforetext = new[i-1]
      local bt = SU.splitUtf8(beforetext)
      local prevjointype = characters.data[SU.codepoint(bt[#bt])] and characters.data[SU.codepoint(bt[#bt])].arabic
      local prevjoinable = prevjointype == "d" or prevjointype == "l"
      if prevjoinable and thisjoinable then
          new[i-1] = new[i-1] .. zwj
          new[i] = zwj..new[i]
      end
    end
  end
  return new
end

function debugUyghur(word)
  SILE.languageSupport.loadLanguage("tr")
  print(showHyphenationPoints(word,"tr"))
  local items = _hyphenate(_hyphenators["tr"],word)
  print(reorderHyphenations(items,true))
end

SILE.hyphenator.languages.ug = function(n)
  local latin = arabicToLatin(n.text)
  if SU.debugging("uyghur") then io.write("Original: ", n.text.." -> "..latin.." -> ") end
  local state = n.options
  -- Make "Turkish" nodes
  newoptions = std.tree.clone(n.options)
  newoptions.origlanguage = n.options.language
  newoptions.language = "tr"
  if not _hyphenators.tr then
    SILE.hyphenate(SILE.shaper:createNnodes(latin, newoptions))
  end
  local items = _hyphenate(_hyphenators["tr"],latin)
  if #items == 1 then
    if SU.debugging("uyghur") then print(latin .." No hyphenation points") end
    return {n}
  end
  if SU.debugging("uyghur") then
    for i = 1,#items do
      io.write(items[i].."/")
    end
    io.write(" -> ")
  end
  items = reorderHyphenations(items)
  newitems = {}
  state.language = "ug"
  for i = 1,#items do
    if SU.debugging("uyghur") then io.write(items[i].."/") end
    local normal = SILE.shaper:createNnodes(items[i], state)
    local prebreak = SILE.shaper:createNnodes(items[i]..(lastjoinable(items[i]) and zwj or "").."-", state)
    local d = SILE.nodefactory.newDiscretionary({
            replacement = normal,
            prebreak = prebreak
          })
      newitems[#newitems+1] = d
      newitems[#newitems+1] = SILE.nodefactory.zeroHbox
  end
  if SU.debugging("uyghur") then print("") end
  return newitems
end

local canmerge = function(x,y)
  if not y:isDiscretionary() and not y:isNnode() then return false end
  if not x:isDiscretionary() and not x:isNnode() then return false end
  if x:isDiscretionary() then content = x.replacement[1] else content = x end
  -- if x.replacement[1].language ~= "ug" or y.replacement[1].language ~= "ug" then return false end
  return true
end

local mergenodes = function (x,y, used)
  -- Extract content
  local xcontent, ycontent
  text = ""
  if x:isDiscretionary() then
    if used then xcontent = x.prebreak else xcontent = x.replacement end
    for i = 1,#(xcontent) do text = text .. xcontent[i].text end
  else
    xcontent = {x}
    text = x.text
  end

  if y:isDiscretionary() then
    ycontent = y.replacement
    for i = 1,#ycontent do text = ycontent[i].text .. text end
  else
    ycontent = {y}
    text = y.text .. text
  end
  -- Remove erroneous ZWJs
  local t2 = ""
  local t = SU.splitUtf8(text)
  text = ""
  for i = 1,#t do
    if t[i] == zwj and t[i+1] ~= "-" then
      --
    else
      text = text .. t[i]
    end
  end
  return SILE.shaper:createNnodes(text, xcontent[1].options)
end

local mergeline = function(nodes)
  local newnodes = { }
  for i = 1,#nodes do
    -- Drop all zerohboxes
    local pos = #newnodes -1
    if nodes[i] == SILE.nodefactory.zeroHbox then -- nothing
    elseif #newnodes >1 and canmerge(nodes[i], newnodes[#newnodes]) then
      local merged = mergenodes(nodes[i], newnodes[#newnodes],i == #nodes)
      for j=1,#merged do
        newnodes[pos+j] = merged[j]
      end
    elseif #newnodes == 0 and nodes[i]:isDiscretionary() and i == 1 then
      local merged = mergenodes(nodes[i], SILE.shaper:createNnodes("x",nodes[i].replacement[1].options)[1])
      for j=1,#merged do
        newnodes[pos+j] = merged[j]
      end
    else
      newnodes[#newnodes+1] = nodes[i]
    end

  end
  return newnodes
end

local oldbreaker = SILE.typesetter.breakIntoLines
SILE.typesetter.breakIntoLines = function(self, nl, breakWidth)
  self:shapeAllNodes(nl)
  local breaks = SILE.linebreak:doBreak( nl, breakWidth)
  local lines = self:breakpointsToLines(breaks)
  for i = 1,#lines do
    lines[i].nodes = mergeline(lines[i].nodes)
    lines[i].ratio = self:computeLineRatio(breaks[i].width, lines[i].nodes)
  end
  return lines
end