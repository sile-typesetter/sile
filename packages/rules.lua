SILE.baseClass:loadPackage("raiselower")
SILE.baseClass:loadPackage("rebox")

SILE.registerCommand("hrule", function(options, content)
  local width = options.width or 0
  local height = options.height or 0
  SILE.typesetter:pushHbox({
    width= SILE.length.new({length = SILE.parseComplexFrameDimension(width,"w") }),
    height= SILE.length.new({ length = SILE.parseComplexFrameDimension(height,"h") }),
    depth= 0,
    value= options.src,
    outputYourself= function (self, typesetter, line)
      local scaledWidth = self.width.length
      if line.ratio < 0 and self.width.shrink > 0 then
        scaledWidth = scaledWidth + self.width.shrink * line.ratio
      elseif line.ratio > 0 and self.width.stretch > 0 then
        scaledWidth = scaledWidth + self.width.stretch * line.ratio
      end

      SILE.outputter.rule(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-(self.height.length), scaledWidth, self.height.length+self.depth)
      typesetter.frame:advanceWritingDirection(scaledWidth)
    end
  })
end, "Creates a line of width <width> and height <height>")

SILE.registerCommand("fullrule", function (options, content)
  SILE.call("raise", { height = options.raise or "0.5em" }, function ()
    SILE.call("hrule", {
        height = options.height or "0.2pt",
        width = options.width or "100%lw"
      })
  end)
end, "Draw a full width hrule centered on the current line")

SILE.registerCommand("underline", function(options, content)
  local hbox = SILE.Commands["hbox"]({}, content)
  local gl = SILE.length.new() - hbox.width
  SILE.Commands["lower"]({height = "0.5pt"}, function()
    SILE.Commands["hrule"]({width = gl.length, height = "0.5pt"})
  end)
  SILE.typesetter:pushGlue({width = hbox.width})
end, "Underlines some content (badly)")

SILE.registerCommand("boxaround", function (options, content)
  local hbox = SILE.Commands["hbox"]({}, content)
  local gl = SILE.length.new() - hbox.width
  SILE.Commands["rebox"]({width = 0}, function()
    SILE.Commands["hrule"]({width = gl.length-1, height = "0.5pt"})
  end)
  SILE.Commands["raise"]({height = hbox.height}, function()
    SILE.Commands["hrule"]({width = gl.length-1, height = "0.5pt"})
  end)
  SILE.call("hrule", { height = hbox.height, width = "0.5pt"})
  SILE.typesetter:pushGlue({width = hbox.width})
  SILE.call("hrule", { height = hbox.height, width = "0.5pt"})
end, "Draws a box around some content")

return { documentation = [[\begin{document}
The \code{rules} package draws lines. It provides three commands.

The first command is \code{\\hrule},
which draws a line of a given length and thickness, although it calls these
\code{width} and \code{height}. (A box is just a square line.)

Lines are treated just like other text to be output, and so can appear in the
middle of a paragraph, like this: \hrule[width=20pt, height=0.5pt] (that one
was generated with \code{\\hrule[width=20pt, height=0.5pt]}.)

Like images, rules are placed along the baseline of a line of text.

The second command provided by \code{rules} is \code{\\underline}, which
underlines its contents.

\note{
Underlining is horrible typographic practice, and
you should \underline{never} do it.}

(That was produced with \code{\\underline\{never\}}.)

Finally, \code{fullrule} draws a thin line across the width of the current frame.
\end{document}]] }
