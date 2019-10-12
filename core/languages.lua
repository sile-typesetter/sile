SILE.languageSupport = {
  languages = {},
  loadLanguage = function (language)
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    if not(language) or language == "" then language = "en" end
    language = SILE.cldr.locales[language] and language or "und"
    ok, fail = pcall(function () SILE.require("languages/" .. language) end)
    if fail then
      if fail:match("not found") then fail = "no support for this language" end
      SU.warn("Error loading language " .. language .. ": " .. fail)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
    SILE.fluent:set_locale(language)
    local ftl, err = io.open("i18n/"..language..".ftl", "r")
    if not err then
      local ftl_entries = ftl:read("*all")
      SILE.fluent:add_messages(ftl_entries)
      io.close(ftl)
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
  local message = SILE.fluent:get_message(key):format(options)
  SILE.process({message})
end)

require("languages/unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.bo = { patterns = {} }
SILE.hyphenator.languages.ur = { patterns = {} }
SILE.hyphenator.languages.sd = { patterns = {} }
