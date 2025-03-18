SILE = require("core.sile")

describe("SILE.utilities", function ()
   describe("sortedpairs", function ()
      it("should iterate over pairs in sorted key order", function ()
         local input = {
            c = "third",
            a = "first",
            b = "second",
         }
         local keys = {}
         local values = {}
         for k, v in SU.sortedpairs(input) do
            table.insert(keys, k)
            table.insert(values, v)
         end
         assert.same({ "a", "b", "c" }, keys)
         assert.same({ "first", "second", "third" }, values)
      end)

      it("should handle mixed key types prioritizing numbers", function ()
         local input = {
            [2] = "two",
            ["1"] = "one string",
            [1] = "one number",
            ["b"] = "bee",
            ["a"] = "ay",
         }
         local keys = {}
         local values = {}
         for k, v in SU.sortedpairs(input) do
            table.insert(keys, k)
            table.insert(values, v)
         end
         assert.same({ 1, 2, "1", "a", "b" }, keys)
         assert.same({ "one number", "two", "one string", "ay", "bee" }, values)
      end)

      it("should handle empty tables", function ()
         local input = {}
         local count = 0
         for _, _ in SU.sortedpairs(input) do
            count = count + 1
         end
         assert.equal(0, count)
      end)
   end)
end)
