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

-- Measure the width of a string in the current font context, typically used for footnote markers.
local measureStringWidth = function(str)
   -- Shape the string using the current font settings.
   local shapedText = SILE.shaper:shapeToken(str, SILE.font.loadDefaults({}))

   -- Calculate the total width by summing the widths of all glyphs.
   local totalWidth = 0
   for _, glyph in ipairs(shapedText) do
      totalWidth = totalWidth + glyph.width
   end

   return totalWidth
end

-- Create a unique id for each footnote
local function generateFootnoteId(frame, note)
   return frame .. ":" .. note.marker
end

local function getFootnoteHeight(frame, note, typesetter)
   local noteId = generateFootnoteId(frame, note)

   -- Simulate typesetting to calculate height
   local noteQueue = {}
   typesetter:pushState()
   -- Redirect the output queue to the noteQueue
   typesetter.state.outputQueue = noteQueue
   SILE.call("parallel_footnote:constructor", { marker = note.marker }, note.content)
   typesetter:popState()

   -- Measure the height of the simulated queue
   local noteHeight = 0
   for _, node in ipairs(noteQueue) do
      noteHeight = noteHeight + node.height:absolute():tonumber() + node.depth:absolute():tonumber()
   end

   -- Cache the calculated height
   footnoteHeightCache[noteId] = noteHeight
   -- Return the calculated height and the simulated noteQueue for footnote content
   -- the noteQueue will be used later to for spliting if needed
   return noteHeight, noteQueue
end

-- Typeset footnotes for each frame, handling overflow and splitting across pages if necessary.
local typesetFootnotes = function()
   for frame, notes in pairs(footnotes) do
      if notes and #notes > 0 then
         log("Processing footnotes for frame: " .. frame)

         local typesetter = footnotePool[frame]
         typesetter:initFrame(typesetter.frame)
         SILE.typesetter = typesetter

         -- Add a rule above the footnotes
         SILE.call("parallel_footnote:rule")

         local nextPageNotes = {}

         SILE.settings:temporarily(function()
            SILE.call("break") -- To prevent the firt footnote being streched across the frame

            local targetHeight = typesetter:getTargetLength():tonumber()
            local currentHeight = 0
            local baselineSkip = SILE.settings:get("document.baselineskip").height:tonumber() * 0.30

            for i, note in ipairs(notes) do
               -- Get the cached or calculated height and simulated noteQueue
               local noteHeight, noteQueue = getFootnoteHeight(frame, note, typesetter)

               -- Adjust for baseline skip
               if i > 1 then
                  noteHeight = noteHeight + baselineSkip
               end

               if currentHeight + noteHeight <= targetHeight then
                  -- Add baseline skip before adding the note (except the first note)
                  if i > 1 then
                     table.insert(typesetter.state.outputQueue, SILE.types.node.vglue(SILE.types.length(baselineSkip)))
                  end

                  -- Note fits entirely
                  currentHeight = currentHeight + noteHeight
                  for _, node in ipairs(noteQueue) do
                     table.insert(typesetter.state.outputQueue, node)
                  end
               else
                  -- Note needs to be split
                  local fittedQueue = {}
                  local remainingQueue = {}
                  local fittedHeight = 0

                  for _, node in ipairs(noteQueue) do
                     local nodeHeight = node.height:absolute():tonumber() + node.depth:absolute():tonumber()
                     if fittedHeight + nodeHeight <= (targetHeight - currentHeight) then
                        table.insert(fittedQueue, node)
                        fittedHeight = fittedHeight + nodeHeight
                     else
                        -- Whatever does not fit is sent to the remaining queue
                        table.insert(remainingQueue, node)
                     end
                  end

                  -- Flush noteQueue from the memory for optimization
                  noteQueue = nil

                  -- Add fitted part to the current frame
                  if #typesetter.state.outputQueue > 0 then
                     table.insert(typesetter.state.outputQueue, SILE.types.node.vglue(SILE.types.length(baselineSkip)))
                  end

                  currentHeight = currentHeight + fittedHeight
                  for _, node in ipairs(fittedQueue) do
                     table.insert(typesetter.state.outputQueue, node)
                  end

                  -- Typeset the fitted part to the current frame
                  typesetter:outputLinesToPage(typesetter.state.outputQueue)

                  -- Reset output queue and move on
                  typesetter.state.outputQueue = {}

                  -- Create a new "split" note and add notes to the next page
                  if #remainingQueue > 0 then
                     local contentFunc = function()
                        for _, node in ipairs(remainingQueue) do
                           table.insert(SILE.typesetter.state.outputQueue, node)
                        end
                     end
                     table.insert(nextPageNotes, {
                        -- Suppress the footnote marker for the overflowed note
                        marker = "",
                        content = contentFunc,
                     })
                  end
               end
            end

            -- Output any remaining content
            if typesetter.state.outputQueue and #typesetter.state.outputQueue > 0 then
               typesetter:outputLinesToPage(typesetter.state.outputQueue)
            else
               SU.warn("No content to output for frame: " .. frame)
            end

            -- Add remaining notes to the next page
            footnotes[frame] = nextPageNotes

            -- Reset output queue after typesetting the remaining footnote content
            typesetter.state.outputQueue = {}
         end)
      else
         log("No footnotes to process for frame: " .. frame)
      end
   end
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
      typesetFootnotes()

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

