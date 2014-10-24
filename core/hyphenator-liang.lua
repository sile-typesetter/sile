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
  if not(language) or language == "" then language = "en" end
  local hyph
  pcall(function () hyph =  SILE.require("languages/"..language.."-compiled") end)
  if hyph then
    _hyphenators[language] = hyph
    return
  end

  if not pcall(function () SILE.require("languages/"..language) end) then
    return
  end

  local languageset = SILE.hyphenator.languages[language];
  if not (languageset) then 
    print("No patterns for language "..language)
    return
  end
  for _,pat in pairs(languageset.patterns) do addPattern(h, pat) end
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

SILE.hyphenate = function (nodelist)
  --local itList = std.tree.clone(nodelist)
  for i,n in ipairs(nodelist) do
    if (n:isNnode() and n.text) then
      if not _hyphenators[n.language] then
        _hyphenators[n.language] = {minWord = 5, leftmin = 2, rightmin = 2, trie = {}, exceptions = {} };
        loadPatterns(_hyphenators[n.language], n.language)
      end
      local breaks = _hyphenate(_hyphenators[n.language],n.text);
      if #breaks > 1 then
        local newnodes = {}
        for j, b in ipairs(breaks) do
          if not(b=="") then
            for _,nn in pairs(SILE.shaper.shape(b, n.options)) do 
              table.insert(newnodes, nn) 
            end
            if not (j == #breaks) then
             table.insert(newnodes, SILE.nodefactory.newDiscretionary({ prebreak = SILE.shaper.shape("-", { pal = n.pal, options = n.options } ) }))
             --table.insert(newnodes, SILE.nodefactory.newPenalty({ value = SILE.settings.get("typesetter.hyphenpenalty") }))
            end
          end
        end
        SU.splice(nodelist, i, i, newnodes);
        i = i + #newnodes - 1
      end
    end
  end
  return nodelist
end
