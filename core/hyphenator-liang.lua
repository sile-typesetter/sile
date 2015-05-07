local function addPattern(h, p)
  local t = h.trie;
  for char in p:gmatch('%D') do
    if not(t[char]) then t[char] = {} end
    t = t[char]
  end
  t["_"] = {};
  local lastWasDigit = 0
  for char in p:gmatch('.') do
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

function loadPatterns(h, language)
  SILE.languageSupport.loadLanguage(language)

  local languageset = SILE.hyphenator.languages[language];
  if not (languageset) then 
    print("No patterns for language "..language)
    return
  end
  for _,pat in pairs(languageset.patterns) do addPattern(h, pat) end
  if not languageset.exceptions then languageset.exceptions = {} end
  for _,exc in pairs(languageset.exceptions) do
    local k = exc:gsub("-", "")
    h.exceptions[k] = { 0 }
    for i in exc:gmatch(".") do table.insert(h.exceptions[k], i == "-" and 1 or 0) end
  end
end

function _hyphenate(self, w)
  if string.len(w) < self.minWord then return {w} end
  local points = self.exceptions[w:lower()]
  local word = {}
  for i in w:gmatch(".") do table.insert(word, i) end
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
SILE.hyphenator.languages = {};
_hyphenators = {};

local hyphenateNode = function(n)
  if not n:isNnode() or not n.text then return {n} end
  if not _hyphenators[n.language] then
    _hyphenators[n.language] = {minWord = 5, leftmin = 2, rightmin = 2, trie = {}, exceptions = {} };
    loadPatterns(_hyphenators[n.language], n.language)
  end
  local breaks = _hyphenate(_hyphenators[n.language],n.text);
  if #breaks <= 1 then return {n} end  
  local newnodes = {}
  for i = 1,#breaks do b = breaks[i]
    if not(b=="") then
      local nnodes = {}
      SILE.shaper:itemize(nnodes, b, n.options)
      newnodes[#newnodes+1] = nnodes[1]:shape()
      if j ~= #breaks then
        d = SILE.nodefactory.newDiscretionary({ prebreak = SILE.shaper:createNnodes("-", n.options) })
        newnodes[#newnodes+1] = d
      end
    end
  end
  for i =1,#newnodes do newnodes[i].parent = n end
  n.children = newnodes
  n.hyphenated = false
  n.done = false
  return newnodes
end

SILE.hyphenate = function (nodelist)
  for i = 1,#nodelist do local n = nodelist[i]
    local newnodes = hyphenateNode(n)
    SU.splice(nodelist, i, i, newnodes)
    i = i + #newnodes - 1
  end
  return nodelist
end
