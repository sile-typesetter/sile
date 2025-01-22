local base = require("packages.base")

local package = pl.class(base)
package._name = "parallel"

-- Helper function for logging
local debugMode = true -- Set to true for debugging
local log = function(...)
   if debugMode then
      SU.debug(package._name, ...)
   end
end

-- Typesetter pool for managing typesetters for different frames (e.g., left and right frames).
local typesetterPool, footnotePool = {}, {}

-- Make sure you have ftn_left and ftn_right frames setup in your document class
-- Encapsulate the logic for managing footnotes.
local FootnoteManager = {}
FootnoteManager.__index = FootnoteManager

-- Initialize the FootnoteManager
function FootnoteManager:new()
   return setmetatable({ frames = { ftn_left = {}, ftn_right = {} } }, self)
end

-- Add a footnote to the manager
function FootnoteManager:add(frame, note)
   table.insert(self.frames[frame], note)
end

-- Get footnotes for a specific frame
function FootnoteManager:get(frame)
   return self.frames[frame]
end

-- Iterate over footnotes for a specific frame
function FootnoteManager:processNotes(frame, callback)
   for _, note in ipairs(self.frames[frame]) do
      callback(note)
   end
end

-- Create an instance of the FootnoteManager
local footnoteManager = FootnoteManager:new()

-- Cache the height of each footnote for optimization
FootnoteManager.footnoteHeightCache = {}

-- Stores layout calculations for each frame, such as height, marking and overflow tracking.
local calculations = {}

-- Specifies the order of frames for synchronizing and page-breaking logic.
local folioOrder = {}

-- A null typesetter used as a placeholder. This typesetter doesn't output any content.
-- Its purpose is to make the transtion between frames easier and trouble free.
local nulTypesetter = pl.class(SILE.typesetters.base)
nulTypesetter.outputLinesToPage = function() end -- Override to suppress output

-- Utility function: Iterate over typesetters in a pool and apply a callback function.
local iterateTypesetters = function(pool, callback)
   local oldtypesetter = SILE.typesetter
   for frame, typesetter in pairs(pool) do
      SILE.typesetter = typesetter
      callback(frame, typesetter)
   end
   SILE.typesetter = oldtypesetter
end

-- Utility function: Calculate the height of new material for a given frame.
local calculateFrameHeight = function(frame, typesetter)
   local height = calculations[frame].cumulativeHeight or SILE.types.length()
   -- Cache the state of the output queue to avoid recalculating from mark every time
   local lines = typesetter.state.outputQueue

   -- typesetter.state.outputQueue now holds actual content reflecting the real layout of lines.
   -- Therefore, we can calculate the height of new material by adding the height of each line
   -- in the queue.

   for i = calculations[frame].mark + 1, #lines do
      height = height + lines[i].height + lines[i].depth
   end

   return height
end

-- Utility function: Add a phantom box to the current frame.
local addPhantomHeight = function(height)
   SILE.call("rebox", { height = height, phantom = true })
end

-- Utility function: Manage the heights of frames.
local manageFrameHeights = function(frames, callback)
   local frameHeights = {}
   local maxHeight = SILE.types.length()

   -- Calculate the height of new material for each frame
   iterateTypesetters(frames, function(frame, typesetter)
      local height = calculateFrameHeight(frame, typesetter)
      frameHeights[frame] = height
      if height > maxHeight then
         maxHeight = height
      end
   end)

   -- Apply the callback function to each frame
   iterateTypesetters(frames, function(frame, typesetter)
      callback(frame, frameHeights[frame], maxHeight - frameHeights[frame])
   end)
end

-- Balance the heights of frames by adding dummy content to shorter frames.
-- This ensures that all frames are aligned to the height of the tallest frame.
local balanceFramesWithPhantomBox = function()
   manageFrameHeights(typesetterPool, function(frame, currentHeight, heightDiff)
      if heightDiff:tonumber() > 0 then
         addPhantomHeight(heightDiff)
         log("Added phantom height of", heightDiff, "to frame", frame)
      end
   end)
end

-- Balances the height of content across frames by adding glue to the shorter frame.
local addBalancingGlue = function()
   manageFrameHeights(typesetterPool, function(frame, currentHeight, heightDiff)
      if heightDiff:tonumber() > 0 then
         -- Add vkern (vertical glue) to balance the frame height
         local typesetter = typesetterPool[frame]
         table.insert(typesetter.state.outputQueue, SILE.types.node.vkern({ height = heightDiff }))
         log("Added balancing glue of", heightDiff, "to bottom of frame", frame)
      end
   end)
