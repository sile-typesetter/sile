local inputfilter = SILE.require("packages/inputfilter").exports

SILE.require("packages/color")
SILE.require("packages/raiselower")

local function addChords(text, content)
  local result = {}

  for token in SU.gtoke(text, "<[^>]+>") do
    if (token.string) then
      table.insert(result, token.string)
    else
      local c = string.sub(token.separator, 2, -2)
      table.insert(result, inputfilter.createCommand(
        content.pos, content.col, content.line,
        "ch", {name=c}))
    end
  end
  return result
end

SILE.registerCommand("ch", function(options, content)
  local chordBox = SILE.Commands["hbox"]({}, {options.name})
  SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil

  -- Temporary hard coded values should be configurable
  local offset = SILE.toPoints("2", "ex", "h")
  local chordLineHeight = SILE.toPoints("4", "mm", "h")
  chordBox.width = SILE.length.zero
  chordBox.height = chordLineHeight

  SILE.call("color", {color = "#800000"}, function ()
    SILE.call("raise", {height = offset}, function()
      SILE.typesetter:pushHbox(chordBox)
    end)
  end)
end, "Insert a a chord name above the text")

SILE.registerCommand("chordmode", function(options, content)
  SILE.process(inputfilter.transformContent(content, addChords))
end, "Transform embedded chords to 'ch' commands")

