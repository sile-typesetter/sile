local base = require("packages.base")

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

local Bibliography = require("packages.bibtex.bibliography") -- Legacy

local function loadCslLocale (name)
   local filename = SILE.resolveFile("packages/bibtex/csl/locales/locales-" .. name .. ".xml")
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
   local filename = SILE.resolveFile("packages/bibtex/csl/styles/" .. name .. ".csl")
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

local package = pl.class(base)
package._name = "bibtex"

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

function package:loadOptPackage (pack)
   local ok, _ = pcall(function ()
      self:loadPackage(pack)
      return true
   end)
   SU.debug("bibtex", "Optional package " .. pack .. (ok and " loaded" or " not loaded"))
   return ok
end

function package:_init ()
   base._init(self)
   -- Formerly we used a SILE.scratch variable, but these expose too much of the internals to the outer world.
   -- So we now use a private member instead.
   self._data = {
      bib = {},
      cited = {
         keys = {}, -- Cited keys in the order they are cited (ordered set)
         refs = {}, -- Table of cited keys with their first citation number, last locator and last position (table)
         lastkey = nil, -- Last entry key used in a citation, to track ibid/ibid-with-locator (string)
      },
   }

   -- For DOI, PMID, PMCID and URL support.
   self:loadPackage("url")
   -- For underline styling support
   self:loadPackage("rules")
   -- For TeX-like math support (extension)
   self:loadPackage("math")
   -- For superscripting support in number formatting
   -- Play fair: try to load 3rd-party optional textsubsuper package.
   -- If not available, fallback to raiselower to implement textsuperscript
   if not self:loadOptPackage("textsubsuper") then
      self:loadPackage("raiselower")
      self.commands:register("textsuperscript", function (_, content)
         -- Fake more or less ad hoc superscripting
         SILE.call("raise", { height = "0.7ex" }, function ()
            SILE.call("font", { size = "1.5ex" }, content)
         end)
      end)
   end
end

function package:declareSettings ()
   self.settings:declare({
      parameter = "bibtex.style",
      type = "string",
      default = "csl",
      help = "BibTeX style",
   })

   -- For CSL hanging-indent or second-field-align
   self.settings:declare({
      parameter = "bibliography.indent",
      type = "measurement",
      default = SILE.types.measurement("3em"),
      help = "Left indentation for bibliography entries when the citation style requires it.",
   })
end

--- Retrieve the CSL engine, creating it if necessary.
-- @treturn CslEngine CSL engine instance
function package:getCslEngine ()
   if not self._engine then
      SILE.call("bibliographystyle", { lang = "en-US", style = "chicago-author-date" })
   end
   return self._engine
end

--- Retrieve an entry and mark it as cited if it is not already.
-- @tparam string key Citation key
-- @tparam boolean warn_uncited Warn if the entry is not cited yet
-- @treturn table Bibliography entry
-- @treturn number Citation number
-- @treturn string|nil Locator value
function package:_getEntryForCite (key, warn_uncited)
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

--- Track the position of a citation acconrding to the CSL rules.
-- @tparam string key Citation key
-- @tparam table locator Locator (label and value)
-- @tparam boolean is_single Single or multiple citation
-- @treturn string Position of the citation (first, subsequent, ibid, ibid-with-locator)
function package:_getCitePosition (key, locator, is_single)
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

--- Get the citation key from the options or content (of a command).
-- @tparam table options Options
-- @tparam table content Content
-- @treturn string Citation key
function package:_getCitationKey (options, content)
   if options.key then
      return options.key
   end
   return SU.ast.contentToString(content)
end

--- Retrieve a locator from the options.
-- @tparam table options Options
-- @treturn table Locator
function package:_getLocator (options)
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