end

-- Adds a flexible glue (parskip) to the bottom of each frame
-- This is decoupled from addBalancingGlue calculations, serving a simple purpose.
local addParskipToFrames = function(parskipHeight)
   iterateTypesetters(typesetterPool, function(_, typesetter)
      table.insert(typesetter.state.outputQueue, SILE.types.node.vglue({ height = parskipHeight }))
   end)
end

-- Create a unique id for each footnote
function FootnoteManager:generateFootnoteId(frame, note)
   return frame .. ":" .. note.marker
end

function FootnoteManager:getFootnoteHeight(frame, note, typesetter)
   local noteId = self:generateFootnoteId(frame, note)

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
   self.footnoteHeightCache[noteId] = noteHeight

   -- Return the calculated height and the simulated noteQueue for footnote content
   -- the noteQueue will be used later to for spliting if needed
   return self.footnoteHeightCache[noteId], noteQueue
end

-- Typeset footnotes for each frame, handling overflow and splitting across pages if necessary.
function FootnoteManager:preprocessFrame(frame, typesetter)
   typesetter:initFrame(typesetter.frame)
   SILE.typesetter = typesetter

   -- Add a rule above the footnotes
   SILE.call("parallel_footnote:rule")

   return {
      targetHeight = typesetter:getTargetLength():tonumber(),
      currentHeight = 0,
      baselineSkip = SILE.settings:get("document.baselineskip").height:tonumber() * 0.40,
      nextPageNotes = {},
   }
end

function FootnoteManager:processSingleNote(frame, note, context, typesetter)
   local noteHeight, noteQueue = self:getFootnoteHeight(frame, note, typesetter)

   -- Adjust for baseline skip
   if context.currentIndex > 1 then
      noteHeight = noteHeight + context.baselineSkip
   end

   if context.currentHeight + noteHeight <= context.targetHeight then
      -- Note fits entirely
      if context.currentIndex > 1 then
         table.insert(typesetter.state.outputQueue, SILE.types.node.vglue(SILE.types.length(context.baselineSkip)))
      end

      context.currentHeight = context.currentHeight + noteHeight
      for _, node in ipairs(noteQueue) do
         table.insert(typesetter.state.outputQueue, node)
      end
   else
      -- Note needs to be split
      self:handleOverflowingNote(noteQueue, context, typesetter)
   end
end

function FootnoteManager:handleOverflowingNote(noteQueue, context, typesetter)
   local fittedQueue, remainingQueue = {}, {}
   local fittedHeight = 0

   for _, node in ipairs(noteQueue) do
      local nodeHeight = node.height:absolute():tonumber() + node.depth:absolute():tonumber()
      if fittedHeight + nodeHeight <= (context.targetHeight - context.currentHeight) then
         table.insert(fittedQueue, node)
         fittedHeight = fittedHeight + nodeHeight
      else
         table.insert(remainingQueue, node)
      end
   end

   -- Add fitted part to the current frame
   if #typesetter.state.outputQueue > 0 then
      table.insert(typesetter.state.outputQueue, SILE.types.node.vglue(SILE.types.length(context.baselineSkip)))
   end

   context.currentHeight = context.currentHeight + fittedHeight
   for _, node in ipairs(fittedQueue) do
      table.insert(typesetter.state.outputQueue, node)
   end

   -- Typeset the fitted part
   typesetter:outputLinesToPage(typesetter.state.outputQueue)

   -- Reset output queue
   typesetter.state.outputQueue = {}

   -- Add remaining notes to the next page
   if #remainingQueue > 0 then
      local contentFunc = function()
         for _, node in ipairs(remainingQueue) do
            table.insert(SILE.typesetter.state.outputQueue, node)
         end
      end
      table.insert(context.nextPageNotes, {
         marker = "", -- Suppress marker for overflowed notes
         content = contentFunc,
      })
   end
end

function FootnoteManager:finalizeFrame(frame, context, typesetter)
   -- Output any remaining content
   if typesetter.state.outputQueue and #typesetter.state.outputQueue > 0 then
      typesetter:outputLinesToPage(typesetter.state.outputQueue)
   else
      SU.warn("No content to output for frame: " .. frame)
   end

   -- Add remaining notes to the next page
   self.frames[frame] = context.nextPageNotes

   -- Reset output queue
   typesetter.state.outputQueue = {}
