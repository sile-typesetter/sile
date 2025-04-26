local base = require("packages.base")

local package = pl.class(base)
package._name = "dropcaps"

function package:_init ()
   base._init(self)
   self:loadPackage("rebox")
   self:loadPackage("raiselower")
end

function package:declareSettings ()
   SILE.settings:declare({
      parameter = "dropcaps.bsratio",
      type = "number or nil",
      default = nil, -- nil means "use computed value based on font metrics"
      help = "When set, fixed default ratio of the descender with respect to the baseline (around 0.3 in usual fonts).",
   })
end

local function shapeHbox (options, content)
   local hbox = SILE.typesetter:makeHbox(function ()
      SILE.call("font", options, content)
   end)
   return hbox
end

local metrics = require("fontmetrics")
local bsratiocache = {}

local computeBaselineRatio = function ()
   local fontoptions = SILE.font.loadDefaults({})
   local bsratio = bsratiocache[SILE.font._key(fontoptions)]
   if not bsratio then
      local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
      local m = metrics.get_typographic_extents(face)
      bsratio = m.descender / (m.ascender + m.descender)
      bsratiocache[SILE.font._key(fontoptions)] = bsratio
   end
   return bsratio
end

local function getToleranceDepth ()
   -- In non-strict mode, we allow using more lines to fit the dropcap.
   -- However we cannot just check if the "extra depth" of the dropcap is above 0.
   -- First, our depth adjustment is but a best attempt.
   -- Moreover, some characters may have a small depth of their own (ex. "O" in Gentium Plus)
   -- We must just ensure they stay within "reasonable bounds" with respect to the baseline,
   -- so as not to flow over the next lines.
   -- We compute a tolerance ratio based on the font metrics, expecting the font to be well-designed.
   -- The user can override the computation and set the dropcaps.bsratio setting manually.
   -- (LaTeX would likely approximate it using a \strut = with a depth ratio of 0.3bs)
   local bsratio
   if SILE.settings:get("dropcaps.bsratio") then
      bsratio = SILE.settings:get("dropcaps.bsratio")
      SU.debug("dropcaps", "Using user-defined descender baseline ratio", bsratio)
   else
      bsratio = computeBaselineRatio()
      SU.debug("dropcaps", "Using computed descender baseline ratio", bsratio)
   end
   return bsratio * SILE.types.measurement("1bs"):tonumber()
end

function package:registerCommands ()
   -- This implementation relies on the hangafter and hangindent features of Knuth's line-breaking algorithm.
   -- These features in core line breaking algorithm supply the blank space in the paragraph shape but don't fill it with anything.
   self:registerCommand("dropcap", function (options, content)
      local lines = SU.cast("integer", options.lines or 3)
      local join = SU.boolean(options.join, false)
      local standoff = SU.cast("measurement", options.standoff or "1spc")
      local raise = SU.cast("measurement", options.raise or 0)
      local shift = SU.cast("measurement", options.shift or 0)
      local size = SU.cast("measurement or nil", options.size or nil)
      local scale = SU.cast("number", options.scale or 1.0)
      local strict = SU.boolean(options.strict, true)
      if strict and options.depthadjust then
         SU.warn("The depthadjust option is ignored in strict mode")
      end
      local color = options.color
      -- We need to measure the "would have been" size before using this.
      options.size = nil
      -- Clear irrelevant option values before passing to font and measuring content.
      options.lines, options.join, options.raise, options.shift, options.color, options.scale =
         nil, nil, nil, nil, nil, nil

      if color then
         self:loadPackage("color")
      end

      -- Some initial capital fonts have all their glyphs hanging below the baseline (e.g. EB Garamond Initials)
      -- We cannot manage all pathological cases.
      -- Quite empirically, we can shape character(s) which shouldn't usually have a depth normally.
      -- If it has, then likely all glyphs do also and we need to compensate for that everywhere.
      local depthadjust = options.depthadjust or "I"
      local depthAdjustment = not strict and shapeHbox(options, { depthadjust }).depth:tonumber() or 0
      SU.debug("dropcaps", "Depth adjustment", depthAdjustment)

      -- We want the drop cap to span over N lines, that is N - 1 baselineskip + the height of the first line.
      -- Note this only works for the default linespace mechanism.
      -- We determine the height of the first line by measuring the size the initial content *would have* been.
      local tmpHbox = shapeHbox(options, content)
      local extraHeight = types.measurement((lines - 1) .. "bs"):tonumber()
      local curHeight = tmpHbox.height:tonumber() + depthAdjustment
      local targetHeight = (curHeight - depthAdjustment) * scale + extraHeight
      if strict then
         -- Take into account the compensated depth of the initial
         curHeight = curHeight + tmpHbox.depth:tonumber()
      end
      SU.debug("dropcaps", "Target height", targetHeight)

      -- Now we need to figure out how to scale the dropcap font to get an initial of targetHeight.
      -- From that we can also figure out the width it will be at that height.
      local curSize = types.measurement(settings:get("font.size")):tonumber()
      local curWidth = tmpHbox.width:tonumber()
      options.size = size and size:tonumber() or (targetHeight / curHeight * curSize)
      local targetWidth = curWidth / curSize * options.size
      SU.debug("dropcaps", "Target font size", options.size)
      SU.debug("dropcaps", "Target width", targetWidth)

      -- Typeset the dropcap with its final shape, but don't output it yet.
      local hbox = shapeHbox(options, content)

      if not strict then
         -- Compensation for regular extra depth.
         local compensationHeight = depthAdjustment * options.size / curSize
         SU.debug("dropcaps", "Compensation height", compensationHeight)

         -- Some fonts have descenders on letters such as Q, J, etc.
         -- In that case we may need extra lines to the dropcap.
         local extraDepth = hbox.depth:tonumber() - compensationHeight
         local toleranceDepth = getToleranceDepth()
         if extraDepth > toleranceDepth then
            SU.debug("dropcaps", "Extra depth", extraDepth, "> tolerance", toleranceDepth)
            local extraLines = math.ceil((extraDepth - toleranceDepth) / types.measurement("1bs"):tonumber())
            lines = lines + extraLines
            SU.debug("dropcaps", "Extra lines needed to fit", extraLines)
         else
            SU.debug("dropcaps", "Extra depth", extraDepth, "< tolerance", toleranceDepth)
         end
         raise = raise:tonumber() + compensationHeight
      else
         raise = raise:tonumber() + hbox.depth:tonumber()
      end

      -- Setup up the necessary indents for the final paragraph content
      local joinOffset = join and standoff:tonumber() or 0
      settings:set("current.hangAfter", -lines)
      settings:set("current.hangIndent", targetWidth + joinOffset)
      noindent()
      SU.debug("dropcaps", "joinOffset", joinOffset)

      -- The paragraph is indented so as to leave enough space for the drop cap.
      -- We "trick" the typesetter with a zero-dimension box wrapping our original box.
      rebox({ height = 0, depth = 0, width = -joinOffset }, function ()
         glue({ width = shift - targetWidth - joinOffset })
         lower({ height = extraHeight - raise }, function ()
            call(color and "color" or "noop", { color = color }, function ()
               typesetter:pushHbox(hbox)
            end)
         end)
      end)
   end, "Show an 'initial capital' (also known as a 'drop cap') at the start of the content paragraph.")
