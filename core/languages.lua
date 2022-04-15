local loadftl = function(path, locale)
  local ftl, err = io.open(path, "r")
  if not err then
    local ftl_entries = ftl:read("*all")
    SILE.fluent:add_messages(ftl_entries, locale)
    io.close(ftl)
  end
end

SILE.languageSupport = {
  languages = {},
  loadLanguage = function (language)
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    if not(language) or language == "" then language = "en" end
    language = SILE.cldr.locales[language] and language or "und"
    SILE.fluent:set_locale(language)
    SU.debug("fluent", "load", language)
    local lang, fail = pcall(function () SILE.require("languages/" .. language) end)
    if fail then
      if fail:match("not found") then fail = "no support for this language" end
      SU.warn("Error loading language " .. language .. ": " .. fail)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
    loadftl("i18n/"..language..".ftl", language)
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
  local locale = SILE.settings.get("document.language")
  SU.debug("fluent", function () return string.format("Looking for %s in %s", key, locale) end)
  local key = content[1]
  local entry
  if key then
    entry = SILE.fluent:get_message(key, locale)
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
  local input = content[1]
  SU.debug("fluent", "Loading message(s) into locale", locale)
  if (options["src"]) then
    loadftl(options["src"], locale)
  else
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