end

function FootnoteManager:typesetFootnotes()
   for frame, notes in pairs(self.frames) do
      if notes and #notes > 0 then
         log("Processing footnotes for frame: " .. frame)

         local typesetter = footnotePool[frame]
         local context = self:preprocessFrame(frame, typesetter)

         SILE.settings:temporarily(function()
            SILE.call("break") -- Prevent the first footnote from being stretched across the frame

            -- Use `processNotes` to iterate through notes and process them
            self:processNotes(frame, function(note)
               context.currentIndex = context.currentIndex or 0
               context.currentIndex = context.currentIndex + 1
               self:processSingleNote(frame, note, context, typesetter)
            end)

            self:finalizeFrame(frame, context, typesetter)
         end)
      else
         log("No footnotes to process for frame: " .. frame)
      end
   end
end

-- Handles page-breaking logic for parallel frames.
local parallelPagebreak = function()
   for _, thisPageFrames in ipairs(folioOrder) do
      local hasOverflow = false
      local overflowContent = {}

      -- Process each frame for overflow content
      iterateTypesetters(typesetterPool, function(frame, typesetter)
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
            -- overflowContent[frame] = linesToFit
            overflowContent[frame] = pl.tablex.copy(linesToFit)
            -- Reset output queue to avoid double processing
            typesetter.state.outputQueue = {}
         else
            overflowContent[frame] = {}
         end

         typesetter:outputLinesToPage(thispage)
      end)

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
         balanceFramesWithPhantomBox()
      end
   end

   -- Ensure all the first pair of frames on the new page are synchronized
   SILE.call("sync")
end

-- Initialization function for the package.
function package:_init(options)
   base._init(self, options)

   -- Load necessary packages
   self:loadPackage("rebox") -- for footnote:rule
   self:loadPackage("rules") -- for footnote:rule
   self:loadPackage("counters") -- for footnote counting
   self:loadPackage("raiselower") -- for footnote superscript mark
   -- Load the `resilient.footnotes` package for the footenot:mark style.
   -- self:loadPackage("resilient.footnotes")

   -- Initialize the null typesetter.
   SILE.typesetter = nulTypesetter(SILE.getFrame("page"))

   -- Ensure the `frames` option is provided.
   if type(options.frames) ~= "table" or type(options.ftn_frames) ~= "table" then
      SU.error("Package parallel must be initialized with a set of appropriately named frames")
   end

   -- Set up typesetters for each frame.
   for frame, typesetter in pairs(options.frames) do
      typesetterPool[frame] = SILE.typesetters.base(SILE.getFrame(typesetter))
      typesetterPool[frame].id = typesetter
      typesetterPool[frame].buildPage = function() end -- Disable auto page-building

      -- Register commands (e.g., \left, \right) for directing content to frames.
      local fontcommand = frame .. ":font"
      self:registerCommand(frame, function(_, _)
         SILE.typesetter = typesetterPool[frame]
         SILE.call(fontcommand)
      end)

      -- Define default font commands for frames if not already defined.
      if not SILE.Commands[fontcommand] then
         self:registerCommand(fontcommand, function(_, _) end)
      end
   end

   -- Set up typesetters for each footnote frame.
   for frame, typesetter in pairs(options.ftn_frames) do
      footnotePool[frame] = SILE.typesetters.base(SILE.getFrame(typesetter))
      footnotePool[frame].id = typesetter
      -- You should not disable the auto page-building here, otherwise you can't typeset
      -- any footnotes on the last page of your document.
   end

   -- Configure the order of frames for the folio (page layout).
   if not options.folios then
      folioOrder = { {} }
      for frame, _ in pl.tablex.sort(options.frames) do
         table.insert(folioOrder[1], frame)
      end
   else
      folioOrder = options.folios
   end

   -- Customize the `newPage` method to synchronize frames.
   -- Ensure that each new page starts clean but balanced
   self.class.newPage = function(self_)
      self.class._base.newPage(self_)

      -- Reset calculations
      iterateTypesetters(typesetterPool, function(frame, _)
         calculations[frame] = { mark = 0 }
      end)

      -- Align and balance frames
      SILE.call("sync")
   end

   -- Initialize calculations for each frame.
   iterateTypesetters(typesetterPool, function(frame, _)
      calculations[frame] = { mark = 0 }
   end)

   -- Override the `finish` method to handle parallel page-breaking.
   local oldfinish = self.class.finish
   self.class.finish = function(self_)
      parallelPagebreak()
      oldfinish(self_)
   end
