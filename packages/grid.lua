local gridSpacing -- Should be a setting

local makeUp = function ()
  if not SILE.typesetter.frame.state.totals.gridCursor then SILE.typesetter.frame.state.totals.gridCursor = 0 end
  local toadd = gridSpacing - (SILE.typesetter.frame.state.totals.gridCursor % gridSpacing)
  SILE.typesetter.frame.state.totals.gridCursor = SILE.typesetter.frame.state.totals.gridCursor + toadd
  return SILE.nodefactory.newVglue({ height = SILE.length.new({ length = toadd }) })
end

local leadingFor = function(this, vbox, previous)
  if not this.frame.state.totals.gridCursor then this.frame.state.totals.gridCursor = 0 end
  if not previous then return SILE.nodefactory.newVglue({height=SILE.length.new({})}) end
  if type(vbox.height) == "table" then
    this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + vbox.height.length + previous.depth
  else
    this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + vbox.height + previous.depth
  end
  return makeUp()
end

local pushVglue = function(this, spec)
  if not this.frame.state.totals.gridCursor then
    this.frame.state.totals.gridCursor = 0
  end
  spec.height.stretch = 0
  spec.height.shrink = 0
  this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + SILE.toAbsoluteMeasurement(spec.height.length)
  SILE.defaultTypesetter.pushVglue(this, spec)
  SILE.defaultTypesetter.pushVglue(this, makeUp())
end

local debugGrid = function()
  local t = SILE.typesetter
  if not t.frame.state.totals.gridCursor then t.frame.state.totals.gridCursor = 0 end
  local g = t.frame.state.totals.gridCursor
  while g < t.frame:bottom() do
    SILE.outputter.rule(t.frame:left(), t.frame:top() + g, t.frame:width(), 0.1)
    g = g + gridSpacing
  end
end

