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
   SILE.scratch.bibtex = { bib = {}, cited = { keys = {}, citnums = {} } }
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
      self:registerCommand("textsuperscript", function (_, content)
         SILE.call("raise", { height = "0.7ex" }, function ()
            SILE.call("font", { size = "1.5ex" }, content)
         end)
      end)
   end
end

function package.declareSettings (_)
   SILE.settings:declare({
      parameter = "bibtex.style",
      type = "string",
      default = "chicago",
      help = "BibTeX style",
   })
end

--- Retrieve the CSL engine, creating it if necessary.
-- @treturn CslEngine CSL engine instance
function package.getCslEngine (_)
   if not SILE.scratch.bibtex.engine then
      SILE.call("bibliographystyle", { lang = "en-US", style = "chicago-author-date" })
   end
   return SILE.scratch.bibtex.engine
end

--- Retrieve an entry and mark it as cited if it is not already.
-- The citation key is taken from the options, or from the content if not provided.
-- @tparam table options Options
-- @tparam table content Content
-- @tparam boolean warn_uncited Warn if the entry is not cited yet
-- @treturn table Bibliography entry
function package.getEntryForCite (_, options, content, warn_uncited)
   if not options.key then
      options.key = SU.ast.contentToString(content)
   end
   local entry = resolveEntry(SILE.scratch.bibtex.bib, options.key)
   if not entry then
      return
   end
   -- Keep track of cited entries
   local citnum = SILE.scratch.bibtex.cited.citnums[options.key]
   if not citnum then
      if warn_uncited then
         SU.warn("Reference to a non-cited entry " .. options.key)
      end
      -- Make it cited
      table.insert(SILE.scratch.bibtex.cited.keys, options.key)
      citnum = #SILE.scratch.bibtex.cited.keys
      SILE.scratch.bibtex.cited.citnums[options.key] = citnum
   end
   return entry, citnum
end

--- Retrieve a locator from the options.
-- @tparam table options Options
-- @treturn table Locator
function package.getLocator (_, options)
   local locator
   for k, v in pairs(options) do
      if k ~= "key" then
         if not locators[k] then
            SU.warn("Unknown option '" .. k .. "' in \\csl:cite")
         else
            if not locator then
               local label = locators[k]
               locator = { label = label, value = v }
            else
               SU.warn("Multiple locators in \\csl:cite, using the first one")
            end
         end
      end
   end
   return locator
end

