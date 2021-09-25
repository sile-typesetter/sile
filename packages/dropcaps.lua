SILE.require("packages/rebox")
SILE.require("packages/raiselower")

local shapeHbox = function (options, content)
  -- Clear irrelevant values before passing to font
  options.lines, options.join, options.raise, options.shift = nil, nil, nil, nil
  SILE.call("noindent")
  local hbox = SILE.call("hbox", {}, function ()
    SILE.call("font", options, content)
  end)
  table.remove(SILE.typesetter.state.nodes)
  return hbox
end

-- This implementation relies on the hangafter and hangindent features of Knuth's line-breaking algorithm.
-- These features in core line breaking algorithm supply the blank space in the paragraph shape but don't fill it with anything.
SILE.registerCommand("dropcap", function (options, content)
  local lines = SU.cast("integer", options.lines or 3)
  local join = SU.boolean(options.join, false)
  local raise = SU.cast("measurement", options.raise or 0)
  local shift = SU.cast("measurement", options.shift or 0)
  local size = SU.cast("measurement or nil", options.size or nil)
  options.size = nil -- we need to measure the "would have been" size before using this

  -- We want the drop cap to spanning N lines is N-1 baselineskip plus the height of the first line.
  -- We Define the height of the first line based on measuring the size the initial would have been.
  local tmpHbox = shapeHbox(options, content)
  local extraHeight = SILE.measurement((lines - 1).."bs"):tonumber()
  local targetHeight = tmpHbox.height:tonumber() + extraHeight
  SU.debug("dropcaps", "Target height", targetHeight)

  -- Now we need to figure out how to scale the dropcap font to get an initial of targetHeight.
  -- From that we can also figure out the width it will be at that height.
  local curSize = SILE.measurement(SILE.settings.get("font.size")):tonumber()
  local curHeight, curWidth = tmpHbox.height:tonumber(), tmpHbox.width:tonumber()
  options.size = size and size:tonumber() or (targetHeight / curHeight * curSize)
  local targetWidth = curWidth / curSize * options.size
  SU.debug("dropcaps", "Target font size", options.size)
  SU.debug("dropcaps", "Target width", targetWidth)

  -- Typeset the dropcap with its final shape, but don't output it yet
  local hbox = shapeHbox(options, content)

  -- Setup up the necessary indents for the final paragraph content
  local joinOffset = SILE.measurement(join and "1spc" or 0):tonumber()
  SILE.settings.set("linebreak.hangAfter", -lines)
  SILE.settings.set("linebreak.hangIndent", targetWidth + joinOffset)
  SU.debug("dropcaps", "joinOffset", joinOffset)

  -- The paragraph is indented so as to leave enough space for the drop cap.
  -- We "trick" the typesetter with a zero-dimension box wrapping our original box.
  SILE.call("rebox", { height = 0, width = -joinOffset }, function ()
    SILE.call("glue", { width = shift - targetWidth - joinOffset })
    SILE.call("lower", { height = extraHeight - raise }, function ()
      SILE.typesetter:pushHbox(hbox)
    end)
  end)
end, "Show an 'initial capital' (also known as a 'drop cap') at the start of the content paragraph.")

return {
  documentation = [[
\begin{document}
The \code{dropcaps} package allows you to format paragraphs with an 'initial capital' (also commonly
referred as a 'drop cap'), typically one large capital letter used as a decorative element at the beginning of a paragraph.

It provides the \code{\\dropcap} command.
The content passed will be the initial character(s).
The primary option is \code{lines}, an integer specifying the number of lines to span.
The default value is 3.
The \code{join} is a boolean for whether to join the dropcap to the first line, defaults to false.
To tweak the position of the dropcap, measurements may be passed to the \code{raise} and \code{shift} options.
Old-style typographers also have the possibility to enable, at their convenience, the join option,
for use when the initial belongs to the first word of the sentence.
In that case, the first line is closer to the initial than subsequent indented lines.
Other options passed to \\dropcap will be passed through to \\font when drawing the initial letter(s).
This may be useful for passing OpenType options or other font preferences.
\end{document}
]] }
