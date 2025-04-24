----------------------------------------------------------------
--  parallel – multi–frame / diglot typesetting for SILE
----------------------------------------------------------------
--
--  This file can simply be dropped into ⟨project⟩/packages
--  or placed in a $SILE_HOME search path.  The only external
--  requirement is plain (pl) which ships with SILE.
--
----------------------------------------------------------------
local base = require("packages.base")
local package = pl.class(base)
package._name = "parallel"

----------------------------------------------------------------
--  Debug / trace helper
----------------------------------------------------------------
local DEBUG = true -- ⇐ flip to false in production
local log = function(...)
   if DEBUG then
      SU.debug(package._name, ...)
   end
end

----------------------------------------------------------------
--  Two pools of typesetters: main‑text frames & footnote frames
----------------------------------------------------------------
local typesetterPool, footnotePool = {}, {}

----------------------------------------------------------------
--  Misc. shared state tables
----------------------------------------------------------------
local calculations = {} -- running height / mark bookkeeping
local folioOrder = {} -- frame order on the physical page

----------------------------------------------------------------
--  A no‑op typesetter (used once during class initialisation)
----------------------------------------------------------------
local NullTypesetter = pl.class(SILE.typesetters.default)
NullTypesetter.outputLinesToPage = function() end

----------------------------------------------------------------
--  Footnote manager (all footnote logic is encapsulated here)
----------------------------------------------------------------
local FootnoteManager = {}
FootnoteManager.__index = FootnoteManager

function FootnoteManager:new()
   return setmetatable({
      frames = { ftn_left = {}, ftn_right = {} },
      footnoteHeightCache = {},
   }, self)
end

function FootnoteManager:add(frame, note)
   table.insert(self.frames[frame], note)
end

function FootnoteManager:get(frame)
   return self.frames[frame]
end
function FootnoteManager:clear(frame)
   self.frames[frame] = {}
end
function FootnoteManager:processNotes(frame, fn)
   for _, n in ipairs(self.frames[frame]) do
      fn(n)
   end
end
function FootnoteManager:generateId(frame, note)
   return frame .. ":" .. note.marker
end

--  Measure the height of one footnote (with caching)
function FootnoteManager:height(frame, note, ts)
   local id = self:generateId(frame, note)
   if self.footnoteHeightCache[id] then
      return self.footnoteHeightCache[id], nil
   end

   local q = {}
   ts:pushState()
   ts.state.outputQueue = q
   SILE.call("parallel_footnote:constructor", { marker = note.marker }, note.content)
   ts:popState()

   local h = 0
   for _, node in ipairs(q) do
      h = h + node.height:absolute():tonumber() + node.depth:absolute():tonumber()
   end
   self.footnoteHeightCache[id] = h
   return h, q
end

----------------------------------------------------------------
--  Utility helpers (frame‑height accounting, phantom glue, …)
----------------------------------------------------------------
-- Utility function: Iterate over typesetters in a pool and apply a callback function.
local function iterateTypesetters(pool, callback)
   local old = SILE.typesetter
   for frame, ts in pairs(pool) do
      SILE.typesetter = ts
      callback(frame, ts)
   end
   SILE.typesetter = old
end

-- Utility function: Calculate the height of new material for a given frame.
local function calculateFrameHeight(frame, ts)
   local h = calculations[frame].cumulativeHeight or SILE.types.length()
   -- typesetter.state.outputQueue now holds actual content reflecting the real layout of lines.
   -- Therefore, we can calculate the height of new material by adding the height of each line
   -- in the queue.
   for i = calculations[frame].mark + 1, #ts.state.outputQueue do
      local ln = ts.state.outputQueue[i]
      h = h + ln.height + ln.depth
   end
   return h
end

local function addPhantomHeight(h)
   SILE.call("rebox", { height = h, phantom = true })
end

local phantomText = function(typesetter, color, text, numLines)
   SILE.call("color", { color = color }, function()
      for _ = 1, numLines do
         typesetter:typeset(text) -- Simulate actual content
         SILE.call("break")
      end
   end)
end

--  Fill a short frame with “dummy” lines so that it visually aligns
local createDummyContent = function(height, frame, dummyText)
   local typesetter = typesetterPool[frame]
   local lineHeight = SILE.settings:get("document.baselineskip").height:tonumber()
      + SILE.settings:get("document.lineskip").height:tonumber()

   local fitLines = math.floor(height:tonumber() / lineHeight)
   local remainingHeight = height:tonumber() % lineHeight

   if not dummyText then
      -- Add phantom boxes for each line
      for _ = 1, fitLines do
         addPhantomHeight(lineHeight)
      end
   else
      -- If dummyText is true, add phantom text for each line
      phantomText(typesetter, "red", "dummyText", fitLines)
   end

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
         -- addPhantomHeight(heightDiff)
         -- This seems to work better than adding dummy content. I don't know why.
         createDummyContent(heightDiff, frame, false)
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
   -- Reset noteQueue to release memory
   noteQueue = nil
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

