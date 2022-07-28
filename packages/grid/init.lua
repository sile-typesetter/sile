local base = require("packages.base")

local package = pl.class(base)
package._name = "grid"

-- TODO: consider registering as a setting instead of a frame property
local gridSpacing

local function makeUp (totals)
  local toadd = (gridSpacing - SILE.measurement(totals.gridCursor)) % gridSpacing
  totals.gridCursor = totals.gridCursor + toadd
  SU.debug("typesetter", "Makeup height = " .. toadd)
  return SILE.nodefactory.vglue(toadd)
end

local function leadingFor (typesetter, vbox, previous)
  SU.debug("typesetter", "   Considering leading between two lines (grid mode):")
  SU.debug("typesetter", "   1) " .. tostring(previous))
  SU.debug("typesetter", "   2) " .. vbox)
  if not previous then return SILE.nodefactory.vglue() end
  SU.debug("typesetter", "   Depth of previous line was " .. tostring(previous.depth))
  local totals = typesetter.frame.state.totals
  local oldCursor = SILE.measurement(totals.gridCursor)
  totals.gridCursor = oldCursor + vbox.height:absolute() + previous.depth
  SU.debug("typesetter", "   Cursor change = " .. totals.gridCursor - oldCursor)
  return makeUp(typesetter.frame.state.totals)
end

local function pushVglue (typesetter, spec)
  -- if SU.type(spec) ~= "table" then SU.warn("Please use pushVertical() to pass a premade node instead of a spec") end
  local node = SU.type(spec) == "vglue" and spec or SILE.nodefactory.vglue(spec)
  node.height.stretch = SILE.measurement()
  node.height.shrink = SILE.measurement()
  local totals = typesetter.frame.state.totals
  totals.gridCursor = totals.gridCursor + SILE.measurement(node.height):absolute()
  typesetter:pushVertical(node)
  typesetter:pushVertical(makeUp(typesetter.frame.state.totals))
  return node
end

local function pushExplicitVglue (typesetter, spec)
  -- if SU.type(spec) ~= "table" then SU.warn("Please use pushVertical() to pass a premade node instead of a spec") end
  local node = SU.type(spec) == "vglue" and spec or SILE.nodefactory.vglue(spec)
  node.explicit = true
  node.discardable = false
  node.height.stretch = SILE.measurement()
  node.height.shrink = SILE.measurement()
  local totals = typesetter.frame.state.totals
  totals.gridCursor = totals.gridCursor + SILE.measurement(node.height):absolute()
  typesetter:pushVertical(node)
  typesetter:pushVertical(makeUp(typesetter.frame.state.totals))
  return node
end

local function startGridInFrame (typesetter)
  local queue = typesetter.state.outputQueue
  typesetter.frame.state.totals.gridCursor = SILE.measurement(0)
  if #queue == 0 then
    typesetter.state.previousVbox = typesetter:pushVbox()
    return
  end
  while queue[1] and queue[1].discardable do
    table.remove(queue, 1)
  end
  if queue[1] then
    table.insert(queue, 1, SILE.nodefactory.vbox())
    table.insert(queue, 2, SILE.typesetter:leadingFor(queue[2], queue[1]))
  end
end

local function debugGrid ()
  local frame = SILE.typesetter.frame
  local gridCursor = gridSpacing
  while SILE.measurement(gridCursor) < SILE.measurement(frame:height()) do
    SILE.outputter:drawRule(frame:left(), frame:top() + gridCursor, frame:width(), 0.1)
    gridCursor = gridCursor + gridSpacing
  end
end

local gridPagebuilder = pl.class(require("core.pagebuilder"))

