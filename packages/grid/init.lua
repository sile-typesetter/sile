local base = require("packages.base")

local package = pl.class(base)
package._name = "grid"

local oldPagebuilderType, oldTypesetterType

local function startGridInFrame (typesetter)
   if not SILE.typesetter.state.grid then
      return
   end -- Ensure the frame hook isn't effective when grid is off
   local queue = typesetter.state.outputQueue
   typesetter.frame.state.totals.gridCursor = SILE.types.measurement(0)
   if #queue == 0 then
      typesetter.state.previousVbox = typesetter:pushVbox()
      return
   end
   while queue[1] and (queue[1].discardable or queue[1].gridleading) do
      table.remove(queue, 1)
   end
   if queue[1] then
      table.insert(queue, 1, SILE.types.node.vbox())
      table.insert(queue, 2, SILE.typesetter:leadingFor(queue[2], queue[1]))
   end
end

function package:_init (options)
   self.spacing = SU.cast("measurement", options.spacing or "1bs"):absolute()
   base._init(self)
end

function package:registerCommands ()
   self.commands:register("grid:debug", function (options, _)
      local spacing = SU.cast("measurement", options.spacing or self.spacing):absolute()
      local debugGrid = function ()
         local frame = SILE.typesetter.frame
         local gridCursor = spacing
         while gridCursor < frame:height() do
            SILE.outputter:drawRule(frame:left(), frame:top() + gridCursor, frame:width(), 0.1)
            gridCursor = gridCursor + spacing
         end
      end
      debugGrid()
      SILE.typesetter:registerNewFrameHook(debugGrid)
   end)

   self.commands:register("grid", function (options, _)
      if options.spacing then
         self.spacing = SU.cast("measurement", options.spacing):absolute()
      end
      SILE.typesetter.state.grid = true
      oldPagebuilderType = SILE.typesetter.pagebuilder._name
      oldTypesetterType = SILE.typesetter._name
      SILE.pagebuilders.grid:cast(SILE.typesetter.pagebuilder)
      SILE.typesetters.grid:cast(SILE.typesetter)
      SILE.typesetter.options = { spacing = self.spacing }
      if SILE.typesetter.frame then
         startGridInFrame(SILE.typesetter)
      end
      SILE.typesetter:registerNewFrameHook(startGridInFrame)
   end, "Begins typesetting on a grid spaced at <spacing> intervals.")

   self.commands:register("no-grid", function (_, _)
      SILE.typesetter.state.grid = false
      SILE.typesetters[oldTypesetterType]:cast(SILE.typesetter)
      SILE.pagebuilders[oldPagebuilderType]:cast(SILE.typesetter.pagebuilder)
   end, "Stops grid typesetting.")
end

package.documentation = [[
\begin{document}
\use[module=packages.grid]
\grid[spacing=15pt]
In normal typesetting, SILE determines the spacing between lines of type according to the following two rules:

\begin{itemize}
\item{SILE tries to insert space between two successive lines so that their baselines are separated by a fixed distance called the \code{baselineskip}.}
\item{If this first rule would mean that the bottom and the top of the lines are less than two points apart, then they are forced to be two points apart.
      (This distance is configurable, and called the \code{lineskip}.)}
\end{itemize}

The second rule is designed to avoid the situation where the first line has a long descender (letters such as g, q, j, p, etc.) which abuts a high ascender on the second line (k, l, capitals, etc.).

In addition, the \code{baselineskip} contains a certain amount of “stretch,” so that the lines can expand if this would help with producing a page break at an optimal location, and similarly spacing between paragraphs can stretch or shrink.

The combination of all of these rules means that a line may begin at practically any point on the page.

An alternative way of typesetting is to require that lines begin at fixed points on a regular grid.
Some people prefer the “color” of pages produced by grid typesetting, and the method is often used when typesetting on very thin paper, as lining up the lines of type on both sides of a page ensures that ink does not bleed through from the back to the front.
Compare the following examples: on the left, the lines are guaranteed to fall in the same places on the recto (front) and the verso (back) of the paper; on the right, no such guarantee is made.

\img[src=documentation/grid-1.png,height=130]
\img[src=documentation/grid-2.png,height=130]

The \autodoc:package{grid} package alters the operation of SILE’s typesetter so that the two rules above do not apply; lines are always aligned on a fixed grid, and spaces between paragraphs, etc., are adjusted to conform to the grid.
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
