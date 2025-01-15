local base = require("packages.base")

local package = pl.class(base)
package._name = "parallel"

-- Typesetter pool for managing typesetters for different frames (e.g., left and right frames).
local typesetterPool, footnotePool = {}, {}

-- Make sure you have ftn_left and ftn_right frames setup in your document class
local footnotes = { ftn_left = {}, ftn_right = {} }

-- Cache for footnote heights
local footnoteHeightCache = {}

-- Stores layout calculations for each frame, such as height, marking and overflow tracking.
local calculations = {}

-- Specifies the order of frames for synchronizing and page-breaking logic.
local folioOrder = {}

-- Utility function to iterate through all typesetters in the pool and apply a callback function.
local allTypesetters = function(callback)
   local oldtypesetter = SILE.typesetter -- Save the currently active typesetter.
   for frame, typesetter in pairs(typesetterPool) do
      SILE.typesetter = typesetter -- Temporarily switch to the typesetter for the current frame.
      callback(frame, typesetter) -- Apply the callback to the current frame and its typesetter.
   end
   SILE.typesetter = oldtypesetter -- Restore the original typesetter after iteration.
end

-- A null typesetter used as a placeholder. This typesetter doesn't output any content.
-- Its purpose is to make the transtion between frames easier and trouble free.
local nulTypesetter = pl.class(SILE.typesetters.base) -- we ignore this
nulTypesetter.outputLinesToPage = function() end

-- Utility function to calculate the height of new material for a given frame.
-- This function computes the cumulative height by adding the heights of lines
-- in the `typesetter.state.outputQueue` starting from the marked position.
local calculateFrameHeight = function(frame, typesetter)
   -- Retrieve the cumulative height for the frame or initialize it if not set.
   local height = calculations[frame].cumulativeHeight or SILE.types.length()

   -- Iterate through the output queue from the marked position, summing line heights.
   -- Each line's height is the sum of its height and depth.
   for i = calculations[frame].mark + 1, #typesetter.state.outputQueue do
      local lineHeight = typesetter.state.outputQueue[i].height + typesetter.state.outputQueue[i].depth
      height = height + lineHeight
   end

   -- Return the updated cumulative height for the frame.
   return height
end

-- Calculate the line height of a sample text.
-- This function uses a sample text containing two characters:
-- one with an ascender and one with a descender.
-- The height calculation includes the glyph heights and the baseline skip setting.
local calculateLineHeight = function(sampleText)
   local glyphs = SILE.shaper:shapeToken(sampleText, SILE.font.loadDefaults({}))
   local baselineSkip = SILE.settings:get("document.baselineskip").height
   return glyphs[1].height + glyphs[2].depth + baselineSkip:tonumber()
end

-- Generate dummy content to fill overflowed frames up to the specified height.
local createDummyContent = function(height, frame, offset)
   -- Retrieve the typesetter for the given frame.
   local typesetter = typesetterPool[frame]

   -- Determine the line height using a sample line or fallback to baseline and line skip settings.
   -- local lineHeight = calculateLineHeight("hg")

   -- If lineHeight cannot be calculated, use document's baselineSkip and lineSkip as fallback.
   if not lineHeight then
      local baselineSkip = SILE.settings:get("document.baselineskip").height or SILE.types.length({ length = 0 })
      local lineSkip = SILE.settings:get("document.lineskip").height or SILE.types.length({ length = 0 })
      lineHeight = baselineSkip:tonumber() + lineSkip:tonumber()
   end

   -- Calculate the number of lines required to fill the specified height.
   local numLines = math.floor(height:tonumber() / lineHeight)

   -- Ensure offset is valid; warn if it exceeds the number of lines.
   offset = offset or 0
   if offset >= numLines then
      SU.warn("Offset is larger than the number of lines available; no dummy content will be generated.")
      return
   end

   -- Fill the frame with dummy content using white-colored text to avoid visible output.
   SILE.call("color", { color = "white" }, function()
      typesetter:typeset("sile")
      for i = 1, numLines - offset do
         SILE.call("break")
         typesetter:typeset("sile")
      end
   end)
end

-- Balance the heights of frames by adding dummy content to shorter frames.
-- This ensures that all frames are aligned to the height of the tallest frame.
local balanceFramesWithDummyContent = function(offset)
   local frameHeights = {} -- Table to store the heights of each frame.
   local maxHeight = SILE.types.length(0) -- Track the maximum frame height.

   -- Step 1: Measure the heights of all frames and find the maximum height.
   allTypesetters(function(frame, typesetter) -- This is a callback function.
      local height = calculateFrameHeight(frame, typesetter)
      frameHeights[frame] = height -- Store the height for the current frame.
      if height > maxHeight then
         maxHeight = height -- Update maxHeight if this frame is taller.
      end
   end)

   -- Step 2: Add dummy content to balance the frames to the maximum height.
   allTypesetters(function(frame, typesetter)
      local heightDifference = maxHeight - frameHeights[frame]
      if heightDifference:tonumber() > 0 then
         SILE.typesetter = typesetter -- Switch to the current frame's typesetter.
         createDummyContent(SILE.types.length(heightDifference), frame, offset or 0)
      end
   end)

   -- Log the balancing results for debugging.
   SU.debug(package._name, "Balanced frames to height: ", maxHeight)
