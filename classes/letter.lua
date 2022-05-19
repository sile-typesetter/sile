local plain = require("classes.plain")
local letter = pl.class(plain)
letter._name = "letter"

function letter:_init (options)
  plain._init(self, options)
  self:declareFrame("content", {
      left = "5%pw",
      right = "95%pw",
      top = "2in",
      bottom = "90%ph"
    })
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames["content"]
  SILE.scratch.letter = {
    sender = nil,
    date = nil,
    recipient = "",
    salutation = ""
  }
  -- Avoid calling this (yet) if we're the parent of some child class
  if self._name == "letter" then self:post_init() end
  return self
end

function letter:registerCommands ()

  plain.registerCommands(self)

  SILE.registerCommand("letter", function (_, content)
    SILE.settings.set("current.parindent", SILE.nodefactory.glue())
    SILE.settings.set("document.parindent", SILE.nodefactory.glue())
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