end

-- Registers commands for the package.
function package:registerCommands()
   -- Helper function for registering simple commands
   local registerSimpleCommand = function(name, func)
      self:registerCommand(name, func)
   end

   -- Register the parskip command
   registerSimpleCommand("parskip", function(options, _)
      local height = options.height or "1em"
      SILE.typesetter:leaveHmode()
      SILE.typesetter:pushExplicitVglue(SILE.types.length(height):absolute())
   end)

   self:registerCommand("sync", function(_, _)
      local anybreak = false

      -- Check for potential page breaks.
      iterateTypesetters(typesetterPool, function(_, typesetter)
         -- Flush pending markers
         typesetter:leaveHmode(true)

         -- Copy the current output queue for the page builder
         local lines = pl.tablex.copy(typesetter.state.outputQueue)

         -- Invoke the page builder
         if SILE.pagebuilder:findBestBreak({ vboxlist = lines, target = typesetter:getTargetLength() }) then
            anybreak = true
         end
      end)

      -- Perform a page break if necessary.
      if anybreak then
         parallelPagebreak()
         return
      end

      -- Typeset footnotes after ensuring all main text is processed
      footnoteManager:typesetFootnotes()

      -- Add balancing glue to align frame heights
      addBalancingGlue()

      -- Retrieve the parskip setting
      local parskip = SILE.settings:get("document.parskip")

      -- Add parskip to frames based on the setting
      if not parskip or parskip.height:tonumber() == 0 then
         -- Insert flexible glue if parskip is nil or zero
         addParskipToFrames(SILE.types.length("1em"):absolute())
      else
         -- Use the user-defined parskip value
         addParskipToFrames(parskip)
      end
   end)

   registerSimpleCommand("footnoteNumber", function(options, content)
      local height = options.height or "0.3em" -- Default height for superscripts
      SILE.settings:temporarily(function()
         SILE.call("raise", { height = height }, function()
            SILE.call("font", { size = "0.75em" }, function()
               SILE.settings:set("font.weight", 600)
               SILE.process(content)
            end)
         end)
      end)
   end)

   -- Stolen from `resilient.footnotes` package
   registerSimpleCommand("parallel_footnote:rule", function(options, _)
      local width = SU.cast("measurement", options.width or "20%fw") -- "Usually 1/5 of the text block"
      local beforeskipamount = SU.cast("vglue", options.beforeskipamount or "1ex")
      local afterskipamount = SU.cast("vglue", options.afterskipamount or "1ex")
      local thickness = SU.cast("measurement", options.thickness or "0.5pt")
      SILE.call("noindent")
      -- SILE.typesetter:pushExplicitVglue(beforeskipamount)
      SILE.call("rebox", {}, function()
         SILE.call("hrule", { width = width, height = thickness })
      end)
      SILE.typesetter:leaveHmode()
      SILE.typesetter:pushExplicitVglue(afterskipamount)
   end, "Small helper command to set a footnote rule.")

   registerSimpleCommand("parallel_footnote:constructor", function(options, content)
      local markerText = options.marker or "?" -- Default marker if none provided
      local initialHangIndent = SILE.types.length("1.25em"):absolute() -- Initial hanging indent

      SILE.settings:temporarily(function()
         -- Set font for footnotes, 80% of current font size
         SILE.call("font", { size = "0.8em" }, function()
            -- Create a marker box and measure its width
            local markerBox = SILE.typesetter:makeHbox({ markerText })
            local markerWidth = markerBox.width:tonumber() -- Convert to number

            -- Start with the initial hangIndent as the base value
            local hangIndent = initialHangIndent:tonumber()

            -- Calculate the gap after the marker
            local markerGap = math.max(0.25 * hangIndent, hangIndent - markerWidth)

            -- Adjust hangIndent if the markerGap is greater than expected
            if markerGap > hangIndent - markerWidth then
               hangIndent = markerWidth + markerGap
            end

            -- Apply the updated values to the settings
            SILE.settings:set("document.lskip", SILE.types.length(hangIndent))
            SILE.settings:set("document.parindent", SILE.types.length(-hangIndent))

            -- Push the marker box and adjust the alignment gap
            SILE.typesetter:pushHbox(markerBox)
            SILE.call("kern", { width = markerGap })

            -- Process the footnote content
            SILE.process(content)
            SILE.call("par") -- End the paragraph
         end)
      end)
   end)

   registerSimpleCommand("parallel_footnote", function(options, content)
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

      -- Add the footnote to the manager
      footnoteManager:add(targetFrame, {
         marker = tostring(footnoteNumber) .. ".",
         content = content,
      })
   end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{parallel} package provides a mechanism for typesetting diglot or other parallel documents. When used by a class such as \code{classes/diglot.lua}, it registers a command for each parallel frame, allowing users to select which frame to typeset into.

The package defines the \autodoc:command{\sync} command, which adds vertical spacing to the bottom of each frame to ensure that the \em{next} set of text is horizontally aligned. It also supports independent footnote flows and counters for each frame. Footnotes can be typeset using \autodoc:command{\parallel_footnote}, with styles adopted from the \code{resilient.footnotes} package. Note that \code{document.parskip} is not supported due to manual manipulation of \code{typesetter.state.outputQueue}. Therefore, to start a new paragraph within a frame, users must manually use the \autodoc:command{\parskip} command.

This package is under development and not yet fully mature. Testing indicates that it performs best with a font size of 12pt from the \strong{Gentium Plus} family and with \code{document.parskip} either unset or set to 0pt. Customizing \code{document.parskip}, \code{document.baselineskip}, or using different font families and  sizes between frames can disrupt alignment, making precise frame alignment challenging.

Frame alignment in parallel typesetting is particularly tricky because it involves multiple interdependent variables and processes that must be carefully synchronized to produce visually cohesive results. Each frame may contain varying amounts of content, leading to differences in height between frames. The height of each frame depends on its content, including typeset text, insertions (e.g., footnotes), and vertical glue. Manual adjustments (e.g., custom \code{baselineSkip}, \code{parSkip}, or font sizes) are often required, further complicating alignment.

SILE’s default page builder operates on a single vertical stream, while parallel typesetting demands handling multiple streams (frames) independently while maintaining their horizontal alignment. This requires custom page-breaking and alignment logic to synchronize the streams. Manually tracking and adjusting frame heights by applying stretchy glue is essential for achieving proper alignment.

Insertions like footnotes add further complexity, as they occupy independent frames and their content flows dynamically. Ensuring these dynamic insertions do not disrupt frame alignment is challenging. When footnotes overflow, splitting them across pages can result in misalignment or compressed content if not carefully managed.

Using different font sizes or baselines for frames (e.g., for bilingual text) requires fine-tuning \code{baselineSkip}, \code{lineSkip}, or \code{parskip} settings to maintain alignment. Frames may also have varying widths or layout constraints, making it difficult to directly compare their heights.

Dynamic content, such as varying paragraph lengths, images, or tables, can lead to unpredictable behavior in each frame. Frequent recalibration is necessary to address these issues. Managing overflow content for the main frames and their footnote counterparts without disrupting alignment adds yet another layer of complexity.
To align frames effectively, dummy content, vertical glue, or phantom boxes are often added to the shorter frame. However, these adjustments require precise calculations to avoid visual artifacts caused by estimation errors. Even small inaccuracies in frame height or glue measurements can lead to noticeable misalignment.

SILE is primarily designed for single-frame typesetting, with limited native support for parallel or multi-frame layouts. Consequently, most parallel typesetting functionality must be implemented manually, requiring a deep understanding of SILE’s internals. Achieving proper frame alignment often involves trial and error, such as adding dummy text or phantom boxes to fine-tune the layout.

Synchronizing frames across pages involves recalculating frame heights when a new page is entered, managing footnotes, and ensuring consistent alignment. Frequent synchronization can be computationally expensive, particularly for complex or lengthy documents.

Parallel typesetting demands pixel-perfect precision to avoid noticeable misalignment. Achieving such precision often sacrifices flexibility when handling variable content. Users may need to create separate document classes tailored to specific documents.

For examples and further details, see \url{https://sile-typesetter.org/examples/parallel.sil} and the source code of \code{classes/diglot.lua} or \url{https://github.com/no-vici/parallel_typesetting}.
\end{document}
]]

return package