function package:_init (options)
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

   self:registerCommand("parallel_footnote:constructor", function(options, content)
      local markerText = options.marker or "?" -- Default marker if none provided

      SILE.settings:temporarily(function()
         -- Set font footnotes, 80% of current font size
         SILE.settings:set("font.size", SILE.settings:get("font.size") * 0.80)

         -- Measure the marker width
         local markerWidth = measureStringWidth(markerText)

         -- Set hanging indentation
         local hangIndent = SILE.types.length("14.4pt"):absolute()
         SILE.settings:set("current.hangAfter", 1) -- Indent subsequent lines
         SILE.settings:set("current.hangIndent", hangIndent)

         -- Calculate the gap after the marker
         local markerGap = hangIndent - markerWidth

         -- Typeset the marker
         SILE.typesetter:typeset(markerText)

         -- Add spacing after the marker for alignment
         SILE.call("kern", { width = markerGap })

         -- Process the footnote content
         SILE.process(content)

         -- End the paragraph
         SILE.call("par")
      end)
   end)

   self:registerCommand("parallel_footnote", function(options, content)
      local currentFrame = SILE.typesetter.frame.id
      local targetFrame = currentFrame == "a" and "ftn_left" or "ftn_right"

      -- Increment or retrieve the footnote counter for the target frame
      local footnoteNumber
      if not options.mark then
         SILE.call("increment-counter", { id = targetFrame })
         footnoteNumber = self.class.packages.counters:formatCounter(SILE.scratch.counters[targetFrame])
      else
         footnoteNumber = options.mark
      end

      -- Add the footnote marker to the text
      SILE.call("footnoteNumber", {}, function()
         SILE.typesetter:typeset(footnoteNumber)
      end)

      -- Add the footnote content to the frame's list
      if footnotes[targetFrame] then
         table.insert(footnotes[targetFrame], {
            -- number = footnoteNumber,
            marker = tostring(footnoteNumber) .. ".",
            content = content,
         })
      end
   end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{parallel} package provides a mechanism for typesetting diglot or other parallel documents. When used by a class such as \code{classes/diglot.lua}, it registers a command for each parallel frame, allowing users to select which frame to typeset into.

The package defines the \autodoc:command{\sync} command, which adds vertical spacing to the bottom of each frame to ensure that the \em{next} set of text is horizontally aligned. It also supports independent footnote flows and counters for each frame. Footnotes can be typeset using \autodoc:command{\parallel_footnote}, with styles adopted from the \code{resilient.footnotes} package. Note that \code{document.parskip} is not supported due to manual manipulation of \code{typesetter.state.outputQueue}. Therefore, to start a new paragraph within a frame, users must manually use the \autodoc:command{\parskip} command.

This package is under development and not yet fully mature. Testing has shown that it works best with a font size of 12pt from the \strong{Gentium Plus} family. Custom settings for \code{document.parskip}, \code{document.baselineskip}, or using different font sizes between frames may disrupt frame alignment, making precise alignment challenging.

Frame alignment in parallel typesetting is particularly tricky because it involves multiple interdependent variables and processes that must be carefully synchronized to produce visually cohesive results. Each frame may contain varying amounts of content, leading to differences in height between frames. The height of each frame depends on its content, including typeset text, insertions (e.g., footnotes), and vertical glue. Manual adjustments (e.g., custom \code{baselineSkip}, \code{parSkip}, or font sizes) are often required, further complicating alignment.

SILE’s default page builder operates on a single vertical stream, while parallel typesetting demands handling multiple streams (frames) independently while maintaining their horizontal alignment. This requires custom page-breaking and alignment logic to synchronize the streams. Manually tracking and adjusting frame heights by applying stretchy glue is essential for achieving proper alignment.

Insertions like footnotes add further complexity, as they occupy independent frames and their content flows dynamically. Ensuring these dynamic insertions do not disrupt frame alignment is challenging. When footnotes overflow, splitting them across pages can result in misalignment or compressed content if not carefully managed.

Using different font sizes or baselines for frames (e.g., for bilingual text) requires fine-tuning \code{baselineSkip}, \code{lineSkip}, or \code{parskip} settings to maintain alignment. Frames may also have varying widths or layout constraints, making it difficult to directly compare their heights.

Dynamic content, such as varying paragraph lengths, images, or tables, can lead to unpredictable behavior in each frame. Frequent recalibration is necessary to address these issues. Managing overflow content for the main frames and their footnote counterparts without disrupting alignment adds yet another layer of complexity.
To align frames reasonably, dummy content or vertical glue is often added to the shorter frame. However, such calculations must be precise to avoid visual artifacts caused by estimation errors. Even minor inaccuracies in frame height or glue calculations can result in misalignment.

SILE is primarily designed for single-frame typesetting, with limited native support for parallel or multi-frame layouts. Consequently, most parallel typesetting functionality must be implemented manually, requiring a deep understanding of SILE’s internals. Achieving proper frame alignment often involves trial and error, such as adding dummy text or phantom boxes to fine-tune the layout.

Synchronizing frames across pages involves recalculating frame heights when a new page is entered, managing footnotes, and ensuring consistent alignment. Frequent synchronization can be computationally expensive, particularly for complex or lengthy documents.

Parallel typesetting demands pixel-perfect precision to avoid noticeable misalignment. Achieving such precision often sacrifices flexibility when handling variable content. Users may need to create separate document classes tailored to specific documents.

For examples and further details, see \url{https://sile-typesetter.org/examples/parallel.sil} and the source code of \code{classes/diglot.lua}.
\end{document}
]]

return package