function package:registerCommands ()
   self:registerCommand("loadbibliography", function (options, _)
      local file = SU.required(options, "file", "loadbibliography")
      parseBibtex(file, SILE.scratch.bibtex.bib)
   end)

   self:registerCommand("nocite", function (options, content)
      self:getEntryForCite(options, content, false)
   end, "Mark an entry as cited without actually producing a citation.")

   -- LEGACY COMMANDS

   self:registerCommand("bibstyle", function (_, _)
      SU.deprecated("\\bibstyle", "\\set[parameter=bibtex.style]", "0.13.2", "0.14.0")
   end)

   self:registerCommand("cite", function (options, content)
      local style = SILE.settings:get("bibtex.style")
      if style == "csl" then
         SILE.call("csl:cite", options, content)
         return -- done via CSL
      end
      if not self._deprecated_legacy_warning then
         self._deprecated_legacy_warning = true
         SU.warn("Legacy bibtex.style is deprecated, consider enabling the CSL implementation.")
      end
      local entry = self:getEntryForCite(options, content, false)
      if entry  then
         local bibstyle = require("packages.bibtex.styles." .. style)
         local cite = Bibliography.produceCitation(options, SILE.scratch.bibtex.bib, bibstyle)
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single citation.")

   self:registerCommand("reference", function (options, content)
      local style = SILE.settings:get("bibtex.style")
      if style == "csl" then
         SILE.call("csl:reference", options, content)
         return -- done via CSL
      end
      if not self._deprecated_legacy_warning then
         self._deprecated_legacy_warning = true
         SU.warn("Legacy bibtex.style is deprecated, consider enabling the CSL implementation.")
      end
      local entry = self:getEntryForCite(options, content, true)
      if entry then
         local bibstyle = require("packages.bibtex.styles." .. style)
         local cite, err = Bibliography.produceReference(options, SILE.scratch.bibtex.bib, bibstyle)
         if cite == Bibliography.Errors.UNKNOWN_TYPE then
            SU.warn("Unknown type @" .. err .. " in citation for reference " .. options.key)
            return
         end
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single bibliographic reference.")

   -- CSL IMPLEMENTATION COMMANDS

   -- Hooks for CSL processing

   self:registerCommand("bibSmallCaps", function (_, content)
      -- To avoid attributes in the CSL-processed content
      SILE.call("font", { features = "+smcp" }, content)
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
   self:registerCommand("bibLink", function (options, content)
      SILE.call("href", { src = options.src }, {
         SU.ast.createCommand("url", {}, { content[1] }),
      })
   end)
   self:registerCommand("bibURL", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         -- Play safe
         link = "https://" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self:registerCommand("bibDOI", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://doi.org/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self:registerCommand("bibPMID", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://www.ncbi.nlm.nih.gov/pubmed/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self:registerCommand("bibPMCID", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://www.ncbi.nlm.nih.gov/pmc/articles/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)

   self:registerCommand("bibRule", function (_, content)
      local n = content[1] and tonumber(content[1]) or 3
      local width = n .. "em"
      SILE.call("raise", { height = "0.4ex" }, function ()
         SILE.call("hrule", { height = "0.4pt", width = width })
      end)
   end)

   -- Style and locale loading

   self:registerCommand("bibliographystyle", function (options, _)
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
      SILE.scratch.bibtex.engine = CslEngine(style, locale, {
         localizedPunctuation = SU.boolean(options.localizedPunctuation, false),
         italicExtension = SU.boolean(options.italicExtension, true),
         mathExtension = SU.boolean(options.mathExtension, true),
      })
   end)

   self:registerCommand("csl:cite", function (options, content)
      local entry, citnum = self:getEntryForCite(options, content, false)
      if entry then
         local engine = self:getCslEngine()
         local locator = self:getLocator(options)

         local cslentry = bib2csl(entry, citnum)
         cslentry.locator = locator
         local cite = engine:cite(cslentry)

         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single citation.")

   self:registerCommand("cites", function (_, content)
      if type(content) ~= "table" then
         SU.error("Table content expected in \\cites")
      end
      local cites = {}
      for i = 1, #content do
         if type(content[i]) == "table" then
            local c = content[i]
            if c.command ~= "cite" then
               SU.error("Only \\cite commands are allowed in \\cites")
            end
            local o = c.options
            local entry, citnum = self:getEntryForCite(o, c, false)
            if entry then
               local locator = self:getLocator(o)
               local csljson = bib2csl(entry, citnum)
               csljson.locator = locator
               cites[#cites + 1] = csljson
            end
         end
      end
      if #cites > 0 then
         local engine = self:getCslEngine()
         local cite = engine:cite(cites)
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a group of citations.")

   self:registerCommand("csl:reference", function (options, content)
      local entry, citnum = self:getEntryForCite(options, content, true)
      if entry then
         local engine = self:getCslEngine()

         local cslentry = bib2csl(entry, citnum)
         local cite = engine:reference(cslentry)

         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single bibliographic reference.")

   self:registerCommand("printbibliography", function (options, _)
      local bib
      if SU.boolean(options.cited, true) then
         bib = {}
         for _, key in ipairs(SILE.scratch.bibtex.cited.keys) do
            bib[key] = SILE.scratch.bibtex.bib[key]
         end
      else
         bib = SILE.scratch.bibtex.bib
      end

      local entries = {}
      local ncites = #SILE.scratch.bibtex.cited.keys
      for key, entry in pairs(bib) do
         if entry.type ~= "xdata" then
            crossrefAndXDataResolve(bib, entry)
            if entry then
               local citnum = SILE.scratch.bibtex.cited.citnums[key]
               if not citnum then
                  -- This is just to make happy CSL styles that require a citation number
                  -- However, table order is not guaranteed in Lua so the output may be
                  -- inconsistent across runs with styles that use this number for sorting.
                  -- This may only happen for non-cited entries in the bibliography, and it
                  -- would be a bad practive to use such a style to print the full bibliography,
                  -- so I don't see a strong need to fix this at the expense of performance.
                  -- (and we can't really, some styles might have several sorting criteria
                  -- leading to impredictable order anyway).
                  ncites = ncites + 1
                  citnum = ncites
               end
               local cslentry = bib2csl(entry, citnum)
               table.insert(entries, cslentry)
            end
         end
      end

      print("<bibliography: " .. #entries .. " entries>")
      local engine = self:getCslEngine()
      local cite = engine:reference(entries)
      SILE.processString(("<sile>%s</sile>"):format(cite), "xml")

      SILE.scratch.bibtex.cited = { keys = {}, citnums = {} }
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
\em{Producing citations and references (legacy commands)}
\novbreak

\indent
The “legacy” implementation is based on a custom rendering system.
The plan is to eventually deprecate it in favor of the CSL implementation.

To produce an inline citation, call \autodoc:command{\cite{<key>}}, which will typeset something like “Jones 1982”.
If you want to cite a particular page number, use \autodoc:command{\cite[page=22]{<key>}}.

To produce a bibliographic reference, use \autodoc:command{\reference{<key>}}.

The \autodoc:setting[check=false]{bibtex.style} setting controls the style of the bibliography.
It currently defaults to \code{chicago}, the only style supported out of the box.
It can however be set to \code{csl} to enforce the use of the CSL implementation on the above commands.

This implementation doesn’t currently produce full bibliography listings.
(Actually, you can use the \autodoc:command{\printbibliography} introduced below, but then it always uses the CSL implementation for rendering the bibliography, differing from the output of the \autodoc:command{\reference} command.)

\smallskip
\noindent
\em{Producing citations and references (CSL implementation)}
\novbreak

\indent
While an experimental work-in-progress, the CSL (Citation Style Language) implementation is more powerful and flexible than the legacy commands.

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

To produce an inline citation, call \autodoc:command{\csl:cite{<key>}}, which will typeset something like “(Jones 1982)”.
If you want to cite a particular page number, use \autodoc:command{\csl:cite[page=22]{<key>}}. Other “locator”  options are available (article, chapter, column, line, note, paragraph, section, volume, etc.) – see the CSL documentation for details.
Some frequent abbreviations are also supported (art, chap, col, fig…)

To mark an entry as cited without actually producing a citation, use \autodoc:command{\nocite{<key>}}.
This is useful when you want to include an entry in the bibliography without citing it in the text.

To generate multiple citations grouped correctly, use \autodoc:command{\cites{\cite{<key1>}, \cite{<key2>}, …}}.
This wrapper command only accepts \autodoc:command{\cite} elements following their standard syntax.
Any other element triggers an error, and any text content is silently ignored.

To produce a bibliography of cited references, use \autodoc:command{\printbibliography}.
After printing the bibliography, the list of cited entries will be cleared. This allows you to start fresh for subsequent uses (e.g., in a different chapter).
If you want to include all entries in the bibliography, not just those that have been cited, set the option \autodoc:parameter{cited} to false.

To produce a bibliographic reference, use \autodoc:command{\csl:reference{<key>}}.
Note that this command is not intended for actual use, but for testing purposes.
It may be removed in the future.

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
