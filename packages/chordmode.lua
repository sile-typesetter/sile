local inputfilter = SILE.require("packages/inputfilter").exports

SILE.require("packages/raiselower")

local function addChords(text, content)
  local result = {}
  local chordName = nil
  local currentText = ""
  local process = nil
  local processText, processChordName, processChordText

  local function insertChord()
    table.insert(result, inputfilter.createCommand(
      content.pos, content.col, content.line,
      "ch", {name=chordName}, currentText
    ))
    chordName = nil
  end

  local function insertText()
    if (#currentText>0) then table.insert(result, currentText) end
    currentText = ""
  end

  local function ignore(separator)
    currentText = currentText .. separator
  end

  processText = {
    ["<"] = function(separator)
      insertText()
      process = processChordName
    end
  }

  processChordName = {
    [">"] = function(separator)
      chordName = currentText
      currentText = ""
      process = processChordText
    end
  }

  processChordText = {
    ["<"] = function(separator)
      insertChord()
      currentText = ""
      process = processChordName
    end,
    ["\n"] = function(separator)
      insertChord()
      currentText = separator
      process = processText
    end,
  }
  process = processText

  for token in SU.gtoke(text, "[<\n>]") do
    if(token.string) then
      currentText = currentText .. token.string
    else
      (process[token.separator] or ignore)(token.separator)
    end
  end

  if (chordName ~= nil) then
    insertChord()
  else
    insertText()
  end
  return result
end

SILE.registerCommand("ch", function(options, content)
  local chordBox = SILE.Commands["hbox"]({}, {options.name})
  SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil

  local chordLineHeight = SILE.toPoints("4", "mm", "h")
  local origWidth = chordBox.width
  chordBox.width = SILE.length.zero
  chordBox.height = SILE.settings.get("chordmode.lineheight")

  SILE.call("raise", {height = SILE.settings.get("chordmode.offset")}, function()
    SILE.call("chordmode:chordfont", {}, function ()
      SILE.typesetter:pushHbox(chordBox)
    end)
  end)
  local lyricBox = SILE.Commands["hbox"]({}, content)
  if lyricBox.width < origWidth then
    lyricBox.width = origWidth + SILE.toPoints("0.5em")
  end

end, "Insert a a chord name above the text")

SILE.registerCommand("chordmode", function(options, content)
  SILE.process(inputfilter.transformContent(content, addChords))
end, "Transform embedded chords to 'ch' commands")

SILE.registerCommand("chordmode:chordfont", function(options, content)
  SILE.process(content)
end, "Override this command to change chord style.")

SILE.settings.declare({
  name = "chordmode.offset",
  type = "string",
  default = "2ex",
  help = "Vertical offset between the chord name and the text."
})

SILE.settings.declare({
  name = "chordmode.lineheight",
  type = "Length",
  default = SILE.length.parse("4mm"),
  help = "Length of the chord name line."
})


