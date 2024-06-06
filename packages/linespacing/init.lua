local base = require("packages.base")

local package = pl.class(base)
package._name = "linespacing"

local metrics = require("fontmetrics")

local metricscache = {}

local getLineMetrics = function (l)
   local linemetrics = { ascender = 0, descender = 0, lineheight = SILE.types.length() }
   if not l or not l.nodes then
      return linemetrics
   end
   for i = 1, #l.nodes do
      local node = l.nodes[i]
      if node.is_nnode then
         local m = metricscache[SILE.font._key(node.options)]
         if not m then
            local face = SILE.font.cache(node.options, SILE.shaper.getFace)
            m = metrics.get_typographic_extents(face)
            m.ascender = m.ascender * node.options.size
            m.descender = m.descender * node.options.size
            metricscache[SILE.font._key(node.options)] = m
         end
         SILE.settings:temporarily(function ()
            SILE.call("font", node.options, {})
            m.lineheight = SU.cast("length", SILE.settings:get("linespacing.css.line-height")):absolute()
         end)
         if m.ascender > linemetrics.ascender then
            linemetrics.ascender = m.ascender
         end
         if m.descender > linemetrics.descender then
            linemetrics.descender = m.descender
         end
         if m.lineheight > linemetrics.lineheight then
            linemetrics.lineheight = m.lineheight
         end
      end
   end
   return linemetrics
end

local linespacingLeading = function (_, vbox, previous)
   local method = SILE.settings:get("linespacing.method")

   local firstline = SILE.settings:get("linespacing.minimumfirstlineposition"):absolute()
   if not previous then
      if firstline.length:tonumber() > 0 then
         local toAdd = SILE.types.length(firstline.length - vbox.height)
         return SILE.types.node.vkern(toAdd)
      else
         return nil
      end
   end

   if method == "tex" then
      return SILE.typesetters.base:leadingFor(vbox, previous)
   end

   if method == "fit-glyph" then
      local extra = SILE.settings:get("linespacing.fit-glyph.extra-space"):absolute()
      local toAdd = SILE.types.length(extra)
      return SILE.types.node.vglue(toAdd)
   end

   if method == "fixed" then
      local btob = SILE.settings:get("linespacing.fixed.baselinedistance"):absolute()
      local toAdd = SILE.types.length(btob.length - (vbox.height + previous.depth), btob.stretch, btob.shrink)
      return SILE.types.node.vglue(toAdd)
   end

   -- For these methods, we need to read the font metrics
   if not metrics then
      SU.error("'" .. method .. "' line spacing method requires font metrics module, which is not available.")
   end

   local thismetrics = getLineMetrics(vbox)
   local prevmetrics = getLineMetrics(previous)
   if method == "fit-font" then
      -- Distance to next baseline is max(descender) of fonts on previous +
      -- max(ascender) of fonts on next
      local extra = SILE.settings:get("linespacing.fit-font.extra-space"):absolute()
      local btob = prevmetrics.descender + thismetrics.ascender + extra
      local toAdd = btob - (vbox.height + (previous and previous.depth or 0))
      return SILE.types.node.vglue(toAdd)
   end

   if method == "css" then
      local lh = prevmetrics.lineheight
      local leading = (lh - (prevmetrics.ascender + prevmetrics.descender))
      if previous then
         previous.height = previous.height + leading / 2
         previous.depth = previous.depth + leading / 2
      end
      return SILE.types.node.vglue()
   end

   SU.error("Unknown line spacing method " .. method)
end

function package:_init ()
   base._init(self)
   self.class:registerPostinit(function (_)
      SILE.typesetter.leadingFor = linespacingLeading
   end)
end