end

package.documentation = [[
\begin{document}
\use[module=packages.dropcaps]
The \autodoc:package{dropcaps} package allows you to format paragraphs with an “initial capital” (also commonly referred as a “drop cap”), typically one large capital letter used as a decorative element at the beginning of a paragraph.

It provides the \autodoc:command{\dropcap} command.
The content passed will be the initial character(s).
The primary option is \autodoc:parameter{lines}, an integer specifying the number of lines to span (defaults to \code{3}).
The scale of the characters can be adjusted relative to the first line using the \autodoc:parameter{scale} option (defaults to \code{1.0}).
The \autodoc:parameter{join} parameter is a boolean for whether to join the dropcap to the first line (defaults to \code{false}).
If \autodoc:parameter{join} is \code{true}, the value of the \autodoc:parameter{standoff} option (defaults to \code{1spc}) is applied to all but the first line.
Optionally \autodoc:parameter{color} can be passed to change the typeface color, which is sometimes useful to offset the apparent weight of a large glyph.
To tweak the position of the dropcap, measurements may be passed to the \autodoc:parameter{raise} and \autodoc:parameter{shift} options.
Other options passed to \autodoc:command{\dropcap} will be passed through to \autodoc:command{\font} when drawing the initial letter(s).
This may be useful for passing OpenType options or other font preferences.

Some fonts have capitals — such as, typically, \autodoc:example{Q} and \autodoc:example{J} — hanging below the baseline.
By default, the dropcap fits the specified number of lines and the characters are typeset in a smaller size to fit these descenders.

With the \autodoc:parameter{strict=false} option, the characters are scaled with respect to their height only, and extra hanged lines are added to the dropcap in order to accommodate the descenders.
The dropcap is allowed to overflow the baseline by a reasonable amount, before triggering the addition of extra lines, for fonts that have capitals very slightly hanging below the baseline.
This tolerance is computed based on the font metrics.
If you want to bypass this mechanism and adjust the tolerance, you can use the \autodoc:setting{dropcaps.bsratio} setting.

Moreover, some fonts, such as EB Garamond Initials, have \em{all} capitals hanging below the baseline.
To take this case into account in non-strict mode, the depth adjustment of the dropcap is empirically corrected based on that of a character which shouldn't have any, by default an \autodoc:example{I}.
The character(s) used for this depth adjustment correction can be specified using the \autodoc:parameter{depthadjust} option.

\begin{autodoc:note}
One caveat is that the size of the initials is calculated using the default linespacing mechanism.
If you are using an alternative method from the \autodoc:package{linespacing} package, you might see strange results.
Set the \autodoc:setting{document.baselineskip} to approximate your effective leading value for best results.
If that doesn't work set the size manually.
Using \code{SILE.setCommandDefaults()} can be helpful for so you don't have to set the size every time.
\end{autodoc:note}
\end{document}
]]

return package
