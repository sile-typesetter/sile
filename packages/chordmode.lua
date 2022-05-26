local inputfilter = require("packages.inputfilter").exports

local function addChords(text, content)
  local result = {}
  local chordName
  local currentText = ""
  local process
  local processText, processChordName, processChordText

  local function insertChord()
    table.insert(result, inputfilter.createCommand(
      content.pos, content.col, content.line,
      "ch", { name = chordName }, currentText
    ))
    chordName = nil
  end

  local function insertText()
    if #currentText > 0 then table.insert(result, currentText) end
    currentText = ""
  end

  local function ignore(separator)
    currentText = currentText .. separator
  end

  processText = {
    ["<"] = function (_)
      insertText()
      process = processChordName
    end
  }

  processChordName = {
    [">"] = function (_)
      chordName = currentText
      currentText = ""
      process = processChordText
    end
  }

  processChordText = {
    ["<"] = function (_)
      insertChord()
      currentText = ""
      process = processChordName
    end,
    ["\n"] = function (separator)
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

local function init (class, _)

  class:loadPackage("raiselower")

  SILE.settings:declare({
    parameter = "chordmode.offset",
    type = "length",
    default = SILE.length("2ex"),
    help = "Vertical offset between the chord name and the text."
  })

  SILE.settings:declare({
    parameter = "chordmode.lineheight",
    type = "length",
    default = SILE.length("4mm"),
    help = "Length of the chord name line."
  })

end

local function registerCommands (_)

  SILE.registerCommand("ch", function (options, content)
    local chordBox = SILE.call("hbox", {}, { options.name })
    SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil
    local origWidth = chordBox.width
    chordBox.width = SILE.length()
    chordBox.height = SILE.settings:get("chordmode.lineheight")
    SILE.call("raise", { height = SILE.settings:get("chordmode.offset") }, function ()
      SILE.call("chordmode:chordfont", {}, function ()
        SILE.typesetter:pushHbox(chordBox)
      end)
    end)
    local lyricBox = SILE.call("hbox", {}, content)
    if lyricBox.width < origWidth then
      lyricBox.width = origWidth + SILE.length("0.5em"):absolute()
    end
  end, "Insert a chord name above the text")

  SILE.registerCommand("chordmode", function (_, content)
    SILE.process(inputfilter.transformContent(content, addChords))
  end, "Transform embedded chords to 'ch' commands")

  SILE.registerCommand("chordmode:chordfont", function (_, content)
    SILE.process(content)
  end, "Override this command to change chord style.")

end

return {
  init = init,
  registerCommands = registerCommands,
  documentation = [[
\begin{document}
\script[src=packages/chordmode]

This package provides the \autodoc:environment{chordmode} environment, which transforms
lines like:

\begin{verbatim}
  I’ve be<G>en a wild rover for many’s a <C>year
\end{verbatim}

into:

\begin{chordmode}
  I’ve be<G>en a wild rover for many’s a <C>year
\end{chordmode}
\par

The chords can be styled by redefining the \autodoc:command{\chordmode:chordfont}
command, and the offset between the chord name and text set with the
\autodoc:setting{chordmode.offset} setting.

\end{document}
]]
}
