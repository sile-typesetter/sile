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

-- BUG ALERT: This implementation is known to not account for font.hyphenchar being changed midway through a document.
-- If the font also changed the node options would be different anyway so in 99%+ of cases this cheat is expected to
-- work but technically the memoization should include the setting or the ID of the current setting stack or something.

local lastoptions, lasthyphen

local _defaultHyphenateSegments = pl.utils.memoize(function (hash)
  local hyphen = SILE.shaper:createNnodes(SILE.settings:get("font.hyphenchar"), lastoptions)
  return SILE.nodefactory.discretionary({ prebreak = hyphen }), segments
end)

local function defaultHyphenateSegments (node, segments, _)
  if lastoptions ~= node.options then
    lastoptions = node.options
    local hash = pl.pretty.write(node.options, "", true)
    local discretionary = _defaultHyphenateSegments(hash)
    lasthyphen = discretionary
  end
  return lasthyphen, segments
end

local initHyphenator = function (lang)
  if not SILE._hyphenators[lang] then
    SILE._hyphenators[lang] = { minWord = 5, leftmin = 2, rightmin = 2, trie = {}, exceptions = {}  }
    loadPatterns(SILE._hyphenators[lang], lang)
  end
  if SILE.hyphenator.languages[lang] and not SILE.hyphenator.languages[lang].hyphenateSegments then
    SILE.hyphenator.languages[lang].hyphenateSegments = defaultHyphenateSegments
  end
end

local hyphenateNode = function (node)
  if not node.language then return { node } end
  if not node.is_nnode or not node.text then return { node } end
  if node.language and (type(SILE.hyphenator.languages[node.language]) == "function") then
    return SILE.hyphenator.languages[node.language](node)
  end
  initHyphenator(node.language)
  local segments = SILE._hyphenate(SILE._hyphenators[node.language], node.text)
  local hyphen
  if #segments > 1 then
    local hyphenateSegments = SILE.hyphenator.languages[node.language].hyphenateSegments
    local newnodes = {}
    for j, segment in ipairs(segments) do
      if segment == "" then
        SU.dump({ j, segments })
        SU.error("No hyphenation segment should ever be empty", true)
      end
      hyphen, segments = hyphenateSegments(node, segments, j)
      for _, newNode in ipairs(SILE.shaper:createNnodes(segments[j], node.options)) do
        if newNode.is_nnode then
          newNode.parent = node
          table.insert(newnodes, newNode)
        end
      end
      if j < #segments then
        hyphen.parent = node
        table.insert(newnodes, hyphen)
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
