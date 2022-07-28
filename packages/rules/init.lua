local base = require("packages.base")

local package = pl.class(base)
package._name = "rules"

local function getUnderlineParameters ()
  local ot = require("core.opentype-parser")
  local fontoptions = SILE.font.loadDefaults({})
  local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  local upem = font.head.unitsPerEm
  local underlinePosition = font.post.underlinePosition / upem * fontoptions.size
  local underlineThickness = font.post.underlineThickness / upem * fontoptions.size
  return underlinePosition, underlineThickness
end

local function getStrikethroughParameters ()
  local ot = require("core.opentype-parser")
  local fontoptions = SILE.font.loadDefaults({})
  local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  local upem = font.head.unitsPerEm
  local yStrikeoutPosition = font.os2.yStrikeoutPosition / upem * fontoptions.size
  local yStrikeoutSize = font.os2.yStrikeoutSize / upem * fontoptions.size
  return yStrikeoutPosition, yStrikeoutSize
end

-- \hfill (from the "plain" class) and \leaders (from the "leaders" package) use glues,
-- so we behave the same for hrulefill.
local hrulefillglue = pl.class(SILE.nodefactory.hfillglue)
hrulefillglue.raise = SILE.measurement()
hrulefillglue.thickness = SILE.measurement("0.2pt")

function hrulefillglue:outputYourself (typesetter, line)
  local outputWidth = SU.rationWidth(self.width, self.width, line.ratio):tonumber()
  local oldx = typesetter.frame.state.cursorX
  typesetter.frame:advancePageDirection(-self.raise)
  typesetter.frame:advanceWritingDirection(outputWidth)
  local newx = typesetter.frame.state.cursorX
  local newy = typesetter.frame.state.cursorY
  SILE.outputter:drawRule(oldx, newy, newx - oldx, self.thickness)
  typesetter.frame:advancePageDirection(self.raise)
end

function package:_init ()

  base._init(self)

  self.class:loadPackage("raiselower")
  self.class:loadPackage("rebox")

end

