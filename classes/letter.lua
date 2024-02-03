local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "letter"

class.defaultFrameset = {
  content = {
      left = "5%pw",
      right = "95%pw",
      top = "2in",
      bottom = "90%ph"
    }
}

function class:_init (options)
  plain._init(self, options)
  SILE.scratch.letter = {
    sender = nil,
    date = nil,
    recipient = "",
    salutation = ""
  }
end

function class:registerCommands ()

  plain.registerCommands(self)

  self:registerCommand("letter", function (_, content)
    SILE.settings:set("current.parindent", SILE.types.node.glue())
    SILE.settings:set("document.parindent", SILE.types.node.glue())
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

  self:registerCommand("sender", function (_, content)
    SILE.scratch.letter.sender = content
  end)
  self:registerCommand("recipient", function (_, content)
    SILE.scratch.letter.recipient = content
  end)
  self:registerCommand("salutation", function (_, content)
    SILE.scratch.letter.salutation = content
  end)
  self:registerCommand("date", function (_, content)
    SILE.scratch.letter.date = content
  end)

  self:registerCommand("letter:format:date", function ()
    if not SILE.scratch.letter.date then
      SILE.scratch.letter.date = { os.date("%A, %d %B") }
    end
    SILE.process(SILE.scratch.letter.date)
    SILE.call("par")
  end)

  self:registerCommand("letter:format:sender", function ()
    SILE.process(SILE.scratch.letter.sender)
  end)

  self:registerCommand("letter:format:recipient", function ()
    SILE.process(SILE.scratch.letter.recipient)
  end)

  self:registerCommand("letter:format:salutation", function ()
    SILE.process(SILE.scratch.letter.salutation)
  end)

end

return class
