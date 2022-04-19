SILE.settings.declare({
  parameter = "languages.am.justification",
  type = "string",
  default = "left",
  help = "Justification method for Ethiopic word separators: left or centered"
})

SILE.nodeMakers.am = pl.class({
    _base = SILE.nodeMakers.unicode,
    iterator = function (self, items)
      local ics = SILE.settings.get("document.letterspaceglue")
      local style = SILE.settings.get("languages.am.justification")
      return coroutine.wrap(function ()
        for i = 1, #items do
          local item = items[i]
          local char = items[i].text
          local cp = SU.codepoint(char)
          if cp == 0x1361 then -- ETHIOPIC WORDSPACE
            if style == "centered" then
              self:makeToken()
              self:makeGlue(item)
            end
            self:addToken(char, item)
            self:makeToken()
            self:makeGlue(item)
          elseif cp == 0x1362 then -- ETHIOPIC FULL STOP
            if style == "centered" then
              self:makeToken()
              self:makeGlue(item)
            end
            self:addToken(char, item)
            self:makeToken()
            self:makeGlue(item)
            self:makePenalty() -- This is cheating. We should really make double width glue
            self:makeGlue(item)
          else
            self:dealWith(items[i])
          end
        end
        if ics then self:makeLetterSpaceGlue() end
        self:makeToken()
      end)
    end
  })
