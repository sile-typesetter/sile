SILE.languageSupport = {
  languages = {},
  loadLanguage = function(language)
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    if not(language) or language == "" then language = "en" end
    ok, fail = pcall(function () SILE.require("languages/"..language.."-compiled") end)
    if ok then return end
    ok, fail = pcall(function () SILE.require("languages/"..language) end)
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
  local lang = SU.required(o, "main", "language setting")
  SILE.languageSupport.loadLanguage(lang)
  SILE.settings.set("document.language", lang)
end)

require("languages/unicode")
SILE.nodeMakers.basic = SILE.nodeMakers.base {
  iterator = function (self, items)
    self:init()
    return coroutine.wrap(function()
      for i = 1,#items do item = items[i]
        local char = items[i].text
        if char:match(SILE.settings.get("shaper.spacepattern")) then
          self:makeToken()
          self:makeGlue()
        else
          self:addToken(char,item)
        end
      end
      self:makeToken()
    end)
  end
}


-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = {patterns={}}
SILE.hyphenator.languages.urd = {patterns={}}
SILE.hyphenator.languages.snd = {patterns={}}