function package.declareSettings (_)
   SILE.settings:declare({
      parameter = "linespacing.method",
      default = "tex",
      type = "string",
      help = "How to set the line spacing (tex, fixed, fit-font, fit-glyph, css)",
   })

   SILE.settings:declare({
      parameter = "linespacing.fixed.baselinedistance",
      default = SILE.types.length("1.2em"),
      type = "length",
      help = "Distance from baseline to baseline in the case of fixed line spacing",
   })

   SILE.settings:declare({
      parameter = "linespacing.minimumfirstlineposition",
      default = SILE.types.length(0),
      type = "length",
   })

   SILE.settings:declare({
      parameter = "linespacing.fit-glyph.extra-space",
      default = SILE.types.length(0),
      type = "length",
   })

   SILE.settings:declare({
      parameter = "linespacing.fit-font.extra-space",
      default = SILE.types.length(0),
      type = "length",
   })

   SILE.settings:declare({
      parameter = "linespacing.css.line-height",
      default = SILE.types.length("1.2em"),
      type = "length",
   })
end

function package:registerCommands ()
   self:registerCommand("linespacing-on", function ()
      SILE.typesetter.leadingFor = linespacingLeading
   end)

   self:registerCommand("linespacing-off", function ()
      SILE.typesetter.leadingFor = SILE.typesetters.base.leadingFor
   end)
end

package.documentation = [[
\begin{document}
\linespacing-on
SILE’s default method of inserting leading between lines should be familiar to users of TeX, but it is not the most friendly system for book designers.
The \autodoc:package{linespacing} package provides a better choice of leading systems.

After loading the package, you are able to choose the linespacing mode by setting the \autodoc:setting{linespacing.method} parameter.
The following examples have funny sized words in them so that you can see how the different methods interact.

By default, this is set to \code{tex}. The other options available are:

\medskip
\set[parameter=linespacing.method,value=fixed]
\set[parameter=linespacing.fixed.baselinedistance,value=1.5em]
\begin{itemize}
\item{\code{fixed}. This set the lines at a fixed baseline-to-baseline distance, determined by the \autodoc:setting{linespacing.fixed.baselinedistance} parameter.
You can specify this parameter either relative to the type size (\code{1.2em}) or as a absolute distance (\code{15pt}).
This paragraph is set with a fixed 1.5em baseline-to-baseline distance.}
\end{itemize}

\medskip
\set[parameter=linespacing.method,value=fit-glyph]
\begin{itemize}
\item{\code{fit-glyph}. This sets the lines solid; that is, the lowest point on line 1 (either a descender like \font[size=20pt]{q} or, if there are no descenders, the baseline) will touch the \font[size=20pt]{highest} point of line 2, as in this paragraph.
You generally don’t want to use this as-is.}
\end{itemize}

\set[parameter=linespacing.fit-glyph.extra-space,value=5pt]

What you probably want to do is insert a constant (relative or absolute) s\font[size=20pt]{p}ace between the lines by setting the \autodoc:setting{linespacing.fit-glyph.extra-space} parameter.
\font[size=20pt]{T}his paragraph is set with 5 points of space between the descenders and the ascenders.

\medskip
\set[parameter=linespacing.method,value=fit-font]
\begin{itemize}
\item{\code{fit-font}. This inspects each \code{hbox} on the line, and asks the fonts it finds for their bounding boxes—the highest ascender and the lower descender.
It then sets the lines solid.
Essentially each character is treated as if it is the same height, rather like composing a slug of metal type.
If there are things other than text on your line, or the text is buried inside other boxes, this may not work well.}
\end{itemize}

\set[parameter=linespacing.fit-font.extra-space,value=5pt]

As with \code{fit-glyph}, you can insert extra space between the lines with the \autodoc:setting{linespacing.fit-font.extra-space} parameter.

\medskip
\set[parameter=linespacing.method,value=css]
\set[parameter=linespacing.css.line-height,value=2em]
\begin{itemize}
\item{\code{css}. This is similar to the method used in browsers; the baseline distance is set with the \autodoc:setting{linespacing.css.line-height} parameter, and the excess \font[size=20pt]{space} between this parameter and the actual height of the line is distributed between the top and bottom of the line.}
\end{itemize}
\medskip

\linespacing-off
\end{document}
]]

return package
