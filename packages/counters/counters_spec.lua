SILE = require("core.sile")
SILE.input.backend = "dummy"
SILE.init()
SILE.utilities.error = error

describe("#counters #package", function ()
   local class = require("classes.plain")({})

   -- Then we load the package and can use it as actual code would do.
   class:loadPackage("counters")

   it("should create a simple counter", function ()
      local count = class.packages.counters:formatCounter(class:getCounter("simple"))
      assert.is.equal("0", count)
   end)

   it("should increment a simple counter", function ()
      SILE.call("increment-counter", { id = "simple" })
      local count = class.packages.counters:formatCounter(class:getCounter("simple"))
      assert.is.equal("1", count)
   end)

   it("should increment a simple counter, changing its display", function ()
      SILE.call("increment-counter", { id = "simple", display = "roman" })
      local count = class.packages.counters:formatCounter(class:getCounter("simple"))
      assert.is.equal("ii", count)
   end)

   it("should set a simple counter", function ()
      SILE.call("set-counter", { id = "simple", value = 5 })
      local count = class.packages.counters:formatCounter(class:getCounter("simple"))
      assert.is.equal("v", count)
   end)

   it("should set a simple counter, changing its display", function ()
      SILE.call("set-counter", { id = "simple", display = "alpha" })
      local count = class.packages.counters:formatCounter(class:getCounter("simple"))
      assert.is.equal("e", count)
   end)

   it("should create a multilevel counter", function ()
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("0", count)
   end)

   it("should increment a multilevel counter at current level", function ()
      SILE.call("increment-multilevel-counter", { id = "multi" })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("1", count)
   end)

   it("should increment a multilevel counter at level 2", function ()
      SILE.call("increment-multilevel-counter", { id = "multi", level = 2 })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("1.1", count)
   end)

   it("should increment a multilevel counter at level 3", function ()
      SILE.call("increment-multilevel-counter", { id = "multi", level = 3 })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("1.1.1", count)
   end)

   it("should increment a multilevel counter at level 2, clearing sub-levels", function ()
      SILE.call("increment-multilevel-counter", { id = "multi", level = 2 })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("1.2", count)
   end)

   it("should set a multilevel counter", function ()
      SILE.call("set-multilevel-counter", { id = "multi", level = 3, value = 5 })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("1.2.5", count)
   end)

   it("should set a multilevel counter, changing its display", function ()
      SILE.call("set-multilevel-counter", { id = "multi", level = 3, display = "alpha" })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("1.2.e", count)
   end)

   it("should format a counter with or without leading zeros", function ()
      SILE.call("set-multilevel-counter", { id = "multi", level = 1, value = 0 })
      SILE.call("increment-multilevel-counter", { id = "multi", level = 2 })
      local count = class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"))
      assert.is.equal("0.1", count)
      count =
         class.packages.counters:formatMultilevelCounter(class:getMultilevelCounter("multi"), { noleadingzeros = true })
      assert.is.equal("1", count)
   end)
end)
