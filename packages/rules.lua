SILE.baseClass:loadPackage("raiselower")
SILE.baseClass:loadPackage("rebox")

SILE.registerCommand("hrule", function (options, _)
  local width = SU.cast("length", options.width)
  local height = SU.cast("length", options.height)
  local depth = SU.cast("length", options.depth)
  SILE.typesetter:pushHbox({
    width = width:absolute(),
    height = height:absolute(),
    depth = depth:absolute(),
    value = options.src,
    outputYourself= function (self, typesetter, line)
      local outputWidth = SU.rationWidth(self.width, self.width, line.ratio)
      typesetter.frame:advancePageDirection(-self.height)
      local oldx = typesetter.frame.state.cursorX
      local oldy = typesetter.frame.state.cursorY
      typesetter.frame:advanceWritingDirection(outputWidth)
      typesetter.frame:advancePageDirection(self.height + self.depth)
      local newx = typesetter.frame.state.cursorX
      local newy = typesetter.frame.state.cursorY
      SILE.outputter:drawRule(oldx, oldy, newx - oldx, newy - oldy)
    end
  })
end, "Creates a line of width <width> and height <height>")

SILE.registerCommand("fullrule", function (options, _)
  SILE.call("raise", { height = options.raise or "0.5em" }, function ()
    SILE.call("hrule", {
        height = options.height or "0.2pt",
        width = options.width or "100%lw"
      })
  end)
end, "Draw a full width hrule centered on the current line")

SILE.registerCommand("underline", function (_, content)
  local hbox = SILE.call("hbox", {}, content)
  local gl = SILE.length() - hbox.width
  SILE.call("lower", {height = "0.5pt"}, function()
    SILE.call("hrule", {width = gl.length, height = "0.5pt"})
  end)
  SILE.typesetter:pushGlue({width = hbox.width})
end, "Underlines some content (badly)")

SILE.registerCommand("boxaround", function (_, content)
  local hbox = SILE.call("hbox", {}, content)
  local gl = SILE.length() - hbox.width
  SILE.call("rebox", {width = 0}, function()
    SILE.call("hrule", {width = gl.length-1, height = "0.5pt"})
  end)
  SILE.call("raise", {height = hbox.height}, function ()
    SILE.call("hrule", {width = gl.length-1, height = "0.5pt"})
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