end

-- Handles page-breaking and overflow logic for parallel frames.
local parallelPagebreak = function()
   for _, thisPageFrames in ipairs(folioOrder) do
      local hasOverflow = false
      local overflowContent = {}

      -- Process each frame for overflow content
      allTypesetters(function(frame, typesetter)
         typesetter:initFrame(typesetter.frame)
         local thispage = {}
         local linesToFit = typesetter.state.outputQueue
         local targetLength = typesetter:getTargetLength():tonumber()
         local currentHeight = 0

         while
            #linesToFit > 0
            and currentHeight + (linesToFit[1].height:tonumber() + linesToFit[1].depth:tonumber()) <= targetLength
         do
            local line = table.remove(linesToFit, 1)
            currentHeight = currentHeight + (line.height:tonumber() + line.depth:tonumber())
            table.insert(thispage, line)
         end

         if #linesToFit > 0 then
            hasOverflow = true
            overflowContent[frame] = linesToFit
            typesetter.state.outputQueue = {}
         else
            overflowContent[frame] = {}
         end

         typesetter:outputLinesToPage(thispage)
      end)

      -- Process footnotes before page break
      -- typesetFootnotes()

      -- End the current page
      SILE.documentState.documentClass:endPage()

      if hasOverflow then
         -- Start a new page
         SILE.documentState.documentClass:newPage()

         -- Restore overflow content to the frames
         for frame, overflowLines in pairs(overflowContent) do
            local typesetter = typesetterPool[frame]
            for _, line in ipairs(overflowLines) do
               table.insert(typesetter.state.outputQueue, line)
            end
         end

         -- Rebalance frames
         balanceFramesWithDummyContent()
      end
   end

   -- Ensure all the first pair of frames on the new page are synchronized
   SILE.call("sync")
end

-- Add balancing glue to shorter frames to align their height with the target height.
-- This ensures consistent alignment across frames by adding vertical glue to the output queue.
local addBalancingGlue = function(height)
   allTypesetters(function(frame, typesetter)
      -- Calculate the height of new material in the current frame.
      calculations[frame].heightOfNewMaterial = calculateFrameHeight(frame, typesetter)

      -- Determine the amount of glue needed to match the target height.
      local glue = height - calculations[frame].heightOfNewMaterial

      -- If glue is needed, add it to the frame's output queue.
      if glue:tonumber() > 0 then
         table.insert(typesetter.state.outputQueue, SILE.types.node.vglue({ height = glue }))
         SU.debug(package._name, "Added balancing glue of", glue, "to the bottom of frame", frame)
      end

      -- Marking is unnecessary here as the `\sync` command handles it.
      -- calculations[frame].mark = #typesetter.state.outputQueue
   end)
end

-- Adds a flexible glue (parskip) to the bottom of each frame
-- This is decoupled from addBalancingGlue calculations, serving a simple purpose.
local addParskipToFrames = function(parskipHeight)
   allTypesetters(function(_, typesetter)
      table.insert(typesetter.state.outputQueue, SILE.types.node.vglue({ height = parskipHeight }))
   end)
end

function package:_init(options)
   base._init(self, options)

   -- Load necessary packages
   self:loadPackage("rebox") -- for footnote:rule
   self:loadPackage("rules") -- for footnote:rule
   self:loadPackage("counters") -- for footnote counting
   self:loadPackage("raiselower") -- for footnote superscript mark

   SILE.typesetter = nulTypesetter(SILE.getFrame("page"))
   if type(options.frames) ~= "table" then
      SU.error([[
         Package parallel must be initialized with a set of appropriately named frames

         This package is usually intended to be loaded from some supporting class or
         from another package, responsible for correct initialization.
      ]])
   end
   for frame, typesetter in pairs(options.frames) do
      typesetterPool[frame] = SILE.typesetters.base(SILE.getFrame(typesetter))
      typesetterPool[frame].id = typesetter
      typesetterPool[frame].buildPage = function()
         -- No thank you, I will do that.
      end
      -- Fixed leading here is obviously a bug, but n-way leading calculations
      -- get very complicated...
      -- typesetterPool[frame].leadingFor = function() return SILE.types.node.vglue(SILE.settings:get("document.lineskip")) end
      local fontcommand = frame .. ":font"
      self:registerCommand(frame, function(_, _) -- \left ...
         SILE.typesetter = typesetterPool[frame]
         SILE.call(fontcommand)
      end)
      if not SILE.Commands[fontcommand] then
         self:registerCommand(fontcommand, function(_, _) end) -- to be overridden
      end
   end

   -- Initialize typesetters for each footnote frame.
   for frame, typesetter in pairs(options.ftn_frames) do
      footnotePool[frame] = SILE.typesetters.base(SILE.getFrame(typesetter))
      footnotePool[frame].id = typesetter

      -- Do not disable auto page-building here, as it is required for typesetting
      -- footnotes on the last page of the document.
   end

   if not options.folios then
      folioOrder = { {} }
      -- Note output order doesn't matter for PDF, but for our test suite it is
      -- essential that the output order is deterministic, hence this sort()
      for frame, _ in pl.tablex.sort(options.frames) do
         table.insert(folioOrder[1], frame)
      end
   else
      folioOrder = options.folios -- As usual we trust the user knows what they're doing
   end
   self.class.newPage = function(self_)
      allTypesetters(function(frame, _)
         calculations[frame] = { mark = 0 }
      end)
      self.class._base.newPage(self_)
      SILE.call("sync")
   end
   allTypesetters(function(frame, _)
      calculations[frame] = { mark = 0 }
   end)
   local oldfinish = self.class.finish
   self.class.finish = function(self_)
      parallelPagebreak()
      oldfinish(self_)
   end
