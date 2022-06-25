--
-- A table package for SILE
-- Or rather "parbox-based tables", using the parbox package as a building block.
-- 2021-2022 Didier Willis
-- License: MIT
--
SILE.require("packages/parbox")

-- UTILITY FUNCTIONS

-- Parse the cols specification "c1 c2 .. cN" and return
-- an array of numeric values (we work in absolute points afterwards).
local parseColumnSpec = function (colspec)
  local b = {}
  for token in SU.gtoke(colspec, "[ ]+") do
    if (token.string) then
      local value = SU.cast("measurement", token.string)
      b[#b+1] = value:tonumber()
    end
  end
  if #b == 0 then
    SU.error("Invalid table column specification")
  end
  return b
end

-- Parse the padding specification as a single measurement or a set of
-- four (top bottom left right).
local parsePadding = function (rawspec)
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
  if #spec ~= 4 then SU.error("Invalid padding specification: "..rawspec) end
  return spec
end

-- Compute a cell width from the column widths,
-- taking into account the cell spanning,
-- and memorize already computed values as a micro-optimization
local computeCellWidth = function (col, span, cols)
  if cols[col..":"..span] then return cols[col..":"..span] end
  local width = 0
  if col > #cols or col + span - 1 > #cols then
    SU.error("Table contains an extraneous column")
  end
  for i = col, col + span - 1 do
    width = width + cols[i]
  end
  cols[col..":"..span] = width
  return width
end

-- Let's admit that these whole tables assembled from parboxes
-- can be pretty fragile if one starts messing up with glues,
-- etc. There are a number of "dangerous" settings we want to
-- disable temporarily where suitable... The parbox resets the
-- settings to top-level, so we enforce additional settings
-- on top of that... In a heavy-handed way (this function
-- might even be called where uneeded, strictly speaking).
local vglueNoStretch = function (vg)
  return SILE.nodefactory.vglue(SILE.length(vg.height.length))
end
local temporarilyClearFragileSettings = function (callback)
  SILE.settings:pushState()
  -- Kill that small lineskip thing that may move rows a bit.
  SILE.settings:set("document.lineskip", SILE.length())
  -- Kill stretchability at baseline and paragraph level.
  SILE.settings:set("document.baselineskip", vglueNoStretch(SILE.settings:get("document.baselineskip")))
  SILE.settings:set("document.parskip", vglueNoStretch(SILE.settings:get("document.parskip")))
  callback()
  SILE.settings:popState()
end

-- Apply a background color to an hbox.
-- N.B. It assumes the hbox is NOT in the output queue
-- (i.e. was stolen back and or stored earlier).
-- It also assumes the box dimensions at this step are numbers,
-- not lengths (with stretch/shrink).
SILE.require("packages/color")
local colorBox = function (hbox, color)
  if not color then
    SILE.typesetter:pushHbox(hbox)
  else
    SILE.typesetter:pushHbox({
      inner = hbox,
      color = color,
      width = hbox.width,
      height = hbox.height,
      depth = hbox.depth,
      outputYourself= function (self, typesetter, line)
        local saveY = typesetter.frame.state.cursorY
        local saveX = typesetter.frame.state.cursorX

        -- We want the colored background first, i.e. below the content box.
        -- Note that this is not a general solution for coloring an hbox
        -- (in the general case, dimensions have stretch/shrink so we would
        -- need to compute the scaled ratio with respect to the the line).
        -- In other terms, it works here due to other logic before, but not
        -- take it as a good example of how to color an hbox.
        SILE.outputter:pushColor(self.color)
        SILE.outputter:drawRule(
          saveX,
          saveY - self.height:tonumber(),
          self.width:tonumber(),
          self.height:tonumber() + self.depth:tonumber())
        SILE.outputter:popColor()

        self.inner:outputYourself(SILE.typesetter, line)

        typesetter.frame.state.cursorY = saveY
        typesetter.frame.state.cursorX = saveX
        typesetter.frame:advanceWritingDirection(self.width)
      end
    })
  end
end

-- CLASSES

-- Used for the re-shaping and shipout passes (see below).

local cellNode = pl.class({
  type = "cellnode",
  cellBox = nil,
  valign = nil,
  color = nil,
  _init = function (self, cellBox, valign, color)
    self.cellBox = cellBox
    self.valign = valign
    self.color = color
  end,
  height = function (self)
    return self.cellBox.height + self.cellBox.depth
  end,
  adjustBy = function (self, adjustement)
    -- Correct the box by an amount. It was build with "middle" valign,
    -- so we distribute the adjustement evently.
    self.cellBox.height = self.cellBox.height + adjustement / 2
    self.cellBox.depth = self.cellBox.depth + adjustement / 2
    -- Handle the alignment option on cells, i.e. derive the necessary offset.
    -- For valign "top", nothing to do, we are already good.
    if self.valign == "bottom" then
      self.cellBox.offset = -adjustement
    elseif self.valign ~= "top" then -- enforce "middle"(default)
      self.cellBox.offset = -adjustement / 2
    end
  end,
  shipout = function (self)
    colorBox(self.cellBox, self.color)
  end
})

local cellTableNode = pl.class({
  type = "celltablenode",
  rows = {},
  width = nil,
  _init = function (self, rows, width)
    self.rows = rows
    self.width = width
  end,
  height = function(self)
    local h = 0
    for i = 1, #self.rows do
      h = self.rows[i]:height() + h
    end
    return h
  end,
  adjustBy = function(self, adjustement)
    -- Distribute the adjustment evenly on all rows.
    for i = 1, #self.rows do
      self.rows[i]:adjustBy(adjustement / #self.rows)
    end
  end,
  shipout = function (self)
    SILE.call("parbox", { width = self.width, strut = "character", valign = "middle" }, function()
      temporarilyClearFragileSettings(function()
        for i = 1, #self.rows do
          -- Set up queue but avoid a newPar? Apparently not needed here.
          -- SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = SILE.nodefactory.zerohbox()
          self.rows[i]:shipout()
        end
      end)
    end)
  end
})

local rowNode = pl.class({
  type = "rownode",
  cells = {},
  color = nil,
  _init = function (self, cells, color)
    self.cells = cells
    self.color = color
  end,
  height = function (self)
    local h = SILE.length()
    for i = 1, #self.cells do
      h = SU.max(self.cells[i]:height(), SILE.length(h))
    end
    return h
  end,
  adjustBy = function (self, adjustement)
    local minHeight = self:height() + (adjustement or 0)
    for i = 1, #self.cells do
      self.cells[i]:adjustBy(minHeight - self.cells[i]:height())
    end
  end,
  shipout = function (self)
      -- A regular hbox suffices here.
      -- Important hack or a parindent occurs sometimes: Set up queue but avoid a newPar.
      -- We had do to the same weird magic in the parbox package too at one step, see the
      -- comment there.
      SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = SILE.nodefactory.zerohbox()
      local hbox = SILE.call("hbox", {}, function ()
        for i = 1, #self.cells do
          self.cells[i]:shipout()
        end
      end)
    if self.color then
      table.remove(SILE.typesetter.state.nodes) -- steal it back...
      colorBox(hbox, self.color) -- ...and re-wrap it with color.
    end
    SILE.typesetter:leaveHmode(1) -- 1 = do not eject to page yet (see repeating header logic)
  end
})

-- AST PROCESSING

local processTable = {}

processTable["cell"] = function (content, args, tablespecs)
    local span = SU.cast("integer", content.options.span or 1)
    local color = content.options.background and SILE.colorparser(content.options.background)
    local pad = parsePadding(content.options.padding or tablespecs.cellpadding)
    local width = computeCellWidth(args.col, span, tablespecs.cols)

    -- build the parbox...
    local cellBox = SILE.call("parbox", { width = width - pad[3] - pad[4],
              padding = pad,
              border = content.options.border or tablespecs.cellborder,
              bordercolor = tablespecs.bordercolor,
              valign = "middle", strut="character" }, function ()
      temporarilyClearFragileSettings(function()
        SILE.call("ptable:cell:hook", content.options, content)
      end)
    end)
    table.remove(SILE.typesetter.state.nodes) -- .. but steal it back...
    -- NOTE (reminder): when building the parbox, migrating nodes (e.g. footnotes)
    -- have been moved to the parent typesetter. Stealing the resulting box,
    -- doesn't change that. But it occurs before pushing all boxes, I am
    -- unsure where footnotes for long tables spanning over multiple
    -- pages and/or split cells will end up...
    return cellNode(cellBox, content.options.valign, color)
  end

processTable["celltable"] = function (content, args, tablespecs)
    local span = SU.cast("integer", content.options.span or 1)
    local width = computeCellWidth(args.col, span, tablespecs.cols)
    local rows = {}
    for i = 1, #content do
      if type(content[i]) == "table" then
        if content[i].command == "row" then
          local row = content[i]
          local node = processTable["row"](row, { col = args.col }, tablespecs)
          rows[#rows+1] = node
        else
          SU.error("Unexpected '"..content[i].command.."' in celltable")
        end
      end
      -- All text nodes are silently ignored
    end
    return cellTableNode(rows, width)
  end

processTable["row"] = function (content, args, tablespecs)
    local color = content.options.background and SILE.colorparser(content.options.background)

    SILE.settings:set("document.lineskip", SILE.length())
    local iCell = args.col and args.col or 1
    local cells = {}
    for i = 1, #content do
      if type(content[i]) == "table" then
        local subcell = content[i].command
        if subcell == "cell" or subcell == "celltable" then
          local cell = content[i]
          local node = processTable[subcell](cell, { col = iCell }, tablespecs)
          cells[#cells+1] = node
          iCell = iCell + (cell.options.span and cell.options.span or 1)
        else
          SU.error("Unexpected '"..content[i].command.."' in row")
        end
      end
      -- All text nodes are silently ignored
    end
    return rowNode(cells, color)
  end

-- TYPESETTER TWEAKS

-- We modify the typesetter globally to check whether the content on a new
-- frame is a table row, which needs repeating a header row to be inserted.
-- EXPERIMENTAL AND SOMEWHAT HACKY-WHACKY = MIGHT NOT BE ROBUST
local oldInitNextFrame = SILE.typesetter.initNextFrame
SILE.typesetter.initNextFrame = function (self)
  oldInitNextFrame(self)
  -- Check the top vboxes:
  -- There could be a leading frame vglue, so we check the two first boxes.
  for k = 1, 2 do
    if self.state.outputQueue[k] and self.state.outputQueue[k]._header_ then
      local header = self.state.outputQueue[k]._header_
      table.insert(self.state.outputQueue, k, header)
      break
    end
  end
end

-- COMMANDS

-- The table building logic works as follows:
--  1. Parse the AST
--      - Computing widths, spans, etc. on the way
--      - Constructing an object hierarchy
--      - Each true cell is pre-composed in a middle-aligned parbox that is
--        stolen back from the output queue
--  2. Adjust each element in the object hierarchy (= re-shaping)
--      - All lines and cells have consistent height
--      - For cells, apply the alignment (valign)
--  3. Shipout the resulting content
--      - Building the boxes for rows and celltables
--      - Re-using the adjusted boxes for cells.
--
-- For developers, note that there is only one exposed command, "ptable".
-- The "row", "cell", "celltable" are AST nodes without command in the global
-- scope, so they only exist within the table.
-- All parboxes are constructed middle-aligned, and with "character" strut,
-- which sounds correct for easy height adjustement afterwards.

SILE.registerCommand("ptable", function (options, content)
  local cols = parseColumnSpec(SU.required(options, "cols", "ptable"))
  local cellpadding = options.cellpadding or "4pt"
  local cellborder = options.cellborder or "0.4pt"
  local bordercolor = options.bordercolor

  local totalWidth = SU.sum(cols)
  local tablespecs = {
    cols = cols,
    cellpadding = cellpadding,
    cellborder = cellborder,
    bordercolor = bordercolor
  }

  SILE.typesetter:leaveHmode()
  SILE.call("medskip")

  local headerVbox
  temporarilyClearFragileSettings(function()
    SILE.settings:set("document.parindent", SILE.length())
    local iRow = 1
    for i = 1, #content do
      if type(content[i]) == "table" then
        if content[i].command == "row" then
          local row = content[i]
          local node = processTable["row"](row, { width = totalWidth, row = iRow }, tablespecs)
          node:adjustBy(0)
          node:shipout()
          -- begin header row logic (experimental, might not be robust).
          -- The row shipout didn't ship the queue to the page...
          if SU.boolean(options.header, false) then
            local currentVbox
            -- ... so the last vbox should be our new row, skipping one vglue if present...
            for b = #SILE.typesetter.state.outputQueue, 2, -1 do
              if SILE.typesetter.state.outputQueue[b].is_vbox then
                currentVbox = SILE.typesetter.state.outputQueue[b]
                break
              end
            end
            if iRow == 1 and currentVbox then
              headerVbox = currentVbox
            elseif currentVbox and headerVbox then
              -- Hack a link to the header vbox in the current vbox.
              currentVbox._header_ = headerVbox
            end
          end
          -- end header row logic.
          SILE.typesetter:leaveHmode() -- Now we should be allowed to output to page, if it wants to.
          if SU.boolean(options.header, false) and iRow == 1 then
            SILE.call("novbreak") -- We wouldn't a page break just after the initial header only.
          end
          iRow = iRow + 1
        else
            SU.error("Unexpected '"..content[i].command.."' in table")
        end
      end
      -- All text nodes in ignored without warning.
    end
  end)
  SILE.typesetter:leaveHmode()
  SILE.call("novbreak") -- FIXME weak solution to avoid breaks between table and a possible caption.
  SILE.call("medskip")  -- Also I don't like much hard-coded skips...
end)

-- The default implementation adds an "halign" option for horizontal
-- cell alignment, which is handy e.g. for Markdown support.
-- Other packages and classes could redefine this hook to support
-- their own options (such as cell styles etc.)
SILE.registerCommand("ptable:cell:hook", function(options, content)
  if options.halign == "center" then
    SILE.call("center", {}, content)
  elseif options.halign == "left" then
    SILE.call("noindent")
    SILE.call("raggedright", {}, content)
  elseif options.halign == "right" then
    SILE.call("noindent")
    SILE.call("raggedleft", {}, content)
  else
    SILE.process(content)
  end
end)

return {
  documentation = [[\begin{document}
The \autodoc:package{ptable} package provides commands to typeset flexible tables.\footnote{The
name stands for \em{perfect table}… No, just kidding, it stands for \em{parbox-based table},
as the so-called “parbox” is the underlying building block. You don’t have to understand it to
use this package, though.}

There are many different ways tables could be declared. TeX, LaTeX and friends do it in
a certain way. HTML and other W3C standards do it differently. And in the wild world of
XML document formats and specifications, there are many other syntaxes, from fairly
simple to highly complex ones (TEI, OASIS, DITA, CALS…), so this package, while
influenced by some of them, does not try to mimic a specific one in particular.

\smallskip

\em{Table structure.}
\novbreak

The tables proposed here are based on pre-determined column widths, provided
via the mandatory \autodoc:parameter{cols} option of the \autodoc:environment{ptable} environment.
It implies that the column widths do not automatically adapt to the content,
but inversely that the content will be line-broken etc. to horizontally fit in
fixed-width cells.

That column specification is a space-separated
list of widths (indirectly also determining the expected number
of columns). Let us illustrate it with “50\%fw 50\%fw”.

\begin[cols=50%fw 50%fw]{ptable}
  \begin{row}
    \cell{A\footnote{By the way, footnotes in tables are supported.}}
    \cell{B}
  \end{row}
  \begin{row}
    \cell{C}
    \cell{D}
  \end{row}
\end{ptable}

The other options are \autodoc:parameter{cellpadding} (defaults to 4pt) and
\autodoc:parameter{cellborder} (defaults to 0.4pt; set it to zero to disable
the borders). Both can be either a single length (applying to all
sides) or four space-separated lengths (top, bottom, left, right).
The \autodoc:parameter{bordercolor} option (defaults to unset, i.e. black)
defines the color of any border defined here or later overriddden.
Finally, there is the \autodoc:parameter{header} boolean option, which is false
by default. If set to true, the first row of the table is considered to be a header,
repeated on each page if the table spans over multiple pages.

A \autodoc:command{\ptable} can only contain \autodoc:command[check=false]{\row} elements.
Any other element causes an error to be reported, and any text content is silently ignored.

In turn, a \autodoc:command[check=false]{\row} can only contain \autodoc:command[check=false]{\cell}
or \autodoc:command[check=false]{\celltable} elements, with the same rules applying. It only has one
option, \autodoc:parameter{background}.

The \autodoc:command[check=false]{\cell} is the final element containing text or actually anything
you may want, including complete paragraphs, images, etc. It has two options
(\autodoc:parameter{span} and \autodoc:parameter{valign}) that will be described later, besides
the \autodoc:parameter{border} and \autodoc:parameter{padding} specifications and the \autodoc:parameter{background} color.
All options (including additional ones you may set) are also passed to a cell “hook”.

The \autodoc:command[check=false]{\celltable} is a specific type of cell related to cells spanning over
multiple rows. It has only one option (\autodoc:parameter{span}) and will be addressed later
too.

Rows and regular cells, as noted, can have background color. The color specification is the
same as defined in the \autodoc:package{color} package. The global cell border and padding specifications
from the table can be overridden on each cell.

\center{\parbox[width=70%fw, strut=character]{%
\begin[cols=30%fw 35%fw 35%fw, cellborder=0]{ptable}
  \begin{row}
    \cell[border=1pt 0.5pt 0 0]{}
    \cell[border=1pt 0.5pt 0 0]{\center{orbital period (yr)}}
    \cell[border=1pt 0.5pt 0 0]{\center{radius (km)}}
  \end{row}
  \begin{row}
    \cell[padding=4pt 0 4pt 4pt]{Mercury}
    \cell[padding=4pt 0 4pt 4pt]{\center{0.24}}
    \cell[padding=4pt 0 4pt 4pt]{\center{2440}}
  \end{row}
  \begin{row}
    \cell[border=0 1pt 0 0]{Venus}
    \cell[border=0 1pt 0 0]{\center{0.62}}
    \cell[border=0 1pt 0 0]{\center{6051}}
  \end{row}
\end{ptable}
}}

\smallskip

\em{Cell content.}
\novbreak

For now, let us stick with regular cells. As stated, their content could
be anything. Each cell can be regarded as an independent mini-frame.
Notably, the “frame width” within a cell is actually that of this cell,
meaning that any command relying on it adapts correctly.\footnote{The
“frame height” on the other hand is not known yet as the cells will
vertically adapt automatically to the content.} That is true too for other
frame-related relative units, such as the line length.

We could illustrate it with many commands, but allow us some \em{inception}
with tables-within-tables, all using “60\%fw 40\%fw” as column specification.

\begin[cols=60%fw 40%fw]{ptable}
  \begin{row}
    \cell{%
\begin[cols=60%fw 40%fw]{ptable}
  \begin{row}
    \cell{%
\begin[cols=60%fw 40%fw]{ptable}
  \begin{row}
    \cell{A}
    \cell{B}
  \end{row}
\end{ptable}
    }
    \cell{C}
  \end{row}
\end{ptable}
    }
    \cell{D}
  \end{row}
\end{ptable}

Notice how each embedded table is relative to its parent cell width,
and the column heights are automatically adjusted. By default,
the content is middle-aligned but this is where the \autodoc:parameter{valign}
cell option may be used. Let’s set it to “top” for C and
“bottom” for D.

\begin[cols=60%fw 40%fw]{ptable}
  \begin{row}
    \cell{
\begin[cols=60%fw 40%fw]{ptable}
  \begin{row}
    \cell{
\begin[cols=60%fw 40%fw]{ptable}
  \begin{row}
    \cell{A}
    \cell{B}
  \end{row}
\end{ptable}
    }
    \cell[valign=top]{C}
  \end{row}
\end{ptable}
    }
    \cell[valign=bottom]{D}
  \end{row}
\end{ptable}

\em{Column and row spanning.}
\novbreak

By default, each cell takes up the width of one column.
You can allow some cells to span over multiple columns, using
the \autodoc:parameter{span} option with the appropriate value, e.g. 2 below
on cell A. This is also what some office programs call “merging”.

\begin[cols=50%fw 50%fw]{ptable}
  \begin{row}
    \cell[span=2]{A}
  \end{row}
  \begin{row}
    \cell{B}
    \cell{C}
  \end{row}
\end{ptable}

So far, so easy. But what about spanning over multiple rows?
Each cell takes up, by default, the height of one row… and in this
table package, one cannot change that fact.

Instead of “merging”, we however have “splitting”, in that
direction. You will still specify a \em{single cell}, but of a special type
which turns out to be a (sub-)table. The command
for that purpose is the abovementioned \autodoc:environment[check=false]{celltable}.
It can only contain rows, so it is really an inner table used
as a cell.

\begin[cols=50%fw 50%fw]{ptable}
  \begin{row}
    \cell{A}
    \begin{celltable}
      \begin{row}
        \cell{B}
      \end{row}
      \begin{row}
        \cell{C}
      \end{row}
    \end{celltable}
  \end{row}
\end{ptable}

In other terms, the above table has only one row, but
the second cell is divided into two sub-rows. Other
than that, this special type of cell remains a cell,
so the column heights will automatically be adjusted
if need be (evenly distributed between the sub-rows)…
and as a cell, too, it supports the \autodoc:parameter{span} option
for column spanning. One might thus achieve fairly
complex layouts.\footnote{Exercise left to the reader: can
you craft the same table but with the C and E columns
merged?}

\begin[cols=33.333%fw 33.333%fw 33.333%fw]{ptable}
  \begin[background=#ddd]{row}
    \cell{A.}
    \cell{B.}
    \cell{C.}
  \end{row}
  \begin{row}
    \cell[span=2, background=#eee]{D.}
    \cell{E}
  \end{row}
  \begin{row}
    \cell{F.}
    \begin[span=2]{celltable}
      \begin{row}
        \cell{G.}
        \cell{H.}
      \end{row}
      \begin{row}
        \cell[span=2]{I.}
      \end{row}
    \end{celltable}
  \end{row}
\end{ptable}

\em{Cell styling.}
\novbreak

Each cell being a mini-frame, it resets its settings to their top-level (i.e. document) values.
Cell content and options, though, are passed to a \autodoc:command{\ptable:cell:hook}.
Would you want to define specific styling for some cells, you can re-define that command to
achieve it\footnote{The default implementation supports an \autodoc:parameter{halign}
option for horizontal cell alignement (left, right or center, or justified if not set).}.

\smallskip

\em{Other considerations.}
\novbreak

Due to the way the table is built by assembling boxes,
page breaks may only occur between first-level rows.
With tables involving cell splitting, it might be difficult
to get a good break-point.

\end{document}]]
}
