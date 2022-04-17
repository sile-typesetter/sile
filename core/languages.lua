local loadkit = require("loadkit")

loadkit.register("ftl", function (file)
  local contents = assert(file:read("*a"))
  file:close()
  return assert(SILE.fluent:add_messages(contents))
end)

SILE.languageSupport = {
  languages = {},
  loadLanguage = function (language)
    language = language or SILE.settings.get("document.language")
    language = SILE.cldr.locales[language] and language or "und"
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    local lang, fail = pcall(function () SILE.require("languages/" .. language) end)
    if fail then
      if fail:match("not found") then fail = "no support for this language" end
      SU.warn("Error loading language " .. language .. ": " .. fail)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
    local ftlresource = string.format("i18n.%s", language)
    SU.debug("fluent", "Loading FTL resource", ftlresource, "into locale", language)
    SILE.fluent:set_locale(language)
    local _, ftlfail = pcall(function () return require(ftlresource) end)
    if not ftlfail then
      SU.warn("Error loading localizations " .. language .. ": " .. ftlfail)
    end
    if type(lang) == "table" and lang.init then
      lang.init()
    end
  end
}

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
