--- A CSL processor for bibliographies.
--
-- @copyright License: MIT (c) 2025 Omikhleia
--
local loadkit = require("loadkit")
local cslStyleLoader = loadkit.make_loader("csl")
local cslLocaleLoader = loadkit.make_loader("xml")

local CslLocale = require("packages.bibtex.csl.locale")
local CslStyle = require("packages.bibtex.csl.style")
local CslEngine = require("packages.bibtex.csl.engine")

local bibparser = require("packages.bibtex.support.bibparser")
local parseBibtex, crossrefAndXDataResolve = bibparser.parseBibtex, bibparser.crossrefAndXDataResolve

local bib2csl = require("packages.bibtex.support.bib2csl")
local locators = require("packages.bibtex.support.locators")

-- HELPERS

local resolveFile = SILE and SILE.resolveFile or function (filename)
   return filename
end

-- Loaders for CSL locale and style files.
local function loadCslLocale (name)
   local filename = resolveFile("csl/locales/" .. name .. ".xml")
      or resolveFile("packages/bibtex/csl/locales/locales-" .. name .. ".xml")
      or cslLocaleLoader("packages.bibtex.csl.locales.locales-" .. name)
   if not filename then
      SU.error("Could not find CSL locale '" .. name .. "'")
   end
   local locale, err = CslLocale.read(filename)
   if not locale then
      SU.error("Could not open CSL locale '" .. name .. "'': " .. err)
      return
   end
   return locale
end
local function loadCslStyle (name)
   local filename = resolveFile("csl/styles/" .. name .. ".csl")
      or resolveFile("packages/bibtex/csl/styles/" .. name .. ".csl")
      or cslStyleLoader("packages.bibtex.csl.styles." .. name)
   if not filename then
      SU.error("Could not find CSL style '" .. name .. "'")
   end
   local style, err = CslStyle.read(filename)
   if not style then
      SU.error("Could not open CSL style '" .. name .. "'': " .. err)
      return
   end
   return style
end

local OP = {
   EQ = 0,
   IN = 1,
}

local CSLVAR = {
   ["type"] = OP.EQ,
   keyword = OP.IN,
}
local function isMatching (entry, var, val)
   if not entry[var] then
      return false
   end
   if CSLVAR[var] == OP.EQ then
      return entry[var] == val
   elseif CSLVAR[var] == OP.IN then
      return entry[var]:contains(val)
   end
   SU.error("Unsupported CSL variable " .. var .. " in filter")
end
local getIssuedYear = function (entry)
   local d = entry.issued
   if not d then
      return nil
   end
   if type(d) == "table" then -- range of dates
      if d.startdate then
         return d.startdate.year
      end
      if d.enddate then
         return d.enddate.year
      end
   end
   return d.year
end
local function builtinFilter(name)
   local year = name:match("^issued%-(%d+)$")
   if year then
      return function (entry)
         local issuedYear = getIssuedYear(entry)
         return issuedYear and issuedYear == year
      end
   end
   local year1, year2 = name:match("^issued%-(%d+)%-(%d+)$")
   if year1 and year2 then
      return function (entry)
         local issuedYear = getIssuedYear(entry)
         return issuedYear and tonumber(issuedYear) >= tonumber(year1) and tonumber(issuedYear) <= tonumber(year2)
      end
   end
   local varkey, val = name:match("^not%-([^-]+)%-(.+)$")
   if varkey and val then
      return function (entry)
         return not isMatching(entry, varkey, val)
      end
   end
   varkey, val = name:match("^([^-]+)%-(.+)$")
   if varkey and val then
      return function (entry)
         return isMatching(entry, varkey, val)
      end
   end
   return false
end

-- CSL ENTRY PROXY (PSEUDO-CLASS)

--- Construct a proxy object that overrides the original entry table.
-- It is used to allow overriding CSL field values without modifying the original entry,
-- so that we can for instance cache the CSL item and override some fields at some later
-- processing time.
-- We also want the proxy to work if the value is deep copied, so we cannot just use a sentinel
-- value representing nil, but must actually keep track of nil-hidden fields inside the proxy.
-- @tparam  table entry Orignal table to proxy
-- @treturn table Proxy object wrapping the original entry
local function CslEntry(entry)
   local proxy = {
      __entry = entry,
      __override = {},
      __hidden = {},
   }
   setmetatable(proxy, {
      __index = function(t, key)
         if t.__hidden[key] then return nil end
         local val = t.__override[key]
         if val ~= nil then return val end
         return t.__entry[key]
      end,
      __newindex = function(t, key, value)
         if value == nil then
            t.__hidden[key] = true
            t.__override[key] = nil
         else
            t.__hidden[key] = nil
            t.__override[key] = value
         end
      end,
      __pairs = function(t)
         local merged = {}
         for k, v in pairs(t.__entry) do
            if not t.__hidden[k] then merged[k] = v end
         end
         for k, v in pairs(t.__override) do
            if not t.__hidden[k] then merged[k] = v end
         end
         return pairs(merged)
      end,
   })
   return proxy
