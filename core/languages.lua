--- SILE language class.
-- @interfaces languages

local loadkit = require("loadkit")
local cldr = require("cldr")

loadkit.register("ftl", function (file)
   local contents = assert(file:read("*a"))
   file:close()
   return assert(fluent:add_messages(contents))
end)

SILE.scratch.loaded_languages = {}

SILE.languageSupport = {
   languages = {},
   loadLanguage = function (language)
      language = language or SILE.settings:get("document.language")
      language = cldr.locales[language] and language or "und"
      if SILE.scratch.loaded_languages[language] then
         return
      end
      SILE.scratch.loaded_languages[language] = true
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
