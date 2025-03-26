--- SILE language class.
-- @interfaces languages

local language = pl.class()
language.type = "language"
language._name = "base"

local loadkit = require("loadkit")
local setenv = require("rusile").setenv

local nodeMaker = require("languages.base-nodemaker")

-- Allows loading FTL resources directly with require(). Guesses the locale based on SILE's default resource paths,
-- otherwise if it can't guess it Loads assets directly into the *current* fluent bundle.
local require_ftl = loadkit.make_loader("ftl", function (file)
   local contents = assert(file:read("*a"))
   file:close()
   return assert(fluent:add_messages(contents))
end)

function language:_init (typesetter)
   self.typesetter = typesetter
   self:_declareBaseSettings()
   self:declareSettings()
   self:_registerBaseCommands()
   self:registerCommands()
   self:loadMessages()
   self:activate()
end

function language:_post_init ()
   if not self.nodeMaker then
      self.nodeMaker = nodeMaker(self._name)
   end
end

function language:activate ()
   local lang = self:_getLegacyCode()
   fluent:set_locale(lang)
   os.setlocale(lang)
   setenv("LANG", lang)
end

function language:_getLegacyCode ()
   return self._name
end

-- TODO: not about hyphenation rules per warning....
function language:loadMessages()
   local lang = self:getShortcode()
   local ftlresource = string.format("languages.%s.messages", language)
   SU.debug("fluent", "Loading FTL resource", ftlresource, "into locale", lang)
   -- This needs to be set so that we load localizations into the right bundle,
   -- but this breaks the sync enabled by the hook in the document.language
   -- setting, so we want to set it back when we're done.
   local original_lang = fluent:get_locale()
   fluent:set_locale(lang)
   local gotftl, ftl = pcall(require_ftl, ftlresource)
   if not gotftl then
      SU.warn(
         ("Unable to load localized strings (e.g. table of contents header text) for %s: %s"):format(
            lang,
            ftl:gsub(":.*", "")
         )
      )
   end
   fluent:set_locale(original_lang)
end

function language:_declareBaseSettings ()
   SILE.settings:declare({
      parameter = "document.language",
      type = "string",
      default = "en",
      hook = function (lang)
         self.typesetter:switchLanguage(lang)
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
      local lang = options.lang or SILE.settings:get("document.language") or "und"
      SILE.languageSupport.loadLanguage(lang)
      initHyphenator(lang)
      for token in SU.gtoke(content[1]) do
         if token.string then
            registerException(SILE._hyphenators[lang], token.string)
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

return language
