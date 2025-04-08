local base = require("packages.base")

local package = pl.class(base)
package._name = "chordmode"

function package:_init ()
   base._init(self)
   self:loadPackage("raiselower")
   self:loadPackage("inputfilter")
end

function package:declareSettings ()
   SILE.settings:declare({
      parameter = "chordmode.offset",
      type = "length",
      default = SILE.types.length("2ex"),
      help = "Vertical offset between the chord name and the text.",
   })
end

function package:registerCommands ()
   self:registerCommand("ch", function (options, content)
      local chordBox = SILE.typesetter:makeHbox(function ()
         SILE.call("chordmode:chordfont", {}, { options.name })
      end)
      local origWidth = chordBox.width
      chordBox.width = SILE.types.length()

      SILE.call("raise", { height = SILE.settings:get("chordmode.offset") }, function ()
         SILE.typesetter:pushHbox(chordBox)
      end)

      local lyricBox = SILE.call("hbox", {}, content)
      if lyricBox.width < origWidth then
         lyricBox.width = origWidth + SILE.types.length("0.5em"):absolute()
      end
      local chordLineHeight = chordBox.height + SILE.settings:get("chordmode.offset"):absolute()
      if chordLineHeight > lyricBox.height then
         lyricBox.height = chordLineHeight
      end
   end, "Insert a chord name above the text")

   local function _addChords (text, content)
      local result = {}
      local chordName
      local currentText = ""
      local process
      local processText, processChordName, processChordText

      local function insertChord ()
         table.insert(
            result,
            self.class.packages.inputfilter:createCommand(
               content.pos,
               content.col,
               content.lno,
               "ch",
               { name = chordName },
               currentText
            )
         )
         chordName = nil
      end

      local function insertText ()
         if #currentText > 0 then
            table.insert(result, currentText)
         end
         currentText = ""
      end

      local function ignore (separator)
         currentText = currentText .. separator
      end

      processText = {
         ["<"] = function (_)
            insertText()
            process = processChordName
         end,
      }

      processChordName = {
         [">"] = function (_)
            chordName = currentText
            currentText = ""
            process = processChordText
         end,
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
         if token.string then
            currentText = currentText .. token.string
         else
            (process[token.separator] or ignore)(token.separator)
         end
      end

      if chordName ~= nil then
         insertChord()
      else
         insertText()
      end
      return result
   end

   self:registerCommand("chordmode", function (_, content)
      SILE.process(self.class.packages.inputfilter:transformContent(content, _addChords))
   end, "Transform embedded chords to 'ch' commands")

   self:registerCommand("chordmode:chordfont", function (_, content)
      SILE.process(content)
   end, "Override this command to change chord style.")
end

package.documentation = [[
\begin{document}
\use[module=packages.chordmode]
This package provides the \autodoc:environment{chordmode} environment, which transforms lines like:

\begin{verbatim}
  I’ve be<G>en a wild rover for many’s a <C>year
\end{verbatim}

into:

\begin{autodoc:example}
\begin{chordmode}
  I’ve be<G>en a wild rover for many’s a <C>year
\end{chordmode}
\par
\end{autodoc:example}

The chords can be styled by redefining the \autodoc:command{\chordmode:chordfont} command, and the offset between the chord name and text adjusted with the \autodoc:setting{chordmode.offset} setting.
\end{document}
]]

return package
