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
  local ot = SILE.require("core/opentype-parser")
  local fontoptions = SILE.font.loadDefaults({})
  local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  local upem = font.head.unitsPerEm
  local underlinePosition = -font.post.underlinePosition / upem * fontoptions.size
  local underlineThickness = font.post.underlineThickness / upem * fontoptions.size

  local hbox = SILE.call("hbox", {}, content)
  table.remove(SILE.typesetter.state.nodes) -- steal it back...

  -- Re-wrap the hbox in another hbox responsible for boxing it at output
  -- time, when we will know the line contribution and can compute the scaled width
  -- of the box, taking into account possible stretching and shrinking.
  SILE.typesetter:pushHbox({
    inner = hbox,
    width = hbox.width,
    height = hbox.height,
    depth = hbox.depth,
    outputYourself = function(self, typesetter, line)
      local oldX = typesetter.frame.state.cursorX
      local Y = typesetter.frame.state.cursorY

      -- Build the original hbox.
      -- Cursor will be moved by the actual definitive size.
      self.inner:outputYourself(SILE.typesetter, line)
      local newX = typesetter.frame.state.cursorX

      -- Output a line.
      -- NOTE: According to the OpenType specs, underlinePosition is "the suggested distance of
      -- the top of the underline from the baseline" so it seems implied that the thickness
      -- should expand downwards
      SILE.outputter:drawRule(oldX, Y + underlinePosition, newX - oldX, underlineThickness)
    end
  })
end, "Underlines some content")

SILE.registerCommand("boxaround", function (_, content)
  -- This command was not documented and lacks feature.
  -- Plan replacement with a better suited package.
  SU.deprecated("\\boxaround (undocumented)", "\\framebox (package)", "0.12.0", "0.13.0")

  local hbox = SILE.call("hbox", {}, content)
  table.remove(SILE.typesetter.state.nodes) -- steal it back...

  -- Re-wrap the hbox in another hbox responsible for boxing it at output
  -- time, when we will know the line contribution and can compute the scaled width
  -- of the box, taking into account possible stretching and shrinking.
  SILE.typesetter:pushHbox({
    inner = hbox,
    width = hbox.width,
    height = hbox.height,
    depth = hbox.depth,
    outputYourself = function(self, typesetter, line)
      local oldX = typesetter.frame.state.cursorX
      local Y = typesetter.frame.state.cursorY

      -- Build the original hbox.
      -- Cursor will be moved by the actual definitive size.
      self.inner:outputYourself(SILE.typesetter, line)
      local newX = typesetter.frame.state.cursorX

      -- Output a border
      -- NOTE: Drawn inside the hbox, so borders overlap with inner content.
      local w = newX - oldX
      local h = self.height:tonumber()
      local d = self.depth:tonumber()
      local thickness = 0.5

      SILE.outputter:drawRule(oldX, Y + d - thickness, w, thickness)
      SILE.outputter:drawRule(oldX, Y - h, w, thickness)
      SILE.outputter:drawRule(oldX, Y - h, thickness, h + d)
      SILE.outputter:drawRule(oldX + w - thickness, Y - h, thickness, h + d)
    end
  })
end, "Draws a box around some content")

return { documentation = [[\begin{document}
The \autodoc:package{rules} package draws lines. It provides three commands.

The first command is \autodoc:command{\hrule},
which draws a line of a given length and thickness, although it calls these
\autodoc:parameter{width} and \autodoc:parameter{height}. (A box is just a square line.)

Lines are treated just like other text to be output, and so can appear in the
middle of a paragraph, like this: \hrule[width=20pt, height=0.5pt] (that one
was generated with \autodoc:command{\hrule[width=20pt, height=0.5pt]}.)

Like images, rules are placed along the baseline of a line of text.

The second command provided by this package is \autodoc:command{\underline}, which
underlines its contents.

\note{
Underlining is horrible typographic practice, and
you should \underline{never} do it.}

(That was produced with \autodoc:command{\underline{never}}.)

Finally, \autodoc:command{\fullrule} draws a thin line across the width of the current frame.
\end{document}]] }
