SILE.languageSupport = {
  languages = {},
  loadLanguage = function (language)
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    if not(language) or language == "" then language = "en" end
    ok, fail = pcall(function () SILE.require("languages/" .. language .. "-compiled") end)
    if ok then return end
    ok, fail = pcall(function () SILE.require("languages/" .. language) end)
    if fail then
      if fail:match("not found") then fail = "no support for this language" end
      SU.warn("Error loading language " .. language .. ": " .. fail)
      SILE.languageSupport.languages[language] = {} -- Don't try again
    end
  end,
  compile = function (language)
    local ser = require("serpent")
    -- Ensure things are loaded
    SILE.languageSupport.loadLanguage(language)
    SILE.hyphenate({ SILE.nodefactory.newNnode({ language = language, text = "" }) })
    local file = io.open("languages/" .. language .. "-compiled.lua", "w")
    file:write("_hyphenators." .. language .. " = " .. ser.line(_hyphenators[language]) .. "\n")
    file:write("SILE.hyphenator.languages." .. language .. " = " .. ser.line(SILE.hyphenator.languages[language]) .. "\n")
    file:close()
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

require("languages/unicode")

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.bo = { patterns = {} }
SILE.hyphenator.languages.ur = { patterns = {} }
SILE.hyphenator.languages.sd = { patterns = {} }
