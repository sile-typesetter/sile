local inputfilter = SILE.require("packages/inputfilter").exports

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
  local offset = SILE.toPoints("2.5", "mm", "h")
  local chordLineHeight = SILE.toPoints("4", "mm", "h")
  local chordBoxHeight = chordLineHeight + 2 * offset
  local heightOffset = chordLineHeight - chordBox.height + offset
  local width = chordBox.width.length

  SILE.typesetter:pushHbox({
    height = chordBoxHeight,
    outputYourself = function (self, typesetter, line)
      typesetter.frame:moveY(-heightOffset)
      SILE.outputter:pushColor({r=0.5, g=0, b=0})
    end
  });
  table.insert(SILE.typesetter.state.nodes, chordBox)
  SILE.typesetter:pushHbox({
    height = chordBoxHeight,
    outputYourself = function (self, typesetter, line)
      typesetter.frame:moveY(heightOffset)
      typesetter.frame:moveX(-width)
      SILE.outputter:popColor()
    end
  });
  SILE.process(content)
end, "Insert a a chord name above the text")

SILE.registerCommand("chordmode", function(options, content)
  SILE.process(inputfilter.transformContent(content, addChords))
end, "Transform embedded chords to 'ch' commands")