function package:registerCommands ()

  local class = self.class

  class:registerCommand("hrule", function (options, _)
    local width = SU.cast("length", options.width)
    local height = SU.cast("length", options.height)
    local depth = SU.cast("length", options.depth)
    SILE.typesetter:pushHbox({
      width = width:absolute(),
      height = height:absolute(),
      depth = depth:absolute(),
      value = options.src,
      outputYourself = function (node, typesetter, line)
        local outputWidth = SU.rationWidth(node.width, node.width, line.ratio)
        typesetter.frame:advancePageDirection(-node.height)
        local oldx = typesetter.frame.state.cursorX
        local oldy = typesetter.frame.state.cursorY
        typesetter.frame:advanceWritingDirection(outputWidth)
        typesetter.frame:advancePageDirection(node.height + node.depth)
        local newx = typesetter.frame.state.cursorX
        local newy = typesetter.frame.state.cursorY
        SILE.outputter:drawRule(oldx, oldy, newx - oldx, newy - oldy)
        typesetter.frame:advancePageDirection(-node.depth)
      end
    })
  end, "Draws a blob of ink of width <width>, height <height> and depth <depth>")

  class:registerCommand("hrulefill", function (options, _)
    local raise
    local thickness
    if options.position and options.raise then
      SU.error("hrulefill cannot have both position and raise parameters")
    end
    if options.thickness then
      thickness = SU.cast("measurement", options.thickness)
    end
    if options.position == "underline" then
      local underlinePosition, underlineThickness = getUnderlineParameters()
      thickness = thickness or underlineThickness
      raise = underlinePosition
    elseif options.position == "strikethrough" then
      local yStrikeoutPosition, yStrikeoutSize = getStrikethroughParameters()
      thickness = thickness or yStrikeoutSize
      raise = yStrikeoutPosition + thickness / 2
    elseif options.position then
      SU.error("Unknown hrulefill position '"..options.position.."'")
    else
      raise = SU.cast("measurement", options.raise or "0")
    end

    SILE.typesetter:pushExplicitGlue(hrulefillglue({
      raise = raise,
      thickness = thickness or SILE.measurement("0.2pt"),
    }))
  end, "Add a huge horizontal hrule glue")

  class:registerCommand("fullrule", function (options, _)
    local thickness = SU.cast("measurement", options.thickness or "0.2pt")
    local raise = SU.cast("measurement", options.raise or "0.5em")

    -- BEGIN DEPRECATION COMPATIBILITY
    if options.height then
      SU.deprecated("\\fullrule[…, height=…]", "\\fullrule[…, thickness=…]", "0.13.1", "0.15.0")
      thickness = SU.cast("measurement", options.height)
    end
    if not SILE.typesetter:vmode() then
      SU.deprecated("\\fullrule in horizontal mode", "\\hrule or \\hrulefill", "0.13.1", "0.15.0")
      if options.width then
        SU.deprecated("\\fullrule with width", "\\hrule and \\raise", "0.13.1", "0.15.0")
        SILE.call("raise", { height = raise }, function ()
          SILE.call("hrule", {
            height = thickness,
            width = options.width
          })
        end)
      else
        -- This was very broken anyway, as it was overflowing the line.
        -- At least we try better...
        SILE.call("hrulefill", { raise = raise, thickness = thickness })
      end
     return
    end
    if options.width then
      SU.deprecated("\\fullrule with width", "\\hrule and \\raise", "0.13.1 ", "0.15.0")
      SILE.call("raise", { height = raise }, function ()
        SILE.call("hrule", {
          height = thickness,
          width = options.width
        })
      end)
    end
    -- END DEPRECATION COMPATIBILITY

    SILE.typesetter:leaveHmode()
    SILE.call("noindent")
    SILE.call("hrulefill", { raise = raise, thickness = thickness })
    SILE.typesetter:leaveHmode()
  end, "Draw a full width hrule centered on the current line")

  class:registerCommand("underline", function (_, content)
    local underlinePosition, underlineThickness = getUnderlineParameters()

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
      outputYourself = function (node, typesetter, line)
        local oldX = typesetter.frame.state.cursorX
        local Y = typesetter.frame.state.cursorY

        -- Build the original hbox.
        -- Cursor will be moved by the actual definitive size.
        node.inner:outputYourself(SILE.typesetter, line)
        local newX = typesetter.frame.state.cursorX

        -- Output a line.
        -- NOTE: According to the OpenType specs, underlinePosition is "the suggested distance of
        -- the top of the underline from the baseline" so it seems implied that the thickness
        -- should expand downwards
        SILE.outputter:drawRule(oldX, Y - underlinePosition, newX - oldX, underlineThickness)
      end
    })
  end, "Underlines some content")

  class:registerCommand("strikethrough", function (_, content)
    local yStrikeoutPosition, yStrikeoutSize = getStrikethroughParameters()

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
      outputYourself = function (node, typesetter, line)
        local oldX = typesetter.frame.state.cursorX
        local Y = typesetter.frame.state.cursorY
        -- Build the original hbox.
        -- Cursor will be moved by the actual definitive size.
        node.inner:outputYourself(SILE.typesetter, line)
        local newX = typesetter.frame.state.cursorX
        -- Output a line.
        -- NOTE: The OpenType spec is not explicit regarding how the size
        -- (thickness) affects the position. We opt to distribute evenly
        SILE.outputter:drawRule(oldX, Y - yStrikeoutPosition - yStrikeoutSize / 2, newX - oldX, yStrikeoutSize)
      end
    })
  end, "Strikes out some content")

  class:registerCommand("boxaround", function (_, content)
    -- This command was not documented and lacks feature.
    -- Plan replacement with a better suited package.
    SU.deprecated("\\boxaround (undocumented)", "\\framebox (package)", "0.12.0")

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
      outputYourself = function (node, typesetter, line)
        local oldX = typesetter.frame.state.cursorX
        local Y = typesetter.frame.state.cursorY

        -- Build the original hbox.
        -- Cursor will be moved by the actual definitive size.
        node.inner:outputYourself(SILE.typesetter, line)
        local newX = typesetter.frame.state.cursorX

        -- Output a border
        -- NOTE: Drawn inside the hbox, so borders overlap with inner content.
        local w = newX - oldX
        local h = node.height:tonumber()
        local d = node.depth:tonumber()
        local thickness = 0.5

        SILE.outputter:drawRule(oldX, Y + d - thickness, w, thickness)
        SILE.outputter:drawRule(oldX, Y - h, w, thickness)
        SILE.outputter:drawRule(oldX, Y - h, thickness, h + d)
        SILE.outputter:drawRule(oldX + w - thickness, Y - h, thickness, h + d)
      end
    })
  end, "Draws a box around some content")

end

package.documentation = [[
\begin{document}
The \autodoc:package{rules} package provides several line-drawing commands.

The \autodoc:command{\hrule} command draws a blob of ink of a given \autodoc:parameter{width} (length), \autodoc:parameter{height} (above the current baseline) and \autodoc:parameter{depth} (below the current baseline).
Such rules are horizontal boxes, placed along the baseline of a line of text and treated just like other text to be output.
So, they can appear in the middle of a paragraph, like this:
\hrule[width=20pt, height=0.5pt]
(that one was generated with \autodoc:command{\hrule[width=20pt, height=0.5pt]}.)

The \autodoc:command{\underline} command \underline{underlines} its contents.

The \autodoc:command{\strikethrough} command \strikethrough{strikes} its content.

\note{The position and thickness of the underlines and strikethroughs are based on then current font metrics, honoring the values defined by the type designer.}

The \autodoc:command{\hrulefill} inserts an infinite horizontal rubber, similar to an \autodoc:command{\hfill}, but —as its name implies— filled with a rule (that is, a solid line).
By default, it stands on the baseline and has a thickness of 0.2pt, below the baseline.
It supports optional parameters \autodoc:parameter{raise=<dimension>} and \autodoc:parameter{thickness=<dimension>} to adjust the position and thickness of the line, respectively.
The former accepts a negative measurement, to lower the line.
An alternative is to use the \autodoc:parameter{position} option, which can be set to \code{underline} or \code{strikethrough}.
In that case, it honors the current font metrics and the line is drawn at the appropriate position and, by default, with the relevant thickness.
You can still set a custom thickness with the \autodoc:parameter{thickness} parameter.

For instance, \autodoc:command{\hrulefill[position=underline]} gives:
\hrulefill[position=underline]

Finally, \autodoc:command{\fullrule} draws a thin standalone rule across the width of a full text line.
Accepted parameters are \autodoc:parameter{raise} and \autodoc:parameter{thickness}, with the same meanings as above.
\end{document}
]]

return package