end

-- CSL PROCESSOR CLASS

local CslProcessor = pl.class()

--- (Constructor) Create a new CSL Bibliography manager.
-- Usage example:
--
--    local biblio = CslProcessor()
--
-- @treturn CslProcessor New CSL Bibliography manager instance
function CslProcessor:_init ()
   self._filter = {}
   self._data = {
      bib = {}, -- Primary bibliography entries
      aliases = {}, -- Aliases for entries (usable as citation keys)
      related = {}, -- Related entries (for reviews, etc.)
      cited = {
         keys = {}, -- Cited keys in the order they are cited (ordered set)
         refs = {}, -- Table of cited keys with their first citation number, last locator and last position (table)
         lastkey = nil, -- Last entry key used in a citation, to track ibid/ibid-with-locator (string)
      },
   }
end

--- Retrieve the CSL engine used to process bibliographies.
-- If the engine is not set yet, it will initialize it with a default style and locale.
-- @treturn CslEngine CSL engine instance
function CslProcessor:getCslEngine ()
   if not self._engine then
      self:setBibliographyStyle('chicago-author-date', "en-US")
   end
   return self._engine
end

---- Set the bibliography style and locale for the CSL engine.
-- Example usage:
--
--    biblio:setBibliographyStyle('chicago-author-date', 'en-US', {
--       localizedPunctuation = false,
--       italicExtension = true,
--       mathExtension = true,
--       hyphenateISBN = true,
--    })
--
--  Style and locale files are searched in the following order:
--
--  - First in `csl/locales/` (resp. `csl/styles/`) wherever SILE looks at these from the working directory.
--    This allows users to put their own CSL files in a simple place
--  - Then in `packages/bibtex/csl/locales/` (ibid.)
--    This allows users to put their own CSL files e.g. in a local copy of the package, following its structure
--  - Then in `packages.bibtex.csl.locales.locales` (ibid.)
--    This allows users to use CSL files from the (extended) Lua path, e.g. from a module.
--
-- @tparam string stylename Name of the CSL style to use
-- @tparam string lang Language code for the locale (e.g., "en-US")
-- @tparam[opt] table options Additional options for the CSL engine
function CslProcessor:setBibliographyStyle (stylename, lang, options)
   local style = loadCslStyle(stylename)
   if not lang then
      -- Pick the default locale from the style, if any
      lang = style.globalOptions["default-locale"]
   end
   if not lang then
      -- FIXME: lang is mandatory until we can map document.lang to a resolved
      -- BCP47 with region always present, as this is what CSL locales require.
      SU.error("No language specified for CSL style '" .. stylename .. "'")
   end
   local locale = loadCslLocale(lang)
   self._engine = CslEngine(style, locale, options)
end

local function resolveEntry (bib, key)
   local entry = bib[key]
   if not entry then
      SU.warn("Unknown citation key " .. key)
      return
   end
   if entry.type == "xdata" then
      SU.warn("Skipped citation of @xdata entry " .. key)
      return
   end
   crossrefAndXDataResolve(bib, entry)
   return entry
end

--- Retrieve an entry and mark it as cited if it is not already.
-- @tparam string key Citation key
-- @tparam boolean warn_uncited Warn if the entry is not cited yet
-- @treturn table Bibliography entry
-- @treturn number Citation number
-- @treturn string|nil Locator value
function CslProcessor:_getEntryForCite (key, warn_uncited)
   key = self._data.aliases[key] and self._data.aliases[key].label or key
   local entry = resolveEntry(self._data.bib, key)
   if not entry then
      return
   end
   -- Keep track of cited entries
   local cited = self._data.cited.refs[key]
   if not cited then
      if warn_uncited then
         SU.warn("Reference to a non-cited entry " .. key)
      end
      -- Make it cited
      table.insert(self._data.cited.keys, key)
      local citnum = #self._data.cited.keys
      cited = { citnum = citnum }
      self._data.cited.refs[key] = cited
   end
   return entry, cited.citnum
end

