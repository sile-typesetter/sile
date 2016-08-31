SILE.languageSupport = {
  languages = {},
  loadLanguage = function(language)
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    if not(language) or language == "" then language = "en" end
    ok, fail = pcall(function () SILE.require("languages/"..language.."-compiled") end)
    if ok then return end
    ok, fail = pcall(function () SILE.require("languages/"..language) end)
    if fail then
      SU.warn("Error loading language "..language..": "..fail)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
  end,
  compile = function(language)
    local ser = require("serpent")
    -- Ensure things are loaded
    SILE.languageSupport.loadLanguage(language)
    SILE.hyphenate({ SILE.nodefactory.newNnode({language=language, text=""}) })
    local f = io.open("languages/"..language.."-compiled.lua", "w")
    f:write("_hyphenators."..language.."="..ser.line(_hyphenators[language]).."\n")
    f:write("SILE.hyphenator.languages."..language.."="..ser.line(SILE.hyphenator.languages[language]).."\n")
    f:close()
  end
}

SILE.registerCommand("language", function (o,c)
  if not c[1] then
    local lang = SU.required(o, "main", "language setting")
    SILE.languageSupport.loadLanguage(lang)
    SILE.settings.set("document.language", lang)
  else
    local lang = SU.required(o, "lang", "language setting")
    SILE.languageSupport.loadLanguage(lang)
    SILE.settings.temporarily(function ()
      SILE.settings.set("document.language", lang)
      SILE.process(c)
    end)
  end
end)

require("languages/unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = {patterns={}}
SILE.hyphenator.languages.bo = {patterns={}}
SILE.hyphenator.languages.urd = {patterns={}}
SILE.hyphenator.languages.snd = {patterns={}}