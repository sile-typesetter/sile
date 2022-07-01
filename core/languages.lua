local loadkit = require("loadkit")
local cldr = require("cldr")

loadkit.register("ftl", function (file)
  local contents = assert(file:read("*a"))
  file:close()
  return assert(SILE.fluent:add_messages(contents))
end)

local loadonce = {}

SILE.languageSupport = {
  languages = {},
  loadLanguage = function (language)
    language = language or SILE.settings:get("document.language")
    language = cldr.locales[language] and language or "und"
    if loadonce[language] then return end
    loadonce[language] = true
    local langresource = string.format("languages.%s", language)
    local gotlang, lang = pcall(require, langresource)
    if not gotlang then
      SU.warn(("Unable to load language feature support (e.g. hyphenation rules) for %s: %s")
        :format(language, lang:gsub(":.*", "")))
    end
    local ftlresource = string.format("i18n.%s", language)
    SU.debug("fluent", "Loading FTL resource", ftlresource, "into locale", language)
    SILE.fluent:set_locale(language)
    local gotftl, ftl = pcall(require, ftlresource)
    if not gotftl then
      SU.warn(("Unable to load localized strings (e.g. table of contents header text) for %s: %s")
        :format(language, ftl:gsub(":.*", "")))
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
    SILE.settings:temporarily(function ()
      SILE.settings:set("document.language", main)
      SILE.process(content)
    end)
  else
    SILE.settings:set("document.language", main)
  end
end)

SILE.registerCommand("fluent", function (options, content)
  local key = content[1]
  local locale = options.locale or SILE.settings:get("document.language")
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
  local locale = options.locale or SILE.settings:get("document.language")
  SU.debug("fluent", "Loading message(s) into locale", locale)
  SILE.fluent:set_locale(locale)
  if options.src then
    SILE.fluent:load_file(options.src, locale)
  elseif SU.hasContent(content) then
    local input = content[1]
    SILE.fluent:add_messages(input, locale)
  end
end)

require("languages.unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = { patterns = {} }
SILE.hyphenator.languages.bo = { patterns = {} }
SILE.hyphenator.languages.sd = { patterns = {} }
SILE.hyphenator.languages.ur = { patterns = {} }
