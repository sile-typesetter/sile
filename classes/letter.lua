local plain = require("classes.plain")

local letter = pl.class(plain)
letter._name = "letter"

letter.defaultFrameset = {
  content = {
      left = "5%pw",
      right = "95%pw",
      top = "2in",
      bottom = "90%ph"
    }
}

function letter:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(letter) end
  plain._init(self, options)
  SILE.scratch.letter = {
    sender = nil,
    date = nil,
    recipient = "",
    salutation = ""
  }
  return self
end

function letter:registerCommands ()

  plain.registerCommands(self)

  SILE.registerCommand("letter", function (_, content)
    SILE.settings:set("current.parindent", SILE.nodefactory.glue())
    SILE.settings:set("document.parindent", SILE.nodefactory.glue())
    SILE.call("raggedright", {}, function ()
      SILE.call("letter:format:date")
      SILE.call("bigskip")
      if SILE.scratch.letter.sender then
        SILE.call("letter:format:sender")
        SILE.call("bigskip")
      end
      SILE.call("letter:format:recipient")
      SILE.call("bigskip")
      SILE.call("letter:format:salutation")
      SILE.call("bigskip")
      SILE.process(content)
    end)
  end)

  SILE.registerCommand("sender", function (_, content)
    SILE.scratch.letter.sender = content
  end)
  SILE.registerCommand("recipient", function (_, content)
    SILE.scratch.letter.recipient = content
  end)
  SILE.registerCommand("salutation", function (_, content)
    SILE.scratch.letter.salutation = content
  end)
  SILE.registerCommand("date", function (_, content)
    SILE.scratch.letter.date = content
  end)

  SILE.registerCommand("letter:format:date", function ()
    if not SILE.scratch.letter.date then
      SILE.scratch.letter.date = { os.date("%A, %d %B") }
    end
    SILE.process(SILE.scratch.letter.date)
    SILE.call("par")
  end)

  SILE.registerCommand("letter:format:sender", function ()
    SILE.process(SILE.scratch.letter.sender)
  end)

  SILE.registerCommand("letter:format:recipient", function ()
    SILE.process(SILE.scratch.letter.recipient)
  end)

  SILE.registerCommand("letter:format:salutation", function ()
    SILE.process(SILE.scratch.letter.salutation)
  end)

end

return letter
