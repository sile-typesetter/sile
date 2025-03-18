--- SILE language class.
-- @interfaces languages

local language = pl.class()
language.type = "language"
language._name = "base"

local cldr = require("cldr")
local setenv = require("rusile").setenv

function language:_init ()
   self:_declareBaseSettings()
   self:declareSettings()
   self:_registerBaseCommands()
   self:registerCommands()
   self:loadHyphenationData()
   self:loadMessages()
   self:activate()
end

function language:activate()
   local lang = self:getShortcode()
   fluent:set_locale(lang)
   os.setlocale(lang)
   setenv("LANG", lang)
end

function language:getShortcode()
   return self._name
end

function language:loadMessages()
   language = language or SILE.settings:get("document.language")
   language = cldr.locales[language] and language or "und"
   local langresource = string.format("languages.%s", language)
   local gotlang, lang = pcall(require, langresource)
   if not gotlang then
      SU.warn(
         ("Unable to load language feature support (e.g. hyphenation rules) for %s: %s"):format(
            language,
            lang:gsub(":.*", "")
         )
      )
   end
   local ftlresource = string.format("languages.%s.messages", language)
   SU.debug("fluent", "Loading FTL resource", ftlresource, "into locale", language)
   -- This needs to be set so that we load localizations into the right bundle,
   -- but this breaks the sync enabled by the hook in the document.language
   -- setting, so we want to set it back when we're done.
   local original_language = fluent:get_locale()
   fluent:set_locale(language)
   local gotftl, ftl = pcall(require, ftlresource)
   if not gotftl then
      SU.warn(
         ("Unable to load localized strings (e.g. table of contents header text) for %s: %s"):format(
            language,
            ftl:gsub(":.*", "")
         )
      )
   end
   if type(lang) == "table" and lang.init then
      lang.init()
   end
   fluent:set_locale(original_language)
end

function language:loadHyphenationData ()
   local code = self:getShortcode()
   local data = require(("languages.%s.hyphens"):format(code))
   ----------------
end

function language:_declareBaseSettings ()
   SILE.settings:declare({
      parameter = "document.language",
      type = "string",
      default = "en",
      hook = function (language)
         if SILE.language:getShortcode() ~= language then
            SILE.language = SILE.languages[language]()
         end
      end,
      help = "Locale for localized language support",
   })
   SILE.settings:declare({
      parameter = "languages.fixedNbsp",
      type = "boolean",
      default = false,
      help = "Whether to treat U+00A0 (NO-BREAK SPACE) as a fixed-width space",
   })
end

function language.declareSettings (_) end

function language.registerCommands (_) end

function language:_registerBaseCommands ()
   self:registerCommand("language", function (options, content)
      local main = SU.required(options, "main", "language setting")
      SILE.languageSupport.loadLanguage(main)
      if content[1] then
         SILE.settings:temporarily(function ()
            SILE.settings:set("document.language", main)
            SILE.process(content)
         end)
      else
         SILE.settings:set("document.language", main)
      end
   end, nil, nil, true)

   self:registerCommand("fluent", function (options, content)
      local key = content[1]
      local locale = options.locale or SILE.settings:get("document.language")
      local original_locale = fluent:get_locale()
      fluent:set_locale(locale)
      SU.debug("fluent", "Looking for", key, "in", locale)
      local entry
      if key then
         entry = fluent:get_message(key)
      else
         SU.warn("Fluent localization function called without passing a valid message id")
      end
      local message
      if entry then
         message = entry:format(options)
      else
         SU.warn(string.format("No localized message for %s found in locale %s", key, locale))
         fluent:set_locale("und")
         entry = fluent:get_message(key)
         if entry then
            message = entry:format(options)
         end
      end
      fluent:set_locale(original_locale)
      SILE.processString(("<sile>%s</sile>"):format(message), "xml")
   end, nil, nil, true)

   self:registerCommand("ftl", function (options, content)
      local original_locale = fluent:get_locale()
      local locale = options.locale or SILE.settings:get("document.language")
      SU.debug("fluent", "Loading message(s) into locale", locale)
      fluent:set_locale(locale)
      if options.src then
         fluent:load_file(options.src, locale)
      elseif SU.ast.hasContent(content) then
         local input = content[1]
         fluent:add_messages(input, locale)
      end
      fluent:set_locale(original_locale)
   end, nil, nil, true)

   self:registerCommand("hyphenator:add-exceptions", function (options, content)
      local language = options.lang or SILE.settings:get("document.language") or "und"
      SILE.languageSupport.loadLanguage(language)
      initHyphenator(language)
      for token in SU.gtoke(content[1]) do
         if token.string then
            registerException(SILE._hyphenators[language], token.string)
         end
      end
   end, nil, nil, true)
end

