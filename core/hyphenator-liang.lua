local function addPattern (hyphenator, pattern)
   local trie = hyphenator.trie
   local bits = SU.splitUtf8(pattern)
   for i = 1, #bits do
      local char = bits[i]
      if not char:find("%d") then
         if not trie[char] then
            trie[char] = {}
         end
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

local function registerException (hyphenator, exception)
   local text = exception:gsub("-", "")
   local bits = SU.splitUtf8(exception)
   hyphenator.exceptions[text] = {}
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

local function loadPatterns (hyphenator, language)
   SILE.languageSupport.loadLanguage(language)

   local languageset = SILE.hyphenator.languages[language]
   if not languageset then
      print("No patterns for language " .. language)
      return
   end
   -- Some hyphenators (Uygur) have a callback instead of the normal pattern list
   if type(languageset) == "function" then
      return
   end
   for _, pattern in ipairs(languageset.patterns) do
      addPattern(hyphenator, pattern)
   end
   if not languageset.exceptions then
      languageset.exceptions = {}
   end
   for _, exception in ipairs(languageset.exceptions) do
      registerException(hyphenator, exception)
   end
   local hyphenmins = languageset.hyphenmins
   -- TODO: We ought to have a way to set these according to users' preferences
   -- For now, we just set them to the conventional values based on the pattern files, or TeX defaults
   -- Yet, if available, we use the typesetting convention.
   -- For the record, the generation miniam are the real minima below which the pattern file is not
   -- applicable. (So even users' preferences should not go below these values.)
   if hyphenmins then
      if hyphenmins.typesetting then
         hyphenator.leftmin = hyphenmins.typesetting.left or 2
         hyphenator.rightmin = hyphenmins.typesetting.right or 2
         SU.debug("hyphenator", "Setting hyphenation minima for typesetting:", hyphenator.leftmin, hyphenator.rightmin)
      elseif hyphenmins.generation then
         hyphenator.leftmin = hyphenmins.generation.left or 2
         hyphenator.rightmin = hyphenmins.generation.right or 2
         SU.debug("hyphenator", "Setting hyphenation minima from generation:", hyphenator.leftmin, hyphenator.rightmin)
      end
   end
end

SILE._hyphenate = function (self, text)
   if luautf8.len(text) < self.minWord then
      return { text }
   end
   local lowertext = luautf8.lower(text)
   local points = self.exceptions[lowertext]
   local word = SU.splitUtf8(text)
   if not points then
      points = SU.map(function ()
         return 0
      end, word)
      local work = SU.map(luautf8.lower, word)
      table.insert(work, ".")
      table.insert(work, 1, ".")
      table.insert(points, 1, 0)
      for i = 1, #work do
         local trie = self.trie
         for j = i, #work do
            if not trie[work[j]] then
               break
            end
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
      for i = 1, self.leftmin do
         points[i] = 0
      end
      for i = #points - self.rightmin + 1, #points do
         points[i] = 0
      end
   end
   local pieces = { "" }
   for i = 1, #word do
      pieces[#pieces] = pieces[#pieces] .. word[i]
      if points[1 + i] and 1 == (points[1 + i] % 2) then
         table.insert(pieces, "")
      end
   end
   return pieces
end

SILE.hyphenator = {}
SILE.hyphenator.languages = {}
SILE._hyphenators = {}

local function defaultHyphenateSegments (node, segments, _)
   local hyphen = SILE.shaper:createNnodes(SILE.settings:get("font.hyphenchar"), node.options)
   return SILE.types.node.discretionary({ prebreak = hyphen }), segments
end

local initHyphenator = function (lang)
   if not SILE._hyphenators[lang] then
      SILE._hyphenators[lang] = {
         minWord = 5, -- Smallest word length below which hyphenation is not applied
         leftmin = 2, -- Minimum number of characters to the left of the hyphen (TeX default)
         rightmin = 2, -- Minimum number of characters to the right of the hyphen (TeX default)
         trie = {}, -- Trie resulting from the patterns
         exceptions = {}, -- Hyphenation exceptions
      }
      loadPatterns(SILE._hyphenators[lang], lang)
   end
   -- Short circuit this function so Uyghur can override it
   if type(SILE.hyphenator.languages[lang]) == "function" then
      return
   end
   if SILE.hyphenator.languages[lang] and not SILE.hyphenator.languages[lang].hyphenateSegments then
      SILE.hyphenator.languages[lang].hyphenateSegments = defaultHyphenateSegments
   end
end

local hyphenateNode = function (node)
   if not node.language then
      return { node }
   end
   if not node.is_nnode or not node.text then
      return { node }
   end
   -- Short circuit this function so Uyghur can override it
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
