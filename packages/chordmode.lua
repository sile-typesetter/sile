local inputfilter = SILE.require("packages/inputfilter").exports

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
    end;
    ["\n"] = function(separator)
      insertChord()
      currentText = separator
      process = processText
    end
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

