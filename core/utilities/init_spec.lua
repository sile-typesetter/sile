SILE = require("core.sile")
SILE.init()

describe("SILE.utilities", function ()

   it("should exist as SU", function ()
      assert.is.truthy(SU)
   end)

   describe("collatedSort", function ()

      describe("French", function ()
         SILE.call("language", { main = "fr" })

         -- Our reference 'unsorted' table.
         -- Just as table.sort(t), SU.collatedSort(t) has a side-effect on the table, we'll need
         -- to shallow copy it, for each test to be independent from the others.
         local original = {
            "Albert",
            "Jean2",
            "Alain",
            "Jean100",
            "alain",
            "alinoé",
            "Jean-Paul",
            "Alinéa",
            "Jean2",
            "jeanne",
         }

         it("should have expected default sorting", function ()
            local sortme = pl.tablex.copy(original)
            SU.collatedSort(sortme) -- with default options
            assert.is.same({
               "alain",
               "Alain",
               "Albert",
               "Alinéa",
               "alinoé",
               "Jean2",
               "Jean2",
               "Jean100",
               "jeanne",
               "Jean-Paul",
            }, sortme)
         end)
         it("should have expected sorting when ignorePunctuation is disabled", function ()
            local sortme = pl.tablex.copy(original)
            SU.collatedSort(sortme, { ignorePunctuation = false })
            assert.is.same({
               -- Jean-Paul is the guinea pig!
               "alain",
               "Alain",
               "Albert",
               "Alinéa",
               "alinoé",
               "Jean-Paul",
               "Jean2",
               "Jean2",
               "Jean100",
               "jeanne",
            }, sortme)
         end)
         it("should have expected sorting when numericOrdering is disabled", function ()
            local sortme = pl.tablex.copy(original)
            SU.collatedSort(sortme, { numericOrdering = false })
            assert.is.same({
               -- Jean100 and the Jean2 are the guinea pigs!
               "alain",
               "Alain",
               "Albert",
               "Alinéa",
               "alinoé",
               "Jean100",
               "Jean2",
               "Jean2",
               "jeanne",
               "Jean-Paul",
            }, sortme)
         end)
         it("should have expected sorting when caseFirst is 'upper'", function ()
            local sortme = pl.tablex.copy(original)
            SU.collatedSort(sortme, { caseFirst = "upper" })
            assert.is.same({
               -- Alain is the guinea pig!
               "Alain",
               "alain",
               "Albert",
               "Alinéa",
               "alinoé",
               "Jean2",
               "Jean2",
               "Jean100",
               "jeanne",
               "Jean-Paul",
            }, sortme)
         end)
         it("should have expected sorting when language-specific options are configured", function ()
            -- WARNING: This is expected to be used for languages where the default options
            -- are not appropriate. I'm told for example that Japanese may need strength=4.
            -- I've not idea however, so let's BREAK the default French rules for testing!
            SU.collatedSort.fr = { caseFirst = "upper", numericOrdering = false }
            local sortme = pl.tablex.copy(original)
            SU.collatedSort(sortme) -- with default options as overridden.
            assert.is.same({
               -- Alain and the Jean guys are the guinea pigs!
               "Alain",
               "alain",
               "Albert",
               "Alinéa",
               "alinoé",
               "Jean100",
               "Jean2",
               "Jean2",
               "jeanne",
               "Jean-Paul",
            }, sortme)
         end)
         it("should sort complex tables with callback comparison function", function ()
            local sortme = {
               { name = "Jean", age = 30 },
               { name = "Charlie", age = 25 },
               { name = "Bob", age = 30 },
               { name = "Alice", age = 25 },
            }
            SU.collatedSort(sortme, nil, function (a, b, stringCompare)
               -- Sort by ascending age then ascending name
               if a.age < b.age then
                  return true
               end
               if a.age > b.age then
                  return false
               end
               return stringCompare(a.name, b.name) < 0
            end)
            assert.is.same({
               { name = "Alice", age = 25 },
               { name = "Charlie", age = 25 },
               { name = "Bob", age = 30 },
               { name = "Jean", age = 30 },
            }, sortme)
            local namesAndYears = {
               { name = "Alice", year = 2005 },
               { name = "Charlie", year = 1995 },
               { name = "Bob", year = 1990 },
               { name = "Alice", year = 1995 },
            }
            SU.collatedSort(namesAndYears, nil, function (a, b, stringCompare)
               local nameCompare = stringCompare(a.name, b.name)
               if nameCompare < 0 then
                  return true
               end
               if nameCompare > 0 then
                  return false
               end
               return a.year < b.year
            end)
            assert.is.same({
               { name = "Alice", year = 1995 },
               { name = "Alice", year = 2005 },
               { name = "Bob", year = 1990 },
               { name = "Charlie", year = 1995 },
            }, namesAndYears)
         end)
      end)
   end)

   describe("deprecated", function ()
      it("should compute errors based on semver", function ()
         SILE.version = "v0.1.10.r4-h5d5dd3b"
         SU.warn = function () end
         assert.has.errors(function ()
            SU.deprecated("foo", "bar", "0.1.9", "0.1.9")
         end)
         assert.has_no.errors(function ()
            SU.deprecated("foo", "bar", "0.1.11", "0.1.11")
         end)
      end)
   end)

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

   describe("utf8_to_utf16be_hexencoded", function ()
      it("should hex encode input", function ()
         local str = "foo"
         local out = "feff0066006f006f"
         assert.is.equal(out, SU.utf8_to_utf16be_hexencoded(str))
      end)
   end)
end)