local oldPageBuilder = SILE.pagebuilder
local gridFindBestBreak = function(options)
  local vboxlist = SU.required(options, "vboxlist", "in findBestBreak")
  local target   = SU.required(options, "target", "in findBestBreak")
  local i = 0
  local totalHeight = SILE.length.new()
  local bestBreak = 0
  local started = false
  while not started and i < #vboxlist do
    i = i + 1
    if not vboxlist[i]:isVglue() then
      started = true
      i = i - 1
      break
    end
  end
  SU.debug("pagebuilder", "Page builder for frame "..SILE.typesetter.frame.id.." called with "..#vboxlist.." nodes, "..target)
  while i < #vboxlist do
    i = i + 1
    local vbox = vboxlist[i]
    SU.debug("pagebuilder", "Dealing with VBox " .. vbox)
    if (vbox:isVbox()) then
      totalHeight = totalHeight + vbox.height + vbox.depth
    elseif vbox:isVglue() then
      totalHeight = totalHeight + vbox.height
    end
    if vbox.type == "insertionVbox" then
      target = SILE.insertions.processInsertion(vboxlist, i, totalHeight, target)
      vbox = vboxlist[i]
    end
    local left = target - totalHeight.length
    SU.debug("pagebuilder", "I have " .. tostring(left) .. "pts left")
    SU.debug("pagebuilder", "totalHeight " .. totalHeight .. " with target " .. target)
    local badness = 0
    if left < 0 then badness = 1000000 end
    if vbox:isPenalty() then
      if vbox.penalty < -3000 then badness = 100000
      else badness = -(left * left) - vbox.penalty end
    end
    if badness > 0 then
      local onepage = {}
      for j=1,bestBreak do
        onepage[j] = table.remove(vboxlist,1)
      end
      while(#onepage > 1 and onepage[#onepage].discardable) do onepage[#onepage] = nil end
      return onepage, 1000
    end
    bestBreak = i
  end
  local left = target - totalHeight.length
  return false, false
end

SILE.registerCommand("grid:debug", function(o,c)
  debugGrid()
  SILE.typesetter:registerNewFrameHook(debugGrid)
end)

SILE.registerCommand("grid", function(options, content)
  SILE.typesetter.state.grid = true
  SU.required(options, "spacing", "grid package")
  gridSpacing = SILE.parseComplexFrameDimension(options.spacing)
  -- SILE.typesetter:leaveHmode()

  SILE.pagebuilder = std.tree.clone(SILE.pagebuilder)
  SILE.pagebuilder.findBestBreak = gridFindBestBreak

  SILE.typesetter.leadingFor = leadingFor
  SILE.typesetter.pushVglue = pushVglue
  if SILE.typesetter.frame then
      SILE.typesetter.frame.state.totals.gridCursor = 0
      SILE.typesetter.state.previousVbox = SILE.defaultTypesetter.pushVbox(SILE.typesetter,{})
  end
  SILE.typesetter:registerNewFrameHook(function (this)
    this.frame.state.totals.gridCursor = 0
    while this.state.outputQueue[1] and this.state.outputQueue[1].discardable do
      table.remove(this.state.outputQueue,1)
    end
    if this.state.outputQueue[1] then
      table.insert(this.state.outputQueue, 1, SILE.nodefactory.newVbox({}))
      table.insert(this.state.outputQueue, 2, leadingFor(this, this.state.outputQueue[2], this.state.outputQueue[1]))
    end
  end)

end, "Begins typesetting on a grid spaced at <spacing> intervals.")

SILE.registerCommand("no-grid", function (options, content)
  SILE.typesetter.state.grid = false
  SILE.typesetter.leadingFor = SILE.defaultTypesetter.leadingFor
  SILE.typesetter.pushVglue = SILE.defaultTypesetter.pushVglue
  SILE.typesetter.setVerticalGlue = SILE.defaultTypesetter.setVerticalGlue
  SILE.pagebuilder = oldPageBuilder
  -- SILE.typesetter.state = t.state
end, "Stops grid typesetting.")

return {
  documentation = [[
\begin{document}
\grid[spacing=15pt]
In normal typesetting, SILE determines the spacing between lines of type
according to the following two rules:

\noindent• SILE tries to insert space between two successive lines so that their baselines
are separated by a fixed distance called the \code{baselineskip}.

\noindent• If this first rule would mean that the bottom and the top of the lines are less
than two points apart, then they are forced to be two points apart. (This distance
is configurable, and called the \code{lineskip})

The second rule is designed to avoid the situation where the first line has a long
descender (letters such as g, q, j, p, etc.) which abuts a high ascender on the second
line. (k, l, capitals, etc.)

In addition, the \code{baselineskip} contains a certain amount of ‘stretch’, so that
the lines can expand if this would help with producing a page break at an optimal
location, and similarly spacing between paragraphs can stretch or shrink.

The combination of all of these rules means that a line may begin at practically any
point on the page.

An alternative way of typesetting is to require that lines begin at fixed points on
a regular grid. Some people prefer the ‘color’ of pages produced by grid typesetting,
and the method is often used when typesetting on very thin paper as lining up the
lines of type on both sides of a page ensures that ink does not bleed through from
the back to the front. Compare the following examples: on the left, the lines are
guaranteed to fall in the same places on the recto (front) and the verso (back) of
the paper; on the right, no such guarantee is made.

\img[src=documentation/grid-1.png,height=130]
\img[src=documentation/grid-2.png,height=130]

The \code{grid} package alters the way that the SILE’s typesetter operates so that
the two rules above do not apply; lines are always aligned on a fixed grid, and
spaces between paragraphs etc. are adjusted to conform to the grid. Loading the package
adds two new commands to SILE: \code{\\grid[spacing=\em{<dimension>}]} and \code{\\no-grid}.
The first turns on grid typesetting for the remainder of the document; the second turns it off again.

At the start of this section, we issued the command \code{\\grid[spacing=15pt]} to
set up a regular 15-point grid. Here is some text typeset with the grid set up:

\smallskip
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
\smallskip

And here is the same text after we issue \code{\\no-grid}:

\no-grid\smallskip
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
\end{document}
]]
}
