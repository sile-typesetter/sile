local loadftl = function(path)
  local ftl, err = io.open(path, "r")
  if not err then
    local ftl_entries = ftl:read("*all")
    SILE.fluent:add_messages(ftl_entries)
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
    local lang, fail = pcall(function () SILE.require("languages/" .. language) end)
    if fail then
      if fail:match("not found") then fail = "no support for this language" end
      SU.warn("Error loading language " .. language .. ": " .. fail)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
    loadftl("i18n/"..language..".ftl")
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
  local language = SILE.settings.get("document.language")
  SILE.fluent:set_locale(language)
  local message = SILE.fluent:get_message(key):format(options)
  SILE.process({ message })
end)

SILE.registerCommand("ftl", function (options, content)
  local input = content[1]
  if (options["src"]) then
    loadftl(options["src"])
  else
    SILE.fluent:add_messages(input)
  end
end)

require("languages/unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = { patterns = {} }
SILE.hyphenator.languages.bo = { patterns = {} }
SILE.hyphenator.languages.ur = { patterns = {} }
SILE.hyphenator.languages.sd = { patterns = {} }
