local loadkit = require("loadkit")

loadkit.register("ftl", function (file)
  local contents = assert(file:read("*a"))
  file:close()
  return contents
end)

SILE.languageSupport = {
  languages = {},
  loadLanguage = function (language)
    language = language or SILE.settings.get("document.language")
    language = SILE.cldr.locales[language] and language or "und"
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    local ret1, lang = pcall(SILE.require, "languages/" .. language)
    if not ret1 then
      if lang:match("not found") then lang = "no support for this language" end
      SU.warn("Error loading language " .. language .. ": " .. lang)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
    local ftlresource = string.format("i18n.%s", language)
    SU.debug("fluent", "Loading FTL resource", ftlresource, "into locale", language)
    SILE.fluent:set_locale(language)
    local ret2, ftl = pcall(require, ftlresource)
    if ret2 then
      SILE.fluent:add_messages(ftl)
    else
      SU.warn("No document localizations found for " .. language .. ": " .. ftl)
    end
    if type(lang) == "table" and lang.init then
      lang.init()
    end
  end
}

-- Function to load UI localizations for SILE itself. Also sets the default
-- document language, but this is primarily about the UI not the document.
SILE.set_locale = function (locale)
  locale = SILE.cldr.locales[locale] and locale or "en"
  SILE.languageSupport.loadLanguage(locale)
  SILE.settings.set("document.language", locale, true)
  SILE.l10n:set_locale(locale)
  local ftlresource = string.format("l10n.%s", locale)
  local ret, ftl = pcall(require, ftlresource)
  if ret then
    SILE.l10n:add_messages(ftl)
  else
    SU.warn("Error loading UI localizations " .. locale .. ": " .. ftl)
  end
end

SILE.registerCommand("language", function (options, content)
  local main = SU.required(options, "main", "language setting")
  SILE.languageSupport.loadLanguage(main)
  if content[1] then
    SILE.settings.temporarily(function ()
      SILE.settings.set("document.language", main)
      SILE.process(content)
    end)
  else
    SILE.settings.set("document.language", main)
  end
end)

SILE.registerCommand("fluent", function (options, content)
  local key = content[1]
  local locale = options.locale or SILE.settings.get("document.language")
  SU.debug("fluent", "Looking for", key, "in", locale)
  local entry
  if key then
    SILE.fluent:set_locale(locale)
    entry = SILE.fluent:get_message(key)
  else
    SU.warn("Fluent localization function called without passing a valid message id")
  end
  local message
  if entry then
    message = entry:format(options)
  else
    SU.warn(string.format("No localized message for %s found in locale %s", key, locale))
  end
  SILE.process({ message })
end)

SILE.registerCommand("ftl", function (options, content)
  local locale = options.locale or SILE.settings.get("document.language")
  SU.debug("fluent", "Loading message(s) into locale", locale)
  SILE.fluent:set_locale(locale)
  if options.src then
    SILE.fluent:load_file(options.src, locale)
  elseif SU.hasContent(content) then
    local input = content[1]
    SILE.fluent:add_messages(input, locale)
  end
end)

require("languages/unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = { patterns = {} }
SILE.hyphenator.languages.bo = { patterns = {} }
SILE.hyphenator.languages.ur = { patterns = {} }
SILE.hyphenator.languages.sd = { patterns = {} }
