--- SILE language class.
-- @interfaces languages

local loadkit = require("loadkit")

-- Disabled for now, see further below.
-- local cldr = require("cldr")

loadkit.register("ftl", function (file)
   local contents = assert(file:read("*a"))
   file:close()
   return assert(fluent:add_messages(contents))
end)

SILE.scratch.loaded_languages = {}

local icu = require("justenoughicu")

-- This small utility could be moved to utilities as SU.forLanguage()...
-- The input is expected to be a valid BCP47 canonical language.
-- The idea is to find the "closest" language accepted by the callback:
-- Loop removing a language specifier until the callback returns a non-nil value
-- Returns that value and the matched language in that case, or nil no callback matched.
-- E.g. "xx-Xxxx-XX" will be matched against "xx-Xxxx--XX", "xx-Xxxx", "xx" until one of
-- these are satisfied.
-- Returns
--    nil if not callback could process the language
--    language, res if a callback could (returning the matched language pattern and the
--    result of the callback)
local function forLanguage(langbcp47, callback)
   while langbcp47 do
      local res = callback(langbcp47)
      if res then
         return res, langbcp47
      end
      langbcp47 = langbcp47:match("^(.+)-.*$") -- split at dash (-) and remove last part.
   end
   return nil
end

SILE.languageSupport = {
   languages = {},
   loadLanguage = function (language)
      language = language or SILE.settings:get("document.language")
      -- The user may have set document.language to anything, let's ensure a canonical BCP47 language...
      if language ~= "und" then
         language = icu.canonicalize_language(language)
         -- language = cldr.locales[language] and language or "und"
      end
      if SILE.scratch.loaded_languages[language] then
         return
      end
      SILE.scratch.loaded_languages[language] = true
      -- We need to find language resources for this BCP47 identifier, from the less specific
      -- to the more general.
      local langresource, matchedlang = forLanguage(language, function (lang)
         local resource = string.format("languages.%s", lang)
         local gotres, res = pcall(require, resource)
         return gotres and res
      end)
      if not langresource then
         SU.warn(("Unable to load language feature support (e.g. hyphenation rules) for %s")
         :format(language))
      else
         print(("Loaded language feature support for %s: matched %s") -- HACK We'll need a mere SU.debug when OK...
         :format(language, matchedlang))
         if language ~= matchedlang then
            -- Now that's so UGLY. Say the input language was "en-GB".
            -- It matched "en" eventually (as we don't have yet an "languages.en-GB" resources)
            -- PROBLEM: Our languages.xxx files (almost) all work by side effects, putting various things,
            -- in the case of our example, in SILE.nodeMarkers.en, SILE.hyphenator.languages.en
            -- and SU.formatNumber.en... While we now expect the language to be "en-GB"...
            -- It's a HACK, but copy the stuff into our language.
            SILE.nodeMakers[language] = SILE.nodeMakers[matchedlang]
            SU.formatNumber[language] = SU.formatNumber[matchedlang]
            SILE.hyphenator.languages[language] = SILE.hyphenator.languages[matchedlang]
         end
      end
      -- We need to find fluent reources for this BCP47 identifier, from the less specific
      -- to the more general.
      local ftlresource, matchedi18n = forLanguage(language, function (lang)
         local resource = string.format("i18n.%s", lang)
         SU.debug("fluent", "Loading FTL resource", resource, "into locale", lang)
         fluent:set_locale(lang)
         local gotftl, ftl = pcall(require, resource)
         return gotftl and ftl
      end)
      if not ftlresource then
         SU.warn(("Unable to load localized strings (e.g. table of contents header text) for %s")
         :format(language))
      else
         print(("Load localized strings for %s: matched %s") -- HACK We'll need a mere SU.debug when OK...
         :format(language, matchedi18n))
         if language ~= matchedi18n then
            -- Now that's even more UGLY. Say the input language was "en-GB".
            -- It matched "en" eventually (as we don't have yet an "i18n.en-GB" resources)
            -- PROBLEM: the fluent locale must be set to the target language before loading
            -- a ftl file. APIs that aren't stateless are messy :(
            -- in the case of our example, they had to be read into "en"...
            -- HACK HACK, all we can do is reloaad it fully, but under the target "en-GB" name...
            local loaded = string.format("language.%s.messages", matchedi18n)
            package.loaded[loaded] = nil -- HACK force reload!!!
            fluent:set_locale(language)
            require(string.format("i18n.%s", matchedi18n))
         end
      end
      if type(lang) == "table" and lang.init then
         lang.init()
      end
      fluent:set_locale(original_language)
   end,
}

SILE.registerCommand("language", function (options, content)
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

SILE.registerCommand("fluent", function (options, content)
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

SILE.registerCommand("ftl", function (options, content)
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

require("languages.unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = { patterns = {} }
SILE.hyphenator.languages.bo = { patterns = {} }
SILE.hyphenator.languages.sd = { patterns = {} }
SILE.hyphenator.languages.ur = { patterns = {} }
