--
-- Paragraph blocks ("parbox") for SILE
-- Or how to wrap width-contrained vboxes into an hbox:
-- A building block for more advanced concepts.
-- 2021-2022 Didier Willis
-- License: MIT
--
-- Known limitations: LTR-TTB writing direction is assumed.
--
local base = require("packages.base")

local package = pl.class(base)
package._name = "parbox"

-- PARBOXING FUNCTIONS

-- Function for building a new temporary frame which only constraint is to
-- honor the target width of the paragraph box. This frame does not have to
-- be registered in SILE.documentState.thisPageTemplate.frames since we will
-- throw it away after boxing.
local nb_ = 1
local function parboxTempFrame (options)
  local id = "parbox_"..nb_
  local newFrame = SILE.newFrame({
    id = id
  })
  nb_ = nb_+1
  newFrame:constrain("top", SILE.length())
  newFrame:constrain("bottom", SILE.length())
  newFrame:constrain("left", SILE.length())
  newFrame:constrain("right", options.width)
  return newFrame
end

-- Function for moving migrating content (e.g. footnotes) from
-- a typesetter to another.
local function moveMigrating (fromTypesetter, toTypesetter)
  local nodelist = fromTypesetter.state.nodes

  local hasStartedMigration = false
  local i = 1
  while i <= #nodelist do
    if nodelist[i].is_migrating then
      if not hasStartedMigration then
        -- In some complex table scenario using lots of embedded parboxes, with parindent
        -- enabled, something went wrong (weird extra spacing). There was no issue with
        -- parindent to 0.
        -- Found elsewhere in the code, about such zerobox: "Setup queue but avoid calling newPar"
        -- and indeed, seems to fix my issue. Not sure what it really does, there might be dragons
        -- here.
        toTypesetter.state.nodes[#toTypesetter.state.nodes+1] = SILE.nodefactory.zerohbox()
        hasStartedMigration = false
      end
      toTypesetter:pushHorizontal(nodelist[i])
      table.remove(nodelist, i)
    else
      i = i + 1
    end
  end
end

-- Main function for parboxing content.
-- Returns a list of vboxes.
local function parboxFraming (options, content)
  local oldTypesetter = SILE.typesetter
  local parboxTypesetter
  local innerVbox

  SILE.settings:pushState()
  SILE.settings:toplevelState()
  parboxTypesetter = SILE.defaultTypesetter()

  local originalLeaveHmode = parboxTypesetter.leaveHmode
  parboxTypesetter.leaveHmode = function (self, _)
    -- Move migrating material gathered so far.
    moveMigrating(parboxTypesetter, oldTypesetter)
    -- NEVER output, just gather the nodes, hence the enforced 1 here.
    originalLeaveHmode(self, 1)
  end

  local parboxFrame = parboxTempFrame(options)
  parboxTypesetter:initFrame(parboxFrame)
  SILE.typesetter = parboxTypesetter

  SILE.process(content)
  parboxTypesetter:leaveHmode(1)
  innerVbox = parboxTypesetter.state.outputQueue

  SILE.typesetter = oldTypesetter
  SILE.settings:popState()
  -- Important, remove the frame from SILE.frames (it was added there by
  -- SILE.newFrame()), now that we no longer need it. Otherwise, the
  -- performances get awful as all our small frames are kept and solved!
  SILE.frames[parboxFrame.id] = nil
  return innerVbox
end

local function drawBorders (x, y, w, h, border, bordercolor)
  -- The border was initially a debug feature, but it turned out to be neat
  -- for tables (e.g. the ptable package).
  -- There's a little ugly tweak here, the bottom and right borders are drawn
  -- "outside" the box, so that successive parboxes have overlapping borders.
  -- Tables (ptable package) rely on it... That's not perfect, but might not be
  -- too much noticeable with a normal border thickness below 1pt or so...
  if bordercolor then SILE.outputter:pushColor(bordercolor) end
  if border[1] > 0 then SILE.outputter:drawRule(x, y, w, border[1]) end
  if border[2] > 0 then SILE.outputter:drawRule(x, y + h, w, border[2]) end
  if border[3] > 0 then SILE.outputter:drawRule(x, y, border[3], h + border[2]) end
  if border[4] > 0 then SILE.outputter:drawRule(x + w, y, border[4], h + border[2]) end
  if bordercolor then SILE.outputter:popColor() end
end

local function getBaselineExtents (vboxlist)
  -- The core assumption here is that first/last vboxes are actual text lines.
  -- This could be wrong...
  -- Anyhow, the function then returns the height of the first line and the
  -- depthof the last line, so we can use these to vertically align the parbox
  -- with the surrounding content.
  -- The way we do it likely assumes top-to-bottom writing...
  local baseHeight, baseDepth = SILE.length(), SILE.length()
  for i = 1, #vboxlist do
    if vboxlist[i].is_vbox and vboxlist[i].height then
      baseHeight = vboxlist[i].height
      break
    end
  end
  for i = #vboxlist, 1, - 1 do
    if vboxlist[i].is_vbox and vboxlist[i].depth then
      baseDepth = vboxlist[i].depth
      break
    end
  end
  return baseHeight, baseDepth
end

local parseBorderOrPadding = function (rawspec, opt)
  local spec
  if type(rawspec) == "table" then
    spec = rawspec
  else
    spec = {}
    for token in SU.gtoke(rawspec, "[ ]+") do
      if(token.string) then
        local value = SU.cast("measurement", token.string)
        spec[#spec+1] = value:tonumber()
      end
    end
  end
  if #spec == 1 then
    return { spec[1], spec[1], spec[1], spec[1] }
  end
  if #spec ~= 4 then SU.error("Invalid "..opt.." specification: "..rawspec) end
  return spec
end

local function naturalWidth (width, slice)
  -- Since PR #1378, computeLineRatio() also returns the natural width of
  -- the line, in addition to the stretch/shring ratio.
  --
  -- IMPLEMENTATION REMARK / PERFORMANCE IMPROVEMENT
  -- This is to so efficient and could be improved:
  -- We could have modified the typesetter to store it in the line vbox, to
  -- avoid recomputing it. The typesetter has other more important things to
  -- fix/refactor, let's not annoy it with our little parbox case now.
  local _, totalWidth = SILE.typesetter:computeLineRatio(width, slice)
  return totalWidth
end

local function recomputeLineRatio (targetWidth, originalWidth)
  local left = targetWidth:tonumber() - originalWidth:tonumber()
  local ratio = left / originalWidth[left < 0 and "shrink" or "stretch"]:tonumber()
  return math.max(ratio, -1)
end

-- PARBOXING COMMAND

function package:_init ()
  base._init(self)
  self.class:loadPackage("rebox")
  self.class:loadPackage("struts")
end

function package:registerCommands ()
  self:registerCommand("parbox", function (options, content)
    local width = SU.required(options, "width", "parbox")
    local strut = options.strut or "none"
    local border = options.border and parseBorderOrPadding(options.border, "border") or { 0, 0, 0, 0 }
    local valign = options.valign or "top"
    local padding = options.padding and parseBorderOrPadding(options.padding, "padding") or { 0, 0, 0, 0 }
    local bordercolor =  options.bordercolor and SILE.colorparser(options.bordercolor)
    local minimize = SU.boolean(options.minimize, false)

    width = SILE.length(SU.cast("measurement", width)):absolute()

    local vboxes = parboxFraming({ width = width }, content)

    local strutDimen
    if strut == "rule" then
      strutDimen = SILE.call("strut", { method = "rule" })
    elseif strut == "character" then
      strutDimen = SILE.call("strut", { method = "character" })
    else
      strutDimen = { height = SILE.length(0), depth = SILE.length(0) }
    end

    local baseHeight, baseDepth = getBaselineExtents(vboxes)

    local wmax = SILE.length()
    local totalHeight = SILE.length()
    local vboxWidths = {}
    for i = 1, #vboxes do
      -- Try to cancel vertical stretching/shrinking
      if vboxes[i].is_vglue then
        -- Important: many vglues are just the _same_ node, which will be "adjusted"
        -- by the page builder. We cannot tweak directly their height or depth as we
        -- sometimes do with other boxes, as it would have a side effect. So we have
        -- to re-create a new vglue with the appropriate fixed dimension.
        vboxes[i] = SILE.nodefactory.vglue(SILE.length(vboxes[i].height.length))
      end
      totalHeight = totalHeight + vboxes[i].height:absolute() + vboxes[i].depth:absolute()

      if minimize then
        -- We go through all lines to retrieve their natural line.
        local w = SILE.length()
        if vboxes[i].nodes then
          w = naturalWidth(width, vboxes[i].nodes)
          if w > wmax then wmax = w end
        end
        vboxWidths[i] = w
      end
    end

    if minimize then
      -- The max line width can actually be bigger than our target width,
      -- (i.e. notwithstanding its shrinkeability).
      local wmaxlen = SILE.length(wmax.length) -- Lua5.1 doesn't like comparing appels and oranges
      width = SU.min(wmaxlen, width)
      -- We recompute all line ratios based on the new target width.
      for i = 1, #vboxes do
        if vboxes[i].nodes and vboxes[i].ratio then
          local r = recomputeLineRatio(width, vboxWidths[i])
          vboxes[i].ratio = r
        end
      end
    end

    local adjustDepth = SU.max(baseDepth, strutDimen.depth) - baseDepth
    local adjustHeight = SU.max(baseHeight, strutDimen.height) - baseHeight
    local z0 = SILE.length(0)
    local depth, height
    if valign == "bottom" then
      depth = z0 + SILE.length(padding[2]) + SU.max(baseDepth, strutDimen.depth)
      height = totalHeight + SILE.length(padding[1]) - baseDepth + adjustHeight
    elseif valign == "middle" then
      local padwidth = SILE.length(padding[2] + padding[1])
      local half = (totalHeight + adjustHeight + adjustDepth + padwidth) / 2
      depth = half
      height = half
    else -- valign == top
      depth = totalHeight + SILE.length(padding[2]) - baseHeight + adjustDepth
      height = z0 + SILE.length(padding[1]) + SU.max(baseHeight, strutDimen.height)
    end

    return SILE.typesetter:pushHbox({
      width = width + SILE.length(padding[3] + padding[4]),
      depth = depth,
      height = height,
      inner = vboxes,
      valign = valign,
      padding = padding,
      yAdjust = adjustHeight, -- TTB is assumed
      offset = SILE.measurement(), -- INTERNAL: See comment below.
      border = border,
      bordercolor = bordercolor,
      outputYourself= function (node, typesetter, _)
        local saveY = typesetter.frame.state.cursorY
        local saveX = typesetter.frame.state.cursorX

        typesetter.frame.state.cursorY = saveY - node.height:tonumber()
        drawBorders(
          typesetter.frame.state.cursorX:tonumber(),
          typesetter.frame.state.cursorY:tonumber(),
          node.width:tonumber(),
          node.depth:tonumber() + node.height:tonumber(),
          node.border,
          node.bordercolor
        )

        typesetter.frame.state.cursorY = typesetter.frame.state.cursorY + node.yAdjust

        -- Process each vbox
        typesetter.frame.state.cursorY = typesetter.frame.state.cursorY + node.padding[1] - node.offset:tonumber()
        for i = 1, #node.inner do
          typesetter.frame.state.cursorX = saveX + node.padding[3]
          node.inner[i]:outputYourself(typesetter, node.inner[i])
        end

        typesetter.frame.state.cursorY = saveY
        typesetter.frame.state.cursorX = saveX
        typesetter.frame:advanceWritingDirection(node.width)
      end
    })
    -- The offset parameter in the pbox above is for INTERNAL use.
    -- The "ptable" package (parbox-base tables) sets it to tweak and adjust cells.
    -- Kind of a mixed concern here, but it's an easy trick to avoid re-implementing
    -- a bunch of things. And after all these parboxes were made with tables in
    -- mind, though they can be of a more general interest.
  end)
end

package.documentation = [[
A paragraph box (“parbox”) is an horizontal box (so technically an “hbox”)
that contains, as its name implies, one or more paragraphs (so the displayed content
is actually made of vbox’es and vertical glues). The only mandatory
option on the \autodoc:command{\parbox} command is its \autodoc:parameter{width}.
Most of the time, the parbox will be higher that a (regular) text line,
so the option \autodoc:parameter{valign} allows to specify the vertical alignment: top, middle,
bottom. Alignment is relative to the current baseline.

Some important concepts and good stuff are described at the end of this documentation
section, but for now let us show a top-aligned parbox.

\smallskip

(1A) \parbox[width=37%fw, valign=top, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

And a bottom-aligned parbox.

(1B) \parbox[width=37%fw, valign=bottom, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

Finally, the middle-aligned parbox.

(1C) \parbox[width=37%fw, valign=middle, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\medskip

As can be seen, there are however a few issues, if the parbox is intended to be
used (as here) in a regular text flow: the interpretation of “baseline” is
pretty strict, but perhaps unexpected; the line boxing is strict too
and is affected depending on ascenders or descenders. To get what is
logically a more expected output, one would need some vertical adjustment,
which comes in the form of a “strut” (see the \autodoc:package{struts} package).
Let us try again, but this time with the \autodoc:parameter{strut} option set to “character”
(the default, which was used above, corresponds to “none”).

\smallskip

(2A) \parbox[width=37%fw, valign=top, strut=character, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

(2B) \parbox[width=37%fw, valign=bottom, strut=character, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

(2C) \parbox[width=37%fw, valign=middle, strut=character, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\medskip

Or we can set it to “rule”.

\smallskip

(3A) \parbox[width=37%fw, valign=top, strut=rule, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

(3B) \parbox[width=37%fw, valign=bottom, strut=rule, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

(3C) \parbox[width=37%fw, valign=middle, strut=rule, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\medskip

Footnotes (and migrating material) in a parbox are transferred to the upper
context. So they work as expected, but it is the main rationale behind the rule-based strut
above: footnote calls may consist in raised and scaled content, so you might need a bit
more spacing than just a character-derived ascender height.\footnote{The other reason is,
of course, that the character-based method depends on the font size, which might not be the
same inside the parbox and outside. None of the methods is perfect, as line spacing may
also vary depending on the selected algorithm and settings.}

Let us try parboxes of different heights and footnotes in parboxes…

\smallskip

(4) \parbox[width=37%fw, strut=character, border=0.5pt]{\lorem[words=8]

\center{centered}

\raggedleft{I am ragged-left}

\medskip

A paragraph after a skip.\footnote{Footnote from 4, left parbox.}
}
(…)
\parbox[width=37%fw, strut=character, border=0.5pt]{\lorem[words=16]\footnote{Footnote
from 4, right parbox.}
} (…)

\smallskip

Another option is \autodoc:parameter{padding}, with a length applied on all sides of
the parbox. Say, with 5pt.\footnote{If the padding does not seem to be the
same on the sides and on the top and bottom, it is due to the strut.}

\smallskip

(5) \parbox[width=37%fw, valign=middle, strut=character, padding=5pt, border=0.5pt]{one\par
\lorem[words=8]\par
two}

\smallskip

And finally, all the above examples were all framed specifying a \autodoc:parameter{border} option
(as a thickness length, here set to 0.5pt), but obviously the border is not enabled by default, i.e. set to zero.

\smallskip

(6) \parbox[width=37%fw, valign=middle]{one\par
\lorem[words=8]\par
two}

\smallskip

The border and the padding can be specified as a single length (applying on all sides) or a string
containing a space-separated list of four lengths (“top bottom left right”). Additionaly, a
unique \autodoc:parameter{bordercolor} can be specified, the color specification being as defined in the
\autodoc:package{color} package.\footnote{These border and padding options were expecially designed
with tables in mind. For casual box framing, consider using a better-suited solution,
such as the \autodoc:package{framebox} package.}

There is still one advanced option we haven’t described so far, \autodoc:parameter{minimize=true}. When passed,
then the width of the parbox is considered as a maximum width, vould line-breaking have to occur,
but otherwise the box is reduced to the minimum width it actually needs\footnote{Be aware,
however, that the current implementation is not particularly well optimized.}. Compare:

\smallskip

(7A) \parbox[width=37%fw, valign=middle, border=0.5pt]{First\par
37\%fw width\par
Not minimized}
and
(7B) \parbox[width=37%fw, valign=middle, border=0.5pt, minimize=true]{Second\par
37\%fw width\par
Minimized}

\smallskip

We have shown several examples but haven’t mentioned yet what could be one
of the \em{most important concepts} underlying these paragraph boxes: each
of them initializes its own typesetter instance and a dedicated (temporary)
frame.\footnote{For
technically-minded users, the frame is just used to wrap the processing in a constrained
width. The content is afterwards extracted and re-boxed.}
A consequence of the latter remark is that the frame width
(and units expressed in percentages of it) inside the parbox is the actual
width of the parbox. Another notable effect is that centering and right or left
flushing work as expected, out-of-the-box, as could have already been guessed from
example 4 above.
Another important point is that each parbox pushes and resets SILE’s settings
to their top-level values, so that the content inside the parbox may tweak
them, e.g. fonts, right and left skips, etc. without affecting anything else,
especially other embedded parboxes.

In other terms, the parbox acts as as a sort of semi-independent mini-frame.
In the example below, showing all these features, a centered parbox in italic contains
another parbox, each having a size set to 65\%fw.

\smallskip

(8) \parbox[width=65%fw, valign=middle, strut=character, border=0.5pt]{%
\begin{center}
\font[style=italic]%
A centered parbox in italic.

(8X) \parbox[width=65%fw, valign=middle, strut=character, border=0.5pt]{
Another parbox that does not inherit these
things.\footnote{Footnote from 8X, to see it “cascades”
up to the main frame and the printed page.}} (…)
\par
Isn’t it cool?
\end{center}
}

\smallskip

So to recap, the parbox allows one to set up paragraphs inside
a text box. One word, though, on things that may fail. The struts are
implemented by tweaking the height and depth of the first and last vbox
in the parbox, but with complex content, this might not be very robust.
Likewise, the content may include vertical glues and elements that can
be stretched or shrinked. The implementation attempts at removing
them on the first level, but deeply nested elements might cause
issues. It is a powerful tool and it can be a basis for advanced
box models or for tabular elements\footnote{Cells in complex tables
can be regarded as a good use case for paragraph boxes. See the
\autodoc:package{ptable} package.}, etc.
But be warned there could be some edge-cases. Also, it is worth noting
the current implementation has not been experimented yet in right-to-left
or vertical writing direction.
\end{document}]]

return package
