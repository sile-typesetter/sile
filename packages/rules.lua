local function init (class, _)

  class:loadPackage("raiselower")
  class:loadPackage("rebox")

end

local function registerCommands (_)

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
        typesetter.frame:advancePageDirection(-self.depth)
      end
    })
  end, "Draws a blob of ink of width <width>, height <height> and depth <depth>")

  SILE.registerCommand("fullrule", function (options, _)
    SILE.call("raise", { height = options.raise or "0.5em" }, function ()
      SILE.call("hrule", {
          height = options.height or "0.2pt",
          width = options.width or "100%lw"
        })
    end)
  end, "Draw a full width hrule centered on the current line")

  SILE.registerCommand("underline", function (_, content)
    local ot = require("core.opentype-parser")
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

  SILE.registerCommand("strikethrough", function (_, content)
    local ot = SILE.require("core.opentype-parser")
    local fontoptions = SILE.font.loadDefaults({})
    local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
    local font = ot.parseFont(face)
    local upem = font.head.unitsPerEm
    local yStrikeoutSize = font.os2.yStrikeoutSize / upem * fontoptions.size
    local yStrikeoutPosition = font.os2.yStrikeoutPosition / upem * fontoptions.size
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
        SILE.outputter:drawRule(oldX, Y - yStrikeoutPosition, newX - oldX, yStrikeoutSize)
      end
    })
  end, "Strikes out some content")

  SILE.registerCommand("boxaround", function (_, _)
    SU.deprecated("\\boxaround (undocumented)", "\\framebox (package)", "0.12.0", "0.13.0")
  end, "Deprecated")

end

return {
  init = init,
  registerCommands = registerCommands,
  documentation = [[\begin{document}
The \autodoc:package{rules} package provides several line-drawing commands.

The \autodoc:command{\hrule} command draws a blob of ink of a given
\autodoc:parameter{width} (length), \autodoc:parameter{height} (above the
current baseline) and \autodoc:parameter{depth} (below the current baseline).
Such rules are horizontal boxes, placed along the baseline of a line of text and treated
just like other text to be output. So, they can appear in the middle of a paragraph, like this:
\hrule[width=20pt, height=0.5pt] (that one was generated with
\autodoc:command{\hrule[width=20pt, height=0.5pt]}.)

The \autodoc:command{\underline} command \underline{underlines} its contents.

The \autodoc:command{\strikethrough} command \strikethrough{strikes} its content.

\note{
  The position and thickness of the underlines and strikethroughs are based on then
  current font, honoring the values defined by the type designer.
}

Finally, \autodoc:command{\fullrule} draws a thin line across the width of the current frame.
\end{document}]] }