end

function package:registerCommands()
   -- shortcut for \parskip
   self:registerCommand("parskip", function(options, _)
      local height = options.height or "12pt plus 3pt minus 1pt"
      SILE.typesetter:leaveHmode()
      SILE.typesetter:pushExplicitVglue(SILE.types.length(height))
   end)

   -- Synchronize frame heights and handle page breaks.
   self:registerCommand("sync", function(_, _)
      local anybreak = false
      local maxheight = SILE.types.length()

      -- Check for potential page breaks.
      allTypesetters(function(_, typesetter)
         typesetter:leaveHmode(true)
         local lines = pl.tablex.copy(typesetter.state.outputQueue)
         if SILE.pagebuilder:findBestBreak({ vboxlist = lines, target = typesetter:getTargetLength() }) then
            anybreak = true
         end
      end)

      -- Perform a page break if necessary.
      if anybreak then
         parallelPagebreak()
         return
      end

      -- Calculate the height of new material for balancing.
      allTypesetters(function(frame, typesetter)
         calculations[frame].heightOfNewMaterial = calculateFrameHeight(frame, typesetter)
         if calculations[frame].heightOfNewMaterial > maxheight then
            maxheight = calculations[frame].heightOfNewMaterial
            SU.debug(package._name, "Value of maxheight after balancing for frame ", frame, ": ", maxheight)
         end
      end)

      -- Add balancing glue to align frame heights.
      addBalancingGlue(maxheight)

      -- Handle parskip (spacing between successive frames).
      local parskip = SILE.settings:get("document.parskip")

      if not parskip.length then
         -- Insert default parskip value if not defined.
         addParskipToFrames(SILE.types.length("12pt plus 3pt minus 1pt"))
      else
         -- Use user-defined parskip value.
         addParskipToFrames(parskip)
      end
   end)

   self:registerCommand("smaller", function(_, content)
      SILE.settings:temporarily(function()
         local currentSize = SILE.settings:get("font.size")
         SILE.settings:set("font.size", currentSize * 0.75) -- Scale down to 75%
         SILE.settings:set("font.weight", 800)
         SILE.process(content)
      end)
   end)

   self:registerCommand("footnoteNumber", function(options, content)
      local height = options.height or "0.3em" -- Default height for superscripts
      SILE.call("raise", { height = height }, function()
         SILE.call("smaller", {}, function()
            SILE.process(content)
         end)
      end)
   end)

   -- Adapted from the `resilient.footnotes` package.
   -- Defines `parallel_footnote:rule`, a helper command for setting a footnote rule.
   self:registerCommand("parallel_footnote:rule", function(options, _)
      local width = SU.cast("measurement", options.width or "20%fw") -- Default: 1/5 of the text block width.
      local beforeskipamount = SU.cast("vglue", options.beforeskipamount or "1ex") -- Space before the rule.
      local afterskipamount = SU.cast("vglue", options.afterskipamount or "1ex") -- Space after the rule.
      local thickness = SU.cast("measurement", options.thickness or "0.5pt") -- Thickness of the rule.

      SILE.call("noindent")
      SILE.call("rebox", {}, function()
         SILE.call("hrule", { width = width, height = thickness })
      end)
      SILE.typesetter:leaveHmode()
      SILE.typesetter:pushExplicitVglue(afterskipamount)
   end, "Helper command for setting a footnote rule.")

end

package.documentation = [[
\begin{document}
The \autodoc:package{parallel} package provides the mechanism for typesetting diglot or other parallel documents.
When used by a class such as \code{classes/diglot.lua}, it registers a command for each parallel frame, to allow you to select which frame you’re typesetting into.
It also defines the \autodoc:command{\sync} command, which adds vertical spacing to each frame such that the \em{next} set of text is vertically aligned.
See \url{https://sile-typesetter.org/examples/parallel.sil} and the source of \code{classes/diglot.lua} for examples which make the operation clear.
\end{document}
]]

return package
