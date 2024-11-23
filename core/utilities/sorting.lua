--- Table sorting with language-dependent collation.
-- @module SU.sorting
--

local icu = require("justenoughicu")

local collatedSort = {
   -- No ICU for language "und", fallback to 'natural' table.sort
   und = function (t, _, comparator)
      if comparator then
         table.sort(t, function (e1, e2)
            return comparator(e1, e2, function (s1, s2)
               return s1 < s2 and -1 or s1 > s2 and 1 or 0
            end)
         end)
      else
         table.sort(t)
      end
   end,
}

setmetatable(collatedSort, {
   __call = function (self, t, options, comparator)
      local lang = SILE.settings:get("document.language")
      if self[lang] and type(self[lang]) == "function" then
         -- Allow overriding ICU for some languages, typically "und"
         return self[lang](t, options, comparator)
      end

      if self[lang] and type(self[lang]) == "table" then
         -- Allow customizing the default collation options for some languages
         options = options or self[lang]
      end
      -- Be efficient: create the collator once before sorting.
      -- I don't think we need to cache it, still.
      local collator = icu.collation_create(lang, options or {})

      local stringCompareClosure = function (s1, s2)
         return icu.compare(collator, s1, s2)
      end
      table.sort(t, function (e1, e2)
         -- Allow custom comparison function, notably for complex objects
         -- Pass the stringCompare function so that it can be used.
         if comparator then
            return comparator(e1, e2, stringCompareClosure)
         end
         return stringCompareClosure(e1, e2) < 0
      end)
      icu.collation_destroy(collator)
   end,
})

return collatedSort
