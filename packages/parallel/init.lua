----------------------------------------------------------------
--  parallel – multi–frame / diglot typesetting for SILE
----------------------------------------------------------------
--
--  This file can simply be dropped into ⟨project⟩/packages
--  or placed in a $SILE_HOME search path. The only external
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
--  Two pools of typesetters: main text frames & footnote frames
----------------------------------------------------------------
local typesetterPool, footnotePool = {}, {}

----------------------------------------------------------------
--  Shared state tables
----------------------------------------------------------------
local calculations = {} -- Running height / mark bookkeeping
local folioOrder = {} -- Frame order on the physical page

----------------------------------------------------------------
--  A no-op typesetter (used during class initialization)
----------------------------------------------------------------
local NullTypesetter = pl.class(SILE.typesetters.default)
NullTypesetter.outputLinesToPage = function() end

----------------------------------------------------------------
--  Footnote manager: encapsulates all footnote logic
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

-- Measure the height of one footnote (with caching)
function FootnoteManager:height(frame, note, ts)
   local id = self:generateId(frame, note)
   if self.footnoteHeightCache[id] then
      return self.footnoteHeightCache[id], nil
   end

   ts:pushState()
   local q = {}
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
--  Utility Helpers
----------------------------------------------------------------
-- Iterate over typesetters in a pool and apply a callback function
local function iterateTypesetters(pool, callback)
   local old = SILE.typesetter
   for frame, ts in pairs(pool) do
      SILE.typesetter = ts
      callback(frame, ts)
   end
   SILE.typesetter = old
end

-- Calculate the height of new material for a given frame
local function calculateFrameHeight(frame, ts)
   local h = calculations[frame].cumulativeHeight or SILE.types.length()
   for i = calculations[frame].mark + 1, #ts.state.outputQueue do
      local ln = ts.state.outputQueue[i]
      h = h + ln.height + ln.depth
   end
   return h
end

-- Manage the heights of frames
local manageFrameHeights = function(frames, callback)
   local frameHeights = {}
   local maxHeight = SILE.types.length()

   iterateTypesetters(frames, function(frame, typesetter)
      local height = calculateFrameHeight(frame, typesetter)
      frameHeights[frame] = height
      if height > maxHeight then
         maxHeight = height
      end
   end)

   iterateTypesetters(frames, function(frame, typesetter)
      callback(frame, frameHeights[frame], maxHeight - frameHeights[frame])
   end)
end

-- Balances the height of content across frames by adding glue to shorter frames
local addBalancingGlue = function()
   manageFrameHeights(typesetterPool, function(frame, currentHeight, heightDiff)
      if heightDiff:tonumber() > 0 then
         local typesetter = typesetterPool[frame]
         table.insert(typesetter.state.outputQueue, SILE.types.node.vkern({ height = heightDiff }))
         log("Added balancing glue of", heightDiff, "to bottom of frame", frame)
      end
   end)
end

-- Adds a flexible glue (parskip) to the bottom of each frame
local addParskipToFrames = function(parskipHeight)
   iterateTypesetters(typesetterPool, function(_, typesetter)
      table.insert(typesetter.state.outputQueue, SILE.types.node.vglue({ height = parskipHeight }))
   end)
end

----------------------------------------------------------------
--  Footnote Manager Functions
----------------------------------------------------------------
function FootnoteManager:generateFootnoteId(frame, note)
   return frame .. ":" .. note.marker
end

function FootnoteManager:getFootnoteHeight(frame, note, typesetter)
   local noteId = self:generateFootnoteId(frame, note)
   local noteQueue = {}
   typesetter:pushState()
   typesetter.state.outputQueue = noteQueue
   SILE.call("parallel_footnote:constructor", { marker = note.marker }, note.content)
   typesetter:popState()

   local noteHeight = 0
   for _, node in ipairs(noteQueue) do
      noteHeight = noteHeight + node.height:absolute():tonumber() + node.depth:absolute():tonumber()
   end
   self.footnoteHeightCache[noteId] = noteHeight
   return self.footnoteHeightCache[noteId], noteQueue
end