--- Retrieve a locator from an options table.
-- Keys are expected to be locators like "page", "chapter", etc. as per CSL rules,
-- Some some extra convenience abbreviations and aliases are also supported,
-- and mapped to the corresponding CSL locator labels.
-- @tparam table options Options (key-value pairs) that may contain a locator
-- @treturn {label=string,value=string}|nil Locator
function CslProcessor:_getLocator (options)
   local locator
   for k, v in pairs(options) do
      if k ~= "key" then
         if not locators[k] then
            SU.warn("Unknown option '" .. k .. "' in \\cite")
         else
            if not locator then
               local label = locators[k]
               locator = { label = label, value = v }
            else
               SU.warn("Multiple locators in \\cite, using the first one")
            end
         end
      end
   end
   return locator
end

--- Track the position of a citation acconrding to the CSL rules.
-- @tparam string key Citation key
-- @tparam {label=string,value=string}|nil locator Locator
-- @tparam boolean is_single Single or multiple citation
-- @treturn string Position of the citation ("first", "subsequent", "ibid", "ibid-with-locator")
function CslProcessor:_getCitePosition (key, locator, is_single)
   key = self._data.aliases[key] and self._data.aliases[key].label or key
   local cited = self._data.cited.refs[key]
   if not cited then
      -- This method is assumed to be invoked only for cited entries
      -- (i.e. after a call to getEntryForCite).
      SU.error("Entry " .. key .. " not cited yet, cannot track position")
   end
   local pos
   if not cited.position then
      pos = "first"
   else
      -- CSL 1.0.2 for "ibid" and "ibid-with-locator":
      --    a. the current cite immediately follows on another cite, within the same citation,
      --       that references the same item
      --  or
      --    b. the current cite is the first cite in the citation, and the previous citation consists
      --       of a single cite referencing the same item.
      if self._data.cited.lastkey ~= key or not cited.single then
         pos = "subsequent"
      elseif cited.locator then
         -- CSL 1.0.2 rule when preceding cite does have a locator:
         --    If the current cite has the same locator, the position of the current cite is “ibid”.
         --    If the locator differs the position is “ibid-with-locator”.
         --    If the current cite lacks a locator its only position is “subsequent”."
         if locator then
            local same = cited.locator.label == locator.label and cited.locator.value == locator.value
            pos = same and "ibid" or "ibid-with-locator"
         else
            pos = "subsequent"
         end
      else
         -- CSL 1.0.2 rule when preceding cite does not have a locator:
         --    If the current cite has a locator, the position of the current cite is “ibid-with-locator”.
         --    Otherwise the position is “ibid”."
         pos = locator and "ibid-with-locator" or "ibid"
      end
   end
   cited.position = pos
   cited.locator = locator
   cited.single = is_single
   self._data.cited.lastkey = key
   return pos
end

--- Adapt a (BibTeX) entry to a CSL entry.
-- @tparam table entry Raw (BibTeX)
-- @tparam number|nil citnum Citation number (when citing)
-- @treturn CslEntry CSL entry proxy object
function CslProcessor:_adapter (entry, citnum)
   -- Convert the BibTeX entry to a CSL item and cache it in the entry.
   -- Then wrap it in a CslEntry proxy to allow overriding fields,
   -- and set the citation number.
   entry._csl = entry._csl or bib2csl(entry)
   if self._data.related[entry.label] then
      -- If the entry has related entries, we need to resolve them
      -- and add them to the CSL entry.
      local related = pl.List(self._data.related[entry.label]):map(function (r)
         local related_entry = resolveEntry(self._data.bib, r)
         if not related_entry then
            SU.error("Related entry " .. r .. " not found in bibliography")
            return nil
         end
         return self:_adapter(related_entry, 0) -- Some styles break without a citation number...
      end):filter(function (e) return e ~= nil end)
      entry._csl._related = related
   end
   local cslentry = CslEntry(entry._csl)
   cslentry['citation-number'] = citnum
   return cslentry
end

--- Load a bibliography file and parse it.
-- @tparam string bibfile Path to the BibTeX file to load
function CslProcessor:loadBibliography (bibfile)
   local bib = self._data.bib
   local aliases = self._data.aliases
   local related = self._data.related
   parseBibtex(bibfile, bib, aliases, related)
end

--- Cite a sigle entry with optional locator.
-- Usage example:
--
--    local cite = biblio:cite({
--       key = 'mykey1',
--       page = "191-193",
--    })
--
-- @tparam {key=string,[string]=string} item Citation item with a key and optional locator
-- @treturn string|nil Formatted citation string or nil if the entry is not found
function CslProcessor:cite (item)
   local key = item.key
   local entry, citnum = self:_getEntryForCite(key, false) -- no warning if not yet cited
   if entry then
      local engine = self:getCslEngine()
      local locator = self:_getLocator(item)
      local pos = self:_getCitePosition(key, locator, true) -- locator, single cite

      local cslentry = self:_adapter(entry, citnum)
      cslentry.locator = locator
      cslentry.position = pos
      local cite = engine:cite(cslentry)
      return cite
   end