function package:registerCommands ()
   self.commands:register("loadbibliography", function (options, _)
      local file = SU.required(options, "file", "loadbibliography")
      parseBibtex(file, self._data.bib)
   end)

   self.commands:register("nocite", function (options, content)
      local key = self:_getCitationKey(options, content)
      -- Just mark the entry as cited.
      self:_getEntryForCite(key, false) -- no warning if not yet cited
   end, "Mark an entry as cited without actually producing a citation.")

   -- LEGACY COMMANDS

   self.commands:register("cite", function (options, content)
      local style = self.settings:get("bibtex.style")
      if style == "csl" then
         SILE.call("csl:cite", options, content)
         return -- done via CSL
      end
      if not self._deprecated_legacy_warning then
         self._deprecated_legacy_warning = true
         SU.warn("Legacy bibtex.style is deprecated, consider enabling the CSL implementation.")
      end
      -- Ensure the key is set in the options as this was the legacy behavior
      options.key = self:_getCitationKey(options, content)
      local entry = self:_getEntryForCite(options.key, false) -- no warning if not yet cited
      if entry then
         local bibstyle = require("packages.bibtex.styles." .. style)
         local cite = Bibliography.produceCitation(options, self._data.bib, bibstyle)
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single citation.")

   self.commands:register("reference", function (options, content)
      local style = self.settings:get("bibtex.style")
      if style == "csl" then
         SILE.call("csl:reference", options, content)
         return -- done via CSL
      end
      if not self._deprecated_legacy_warning then
         self._deprecated_legacy_warning = true
         SU.warn("Legacy bibtex.style is deprecated, consider enabling the CSL implementation.")
      end
      -- Ensure the key is set in the options as this was the legacy behavior
      options.key = self:_getCitationKey(options, content)
      local entry = self:_getEntryForCite(options.key, true) -- warn if uncited
      if entry then
         local bibstyle = require("packages.bibtex.styles." .. style)
         local cite, err = Bibliography.produceReference(options, self._data.bib, bibstyle)
         if cite == Bibliography.Errors.UNKNOWN_TYPE then
            SU.warn("Unknown type @" .. err .. " in citation for reference " .. options.key)
            return
         end
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single bibliographic reference.")

   -- CSL IMPLEMENTATION COMMANDS

   -- Hooks for CSL processing

   self.commands:register("bibSmallCaps", function (_, content)
      -- To avoid attributes in the CSL-processed content
      SILE.call("font", { features = "+smcp" }, content)
   end)

   self.commands:register("bibSuperScript", function (_, content)
      -- Superscripted content from CSL may contain characters that are not
      -- available in the font even with +sups.
      -- E.g. ACS style uses superscripted numbers for references, but also
      -- comma-separated lists of numbers, or ranges with an en-dash.
      -- We want to be consistent between all these cases, so we always
      -- use fake superscripts.
      SILE.call("textsuperscript", { fake = true }, content)
   end)

   -- CSL 1.0.2 appendix VI
   -- "If the bibliography entry for an item renders any of the following
   -- identifiers, the identifier should be anchored as a link, with the
   -- target of the link as follows:
   --   url: output as is
   --   doi: prepend with “https://doi.org/”
   --   pmid: prepend with “https://www.ncbi.nlm.nih.gov/pubmed/”
   --   pmcid: prepend with “https://www.ncbi.nlm.nih.gov/pmc/articles/”
   -- NOT IMPLEMENTED:
   --   "Citation processors should include an option flag for calling
   --   applications to disable bibliography linking behavior."
   -- (But users can redefine these commands to their liking...)
   self.commands:register("bibLink", function (options, content)
      SILE.call("href", { src = options.src }, {
         SU.ast.createCommand("url", {}, { content[1] }),
      })
   end)
   self.commands:register("bibURL", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         -- Play safe
         link = "https://" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self.commands:register("bibDOI", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://doi.org/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self.commands:register("bibPMID", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://www.ncbi.nlm.nih.gov/pubmed/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self.commands:register("bibPMCID", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://www.ncbi.nlm.nih.gov/pmc/articles/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)

   self.commands:register("bibRule", function (_, content)
      local n = content[1] and tonumber(content[1]) or 3
      local width = n .. "em"
      SILE.call("raise", { height = "0.4ex" }, function ()
         SILE.call("hrule", { height = "0.4pt", width = width })
      end)
   end)

   self.commands:register("bibBoxForIndent", function (_, content)
      local hbox = SILE.typesetter:makeHbox(content)
      local margin = SILE.types.length(self.settings:get("bibliography.indent"):absolute())
      if hbox.width > margin then
         SILE.typesetter:pushHbox(hbox)
         SILE.typesetter:typeset(" ")
      else
         hbox.width = margin
         SILE.typesetter:pushHbox(hbox)
      end
   end)

   -- Style and locale loading

   self.commands:register("bibliographystyle", function (options, _)
      local sty = SU.required(options, "style", "bibliographystyle")
      local style = loadCslStyle(sty)
      -- FIXME: lang is mandatory until we can map document.lang to a resolved
      -- BCP47 with region always present, as this is what CSL locales require.
      if not options.lang then
         -- Pick the default locale from the style, if any
         options.lang = style.globalOptions["default-locale"]
      end
      local lang = SU.required(options, "lang", "bibliographystyle")
      local locale = loadCslLocale(lang)
      self._engine = CslEngine(style, locale, {
         localizedPunctuation = SU.boolean(options.localizedPunctuation, false),
         italicExtension = SU.boolean(options.italicExtension, true),
         mathExtension = SU.boolean(options.mathExtension, true),
      })
   end)

   self.commands:register("csl:cite", function (options, content)
      local key = self:_getCitationKey(options, content)
      local entry, citnum = self:_getEntryForCite(key, false) -- no warning if not yet cited
      if entry then
         local engine = self:getCslEngine()
         local locator = self:_getLocator(options)
         local pos = self:_getCitePosition(key, locator, true) -- locator, single cite

         local cslentry = bib2csl(entry, citnum)
         cslentry.locator = locator
         cslentry.position = pos
         local cite = engine:cite(cslentry)

         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single citation.")

   self.commands:register("cites", function (_, content)
      if type(content) ~= "table" then
         SU.error("Table content expected in \\cites")
      end
      -- We need no count cites to properly handle ibid/ibid-with-locator, as these depend
      -- on the previous citation being a single cite.
      local children = {}
      local nb = 0
      for _, child in ipairs(content) do
         if type(child) == "table" then
            if child.command ~= "cite" then
               SU.error("Only \\cite commands are allowed in \\cites")
            end
            nb = nb + 1
            table.insert(children, child)
         end
         -- Silently ignore other content (normally only blank lines)
      end
      local is_single = nb == 1
      -- Now we can collect the citations
      local cites = {}
      for _, c in ipairs(children) do
         local o = c.options
         local key = self:_getCitationKey(o, c)
         local entry, citnum = self:_getEntryForCite(key, false) -- no warning if not yet cited
         if entry then
            local locator = self:_getLocator(o)
            local pos = self:_getCitePosition(key, locator, is_single) -- no locator, single or multiple citation

            local cslentry = bib2csl(entry, citnum)
            cslentry.locator = locator
            cslentry.position = pos
            cites[#cites + 1] = cslentry
         end
      end
      if #cites > 0 then
         local engine = self:getCslEngine()
         local cite = engine:cite(cites)
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a group of citations.")

   self.commands:register("csl:reference", function (options, content)
      local key = self:_getCitationKey(options, content)
      local entry, citnum = self:_getEntryForCite(key, nil, true) -- no locator, warn if not yet cited
      if entry then
         local engine = self:getCslEngine()

         local cslentry = bib2csl(entry, citnum)
         local cite = engine:reference(cslentry)

         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single bibliographic reference.")

   self.commands:register("printbibliography", function (options, _)
      local bib
      if SU.boolean(options.cited, true) then
         bib = {}
         for _, key in ipairs(self._data.cited.keys) do
            bib[key] = self._data.bib[key]
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
               local cslentry = bib2csl(entry, citnum)
               table.insert(entries, cslentry)
            end
         end
      end
      -- Reset the list of cited entries after having build the entries
      self._data.cited = { keys = {}, refs = {}, lastkey = nil }

      local engine = self:getCslEngine()
      local cite = engine:reference(entries)

      print("<bibliography: " .. #entries .. " entries>")
      if not SILE.typesetter:vmode() then
         SILE.call("par")
      end
      self.settings:temporarily(function ()
         local hanging_indent = SU.boolean(engine.bibliography.options["hanging-indent"], false)
         local must_align = engine.bibliography.options["second-field-align"]
         local lskip = (self.settings:get("document.lskip") or SILE.types.node.glue()):absolute()
         if hanging_indent or must_align then
            -- Respective to the fixed part of the current lskip, all lines are indented
            -- but the first one.
            local indent = self.settings:get("bibliography.indent"):absolute()
            self.settings:set("document.lskip", lskip.width + indent)
            self.settings:set("document.parindent", -indent)
            self.settings:set("current.parindent", -indent)
         else
            -- Fixed part of the current lskip, and no paragraph indentation
            self.settings:set("document.lskip", lskip.width)
            self.settings:set("document.parindent", SILE.types.length())
            self.settings:set("current.parindent", SILE.types.length())
         end
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
         SILE.call("par")
      end)
   end, "Produce a bibliography of references.")
end

package.documentation = [[
\begin{document}
BibTeX is a citation management system.
It was originally designed for TeX but has since been integrated into a variety of situations.
This experimental package allows SILE to read and process Bib(La)TeX \code{.bib} files and output citations and full text references.

\smallskip
\noindent
\em{Loading a bibliography}
\novbreak

\indent
To load a BibTeX file, issue the command \autodoc:command{\loadbibliography[file=<whatever.bib>]}.
You can load multiple files, and the entries will be merged into a single bibliography database.

\smallskip
\noindent
\em{Producing citations and references (CSL implementation)}
\novbreak

\indent
The CSL (Citation Style Language) implementation is more powerful and flexible than the former legacy solution available in earlier versions of this package (see below).

You should first invoke \autodoc:command{\bibliographystyle[style=<style>, lang=<lang>]}, where \autodoc:parameter{style} is the name of the CSL style file (without the \code{.csl} extension), and \autodoc:parameter{lang} is the language code of the CSL locale to use (e.g., \code{en-US}).

The command accepts a few additional options:

\begin{itemize}
\item{\autodoc:parameter{localizedPunctuation} (default \code{false}): whether to use localized punctuation – this is non-standard but may be useful when using a style that was not designed for the target language;}
\item{\autodoc:parameter{italicExtension} (default \code{true}): whether to convert \code{_text_} to italic text (“à la Markdown”);}
\item{\autodoc:parameter{mathExtension} (default \code{true}): whether to recognize \code{$formula$} as math formulae in (a subset of the) TeX-like syntax.}
\end{itemize}

The locale and styles files are searched in the \code{csl/locales} and \code{csl/styles} directories, respectively, in your project directory, or in the Lua package path.
For convenience and testing, SILE bundles the \code{chicago-author-date} and \code{chicago-author-date-fr} styles, and the \code{en-US} and \code{fr-FR} locales.
If you don’t specify a style or locale, the author-date style and the \code{en-US} locale will be used.

To produce an inline citation, call \autodoc:command{\cite{<key>}}, which will typeset something like “(Jones 1982)”.
If you want to cite a particular page number, use \autodoc:command{\cite[page=22]{<key>}}. Other “locator”  options are available (article, chapter, column, line, note, paragraph, section, volume, etc.) – see the CSL documentation for details.
Some frequent abbreviations are also supported (art, chap, col, fig…)

To mark an entry as cited without actually producing a citation, use \autodoc:command{\nocite{<key>}}.
This is useful when you want to include an entry in the bibliography without citing it in the text.

To generate multiple citations grouped correctly, use \autodoc:command{\cites{\cite{<key1>} \cite{<key2>}, …}}.
This wrapper command only accepts \autodoc:command{\cite} elements following their standard syntax.
Any other element triggers an error, and any text content is silently ignored.

To produce a bibliography of cited references, use \autodoc:command{\printbibliography}.
After printing the bibliography, the list of cited entries will be cleared. This allows you to start fresh for subsequent uses (e.g., in a different chapter).
If you want to include all entries in the bibliography, not just those that have been cited, set the option \autodoc:parameter{cited} to false.

To produce a bibliographic reference, use \autodoc:command{\reference{<key>}}.
Note that this command is not intended for actual use, but for testing purposes.
It may be removed in the future.

\smallskip
\noindent
\em{Producing citations and references (legacy commands)}
\novbreak

\indent
The “legacy” implementation is based on a custom rendering system.
The plan is to eventually deprecate and remove it, as the CSL implementation covers more use cases and is more powerful.

The \autodoc:setting[check=false]{bibtex.style} setting controls the style of the bibliography.
It may be set, for instance, to \code{chicago}, the only style supported out of the box.
(By default, it is set to \code{csl} to enforce the use of the CSL implementation.)

To produce an inline citation, call \autodoc:command{\cite{<key>}}, which will typeset something like “Jones 1982”.
If you want to cite a particular page number, use \autodoc:command{\cite[page=22]{<key>}}.

To produce a bibliographic reference, use \autodoc:command{\reference{<key>}}.

This implementation doesn’t currently produce full bibliography listings.
(Actually, you can use the \autodoc:command{\printbibliography} introduced above, but then it always uses the CSL implementation for rendering the bibliography, differing from the output of the \autodoc:command{\reference} command.)

\smallskip
\noindent
\em{Notes on the supported BibTeX syntax}
\novbreak

\indent
The BibTeX file format is a plain text format for bibliographies.

The \code{@type\{…\}} syntax is used to specify an entry, where \code{type} is the type of the entry, and is case-insensitive.
Any content outside entries is ignored.

The \code{@preamble} and \code{@comment} special entries are ignored.
The former is specific to TeX-based systems, and the latter is a comment (everything between the balanced braces is ignored).

The \code{@string\{key=value\}} special entry is used to define a string or “abbreviation,” for use in other subsequent entries.

The \code{@xdata} entry is used to define an entry that can be used as a reference in other entries.
Such entries are not printed in the bibliography.
Normally, they cannot be cited directly.
In this implementation, a warning is raised if they are; but as they have no known type, their formatting is not well-defined, and might not be meaningful.

Regular bibliography entries have the following syntax:

\begin[type=autodoc:codeblock]{raw}
@type{key,
  field1 = value1,
  field2 = value2,
  …
}
\end{raw}

The entry key is a unique identifier for the entry, and is case-sensitive.
Entries consist of fields, which are key-value pairs.
The field names are case-insensitive.
Spaces and line breaks are not important, except for readability.
On the contrary, commas are compulsory between any two fields of an entry.

String values shall be enclosed in either double quotes or curly braces.
The latter allows using quotes inside the string, while the former does not without escaping them with a backslash.

When string values are not enclosed in quotes or braces, they must not contain any whitespace characters.
The value is then considered to be a reference to an abbreviation previously defined in a \code{@string} entry.
If no such abbreviation is found, the value is considered to be a string literal.
(This allows a decent fallback for fields where curly braces or double quotes could historically be omitted, such as numerical values, and one-word strings.)

String values are assumed to be in the UTF-8 encoding, and shall not contain (La)TeX commands.
Special character sequences from TeX (such as \code{`} assumed to be an opening quote) are not supported.
There are exceptions to this rule.
Notably, the \code{~} character can be used to represent a non-breaking space (when not backslash-escaped), and the \code{\\&} sequence is accepted (though this implementation does not mandate escaping ampersands).
With the CSL renderer, see also the non-standard extensions above.

Values can also be composed by concatenating strings, using the \code{#} character.

Besides using string references, entries have two other \em{parent-child} inheritance mechanisms allowing to reuse fields from other entries, without repeating them: the \code{crossref} and \code{xdata} fields.

The \code{crossref} field is used to reference another entry by its key.
The \code{xdata} field accepts a comma-separated list of keys of entries that are to be inherited.

Some BibTeX implementations automatically include entries referenced with the \code{crossref} field in the bibliography, when a certain threshold is met.
This implementation does not do that.

Depending on the types of the parent and child entries, the child entry may inherit some or all fields from the parent entry, and some inherited fields may be reassigned in the child entry.
For instance, the \code{title} in a \code{@collection} entry is inherited as the \code{booktitle} field in a \code{@incollection} child entry.
Some BibTeX implementations allow configuring the data inheritance behavior, but this implementation does not.
It is also currently quite limited on the fields that are reassigned, and only provides a subset of the mappings defined in the BibLaTeX manual, appendix B.

Here is an example of a BibTeX file showing some of the abovementioned features:

\begin[type=autodoc:codeblock]{raw}
@string{JIT = "Journal of Interesting Things"}
...
This text is ignored
...
@xdata{jit-vol1-iss2,
  journal = JIT # { (JIT)},
  year    = {2020},
  month   = {jan},
  volume  = {1},
  number  = {2},
}
@article{my-article,
  author  = {Doe, John and Smith, Jane}
  title   = {Theories & Practices},
  xdata   = {jit-1-2},
  pages   = {100--200},
}
\end{raw}

Some fields have a special syntax.
The \code{author}, \code{editor} and \code{translator} fields accept a list of names, separated by the keyword \code{and}.
The legacy \code{month} field accepts a three-letter abbreviation for the month in English, or a number from 1 to 12.
The more powerful \code{date} field accepts a date-time following the ISO 8601-2 Extended Date/Time Format specification level 1 (such as \code{YYYY-MM-DD}, or a date range \code{YYYY-MM-DD/YYYY-MM-DD}, and more).
\end{document}
]]

return package
