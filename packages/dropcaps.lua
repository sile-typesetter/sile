SILE.require("packages/rebox")
SILE.require("packages/raiselower")

local shapeHbox = function (options, initial)
  -- Clear irrelevant values before passing to font
  options.lines, options.join, options.initial = nil, nil, nil
  SILE.call("noindent")
  local hbox = SILE.call("hbox", {}, function ()
    SILE.call("font", options, { initial })
  end)
  table.remove(SILE.typesetter.state.nodes)
  return hbox
end

-- This implementation relies on the hangafter and hangindent features of Knuth's line-breaking algorithm.
-- These features in core line breaking algorithm supply the blank space in the paragraph shape but don't fill it with anything.
SILE.registerCommand("dropcap", function (options, content)
  local lines = SU.cast("integer", options.lines or 3)
  local join = SU.boolean(options.join, false)
  local initial = SU.required(options, "initial", "dropcap")

  -- We want the drop cap to spanning N lines is N-1 baselineskip plus the height of the first line.
  -- We Define the height of the first line based on measuring the size the initial would have been.
  local tmpHbox = shapeHbox(options, initial)
  local extraHeight = SILE.length((lines - 1).."bs"):tonumber()
  local targetHeight = tmpHbox.height:tonumber() + extraHeight
  SU.debug("dropcaps", "Target height", targetHeight)

  -- Now we need to figure out how to scale the dropcap font to get an initial of targetHeight.
  -- From that we can also figure out the width it will be at that height.
  local curSize = SILE.length(SILE.settings.get("font.size")):tonumber()
  local curHeight, curWidth = tmpHbox.height:tonumber(), tmpHbox.width:tonumber()
  local targetSize = targetHeight / curHeight * curSize
  local targetWidth = curWidth / curSize * targetSize
  SU.debug("dropcaps", "Target font size", targetSize)
  SU.debug("dropcaps", "Target width", targetWidth)

  -- Typeset the dropcap with its final shape, but don't output it yet
  options.size = targetSize
  local hbox = shapeHbox(options, initial)

  -- Setup up the necessary indents for the final paragraph content
  local joinOffset = SILE.length(join and "1spc" or 0):tonumber()
  SILE.settings.set("linebreak.hangAfter", -lines)
  SILE.settings.set("linebreak.hangIndent", targetWidth + joinOffset)
  SU.debug("dropcaps", "joinOffset", joinOffset)

  -- The paragraph is indented so as to leave enough space for the drop cap.
  -- We "trick" the typesetter with a zero-dimension box wrapping our original box.
  SILE.call("rebox", { height = 0, width = -joinOffset }, function ()
    SILE.call("glue", { width = -(targetWidth + joinOffset) })
    SILE.call("lower", { height = extraHeight }, function ()
      SILE.typesetter:pushHbox(hbox)
    end)
  end)

  -- And finally process the content and finish the paragraph
  SILE.process(content)
end, "Show an 'initial capital' (also known as a 'drop cap') at the start of the content paragraph.")

return {
  documentation = [[
\begin{document}
The \code{dropcaps} package allows you to format paragraphs with an 'initial capital' (also commonly
referred as a 'drop cap'), that is, a large capital, typically one letter, used
as a decorative element at the beginning of a paragraph.

It provides the \code{\\dropcap} command, which takes as options the number of lines the initial should span,
the font family to use, and the initial character(s) to typeset.
Provide the rest of the paragraph text as content to the command.
Old-style typographers also have the possibility to enable, at their convenience, the join option,
for use when the initial belongs to the first word of the sentence.
In that case, the first line is closer to the initial than subsequent indented lines.
Other options passed to \\dropcap will be passed through to \\font when drawing the initial letter(s).
This may be useful for passing OpenType options or other font preferences.
\end{document}
]] }
