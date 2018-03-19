SILE.registerCommand("ruby:font", function(options, content)
  SILE.call("font", { size = "0.6zw", weight = 800 })

end)
SILE.settings.declare({
  name = "ruby.height",
  type = "string",
  default = "1zw",
  help = "Vertical offset between the ruby and the main text"
  })

SILE.registerCommand("ruby", function (options, content)
  local reading = SU.required(options, "reading", "\\ruby")
  SILE.typesetter:setpar("")
  SILE.call("hbox", {}, function ()
    SILE.settings.temporarily(function ()
      SILE.call("noindent")
      SILE.call("ruby:font")
      SILE.typesetter:typeset(reading)
    end)
  end)
  local rubybox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  rubybox.outputYourself = function (self, typesetter, line)
    local ox = typesetter.frame.state.cursorX
    local oy = typesetter.frame.state.cursorY
    typesetter.frame:advanceWritingDirection(rubybox.width)
    typesetter.frame:advancePageDirection(-SILE.toPoints(SILE.settings.get("ruby.height")))
    SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
    for i = 1, #(self.value) do
      local node = self.value[i]
      node:outputYourself(typesetter, line)
    end
    typesetter.frame.state.cursorX = ox
    typesetter.frame.state.cursorY = oy
  end
  -- measure the content
  SILE.call("hbox", {}, content)
  cbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SU.debug("ruby", "base box is " .. cbox)
  SU.debug("ruby", "reading is  " .. rubybox)
  if cbox:lineContribution() > rubybox:lineContribution() then
    SU.debug("ruby", "Base is longer, offsetting ruby to fit")
    -- This is actually the offset against the base
    rubybox.width = SILE.length.make(cbox:lineContribution() - rubybox:lineContribution()).length/2
  else
    local diff = rubybox:lineContribution() - cbox:lineContribution()
    if type(diff) == "table" then diff = diff.length end
    local to_insert = SILE.length.new({ length = diff / 2 })
    SU.debug("ruby", "Ruby is longer, inserting " .. to_insert .. " either side of base")
    cbox.width = SILE.length.make(rubybox:lineContribution())
    rubybox.width = 0
    -- add spaces at beginning and end
    table.insert(cbox.value, 1, SILE.nodefactory.newGlue({ width = to_insert }))
    table.insert(cbox.value, SILE.nodefactory.newGlue({ width = to_insert }))
  end
end)