----------------------------------------------------------------
--  Page builder for parallel frames
----------------------------------------------------------------
local footnoteManager = FootnoteManager:new()

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
         -- Typeset this page
         typesetter:outputLinesToPage(thispage)
      end)

      -- End the current page
      SILE.documentState.documentClass:endPage()

      -- At this point, all markers for the page are committed. Now typeset footnotes.
      footnoteManager:typesetFootnotes()

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

----------------------------------------------------------------
--  Font fallback (utility + public command)
----------------------------------------------------------------
local fallbackFonts = {
   "Noto Sans CJK JP",
   "Noto Sans Symbols2",
   "Symbola",
}

local function fontFallback(primary, char)
   -- 1. preferred font?
   if SILE.fonts.getGlyph(primary, char) then
      return primary
   end
   -- 2. cascade through fallbacks
   for _, fb in ipairs(fallbackFonts) do
      if SILE.fonts.getGlyph(fb, char) then
         return fb
      end
   end
   -- 3. give up, but warn once per session
   SU.warn("No glyph for U+" .. string.format("%04X", SU.codepoint(char)) .. " in fallback chain")
   return primary
end

----------------------------------------------------------------
--  Package initialisation
----------------------------------------------------------------
function package:_init(options)
   base._init(self, options)

   -- Load necessary packages
   self:loadPackage("rebox") -- for footnote:rule
   self:loadPackage("rules") -- for footnote:rule
   self:loadPackage("counters") -- for footnote counting
   self:loadPackage("raiselower") -- for footnote superscript mark
   -- Load the `resilient.footnotes` package for the footenot:mark style.
   -- self:loadPackage("resilient.footnotes")

   -- temporary no-op typesetter so class creation doesn't raise error
   SILE.typesetter = NullTypesetter(SILE.getFrame("page"))

   -- Ensure the `frames` option is provided.
   if type(options.frames) ~= "table" or type(options.ftn_frames) ~= "table" then
      SU.error("Package 'parallel' must be initialised with a set of appropriately named frames")
   end

   -- Set up typesetters for each main frame.
   for frame, typesetter in pairs(options.frames) do
      typesetterPool[frame] = SILE.typesetters.default(SILE.getFrame(typesetter))
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
      footnotePool[frame] = SILE.typesetters.default(SILE.getFrame(typesetter))
      footnotePool[frame].id = typesetter
      -- NOTE: You should not disable the auto page-building here, otherwise you can't typeset
      -- any footnotes on the last page of your document.
   end

   ---------------- folio order ----------------
   -- Configure the order of frames for the folio (page layout).
   if options.folios then
      folioOrder = options.folios
   else
      folioOrder = { {} }
      for frame, _ in pl.tablex.sort(options.frames) do
         table.insert(folioOrder[1], frame)
      end
   end

   -- Customize the `newPage` method to synchronize frames.
   -- Ensure that each new page starts clean but balanced
   self.class.newPage = function(self_)
      self.class._base.newPage(self_)

      -- Reset calculations
      iterateTypesetters(typesetterPool, function(frame, _)
         calculations[frame] = { mark = 0, cumulativeHeight = SILE.types.length(0) }
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

   registerSimpleCommand("sync", function(_, _)
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

      -- Typeset footnotes after ensuring all main text is processed.
      -- NOTE: Perhaps this should be done in the page builder?
      -- footnoteManager:typesetFootnotes()

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

   -- Adapted from `resilient.footnotes` package
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
            local markerGap = SU.max(0.25 * hangIndent, hangIndent - markerWidth)

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
      local footnoteNumber, marker
      if not options.mark then
         SILE.call("increment-counter", { id = targetFrame })
         footnoteNumber = self.class.packages.counters:formatCounter(SILE.scratch.counters[targetFrame])
         marker = tostring(footnoteNumber) .. "."
      else
         marker = options.mark
      end

      -- Add the footnote marker to the text
      SILE.call("footnoteNumber", {}, function()
         SILE.typesetter:typeset(footnoteNumber)
      end)

      -- Add the footnote to the manager
      footnoteManager:add(targetFrame, {
         marker = marker,
         content = content,
      })
   end)

   registerSimpleCommand("abstract", function(options, content)
      SILE.settings:temporarily(function()
         SILE.call("font", { size = "0.8em", style = "italic" }, function()
            SILE.settings:set("document.lskip", SILE.types.length("0.75em"))
            SILE.settings:set("document.rskip", SILE.types.length("0.75em"))
            SILE.process(content) -- Process the content passed to the abstract command
            SILE.call("par") -- Without this command the settings for lskip and rskip don't have any effect
         end)
      end)
   end)

   -- inline fallback font (user convenience)
   self:registerCommand("parallel:font-fallback", function(_, c)
      local ts = SILE.typesetter
      local out = {}
      for _, ch in ipairs(c) do
         local glyphFont = fontFallback(ts.state.font.family, ch.text)
         SILE.call("font", { family = glyphFont }, function()
            SILE.typesetter:typeset(ch.text)
         end)
      end
   end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{parallel} package provides a mechanism for typesetting diglot or other parallel documents. When used by a class such as \code{classes/diglot.lua}, it registers a command for each parallel frame, allowing users to select which frame to typeset into.

The package defines the \autodoc:command{\sync} command, which adds vertical spacing to the bottom of each frame to ensure that the \em{next} set of text is horizontally aligned. It also supports independent footnote flows and counters for each frame. Footnotes can be typeset using \autodoc:command{\parallel_footnote}, with styles adopted from the \code{resilient.footnotes} package. Note that \code{document.parskip} is not supported due to manual manipulation of \code{typesetter.state.outputQueue}. Therefore, to start a new paragraph within a frame, users must manually use the \autodoc:command{\parskip} command.

This package is under development and not yet fully mature. Testing indicates that it performs best with a font size of 12pt from the \strong{Gentium Plus} family and with \code{document.parskip} either unset or set to 0pt. Customizing \code{document.parskip}, \code{document.baselineskip}, or using different font families and sizes between frames can disrupt alignment, making precise frame alignment challenging.

Frame alignment in parallel typesetting is particularly tricky because it involves multiple interdependent variables and processes that must be carefully synchronized to produce visually cohesive results. Each frame may contain varying amounts of content, leading to differences in height between frames. The height of each frame depends on its content, including typeset text, insertions (e.g., footnotes), and vertical glue. Manual adjustments (e.g., custom \code{baselineskip}, \code{parskip}, or font sizes) are often required, further complicating alignment.

SILE’s default page builder operates on a single vertical stream, whereas parallel typesetting demands handling multiple streams (frames) independently while maintaining their horizontal alignment. This requires custom page-breaking and alignment logic to synchronize the streams. Manually tracking and adjusting frame heights by applying stretchy glue is essential for achieving proper alignment.

Insertions like footnotes add further complexity, as they occupy independent frames and their content flows dynamically. Ensuring these dynamic insertions do not disrupt frame alignment is challenging. When footnotes overflow, splitting them across pages can result in misalignment or compressed content if not carefully managed.

Using different font sizes or baselines for frames (e.g., for bilingual text) requires fine-tuning \code{baselineskip}, \code{lineskip}, or \code{parskip} settings to maintain alignment. Frames may also have varying widths or layout constraints, making it difficult to directly compare their heights.

Dynamic content, such as varying paragraph lengths, images, or tables, can lead to unpredictable behavior in each frame. Frequent recalibration is necessary to address these issues. Managing overflow content for the main frames and their footnote counterparts without disrupting alignment adds yet another layer of complexity.
To align frames effectively, dummy content, vertical glue, or phantom boxes are often added to the shorter frame. However, these adjustments require precise calculations to avoid visual artifacts caused by estimation errors. Even small inaccuracies in frame height or glue measurements can lead to noticeable misalignment.

SILE is primarily designed for single-frame typesetting, with limited native support for parallel or multi-frame layouts. Consequently, most parallel typesetting functionality must be implemented manually, requiring a deep understanding of SILE’s internals. Achieving proper frame alignment often involves trial and error, such as adding dummy text or phantom boxes to fine-tune the layout.

Synchronizing frames across pages involves recalculating frame heights when a new page is entered, managing footnotes, and ensuring consistent alignment. Frequent synchronization can be computationally expensive, particularly for complex or lengthy documents.

Parallel typesetting demands pixel-perfect precision to avoid noticeable misalignment. Achieving such precision often sacrifices flexibility when handling variable content. Users may need to create separate document classes tailored to specific documents.

For examples and further details, see \url{https://sile-typesetter.org/examples/parallel.sil} and the source code of \code{classes/diglot.lua} or \url{https://github.com/no-vici/parallel_typesetting}.
\end{document}
]]

return package
