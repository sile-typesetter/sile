local tools = SILE.require("packages/tools").exports

local function addChords(text, content)
  local start, stop, chord, char
  local index = 1
  local chordText = nil
  local result = {}
  local strlen = string.len(text)
  
  repeat
    start, stop, chord = string.find(text, "<([^>]+)>", index)
    if stop==nil then
      table.insert(result, string.sub(text, index))
      index = strlen+1
    else
      -- Parse a new chord
      if (start-index) > 1 then
        table.insert(result, string.sub(text, index, start - 1 ))
      end
      index = stop + 1
      start, stop, char = string.find(text, "([<\n])", index)
      if stop==nil then
        chordText = string.sub(text, index)
        index = strlen+1
      else
        if(char=='<') then 
          start = start - 1
        end
        chordText = string.sub(text, index, start)
        index = start
      end
      table.insert(result, tools.createCommand(content.pos, content.col, content.line, "ch", {name=chord}, chordText))
    end
  until index > strlen

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
  SILE.process(tools.transformContent(content, addChords))
end, "Transform embedded chords to 'ch' commands")