end

--- Mark an entry as cited without actually citing it.
-- This is used to include an entry in the bibliography while not citing it in the text.
-- @tparam string key Citation key
function CslProcessor:nocite (key)
   self:_getEntryForCite(key, false) -- no warning whether already cited or not
end

--- Cite multiple entries with optional locators.
-- Usage example:
--
--    local cites = biblio:cites({
--       { key = 'mykey1', page = "191" },
--       { key = 'mykey2', chapter = "2" },
--       { key = 'mykey3' },
--    })
--
-- @tparam {key:string,[string]:string}[] items List of citation items, each with a key and optional locator
-- @treturn string|nil Formatted citation string or nil if no entries are found
function CslProcessor:cites (items)
   local is_single = #items == 1
   local cites = {}
   for _, item in ipairs(items) do
      local key = item.key
      local entry, citnum = self:_getEntryForCite(key, false) -- no warning if not yet cited
      if entry then
         local locator = self:_getLocator(item)
         local pos = self:_getCitePosition(key, locator, is_single) -- no locator, single or multiple citation

         local cslentry = self:_adapter(entry, citnum)
         cslentry.locator = locator
         cslentry.position = pos
         cites[#cites + 1] = cslentry
      end
   end
   if #cites > 0 then
      local engine = self:getCslEngine()
      local cite = engine:cite(cites)
      return cite
   end
end

--- Retrieve a reference for a given key.
-- This is used to get the full reference for an entry, though this is more for debugging
-- purposes than for actual bibliography processing.
-- @tparam string key Citation key
-- @treturn string|nil Formatted reference string or nil if the entry is not found
function CslProcessor:reference (key)
   local entry, citnum = self:_getEntryForCite(key, true) -- warn if not yet cited
   if entry then
      local engine = self:getCslEngine()
      local cslentry = self:_adapter(entry, citnum)
      cslentry._related = nil -- don't include related entries in the reference
      local cite = engine:reference(cslentry)
      return cite
   end
end

--- Retrieve a bibliography of entries.
-- Supported options are:
--
--  - `cited`: boolean, whether to include only cited entries (default: true)
--  - `filter`: string, filters to apply to the entries, if cited is false.
--  - `related`: boolean, whether to include related entries in the bibliography (default: false)
--
-- The filter is a space-separated list of filter names.
-- These can consist of named filters, or built-in filters.
-- The list is understood as a logical AND, i.e. all filters must match.
--
-- Built-in filters are:
--
--  - `issued-Y`: entries issued in year Y
--  - `issued-Y1-Y2`: entries issued between two years Y1 and Y2
--  - `type-x`: entries of the given type (e.g. book, article-journal, etc.)
--  - `not-type-x`: entries that are not of the given type
--  - `keyword-x`: entries that have the given keyword
--  - `not-keyword-x`: entries that do not have the given keyword
--
-- @tparam {cited=boolean,filter=string,related=boolean} options Options for the bibliography
-- @treturn string Formatted bibliography string
function CslProcessor:bibliography (options)
   local bib
   local filter = options.filter
   if SU.boolean(options.cited, true) then
      bib = {}
      for _, key in ipairs(self._data.cited.keys) do
         bib[key] = self._data.bib[key]
      end
      if options.filter then
         SU.error("Filtering does not apply to cited entries")
      end
   else
      bib = self._data.bib
   end

   local entries = {}
   local ncites = #self._data.cited.keys
   for key, entry in pairs(bib) do
      if entry.type ~= "xdata" then
         crossrefAndXDataResolve(bib, entry)
         if entry then
            local citnum
            local cited = self._data.cited.refs[key]
            if not cited then
               citnum = 0
            else
               citnum = cited.citnum
            end
            local cslentry = self:_adapter(entry, citnum)
            if not SU.boolean(options.related, false) then
               cslentry._related = nil -- Don't include related entries in the bibliography
            end
            local isFiltered = not filter or self:applyFilter(cslentry, filter)
            if isFiltered then
               if citnum == 0 then
                  -- This is a non-cited entry, so we need to set the citation number
                  -- to the next available number in the bibliography.
                  ncites = ncites + 1
                  citnum = ncites
                  cslentry['citation-number'] = citnum
               end
               table.insert(entries, cslentry)
            end
         end
      end
   end
   self._data.cited = { keys = {}, refs = {}, lastkey = nil }

   local engine = self:getCslEngine()
   local cite = engine:reference(entries)

   print("<bibliography: " .. #entries .. " entries>")
   return cite
end

--- Define a named filter for the CSL processor.
-- @tparam string name Name of the filter
-- @tparam function filterFn Function taking a CSL entry and returning true if the filter matches
function CslProcessor:defineFilter(name, filterFn)
   self._filter[name] = filterFn
end

--- Apply a filter to a CSL entry.
-- @tparam CslEntry entry CSL entry to filter
-- @tparam string names Names of the filters to apply (separated by spaces)
-- @treturn boolean True if the entry matches all filters, false otherwise
function CslProcessor:applyFilter(entry, names)
   local filters = pl.stringx.split(names, " "):filter(function (s) return s ~= "" end)
   for _, f in ipairs(filters) do
      local filterFn = self._filter[f] or builtinFilter(f)
      if not filterFn(entry) then
         return false
      end
   end
   return true
end

local bibTagsToHtml = {
   bibSmallCaps = { '<span class="bib-smallcaps">', "</span>" },
   bibSuperScript = { '<span class="bib-superscript">', "</span>" },
   bibParagraph = { '<div class="bib-par">', "</div>" },
   bibBoxForIndent = { '<span class="bib-box-for-indent">', "</span>" },
   bibRelated = { '<div class="bib-rel">', "</div>" },
   math = { '<span class="bib-math">\\(', "\\)</span>" }, -- MathJax-compatible \( .. \) delimiters
}

local function biblink (url, text, class)
   return string.format('<a class="%s" href="%s">%s</a>', class, url, text)
end

--- Convert a formatted bibliography to HTML format.
--
-- **NOTE**: Very naive implementation for now. Private, may change in the future.
--
-- @tparam string out The bibliography output as a string
-- @tparam[opt=true] boolean standalone Whether to wrap the output in a full HTML document
-- @treturn string HTML formatted bibliography
function CslProcessor:_toHtml (out, standalone)
   standalone = SU.boolean(standalone, true)

   -- Replace custom tags with HTML equivalents
   for tag, html in pairs(bibTagsToHtml) do
      local openTag = "<" .. tag .. ">"
      local closeTag = "</" .. tag .. ">"
      out = out:gsub(openTag, html[1])
      out = out:gsub(closeTag, html[2])
   end
   out = out:gsub("<bibRule>([%d%.]+)</bibRule>", function(n)
      local dashes = string.rep("—", n)
      return dashes
   end)
   out = out:gsub("<bibURL>(.-)</bibURL>", function(url)
      return biblink(url, url, "bib-url")
   end)
   out = out:gsub("<bibDOI>(.-)</bibDOI>", function(doi)
      local url =not doi:match("^https?://") and "https://doi.org/" .. doi or doi
      return biblink(url, doi, "bib-doi")
   end)
   out = out:gsub("<bibPMID>(.-)</bibPMID>", function(pmid)
      local url = not pmid:match("^https?://") and "https://www.ncbi.nlm.nih.gov/pubmed/" .. pmid or pmid
      return biblink(url, pmid, "bib-pmid")
   end)
   out = out:gsub("<bibPMCID>(.-)</bibPMCID>", function(pmcid)
      local url = not pmcid:match("^https?://") and "https://www.ncbi.nlm.nih.gov/pmc/articles/" .. pmcid or pmcid
      return biblink(url, pmcid, "bib-pmcid")
   end)
   if not standalone then
      return out
   end
   return table.concat({([[<!DOCTYPE html>
<html lang="%s">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Bibliography</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400..800;1,400..800&display=swap" rel="stylesheet">
<script id="MathJax-script" async
   src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js">
</script>
<style>
body {
   font-family: "EB Garamond", serif;
   font-optical-sizing: auto;
   font-size: 16pt;
}
.bib-par {
   padding-left: 3em;
   text-indent: -3em;
   padding-bottom: 0.5em;
}
.bib-smallcaps {
   font-variant: small-caps;
}
.bib-superscript {
   vertical-align: super;
   font-size: smaller;
}
.bib-url, .bib-doi, .bib-pmid, .bib-pmcid {
   text-decoration: none;
   font-size: 0.85em
}
.bib-box-for-indent {
   display: inline-block;
   min-width: 2.7em;
   text-indent: 0;
   padding-right: 0.3em;
}
.bib-rel {
   font-size: 0.9em;
   border-left: 2px solid #bdb1df;
   padding-left: 0.5em;
   color: #54467b;
}
</style>
</head>
<body>
<div class="bibliography">
]]):format(self._engine.locale.lang),
   out,
[[</div>
</body>
</html>
]]}, "\n")
end

return CslProcessor