function language.registerCommand (_, name, func, help, pack)
   SILE.Commands[name] = func
   if not pack then
      local where = debug.getinfo(2).source
      pack = where:match("(%w+).lua")
   end
   --if not help and not pack:match(".sil") then SU.error("Could not define command '"..name.."' (in package "..pack..") - no help text" ) end
   SILE.Help[name] = {
      description = help,
      where = pack,
   }
end
function addPattern (hyphenator, pattern)
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
   for _, pattern in ipairs(languageset.patterns) do
      addPattern(hyphenator, pattern)
   end
   if not languageset.exceptions then
      languageset.exceptions = {}
   end
   for _, exception in ipairs(languageset.exceptions) do
      registerException(hyphenator, exception)
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
      for i = #points - self.rightmin, #points do
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

local function defaultHyphenateSegments (node, segments, _)
   local hyphen = SILE.shaper:createNnodes(SILE.settings:get("font.hyphenchar"), node.options)
   return SILE.types.node.discretionary({ prebreak = hyphen }), segments
end

local initHyphenator = function (lang)
   if not SILE._hyphenators[lang] then
      SILE._hyphenators[lang] = { minWord = 5, leftmin = 2, rightmin = 2, trie = {}, exceptions = {} }
      loadPatterns(SILE._hyphenators[lang], lang)
   end
   if SILE.hyphenator.languages[lang] and not SILE.hyphenator.languages[lang].hyphenateSegments then
      SILE.hyphenator.languages[lang].hyphenateSegments = defaultHyphenateSegments
   end
end

function language:showHyphenationPoints (word, language)
   language = language or "en"
   initHyphenator(language)
   return SU.concat(SILE._hyphenate(SILE._hyphenators[language], word), SILE.settings:get("font.hyphenchar"))
end

function language:hyphenate (nodelist)
   local newlist = {}
   for _, node in ipairs(nodelist) do
      local newnodes = self:hyphenateNode(node)
      if newnodes then
         for _, n in ipairs(newnodes) do
            table.insert(newlist, n)
         end
      end
   end
   return newlist
end

function language:hyphenateNode (node)
   if not node.language then
      return { node }
   end
   if not node.is_nnode or not node.text then
      return { node }
   end
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

SILE.nodeMakers.base = pl.class({

   _init = function (self, options)
      self.contents = {}
      self.options = options
      self.token = ""
      self.lastnode = false
      self.lasttype = false
   end,

   makeToken = function (self)
      if #self.contents > 0 then
         coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
         SU.debug("tokenizer", "Token:", self.token)
         self.contents = {}
         self.token = ""
         self.lastnode = "nnode"
      end
   end,

   addToken = function (self, char, item)
      self.token = self.token .. char
      table.insert(self.contents, item)
   end,

   makeGlue = function (self, item)
      if SILE.settings:get("typesetter.obeyspaces") or self.lastnode ~= "glue" then
         SU.debug("tokenizer", "Space node")
         coroutine.yield(SILE.shaper:makeSpaceNode(self.options, item))
      end
      self.lastnode = "glue"
      self.lasttype = "sp"
   end,

   makePenalty = function (self, p)
      if self.lastnode ~= "penalty" and self.lastnode ~= "glue" then
         coroutine.yield(SILE.types.node.penalty({ penalty = p or 0 }))
      end
      self.lastnode = "penalty"
   end,

   makeNonBreakingSpace = function (self)
      -- Unicode Line Breaking Algorithm (UAX 14) specifies that U+00A0
      -- (NO-BREAK SPACE) is expanded or compressed like a normal space.
      coroutine.yield(SILE.types.node.kern(SILE.shaper:measureSpace(self.options)))
      self.lastnode = "glue"
      self.lasttype = "sp"
   end,

   iterator = function (_, _)
      SU.error("Abstract function nodemaker:iterator called", true)
   end,

   charData = function (_, char)
      local cp = SU.codepoint(char)
      if not chardata[cp] then
         return {}
      end
      return chardata[cp]
   end,

   isActiveNonBreakingSpace = function (self, char)
      return self:isNonBreakingSpace(char) and not SILE.settings:get("languages.fixedNbsp")
   end,

   isBreaking = function (self, char)
      return self.breakingTypes[self:charData(char).linebreak]
   end,

   isNonBreakingSpace = function (self, char)
      local c = self:charData(char)
      return c.contextname and c.contextname == "nobreakspace"
   end,

   isPunctuation = function (self, char)
      return self.puctuationTypes[self:charData(char).category]
   end,

   isSpace = function (self, char)
      return self.spaceTypes[self:charData(char).linebreak]
   end,

   isQuote = function (self, char)
      return self.quoteTypes[self:charData(char).linebreak]
   end,

   isWord = function (self, char)
      return self.wordTypes[self:charData(char).linebreak]
   end,
})


return language
