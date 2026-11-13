--- Support for SyncTeX-like forward and backward search.
--
-- [SyncTeX](https://github.com/jlaurens/synctex) is a file format originally
-- designed for TeX which correlates locations in a source document with
-- locations in the typeset output. It is understood by several PDF viewers and
-- editors (e.g. Okular, Skim, Zathura, vimtex, …) which implement both
-- *forward* search (from a place in the source to a place in the output) and
-- *backward* search (from a place in the output back to the source).
--
-- A SyncTeX file consists in a tree of records, each of them describing the
-- geometry of one box of the output together with the input file, line and
-- (optionally) column the box came from. Barring a few idiosyncrasies of the
-- TeX implementation, the format only assumes a page oriented, top-left origin
-- coordinate system, so it is a good fit for SILE's own model.
--
-- SILE collects the information needed here in two stages:
--
--   1. As content is processed, each node pushed onto the typesetter is
--      tagged with the input location it originates from (see
--      `SILE.synctex:position()` below). This is the same information the
--      error reporting machinery uses, so the granularity of the mapping is
--      the granularity of the locations provided by the active inputter.
--      Inputters which attach positions to command (or element) nodes—such as
--      the SIL and XML inputters—provide line-level information; those that do
--      not provide no more than the location of the enclosing command.
--
--   2. As boxes are rendered to the output (see `SILE.types.node`), their
--      geometry is recorded along with their source location, and the whole
--      lot is written to a `.synctex(.gz)` file next to the output document
--      when SILE is done.
--
-- @module SILE.synctex

local synctex = {}

--- Whether SyncTeX output is enabled for this run.
-- Do not set this directly, call `SILE.synctex:enable()` instead.
-- @tfield boolean enabled
synctex.enabled = false

--- The compression used for the output file.
-- Either `"gzip"` (the default if the zlib library is usable, as it is
-- expected to be found by all consumers) or `"none"` to write an uncompressed
-- file (which most consumers also understand).
-- @tfield string compression
synctex.compression = "gzip"

-- Coordinates in a SyncTeX file are expressed in scaled points (sp), that is
-- 1/65536th of a TeX point, whereas SILE uses big points (bp), that is 1/72nd
-- of an inch. Since 1pt = 1/72.27in, there are 65781.76sp in a bp.
-- (Those figures are enshrined in the format: the "Unit:" field of the file
-- header describes the unit used for coordinates in terms of 1/65781.76bp.)
local spPerBp = 65781.76

local function reset ()
   synctex.pages = {} -- list of pages, in output order
   synctex.page = nil -- page currently being recorded
   synctex.inputs = {} -- list of input filenames, the index being the tag
   synctex.inputTags = {} -- reverse mapping of the above
   synctex.current = nil -- last known source position
   synctex.lastPoint = nil -- source position of the last point record
   synctex.count = 0 -- number of records written
   synctex.inputFiles = {} -- cache of which files are worth recording
end

-- Last trace stack frame and position we resolved, to avoid walking the stack
-- for every single node we typeset.
local cachedFrame, cachedPosition

reset()

--- Reset all recorded information.
-- This is done automatically when SyncTeX output is enabled, but may also be
-- useful for long running processes typesetting several documents in a row.
function synctex:reset ()
   reset()
   cachedFrame, cachedPosition = nil, nil
end

--- Enable SyncTeX output.
-- @tparam[opt] table options Options, currently only `compression` is
--   recognized (see `SILE.synctex.compression`).
function synctex:enable (options)
   options = options or {}
   self:reset()
   self.enabled = true
   if options.compression then
      self.compression = options.compression
   end
   -- The master input document always gets the first tag, like TeX does.
   for _, filename in ipairs(SILE.input.filenames) do
      self:inputTag(filename)
   end
end

--- Disable SyncTeX output, discarding anything recorded so far.
function synctex:disable ()
   self:reset()
   self.enabled = false
end

--- Whether a location designates an input document.
-- SILE processes parts of documents from code as well (localizable strings,
-- for instance), in which case the trace stack points at a Lua source file.
-- Consumers have no use for those, so they are not recorded as inputs.
-- @tparam string filename The filename to check.
-- @treturn boolean
function synctex:isInput (filename)
   if not filename then
      return false
   end
   local known = self.inputFiles[filename]
   if known == nil then
      -- The documents named on the command line are inputs by definition, the
      -- others have to come from the file system to be of any use.
      known = false
      for _, master in ipairs(SILE.input.filenames or {}) do
         if master == filename then
            known = true
            break
         end
      end
      if not known then
         known = not filename:match("%.lua$") and pl.path.isfile(filename) and true or false
      end
      self.inputFiles[filename] = known
   end
   return known
end

--- The tag identifying an input file, registering it if needed.
-- @tparam string filename The input filename.
-- @treturn[1] number The tag of the file.
-- @treturn[2] nil When the file is not an input document.
function synctex:inputTag (filename)
   filename = filename or SILE.currentlyProcessingFile
   if not self:isInput(filename) then
      return nil
   end
   local tag = self.inputTags[filename]
   if not tag then
      tag = #self.inputs + 1
      self.inputs[tag] = filename
      self.inputTags[filename] = tag
   end
   return tag
end

--- The source position currently being processed.
--
-- This is the innermost location known to the trace stack, i.e. the location
-- of the command (or element, depending on the inputter) whose content is
-- being typeset. It is `nil` when no such location is available, for example
-- when typesetting plain text at the top level of a SIL document.
--
-- @treturn[1] table A table with `file`, `lno` and `col` fields.
-- @treturn[2] nil
function synctex:position ()
   local stack = SILE.traceStack
   if not stack then
      return nil
   end
   local top = stack[#stack]
   if top and top == cachedFrame then
      return cachedPosition
   end
   cachedFrame, cachedPosition = top, nil
   for i = #stack, 1, -1 do
      local frame = stack[i]
      if frame.lno and self:isInput(frame.file) then
         cachedPosition = { file = frame.file, lno = frame.lno, col = frame.col }
         break
      end
   end
   return cachedPosition
end

--- Attach the current source position to a node.
-- Nodes already carrying a position are left alone, so that callers may
-- override the position of a node before it is pushed onto the typesetter.
-- @tparam table node A node.
-- @treturn table The same node.
function synctex:stamp (node)
   if not self.enabled or not node or rawget(node, "source") then
      return node
   end
   node.source = self:position()
   return node
end

--- Attach the source position of one node to another one and its descendants.
-- This is used to propagate positions from unshaped nodes to the nodes
-- resulting from shaping them (which are created by the shaper, out of the
-- typesetter's sight).
-- @tparam table node The node to tag.
-- @tparam table source A source position table.
-- @treturn table The same node.
function synctex:inherit (node, source)
   if not self.enabled or not source then
      return node
   end
   if not rawget(node, "source") then
      node.source = source
   end
   local children = rawget(node, "nodes")
   if children then
      for i = 1, #children do
         self:inherit(children[i], source)
      end
   end
   return node
end

--- A source position to use when nothing better is known.
-- Material typeset outside of any located context (from a package hook, say)
-- is attributed to the beginning of the master input document, so that every
-- record can be resolved to a file by consumers. Records with an unknown input
-- file are ignored by SyncTeX readers, which makes the whole file useless to
-- them, hence this fallback.
-- @treturn[1] table A table with `file`, `lno` and `col` fields.
-- @treturn[2] nil
function synctex:defaultSource ()
   local filename = (SILE.input.filenames or {})[1]
   if not filename then
      return nil
   end
   return { file = filename, lno = 1, col = 1 }
end

--- The source position to associate with a node.
-- Falls back to the last known position if the node does not carry one, and
-- remembers the position of nodes that do, so that subsequent unpositioned
-- material is attributed to the most recent known location.
-- @tparam table node A node (or `nil` when recording something else).
-- @treturn[1] table A table with `file` and `lno` fields.
-- @treturn[2] nil
function synctex:source (node)
   local source = node and rawget(node, "source")
   if source then
      self.current = source
   end
   return source or self.current
end

--- Start recording a new page.
-- This is called by the outputter each time a new page is begun.
-- @tparam[opt] number width The width of the page, in points.
-- @tparam[opt] number height The height of the page, in points.
function synctex:beginPage (width, height)
   if not self.enabled then
      return nil
   end
   local page = self.page
   if page and page.pending then
      -- Records were recorded before the outputter started the page they
      -- belong to (box output routines may be called before anything is
      -- actually drawn, and it is the drawing that starts a page). Complete
      -- the page instead of starting a new one.
      page.width, page.height, page.pending = width, height, nil
      return page
   end
   page = {
      number = #self.pages + 1,
      width = width,
      height = height,
      records = {},
   }
   self.pages[#self.pages + 1] = page
   self.page = page
   return page
end

local function currentPage (self)
   if not self.page then
      self:beginPage()
      self.page.pending = true
   end
   return self.page
end

local function addRecord (self, record)
   if not self.enabled then
      return
   end
   record.source = self:source(record.node) or self:defaultSource()
   if record.source and record.source.file then
      -- Any file we come across gets a tag of its own, like TeX does.
      self:inputTag(record.source.file)
   end
   local page = currentPage(self)
   page.records[#page.records + 1] = record
   self.count = self.count + 1
end

--- Record the opening of a box.
-- @tparam string kind Either `"hbox"` or `"vbox"`.
-- @tparam table node The node being output.
-- @tparam number x The horizontal position of the reference point of the box.
-- @tparam number y The vertical position of the reference point of the box,
--   that is the baseline for horizontal boxes and the bottom of the height of
--   vertical boxes.
-- @tparam number width The width of the box.
-- @tparam number height The height of the box.
-- @tparam number depth The depth of the box.
function synctex:openBox (kind, node, x, y, width, height, depth)
   addRecord(self, {
      kind = kind,
      node = node,
      x = x,
      y = y,
      width = width,
      height = height,
      depth = depth,
   })
end

--- Record the closing of the innermost open box.
function synctex:closeBox ()
   addRecord(self, { kind = "close" })
end

--- Record a point in the output, i.e. an input location boundary.
-- A point record is only emitted when the location actually changes, so that
-- the file does not get cluttered with redundant information.
-- @tparam table node The node being output.
-- @tparam number x The horizontal position of the point.
-- @tparam number y The vertical position of the point.
function synctex:point (node, x, y)
   if not self.enabled then
      return
   end
   local source = self:source(node)
   if source and source == self.lastPoint then
      return
   end
   self.lastPoint = source
   addRecord(self, { kind = "point", node = node, x = x, y = y })
end

--- Record a horizontal box, given the current state of the typesetter.
-- The box is expected to be output at the current position of the cursor.
-- @tparam table node The node being output.
-- @tparam table typesetter The typesetter in use.
-- @tparam number width The (scaled) width of the box.
function synctex:recordHbox (node, typesetter, width)
   if not self.enabled then
      return
   end
   local frame = typesetter.frame
   width = SU.cast("number", width)
   local x = SU.cast("number", frame.state.cursorX)
   local y = SU.cast("number", frame.state.cursorY)
   if frame:writingDirection() == "RTL" then
      x = x - width
   end
   self:point(node, x, y)
   self:openBox("hbox", node, x, y, width, SU.cast("number", node.height), SU.cast("number", node.depth))
end

--- Record a vertical box, given the current state of the typesetter.
-- @tparam table node The node being output.
-- @tparam table typesetter The typesetter in use.
function synctex:recordVbox (node, typesetter)
   if not self.enabled then
      return
   end
   local frame = typesetter.frame
   local x = SU.cast("number", frame.state.cursorX)
   local y = SU.cast("number", frame.state.cursorY)
   local width = SU.cast("number", node.width)
   if width == 0 then
      -- Line boxes typically have no width of their own, but they are meant to
      -- span the whole measure.
      width = SU.cast("number", frame:getLineWidth())
      if frame:writingDirection() == "RTL" then
         x = x - width
      end
   end
   self:openBox("vbox", node, x, y, width, SU.cast("number", node.height), SU.cast("number", node.depth))
end

-- Output formatting

local function toSp (n)
   return math.floor(SU.cast("number", n) * spPerBp + 0.5)
end

-- Convert a point expressed in SILE's coordinate system into the one used by
-- SyncTeX, in scaled points.
local function coordinates (x, y)
   local outputter = SILE.outputter
   if outputter and outputter.synctexCoordinates then
      x, y = outputter:synctexCoordinates(x, y)
   end
   return toSp(x), toSp(y)
end

-- The "tag,line" pair identifying the input location of a record.
local function tagLine (tags, source)
   -- Records whose input file cannot be resolved are ignored by consumers, so
   -- rather than emitting one of those, fall back to the first input file (that
   -- is the master document, see `orderedInputs()`).
   local tag = (source and tags[source.file]) or 1
   local line = (source and source.lno) or 1
   return ("%d,%d"):format(tag, line)
end

local function renderRecord (self, tags, record)
   if record.kind == "close" then
      return ")\n"
   end
   local x, y = coordinates(record.x, record.y)
   local location = tagLine(tags, record.source)
   if record.kind == "point" then
      return ("x%s:%d,%d\n"):format(location, x, y)
   end
   local geometry = ("%d,%d:%d,%d,%d"):format(x, y, toSp(record.width), toSp(record.height), toSp(record.depth))
   if record.kind == "vbox" then
      return ("(%s:%s\n"):format(location, geometry)
   elseif record.kind == "hbox" then
      return ("h%s:%s\n"):format(location, geometry)
   end
   SU.error("Unexpected SyncTeX record type: " .. tostring(record.kind))
end

local function renderPages (self, tags)
   local chunks = {}
   local emit = function (str)
      chunks[#chunks + 1] = str
   end
   for _, page in ipairs(self.pages) do
      emit("{" .. page.number .. "\n")
      -- The page record covers the whole sheet, so that any point of the
      -- output can be attributed to a page. Its "line" field is not
      -- meaningful, the first number being the page number itself.
      emit(("[%d,%d:0,0:%d,%d,0\n"):format(page.number, 0, toSp(page.width or 0), toSp(page.height or 0)))
      for _, record in ipairs(page.records) do
         emit(renderRecord(self, tags, record))
      end
      emit("]\n")
      emit("}" .. page.number .. "\n")
   end
   return table.concat(chunks)
end

--- The list of input files, in tag order.
-- The documents given on the command line come first, in the order they were
-- given (like TeX does), followed by any other file we came across.
-- @treturn table An array of filenames.
function synctex:orderedInputs ()
   local order, seen = {}, {}
   local function add (filename)
      if filename and not seen[filename] then
         seen[filename] = true
         order[#order + 1] = filename
      end
   end
   for _, filename in ipairs(SILE.input.filenames or {}) do
      add(filename)
   end
   for _, filename in ipairs(self.inputs) do
      add(filename)
   end
   return order
end

--- Render the whole file as a string.
-- @treturn string The contents of the SyncTeX file.
function synctex:serialize ()
   local chunks, length = {}, 0
   local emit = function (str)
      chunks[#chunks + 1] = str
      length = length + #str
   end
   -- An anchor records the byte offset of the line it sits on, so that a
   -- consumer doing backward search can seek to it and resume parsing there
   -- (the line itself is skipped, see the format documentation). Offsets are
   -- those of the reference implementation, see `synctex(5)`.
   local anchor = function ()
      emit("!" .. length .. "\n")
   end
   emit("SyncTeX Version:1\n")
   local tags = {}
   for tag, filename in ipairs(self:orderedInputs()) do
      tags[filename] = tag
      emit(("Input:%d:%s\n"):format(tag, filename))
   end
   emit("Output:pdf\n")
   emit("Magnification:1000\n")
   emit("Unit:1\n")
   emit("X Offset:0\n")
   emit("Y Offset:0\n")
   emit("Content:\n")
   anchor()
   emit(renderPages(self, tags))
   anchor()
   emit("Postamble:\n")
   emit(("Count:%d\n"):format(self.count))
   anchor()
   emit("Post scriptum:\n")
   return table.concat(chunks)
end

local function compress (self, data)
   if self.compression ~= "gzip" then
      return nil
   end
   local ok, zlib = pcall(require, "zlib")
   if not ok then
      return nil
   end
   -- windowBits of 31 stands for "15 bits of window, gzip wrapper".
   local ok2, compressed = pcall(function ()
      return zlib.deflate(nil, 31)(data, "finish")
   end)
   if ok2 and type(compressed) == "string" and #compressed > 0 then
      return compressed
   end
   return nil
end

--- The filename a SyncTeX file for a given output document would have.
-- @tparam string outputFilename The filename of the output document.
-- @tparam[opt] boolean compressed Whether to use the compressed extension.
-- @treturn string The filename.
function synctex:filename (outputFilename, compressed)
   return pl.path.splitext(outputFilename) .. ".synctex" .. (compressed and ".gz" or "")
end

--- Write the recorded information to a file.
-- @tparam string outputFilename The filename of the output document. The
--   SyncTeX file is written alongside it, with the same base name.
-- @treturn[1] string The filename of the SyncTeX file that was written.
-- @treturn[2] nil
function synctex:write (outputFilename)
   if not self.enabled then
      return nil
   end
   local data = self:serialize()
   local compressed = compress(self, data)
   local filename = self:filename(outputFilename, compressed and true or false)
   local file, err = io.open(filename, "wb")
   if not file then
      SU.warn(("Unable to write SyncTeX file %s: %s"):format(filename, tostring(err)))
      return nil
   end
   file:write(compressed or data)
   file:close()
   SU.debug("synctex", "Wrote SyncTeX file", filename)
   self:reset()
   return filename
end

return synctex
