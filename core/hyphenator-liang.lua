local function addPattern(h, p)
  local t = h.trie
  bits = SU.splitUtf8(p)
  for i = 1,#bits do char = bits[i]
    if not char:find("%d") then
      if not(t[char]) then t[char] = {} end
      t = t[char]
    end
  end
  t["_"] = {}
  local lastWasDigit = 0
  for i = 1,#bits do char = bits[i]
    if char:find("%d") then
      lastWasDigit = 1
      table.insert(t["_"], tonumber(char))
    elseif lastWasDigit == 1 then
      lastWasDigit = 0
    else
      table.insert(t["_"], 0)
    end
  end
end

local function registerException(h, exc)
  local a = SU.splitUtf8(exc)
  local k = exc:gsub("-", "")
  h.exceptions[k] = { }
  j = 1
  for i=1,#a do
    j = j + 1
    if a[i] == "-" then
      j = j - 1
      h.exceptions[k][j] = 1
    else
      h.exceptions[k][j] = 0
    end
  end
end

function loadPatterns(h, language)
  SILE.languageSupport.loadLanguage(language)

  local languageset = SILE.hyphenator.languages[language]
  if not (languageset) then
    print("No patterns for language "..language)
    return
  end
  for _,pat in pairs(languageset.patterns) do addPattern(h, pat) end
  if not languageset.exceptions then languageset.exceptions = {} end
  for _,exc in pairs(languageset.exceptions) do
    registerException(h, exc)
  end
end

function _hyphenate(self, w)
  if string.len(w) < self.minWord then return {w} end
  local points = self.exceptions[w:lower()]
  local word = SU.splitUtf8(w)
  if not points then
    points = SU.map(function()return 0 end, word)
    local work = SU.map(string.lower, word)
    table.insert(work, ".")
    table.insert(work, 1, ".")
    table.insert(points, 1, 0)
    for i = 1, #work do
      local t = self.trie
      for j = i, #work do
        if not t[work[j]] then break end
        t = t[work[j]]
        local p = t["_"]
        if p then
          for k = 1, #p do
            if points[i+k - 2] and points[i+k -2] < p[k] then
              points[i+k -2] = p[k]
            end
          end
        end
      end
    end
    -- Still inside the no-exceptions case
    for i = 1,self.leftmin do points[i] = 0 end
    for i = #points-self.rightmin,#points do points[i] = 0 end
  end
  local pieces = {""}
  for i = 1,#word do
    pieces[#pieces] = pieces[#pieces] .. word[i]
    if points[1+i] and 1 == (points[1+i] % 2) then table.insert(pieces, "") end
  end
  return pieces
end

SILE.hyphenator = {}
SILE.hyphenator.languages = {}
_hyphenators = {}

local initHyphenator = function (lang)
  if not _hyphenators[lang] then
    _hyphenators[lang] = {minWord = 5, leftmin = 2, rightmin = 2, trie = {}, exceptions = {} }
    loadPatterns(_hyphenators[lang], lang)
  end
end

local hyphenateNode = function(n)
  if not n:isNnode() or not n.text then return {n} end
  if n.language and (type(SILE.hyphenator.languages[n.language]) == "function") then
    return SILE.hyphenator.languages[n.language](n)
  end
  initHyphenator(n.language)
  local breaks = _hyphenate(_hyphenators[n.language],n.text)
  if #breaks > 1 then
    local newnodes = {}
    for j, b in ipairs(breaks) do
      if not(b=="") then
        for _,nn in pairs(SILE.shaper:createNnodes(b, n.options)) do
          if nn:isNnode() then
            nn.parent = n
            table.insert(newnodes, nn)
          end
        end
        if not (j == #breaks) then
          d = SILE.nodefactory.newDiscretionary({ prebreak = SILE.shaper:createNnodes(SILE.settings.get("font.hyphenchar"), n.options) })
          d.parent = n
          table.insert(newnodes, d)
         --table.insert(newnodes, SILE.nodefactory.newPenalty({ value = SILE.settings.get("typesetter.hyphenpenalty") }))
        end
      end
    end
    n.children = newnodes
    n.hyphenated = false
    n.done = false
    return newnodes
  end
  return {n}
end

showHyphenationPoints = function (word, language)
  language = language or "en"
  initHyphenator(language)
  return SU.concat(_hyphenate(_hyphenators[language], word), SILE.settings.get("font.hyphenchar"))
end

SILE.hyphenate = function (nodelist)
  local newlist = {}
  for i = 1,#nodelist do
    local n = nodelist[i]
    local newnodes = hyphenateNode(n)
    for j=1,#newnodes do newlist[#newlist+1] = newnodes[j] end
  end
  return newlist
end

SILE.registerCommand("hyphenator:add-exceptions", function (o,c)
  local language = o.lang or SILE.settings.get("document.language")
  SILE.languageSupport.loadLanguage(language)
  initHyphenator(language)
  for token in SU.gtoke(c[1]) do
    if token.string then
      registerException(_hyphenators[language],token.string)
    end
  end
end)
