local function addPattern(hyphenator, pattern)
  local trie = hyphenator.trie
  local bits = SU.splitUtf8(pattern)
  for i = 1, #bits do
    local char = bits[i]
    if not char:find("%d") then
      if not(trie[char]) then trie[char] = {} end
      trie = trie[char]
    end
  end
  trie["_"] = {}
  local lastWasDigit = 0
  for i = 1, #bits do
    local char = bits[i]
    if char:find("%d") then
      lastWasDigit = 1
      table.insert(trie["_"], tonumber(char))
    elseif lastWasDigit == 1 then
      lastWasDigit = 0
    else
      table.insert(trie["_"], 0)
    end
  end
end

local function registerException(hyphenator, exception)
  local text = exception:gsub("-", "")
  local bits = SU.splitUtf8(exception)
  hyphenator.exceptions[text] = { }
  local j = 1
  for _, bit in ipairs(bits) do
    j = j + 1
    if bit == "-" then
      j = j - 1
      hyphenator.exceptions[text][j] = 1
    else
      hyphenator.exceptions[text][j] = 0
    end
  end
end

local function loadPatterns(hyphenator, language)
  SILE.languageSupport.loadLanguage(language)

  local languageset = SILE.hyphenator.languages[language]
  if not (languageset) then
    print("No patterns for language "..language)
    return
  end
  for _, pattern in ipairs(languageset.patterns) do addPattern(hyphenator, pattern) end
  if not languageset.exceptions then languageset.exceptions = {} end
  for _, exception in ipairs(languageset.exceptions) do
    registerException(hyphenator, exception)
  end
end

SILE._hyphenate = function (self, text)
  if string.len(text) < self.minWord then return { text } end
  local points = self.exceptions[text:lower()]
  local word = SU.splitUtf8(text)
  if not points then
    points = SU.map(function ()return 0 end, word)
    local work = SU.map(string.lower, word)
    table.insert(work, ".")
    table.insert(work, 1, ".")
    table.insert(points, 1, 0)
    for i = 1, #work do
      local trie = self.trie
      for j = i, #work do
        if not trie[work[j]] then break end
        trie = trie[work[j]]
        local p = trie["_"]
        if p then
          for k = 1, #p do
            if points[i + k - 2] and points[i + k - 2] < p[k] then
              points[i + k - 2] = p[k]
            end
          end
        end
      end
    end
    -- Still inside the no-exceptions case
    for i = 1, self.leftmin do points[i] = 0 end
    for i = #points-self.rightmin, #points do points[i] = 0 end
  end
  local pieces = {""}
  for i = 1, #word do
    pieces[#pieces] = pieces[#pieces] .. word[i]
    if points[1+i] and 1 == (points[1+i] % 2) then table.insert(pieces, "") end
  end
  return pieces
end

SILE.hyphenator = {}
SILE.hyphenator.languages = {}
SILE._hyphenators = {}

local initHyphenator = function (lang)
  if not SILE._hyphenators[lang] then
    SILE._hyphenators[lang] = { minWord = 5, leftmin = 2, rightmin = 2, trie = {}, exceptions = {}  }
    loadPatterns(SILE._hyphenators[lang], lang)
  end
end

local hyphenateNode = function (node)
  if not node.language then return { node } end
  if not node.is_nnode or not node.text then return { node } end
  if node.language and (type(SILE.hyphenator.languages[node.language]) == "function") then
    return SILE.hyphenator.languages[node.language](node)
  end
  initHyphenator(node.language)
  local breaks = SILE._hyphenate(SILE._hyphenators[node.language], node.text)
  if #breaks > 1 then
    local newnodes = {}
    for j, brk in ipairs(breaks) do
      if not(brk == "") then
        for _, newNode in ipairs(SILE.shaper:createNnodes(brk, node.options)) do
          if newNode.is_nnode then
            newNode.parent = node
            table.insert(newnodes, newNode)
          end
        end
        if not (j == #breaks) then
          local discretionary = SILE.nodefactory.discretionary({ prebreak = SILE.shaper:createNnodes(SILE.settings:get("font.hyphenchar"), node.options) })
          discretionary.parent = node
          table.insert(newnodes, discretionary)
         --table.insert(newnodes, SILE.nodefactory.penalty({ value = SILE.settings:get("typesetter.hyphenpenalty") }))
        end
      end
    end
    node.children = newnodes
    node.hyphenated = false
    node.done = false
    return newnodes
  end
  return { node }
end

SILE.showHyphenationPoints = function (word, language)
  language = language or "en"
  initHyphenator(language)
  return SU.concat(SILE._hyphenate(SILE._hyphenators[language], word), SILE.settings:get("font.hyphenchar"))
end

SILE.hyphenate = function (nodelist)
  local newlist = {}
  for _, node in ipairs(nodelist) do
    local newnodes = hyphenateNode(node)
    if newnodes then
      for _, n in ipairs(newnodes) do
        table.insert(newlist, n)
      end
    end
  end
  return newlist
end

SILE.registerCommand("hyphenator:add-exceptions", function (options, content)
  local language = options.lang or SILE.settings:get("document.language") or "und"
  SILE.languageSupport.loadLanguage(language)
  initHyphenator(language)
  for token in SU.gtoke(content[1]) do
    if token.string then
      registerException(SILE._hyphenators[language], token.string)
    end
  end
end, nil, nil, true)
