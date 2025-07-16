--- A processor for bibliographies.
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
-- They will look for a file in the following order:
--  - First in csl/locales/ (resp. csl/styles/) wherever SILE looks at these from the working directory.
--    This allows users to put their own CSL files in a simple place
--  - Then in `packages/bibtex/csl/locales/` (ibid.)
--    This allows users to put their own CSL files e.g. in a local copy of the package, following its structure
--  - Then in `packages.bibtex.csl.locales.locales` (ibid.)
--    This allows users to use CSL files from the (extended) Lua path, e.g. from a module.
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

-- CSL ENTRY PROXY (PSEUDO-CLASS)

local NIL_SENTINEL = {} -- Sentinel value to indicate that a field is overridden to nil

--- Construct a proxy object that overrides the original entry table.
-- It is used to allow overriding CSL field values without modifying the original entry,
-- so that we can for instance cache the CSL item and override some fields at some later
-- processing time.
-- @tparam  table entry Orignal table to proxy
-- @treturn table       Proxy object wrapping the original entry
local function CslEntry(entry)
   local proxy = {
      _entry = entry,
      _override = {},
   }
   setmetatable(proxy, {
      __index = function (self, key)
         local override = rawget(self._override, key)
         if override ~= nil then
            if override == NIL_SENTINEL then
               return nil
            end
            return override
         end
         return rawget(self._entry, key)
      end,
      __newindex = function (self, key, value)
         if value == nil then
            rawset(self._override, key, NIL_SENTINEL)
         else
            rawset(self._override, key, value)
         end
      end,
   })
   return proxy
end

-- CSL PROCESSOR CLASS

local CslProcessor = pl.class()

--- (Constructor) Create a new CSL Bibliography manager.
-- @treturn CslProcessor New CSL Bibliography manager instance
function CslProcessor:_init ()
   self._data = {
      bib = {},
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
      self:setBibliographyStyle('chicago-author-date', "en-US", {
         localizedPunctuation = false,
         italicExtension = true,
         mathExtension = true,
      })
   end
   return self._engine
end

---- Set the bibliography style and locale for the CSL engine.
-- @tparam string stylename Name of the CSL style to use
-- @tparam string lang      Language code for the locale (e.g., "en-US")
-- @tparam[opt]   table     options Additional options for the CSL engine
function CslProcessor:setBibliographyStyle (stylename, lang, options)
   options = options or {
      localizedPunctuation = false,
      italicExtension = true,
      mathExtension = true,
   }
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
   self._engine = CslEngine(style, locale, {
      localizedPunctuation = SU.boolean(options.localizedPunctuation, false),
      italicExtension = SU.boolean(options.italicExtension, true),
      mathExtension = SU.boolean(options.mathExtension, true),
   })
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
-- @tparam table options Options (key-value pairs) that may contain a locator
-- @treturn table Locator
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
-- @tparam {label=string, value=string}|nil locator Locator
-- @tparam boolean is_single Single or multiple citation
-- @treturn string Position of the citation ("first", "subsequent", "ibid", "ibid-with-locator")
function CslProcessor:_getCitePosition (key, locator, is_single)
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

function CslProcessor:_adapter (entry, citnum)
   -- Convert the BibTeX entry to a CSL item and cache it in the entry.
   -- Then wrap it in a CslEntry proxy to allow overriding fields,
   -- and set the citation number.
   entry._csl = entry._csl or bib2csl(entry)
   local cslentry = CslEntry(entry._csl)
   cslentry['citation-number'] = citnum
   return cslentry
end

--- Cite a sigle entry with optional locator.
-- Usage example:
-- ```lua
-- local cite = biblio:cite({
--    key = 'mykey1',
--    page = "191-193",
-- })
-- ```
-- @tparam {key=string, [string]=string} item Citation item with a key and optional locator
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
-- ```lua
-- local cites = biblio:cites({
--    { key = 'mykey1', page = "191" },
--    { key = 'mykey2', chapter = "2" },
--    { key = 'mykey3' },
-- })
-- @tparam table items List of citation items, each with a key and optional locator
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
-- This is used to get the full reference for an entry, e.g. for a bibliography.
-- It will return the entry as a CSL item, with the citation number set.
-- @tparam string key Citation key
-- @treturn string[nul Formatted reference string or nil if the entry is not found
function CslProcessor:reference (key)
   local entry, citnum = self:_getEntryForCite(key, true) -- warn if not yet cited
   if entry then
      local engine = self:getCslEngine()
      local cslentry = self:_adapter(entry, citnum)
      local cite = engine:reference(cslentry)
      return cite
   end
end

--- Retrieve a bibliography of entries
-- @tparam {cited=boolean} options Options for the bibliography
-- @treturn string Formatted bibliography string
function CslProcessor:bibliography (options)
   local bib
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
            local prevcite = self._data.cited.refs[key]
            if not prevcite then
               -- This is just to make happy CSL styles that require a citation number
               -- However, table order is not guaranteed in Lua so the output may be
               -- inconsistent across runs with styles that use this number for sorting.
               -- This may only happen for non-cited entries in the bibliography, and it
               -- would be a bad practice to use such a style to print the full bibliography,
               -- so I don't see a strong need to fix this at the expense of performance.
               -- (and we can't really, some styles might have several sorting criteria
               -- leading to unpredictable order anyway).
               ncites = ncites + 1
               citnum = ncites
            else
               citnum = prevcite.citnum
            end
            local cslentry = self:_adapter(entry, citnum)
            table.insert(entries, cslentry)
         end
      end
   end
   self._data.cited = { keys = {}, refs = {}, lastkey = nil }

   local engine = self:getCslEngine()
   local cite = engine:reference(entries)

   print("<bibliography: " .. #entries .. " entries>")
   return cite
end

--- Load a bibliography file and parse it.
-- @tparam string bibfile Path to the BibTeX file to load
-- @treturn nil
function CslProcessor:loadBibliography (bibfile)
   local bib = self._data.bib
   parseBibtex(bibfile, bib)
end

local bibTagsToHtml = {
   bibSmallCaps = { '<span class="bib-smallcaps">', "</span>" },
   bibSuperScript = { '<span class="bib-superscript">', "</span>" },
   bibPar = { '<div class="bib-par">', "</div>" },
   bibBoxForIndent = { 'span class="bib-box-for-indent"', "</span>" },
}

local function biblink (url, _, class)
   -- U+1F517 is 🔗
   return string.format('<a class="%s" href="%s">%s</a>', class, url, "&#x1F517;")
end

--- Convert a formatted bibliography to HTML format.
-- NOTE: Very naive implementation for now :)
-- @tparam string out The bibliography output as a string
-- @treturn string HTML formatted bibliography
function CslProcessor:toHtml (out)
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
   return table.concat({([[<!DOCTYPE html>
<html lang="%s">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Bibliography</title>
<style>
body { font-family: Arial, sans-serif; }
.bib-par { padding-left: 3em; text-indent: -3em; padding-top: 0.5em; }
.bib-smallcaps { font-variant: small-caps; }
.bib-superscript { vertical-align: super; font-size: smaller; }
.bib-url, .bib-doi, .bib-pmid, .bib-pmcid { text-decoration: none; }
.bib-box-for-indent { display: inline-block; width: 3em; }
</style>
</head>
<body>
<h1>Bibliography</h1>
<div class="bibliography">
]]):format(self._engine.locale.lang),
   out,
[[</div>
</body>
</html>
]]}, "\n")
end

return CslProcessor