function FootnoteManager:preprocessFrame(frame, typesetter)
   typesetter:initFrame(typesetter.frame)
   SILE.typesetter = typesetter
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

   if context.currentIndex > 1 then
      noteHeight = noteHeight + context.baselineSkip
   end

   if context.currentHeight + noteHeight <= context.targetHeight then
      if context.currentIndex > 1 then
         table.insert(typesetter.state.outputQueue, SILE.types.node.vglue(SILE.types.length(context.baselineSkip)))
      end

      context.currentHeight = context.currentHeight + noteHeight
      for _, node in ipairs(noteQueue) do
         table.insert(typesetter.state.outputQueue, node)
      end
   else
      self:handleOverflowingNote(noteQueue, context, typesetter)
   end
   noteQueue = nil -- Reset to release memory
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

   if #typesetter.state.outputQueue > 0 then
      table.insert(typesetter.state.outputQueue, SILE.types.node.vglue(SILE.types.length(context.baselineSkip)))
   end

   context.currentHeight = context.currentHeight + fittedHeight
   for _, node in ipairs(fittedQueue) do
      table.insert(typesetter.state.outputQueue, node)
   end

   typesetter:outputLinesToPage(typesetter.state.outputQueue)
   typesetter.state.outputQueue = {} -- Reset the output queue to avoid double processing

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
   if typesetter.state.outputQueue and #typesetter.state.outputQueue > 0 then
      typesetter:outputLinesToPage(typesetter.state.outputQueue)
   else
      SU.warn("No content to output for frame: " .. frame)
   end
   self.frames[frame] = context.nextPageNotes
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

            self:processNotes(frame, function(note)
               context.currentIndex = (context.currentIndex or 0) + 1
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
            overflowContent[frame] = pl.tablex.copy(linesToFit)
            typesetter.state.outputQueue = {} -- Reset output queue to avoid double processing
         else
            overflowContent[frame] = {}
         end
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

         -- Rebalance frames if necessary
         -- addBalancingGlue() -- Uncomment if balancing glue is needed
      end
   end

   -- Ensure all the first pair of frames on the new page are synchronized and balanced
   SILE.call("sync")
end

----------------------------------------------------------------
--  Package initialization
----------------------------------------------------------------
function package:_init(options)
   base._init(self, options)

   -- Load necessary packages
   self:loadPackage("rebox") -- for footnote:rule
   self:loadPackage("rules") -- for footnote:rule
   self:loadPackage("counters") -- for footnote counting
   self:loadPackage("raiselower") -- for footnote superscript mark

   -- Temporary no-op typesetter to prevent errors during initialization
   SILE.typesetter = NullTypesetter(SILE.getFrame("page"))

   -- Ensure the frames option is provided.
   if type(options.frames) ~= "table" or type(options.ftn_frames) ~= "table" then
      SU.error("Package 'parallel' must be initialized with a set of appropriately named frames")
   end

   -- Set up typesetters for each main frame.
   for frame, typesetter in pairs(options.frames) do
      typesetterPool[frame] = SILE.typesetters.default(SILE.getFrame(typesetter))
      typesetterPool[frame].id = typesetter
      typesetterPool[frame].buildPage = function() end -- Disable auto page-building

      -- Register commands (e.g., for directing content to frames)
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
   end

   ---------------- frame order ----------------
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
   self.class.newPage = function(self_)
      self.class._base.newPage(self_)
      iterateTypesetters(typesetterPool, function(frame, _)
         calculations[frame] = { mark = 0, cumulativeHeight = SILE.types.length(0) }
      end)
      SILE.call("sync") -- Sync frames on new page
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
      local anyBreak = false

      -- Check for potential page breaks.
      iterateTypesetters(typesetterPool, function(_, typesetter)
         typesetter:leaveHmode(true)
         -- Copy the current output queue for the page builder
         local lines = pl.tablex.copy(typesetter.state.outputQueue)

         -- Invoke the page builder to find breaks
         if SILE.pagebuilder:findBestBreak({ vboxlist = lines, target = typesetter:getTargetLength() }) then
            anyBreak = true
         end
      end)

      -- Perform a page break if necessary.
      if anyBreak then
         parallelPagebreak()
         return
      end

      -- Add balancing glue to align frame heights
      addBalancingGlue()

      -- Retrieve the parskip setting and add to frames based on the setting
      local parskip = SILE.settings:get("document.parskip")
      if not parskip or parskip.height:tonumber() == 0 then
         addParskipToFrames(SILE.types.length("1em"):absolute())
      else
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
      local width = SU.cast("measurement", options.width or "20%fw") -- Usually 1/5 of the text block
      local beforeskipamount = SU.cast("vglue", options.beforeskipamount or "1ex")
      local afterskipamount = SU.cast("vglue", options.afterskipamount or "1ex")
      local thickness = SU.cast("measurement", options.thickness or "0.5pt")
      SILE.call("noindent")
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
         SILE.call("font", { size = "0.8em" }, function()
            local markerBox = SILE.typesetter:makeHbox({ markerText })
            local markerWidth = markerBox.width:tonumber() -- Convert to number

            local hangIndent = initialHangIndent:tonumber()
            local markerGap = SU.max(0.25 * hangIndent, hangIndent - markerWidth)

            if markerGap > hangIndent - markerWidth then
               hangIndent = markerWidth + markerGap
            end

            SILE.settings:set("document.lskip", SILE.types.length(hangIndent))
            SILE.settings:set("document.parindent", SILE.types.length(-hangIndent))

            SILE.typesetter:pushHbox(markerBox)
            SILE.call("kern", { width = markerGap })

            SILE.process(content)
            SILE.call("par") -- End the paragraph
         end)
      end)
   end)

   registerSimpleCommand("parallel_footnote", function(options, content)
      local currentFrame = SILE.typesetter.frame.id
      local targetFrame = currentFrame == "a" and "ftn_left" or "ftn_right"

      local footnoteNumber, marker
      if not options.mark then
         SILE.call("increment-counter", { id = targetFrame })
         footnoteNumber = self.class.packages.counters:formatCounter(SILE.scratch.counters[targetFrame])
         marker = tostring(footnoteNumber) .. "."
      else
         marker = options.mark
      end

      SILE.call("footnoteNumber", {}, function()
         SILE.typesetter:typeset(footnoteNumber)
      end)

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
            SILE.call("par") -- End the paragraph
         end)
      end)
   end)

   -- Inline fallback font for user convenience
   self:registerCommand("parallel:font-fallback", function(options, content)
      -- Retrieve the font family from options, default to "Noto Sans CJK JP" if not provided
      local fontFamily = options.family or "Noto Sans CJK JP"

      SILE.settings:temporarily(function()
         SILE.settings:set("font.family", fontFamily) -- Use the specified or default font family
         SILE.process(content)
      end)
   end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{parallel} package provides a mechanism for typesetting diglot or other parallel documents. When used with a class such as \code{classes/diglot.lua}, it registers a command for each parallel frame, allowing users to select which frame to typeset into.

This package defines the \autodoc:command{\sync} command, which adds vertical spacing to each frame's bottom to ensure that the \em{next} set of text is horizontally aligned. It supports independent footnote flows and counters for each frame. Footnotes can be typeset using \autodoc:command{\parallel_footnote}, adopting styles from the \code{resilient.footnotes} package. Note that \code{document.parskip} is not supported due to manual manipulation of \code{typesetter.state.outputQueue}. Thus, users must manually utilize the \autodoc:command{\parskip} command to start a new paragraph within a frame.

This package is still in development and not yet fully mature. Testing suggests optimal performance with a font size of 12pt from the \strong{Gentium Plus} family, with \code{document.parskip} unset or set to 0pt. Customizing \code{document.parskip}, \code{document.baselineskip}, or using varying font families and sizes between frames can disrupt alignment, making precise frame alignment challenging.

Frame alignment in parallel typesetting is particularly tricky, requiring careful synchronization of multiple interdependent variables and processes to produce visually cohesive results. Each frame may contain different amounts of content, leading to height discrepancies. The height of each frame depends on its content, including typeset text, inserts (e.g., footnotes), and vertical glue. Manual adjustments to settings like \code{baselineskip}, \code{parskip}, or font sizes are often necessary, complicating alignment.

SILE's default page builder operates on a single vertical stream, while parallel typesetting requires independent handling of multiple streams (frames) while maintaining horizontal alignment. This necessitates custom page-breaking and alignment logic to synchronize streams. Manually tracking and adjusting frame heights by applying stretchy glue is key to achieving proper alignment.

Insertions like footnotes increase complexity, as they occupy independent frames and dynamically flow. Ensuring these do not disrupt alignment is challenging. When footnotes overflow, splitting across pages can yield misalignment or compression without careful management.

Different font sizes or baselines for frames (e.g., for bilingual text) require fine-tuning of \code{baselineskip}, \code{lineskip}, or \code{parskip} settings to maintain alignment. Frames may also vary in widths or layout constraints, complicating direct height comparisons.

Dynamic content, such as variable paragraph lengths, images, or tables, can lead to unpredictable behaviors in each frame. Frequent recalibration is essential to tackle these issues. Managing overflow content for main frames and footnote counterparts without disrupting alignment adds complexity.

Aligning frames effectively often involves adding dummy content, vertical glue, or phantom boxes to the shorter frame. However, these adjustments require precise calculations to avoid visual artifacts from estimation errors. Small inaccuracies in frame heights or glue measurements can lead to noticeable misalignment.

SILE is primarily designed for single-frame typesetting, with limited support for parallel or multi-frame layouts. Thus, most parallel functionality must be implemented manually, requiring an intimate understanding of SILE’s internals. Achieving proper frame alignment often entails trial-and-error, including adding dummy text or phantom boxes to finetune layouts.

Synchronizing frames across pages requires recalculating frame heights upon entering a new page, managing footnotes, and ensuring consistency. Frequent synchronization can be computationally intensive, especially for elaborate or lengthy documents.

Parallel typesetting necessitates pixel-perfect precision to avoid noticeable misalignment, often sacrificing flexibility in handling variable content. Users may need to create separate document classes tailored to specific needs.

For examples and further details, see \url{https://sile-typesetter.org/examples/parallel.sil} and the source code of \code{classes/diglot.lua} or \url{https://github.com/no-vici/parallel_typesetting}.
\end{document}
]]

return package
