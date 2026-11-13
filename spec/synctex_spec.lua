SILE = require("core.sile")

describe("SILE.synctex", function ()
   local savedFilenames, savedOutputter

   before_each(function ()
      savedFilenames = SILE.input.filenames
      savedOutputter = SILE.outputter
      SILE.input.filenames = { "test.sil" }
      SILE.outputter = nil
      SILE.synctex:disable()
   end)

   after_each(function ()
      SILE.synctex:disable()
      SILE.input.filenames = savedFilenames
      SILE.outputter = savedOutputter
   end)

   it("should be disabled by default", function ()
      assert.is_false(SILE.synctex.enabled)
   end)

   it("should not do anything when disabled", function ()
      local node = SILE.types.node.hbox({ width = 10 })
      SILE.synctex:stamp(node)
      assert.is_nil(rawget(node, "source"))
      SILE.synctex:recordHbox(node, { frame = {} }, 10)
      assert.is_nil(SILE.synctex:beginPage(100, 100))
      assert.is_nil(SILE.synctex.pages[1])
   end)

   describe("when enabled", function ()
      before_each(function ()
         SILE.synctex:enable()
      end)

      it("should not record locations in code as inputs", function ()
         assert.is_false(SILE.synctex:isInput("core/languages.lua:101"))
         assert.is_true(SILE.synctex:isInput("test.sil"))
      end)

      it("should register the master input document with the first tag", function ()
         assert.is.equal(1, SILE.synctex:inputTag("test.sil"))
         assert.is.equal(1, SILE.synctex:inputTag("test.sil"))
      end)

      it("should give further tags to the documented files it comes across", function ()
         local other = os.tmpname() .. ".sil"
         local file = assert(io.open(other, "w"))
         file:write("")
         file:close()
         assert.is.equal(2, SILE.synctex:inputTag(other))
         os.remove(other)
      end)

      it("should resolve source positions from the trace stack", function ()
         local pId = SILE.traceStack:pushCommand("foo", { file = "test.sil", lno = 42, col = 3 })
         local position = SILE.synctex:position()
         SILE.traceStack:pop(pId)
         assert.is.equal("test.sil", position.file)
         assert.is.equal(42, position.lno)
         assert.is.equal(3, position.col)
      end)

      it("should have no position outside of any located context", function ()
         assert.is_nil(SILE.synctex:position())
      end)

      it("should tag nodes with the current position", function ()
         local pId = SILE.traceStack:pushCommand("foo", { file = "test.sil", lno = 7 })
         local node = SILE.types.node.hbox({ width = 10 })
         SILE.synctex:stamp(node)
         SILE.traceStack:pop(pId)
         assert.is.equal(7, node.source.lno)
      end)

      it("should not override the position of nodes that already have one", function ()
         local node = SILE.types.node.hbox({ width = 10 })
         node.source = { file = "test.sil", lno = 1 }
         local pId = SILE.traceStack:pushCommand("foo", { file = "test.sil", lno = 2 })
         SILE.synctex:stamp(node)
         SILE.traceStack:pop(pId)
         assert.is.equal(1, node.source.lno)
      end)

      it("should propagate positions to shaped nodes", function ()
         local source = { file = "test.sil", lno = 3 }
         local inner = SILE.types.node.hbox({ width = 5 })
         local nnode = SILE.types.node.nnode({ nodes = { inner }, text = "foo" })
         SILE.synctex:inherit(nnode, source)
         assert.is.equal(source, nnode.source)
         assert.is.equal(source, inner.source)
      end)

      it("should record boxes as boxes of the current page", function ()
         SILE.synctex:beginPage(200, 300)
         local node = SILE.types.node.hbox({ width = 10, height = 5, depth = 1 })
         SILE.synctex:recordHbox(node, {
            frame = {
               state = { cursorX = 10, cursorY = 20 },
               writingDirection = function ()
                  return "LTR"
               end,
            },
         }, 10)
         local records = SILE.synctex.pages[1].records
         assert.is.equal(2, #records)
         assert.is.equal("point", records[1].kind)
         assert.is.equal(10, records[1].x)
         assert.is.equal("hbox", records[2].kind)
         assert.is.equal(20, records[2].y)
      end)

      it("should account for right-to-left writing directions", function ()
         SILE.synctex:beginPage(200, 300)
         local node = SILE.types.node.hbox({ width = 10 })
         SILE.synctex:recordHbox(node, {
            frame = {
               state = { cursorX = 100, cursorY = 20 },
               writingDirection = function ()
                  return "RTL"
               end,
            },
         }, 10)
         assert.is.equal(90, SILE.synctex.pages[1].records[1].x)
      end)

      it("should only emit a point record when the position changes", function ()
         SILE.synctex:beginPage(200, 300)
         local typesetter = {
            frame = {
               state = { cursorX = 0, cursorY = 0 },
               writingDirection = function ()
                  return "LTR"
               end,
            },
         }
         local source = { file = "test.sil", lno = 4 }
         for _ = 1, 3 do
            SILE.synctex:recordHbox(SILE.types.node.hbox({ width = 1, source = source }), typesetter, 1)
         end
         local points = 0
         for _, record in ipairs(SILE.synctex.pages[1].records) do
            if record.kind == "point" then
               points = points + 1
            end
         end
         assert.is.equal(1, points)
      end)

      it("should start a new page for each page of the output", function ()
         SILE.synctex:beginPage(200, 300)
         SILE.synctex:openBox("vbox", nil, 0, 0, 10, 10, 0)
         SILE.synctex:closeBox()
         SILE.synctex:beginPage(200, 300)
         assert.is.equal(2, #SILE.synctex.pages)
         assert.is.equal(2, #SILE.synctex.pages[1].records)
         assert.is.equal(0, #SILE.synctex.pages[2].records)
      end)

      it("should complete the page records were recorded before it started", function ()
         -- Output routines may record a box slightly before the outputter
         -- starts the page it belongs to.
         SILE.synctex:openBox("vbox", nil, 0, 0, 10, 10, 0)
         SILE.synctex:beginPage(200, 300)
         assert.is.equal(1, #SILE.synctex.pages)
         assert.is.equal(200, SILE.synctex.pages[1].width)
      end)
   end)

   describe("output", function ()
      local function record (kind, options)
         local defaults = {
            kind = kind,
            source = { file = "test.sil", lno = 2 },
            x = 1,
            y = 2,
            width = 3,
            height = 4,
            depth = 5,
         }
         for k, v in pairs(options or {}) do
            defaults[k] = v
         end
         local page = SILE.synctex.page or SILE.synctex:beginPage(100, 200)
         page.records[#page.records + 1] = defaults
      end

      before_each(function ()
         SILE.synctex:enable()
         SILE.synctex.compression = "gzip"
         SILE.synctex:beginPage(100, 200)
      end)

      it("should convert coordinates from points to scaled points", function ()
         record("hbox")
         local data = SILE.synctex:serialize()
         assert.is_truthy(data:match("\nh1,2:65782,131564:197345,263127,328909\n"))
      end)

      it("should convert coordinates using the outputter", function ()
         SILE.outputter = {
            synctexCoordinates = function (_, x, y)
               return x + 10, y + 20
            end,
         }
         record("hbox")
         local data = SILE.synctex:serialize()
         -- (1 + 10) * 65781.76 = 723599.36
         assert.is_truthy(data:match("\nh1,2:723599,1447199:"))
      end)

      it("should record the geometry of pages", function ()
         local data = SILE.synctex:serialize()
         assert.is_truthy(data:match("\n{1\n"))
         assert.is_truthy(data:match("\n%[1,0:0,0:6578176,13156352,0\n"))
         assert.is_truthy(data:match("\n%]\n}1\n"))
      end)

      it("should record the input files and the postamble", function ()
         local data = SILE.synctex:serialize()
         assert.is_truthy(data:match("^SyncTeX Version:1\n"))
         assert.is_truthy(data:match("\nInput:1:test%.sil\n"))
         assert.is_truthy(data:match("\nOutput:pdf\n"))
         assert.is_truthy(data:match("\nMagnification:1000\n"))
         assert.is_truthy(data:match("\nUnit:1\n"))
         assert.is_truthy(data:match("\nContent:\n"))
         assert.is_truthy(data:match("\nPostamble:\n"))
         assert.is_truthy(data:match("\nCount:%d+\n"))
         assert.is_truthy(data:match("\nPost scriptum:\n$"))
      end)

      it("should fall back to the master document for unlocated material", function ()
         SILE.synctex:openBox("hbox", SILE.types.node.hbox({ width = 1 }), 1, 2, 3, 4, 5)
         local data = SILE.synctex:serialize()
         assert.is_truthy(data:match("\nh1,1:"))
      end)

      it("should attribute unlocated boxes to the last known position", function ()
         local located = SILE.types.node.hbox({ width = 1, source = { file = "test.sil", lno = 6 } })
         local unlocated = SILE.types.node.hbox({ width = 1 })
         SILE.synctex:openBox("hbox", located, 1, 2, 3, 4, 5)
         SILE.synctex:openBox("hbox", unlocated, 1, 2, 3, 4, 5)
         local data = SILE.synctex:serialize()
         assert.is_equal(2, select(2, data:gsub("\nh1,6:", "")))
      end)

      it("should write anchors pointing at their own offset", function ()
         record("hbox")
         record("point")
         local data = SILE.synctex:serialize()
         local offset = 0
         for line in data:gmatch("([^\n]*)\n") do
            if line:sub(1, 1) == "!" then
               assert.is.equal(offset, tonumber(line:sub(2)))
            end
            offset = offset + #line + 1
         end
      end)

      it("should write an uncompressed file when asked to", function ()
         SILE.synctex.compression = "none"
         local filename = SILE.synctex:write("output.pdf")
         assert.is.equal("output.synctex", filename)
         local file = assert(io.open(filename, "rb"))
         local data = file:read("*a")
         file:close()
         os.remove(filename)
         assert.is_truthy(data:match("^SyncTeX Version:1\n"))
      end)

      it("should write a gzipped file by default", function ()
         local filename = SILE.synctex:write("output.pdf")
         assert.is.equal("output.synctex.gz", filename)
         local file = assert(io.open(filename, "rb"))
         local magic = file:read(2)
         file:close()
         os.remove(filename)
         assert.is.equal("\31\139", magic)
      end)
   end)
end)
