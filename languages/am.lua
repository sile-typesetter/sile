
SILE.nodeMakers.am = SILE.nodeMakers.unicode {
  iterator = function (self, items)
    self:init()
    local ics = SILE.settings.get("document.letterspaceglue")
    return coroutine.wrap(function()
      for i = 1,#items do item = items[i]
        local char = items[i].text
        local cp = SU.codepoint(char)
        if cp == 0x1361 then --
          -- XXX depends on method
          self:addToken(char,item)
          self:makeToken()
          self:makeGlue()
        else
          self:dealWith(items[i])
        end
      end
      if ics then self:makeLetterSpaceGlue() end
      self:makeToken()
    end)
  end
}