function gridPagebuilder.findBestBreak (_, options)
  local vboxlist = SU.required(options, "vboxlist", "in findBestBreak")
  local target   = SU.required(options, "target", "in findBestBreak")
  local i = 0
  local totalHeight = SILE.length()
  local bestBreak = 0
  SU.debug("pagebuilder", "Page builder for frame "..SILE.typesetter.frame.id.." called with "..#vboxlist.." nodes, "..target)
  if SU.debugging("vboxes") then
    for j, box in ipairs(vboxlist) do
      SU.debug("vboxes", (j == i and " >" or "  ") .. j .. ": " .. box)
    end
  end
  while i < #vboxlist do
    i = i + 1
    if not vboxlist[i].is_vglue then
      i = i - 1
      break
    end
  end
  while i < #vboxlist do
    i = i + 1
    local node = vboxlist[i]
    SU.debug("pagebuilder", "Dealing with VBox " .. node)
    if node.is_vbox then
      totalHeight = totalHeight + node.height:absolute() + node.depth:absolute()
    elseif node.is_vglue then
      totalHeight = totalHeight + node.height:absolute()
    elseif node.is_insertion then
      -- TODO: refactor as hook and without side effects!
      target = SILE.insertions.processInsertion(vboxlist, i, totalHeight, target)
      node = vboxlist[i]
    end
    local left = target - totalHeight
    local _left = left:tonumber()
    SU.debug("pagebuilder", "I have " .. left .. "left")
    SU.debug("pagebuilder", "totalHeight " .. tostring(totalHeight) .. " with target " .. tostring(target))
    local badness = 0
    if _left < 0 then badness = 1000000 end
    if node.is_penalty then
      if node.penalty < -3000 then badness = 100000
      else badness = -_left * _left - node.penalty
      end
    end
    if badness > 0 then
      local onepage = {}
      for j = 1, bestBreak do
        onepage[j] = table.remove(vboxlist, 1)
      end
      while #onepage > 1 and onepage[#onepage].discardable do
        onepage[#onepage] = nil
      end
      return onepage, 1000
    end
    bestBreak = i
  end
  return false, false
end

local oldPageBuilder, oldLeadingFor, oldPushVglue, oldPushExplicitVglue

function package:_init ()
  base._init(self)
  gridSpacing = SILE.measurement()
end

function package:registerCommands ()

  local class = self.class

  class:registerCommand("grid:debug", function (_, _)
    debugGrid()
    SILE.typesetter:registerNewFrameHook(debugGrid)
  end)

  class:registerCommand("grid", function (options, _)
    SILE.typesetter.state.grid = true
    SU.required(options, "spacing", "grid package")
    gridSpacing = SILE.parseComplexFrameDimension(options.spacing)
    oldPageBuilder = SILE.pagebuilder
    SILE.pagebuilder = gridPagebuilder()
    oldLeadingFor = SILE.typesetter.leadingFor
    SILE.typesetter.leadingFor = leadingFor
    oldPushVglue = SILE.typesetter.pushVglue
    SILE.typesetter.pushVglue = pushVglue
    oldPushExplicitVglue = SILE.typesetter.pushExplicitVglue
    SILE.typesetter.pushExplicitVglue = pushExplicitVglue
    if SILE.typesetter.frame then
      startGridInFrame(SILE.typesetter)
    end
    SILE.typesetter:registerNewFrameHook(startGridInFrame)
  end, "Begins typesetting on a grid spaced at <spacing> intervals.")

  class:registerCommand("no-grid", function (_, _)
    SILE.typesetter.state.grid = false
    SILE.typesetter.leadingFor = oldLeadingFor
    SILE.typesetter.pushVglue = oldPushVglue
    SILE.typesetter.pushExplicitVglue = oldPushExplicitVglue
    SILE.pagebuilder = oldPageBuilder
  end, "Stops grid typesetting.")

end

package.documentation = [[
\begin{document}
\grid[spacing=15pt]
In normal typesetting, SILE determines the spacing between lines of type according to the following two rules:

\begin{itemize}
\item{SILE tries to insert space between two successive lines so that their baselines are separated by a fixed distance called the \code{baselineskip}.}
\item{If this first rule would mean that the bottom and the top of the lines are less than two points apart, then they are forced to be two points apart.
      (This distance is configurable, and called the \code{lineskip}).}
\end{itemize}

The second rule is designed to avoid the situation where the first line has a long descender (letters such as g, q, j, p, etc.) which abuts a high ascender on the second line. (k, l, capitals, etc.)

In addition, the \code{baselineskip} contains a certain amount of ‘stretch’, so that the lines can expand if this would help with producing a page break at an optimal location, and similarly spacing between paragraphs can stretch or shrink.

The combination of all of these rules means that a line may begin at practically any point on the page.

An alternative way of typesetting is to require that lines begin at fixed points on a regular grid.
Some people prefer the ‘color’ of pages produced by grid typesetting, and the method is often used when typesetting on very thin paper as lining up the lines of type on both sides of a page ensures that ink does not bleed through from the back to the front.
Compare the following examples: on the left, the lines are guaranteed to fall in the same places on the recto (front) and the verso (back) of the paper; on the right, no such guarantee is made.

\img[src=documentation/grid-1.png,height=130]
\img[src=documentation/grid-2.png,height=130]

The \autodoc:package{grid} package alters the way that the SILE’s typesetter operates so that the two rules above do not apply; lines are always aligned on a fixed grid, and spaces between paragraphs etc. are adjusted to conform to the grid.
Loading the package adds two new commands to SILE: \autodoc:command{\grid[spacing=<dimension>]} and \autodoc:command{\no-grid}.
The first turns on grid typesetting for the remainder of the document; the second turns it off again.

At the start of this section, we issued the command \autodoc:command{\grid[spacing=15pt]} to set up a regular 15-point grid.
Here is some text typeset with the grid set up:

\smallskip
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
\smallskip

And here is the same text after we issue \autodoc:command{\no-grid}:

\no-grid\smallskip
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
\end{document}
]]

return package
