--- Table sorting with language-dependent collation.
-- @module SU.sorting

local icu = require("justenoughicu")

local collatedSort = {
   -- No ICU for language "und", fallback to 'natural' table.sort
   und = function (t, _)
      table.sort(t)
   end,
}

setmetatable(collatedSort, {
   __call = function (self, t, options)
      local lang = SILE.settings:get("document.language")
      if self[lang] and type(self[lang]) == "function" then
         -- Allow overriding ICU for some languages, typically "und"
         return self[lang](t, options)
      end

      if self[lang] and type(self[lang]) == "table" then
         -- Allow customizing the default collation options for some languages
         options = options or self[lang]
      end
      -- Be efficient: create the collator once before sorting.
      -- I don't think we need to cache it, still.
      local collator = icu.collation_create(lang, options or {})
      table.sort(t, function (s1, s2)
         return icu.compare(collator, s1, s2)
      end)
      icu.collation_destroy(collator)
   end,
})

return collatedSort
