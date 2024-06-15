local base = require("packages.base")

local package = pl.class(base)
package._name = "bibtex"

local epnf = require("epnf")
local nbibtex = require("packages.bibtex.support.nbibtex")
local namesplit, parse_name = nbibtex.namesplit, nbibtex.parse_name
local isodatetime = require("packages.bibtex.support.isodatetime")

local Bibliography

local nbsp = luautf8.char(0x00A0)
local function sanitize (str)
   local s = str
      -- TeX special characters:
      -- Backslash-escaped tilde is a tilde,
      -- but standalone tilde is a non-breaking space
      :gsub(
         "(.?)~",
         function (prev)
            if prev == "\\" then
               return "~"
            end
            return prev .. nbsp
         end
      )
      -- Other backslash-escaped characters are skipped
      -- TODO FIXME:
      -- This ok for \", \& etc. which we want to unescape,
      -- BUT what should we do with other TeX-like commands?
      :gsub(
         "\\",
         ""
      )
      -- We will wrap the content in <sile> tags so we need to XML-escape
      -- the input.
      :gsub("&", "&amp;")
      :gsub("<", "&lt;")
      :gsub(">", "&gt;")
   return s
end

-- luacheck: push ignore
-- stylua: ignore start
---@diagnostic disable: undefined-global, unused-local, lowercase-global
local bibtexparser = epnf.define(function (_ENV)
   local strings = {} -- Local store for @string entries

   local identifier = (SILE.parserBits.identifier + S":-")^1
   local balanced = C{ "{" * P" "^0 * C(((1 - S"{}") + V(1))^0) * "}" } / function (...) local t={...}; return t[2] end
   local quoted = C( P'"' * C(((1 - S'"\r\n\f\\') + (P'\\' * 1)) ^ 0) * '"' ) / function (...) local t={...}; return t[2] end
   local _ = WS^0
   local sep = S",;" * _
   local myID = C(identifier)
   local myStrID = myID / function (t) return strings[t] or t end
   local myTag = C(identifier) / function (t) return t:lower() end
   local pieces = balanced + quoted + myStrID
   local value = Ct(pieces * (WS * P("#") * WS * pieces)^0)
      / function (t) return table.concat(t) end / sanitize
   local pair = myTag * _ * "=" * _ * value * _ * sep^-1
      / function (...) local t= {...}; return t[1], t[#t] end
   local list = Cf(Ct("") * pair^0, rawset)
   local skippedType = Cmt(R("az", "AZ")^1, function(_, _, tag)
      -- ignore both @comment and @preamble
      local t = tag:lower()
      return t == "comment" or t == "preamble"
   end)

   START "document"
   document = (V"skipped" -- order important: skipped (@comment, @preamble) must be first
      + V"stringblock" -- order important: @string must be before @entry
      + V"entry")^1
      * (-1 + E("Unexpected character at end of input"))
   skipped  = WS + (V"blockskipped" + (1 - P"@")^1 ) / ""
   blockskipped = (P("@") * skippedType) + balanced / ""
   stringblock = Ct( P("@string") * _ * P("{") * pair * _ * P("}") * _ )
       / function (t)
          strings[t[1]] = t[2]
          return t end
   entry = Ct( P("@") * Cg(myTag, "type") * _ * P("{") * _ * Cg(myID, "label") * _ * sep * list * P("}") * _ )
end)
-- luacheck: pop
-- stylua: ignore end
---@diagnostic enable: undefined-global, unused-local, lowercase-global

local bibcompat = require("packages.bibtex.support.bibmaps")
local crossrefmap, fieldmap = bibcompat.crossrefmap, bibcompat.fieldmap
local months =
   { jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12 }

local function consolidateEntry (entry, label)
   local consolidated = {}
   -- BibLaTeX aliases for legacy BibTeX fields
   for field, value in pairs(entry.attributes) do
      consolidated[field] = value
      local alias = fieldmap[field]
      if alias then
         if entry.attributes[alias] then
            SU.warn("Duplicate field '" .. field .. "' and alias '" .. alias .. "' in entry '" .. label .. "'")
         else
            consolidated[alias] = value
         end
      end
   end
   -- Names field split and parsed
   for _, field in ipairs({ "author", "editor", "translator", "shortauthor", "shorteditor", "holder" }) do
      if consolidated[field] then
         -- FIXME Check our corporate names behave, we are probably bad currently
         -- with nested braces !!!
         -- See biblatex manual v3.20 §2.3.3 Name Lists
         -- e.g. editor = {{National Aeronautics and Space Administration} and Doe, John}
         local names = namesplit(consolidated[field])
         for i = 1, #names do
            names[i] = parse_name(names[i])
         end
         consolidated[field] = names
      end
   end
   -- Month field in either number or string (3-letter code)
   if consolidated.month then
      local month = tonumber(consolidated.month) or months[consolidated.month:lower()]
      if month and (month >= 1 and month <= 12) then
         consolidated.month = month
      else
         SU.warn("Unrecognized month skipped in entry '" .. label .. "'")
         consolidated.month = nil
      end
   end
   -- Extended date fields
   for _, field in ipairs({ "date", "origdate", "eventdate", "urldate" }) do
      if consolidated[field] then
         local dt = isodatetime(consolidated[field])
         if dt then
            consolidated[field] = dt
         else
            SU.warn("Invalid '" .. field .. "' skipped in entry '" .. label .. "'")
            consolidated[field] = nil
         end
      end
   end
   entry.attributes = consolidated
   return entry
end

--- Parse a BibTeX file and populate a bibliography table.
-- @tparam string fn Filename
-- @tparam table biblio Table of entries
local function parseBibtex (fn, biblio)
   fn = SILE.resolveFile(fn) or SU.error("Unable to resolve Bibtex file " .. fn)
   local fh, e = io.open(fn)
   if e then
      SU.error("Error reading bibliography file: " .. e)
   end
   local doc = fh:read("*all")
   local t = epnf.parsestring(bibtexparser, doc)
   if not t or not t[1] or t.id ~= "document" then
      SU.error("Error parsing bibtex")
   end
   for i = 1, #t do
      if t[i].id == "entry" then
         local ent = t[i][1]
         local entry = { type = ent.type, attributes = ent[1] }
         if biblio[ent.label] then
            SU.warn("Duplicate entry key '" .. ent.label .. "', picking the last one")
         end
         biblio[ent.label] = consolidateEntry(entry, ent.label)
      end
   end
end

--- Copy fields from the parent entry to the child entry.
-- BibLaTeX/Biber have a complex inheritance system for fields.
-- This implementation is more naive, but should be sufficient for reasonable
-- use cases.
-- @tparam table parent Parent entry
-- @tparam table entry Child entry
local function fieldsInherit (parent, entry)
   local map = crossrefmap[parent.type] and crossrefmap[parent.type][entry.type]
   if not map then
      -- @xdata and any other unknown types: inherit all missing fields
      for field, value in pairs(parent.attributes) do
         if not entry.attributes[field] then
            entry.attributes[field] = value
         end
      end
      return -- done
   end
   for field, value in pairs(parent.attributes) do
      if map[field] == nil and not entry.attributes[field] then
         entry.attributes[field] = value
      end
      for childfield, parentfield in pairs(map) do
         if parentfield and not entry.attributes[parentfield] then
            entry.attributes[parentfield] = parent.attributes[childfield]
         end
      end
   end
end

--- Resolve the 'crossref' and 'xdata' fields on a bibliography entry.
-- (Supplementing the entry with the attributes of the parent entry.)
-- Once resolved recursively, the crossref and xdata fields are removed
-- from the entry.
-- So this is intended to be called at first use of the entry, and have no
-- effect on subsequent uses: BibTeX does seem to mandate cross refererences
-- to be defined before the entry that uses it, or even in the same bibliography
-- file.
-- Implementation note:
-- We are not here to check the consistency of the BibTeX file, so there is
-- no check that xdata refers only to @xdata entries
-- Removing the crossref field implies we won't track its use and implicitely
-- cite referenced entries in the bibliography over a certain threshold.
-- @tparam table bib Bibliography
-- @tparam table entry Bibliography entry
local function crossrefAndXDataResolve (bib, entry)
   local refs
   local xdata = entry.attributes.xdata
   if xdata then
      refs = xdata and pl.stringx.split(xdata, ",")
      entry.attributes.xdata = nil
   end
   local crossref = entry.attributes.crossref
   if crossref then
      refs = refs or {}
      table.insert(refs, crossref)
      entry.attributes.crossref = nil
   end

   if not refs then
      return
   end
   for _, ref in ipairs(refs) do
      local parent = bib[ref]
      if parent then
         crossrefAndXDataResolve(bib, parent)
         fieldsInherit(parent, entry)
      else
         SU.warn("Unknown crossref " .. ref .. " in bibliography entry " .. entry.label)
      end
   end
end

function package:_init ()
   base._init(self)
   SILE.scratch.bibtex = { bib = {} }
   Bibliography = require("packages.bibtex.bibliography")
end

function package.declareSettings (_)
   SILE.settings:declare({
      parameter = "bibtex.style",
      type = "string",
      default = "chicago",
      help = "BibTeX style",
   })
end

function package:registerCommands ()
   self:registerCommand("loadbibliography", function (options, _)
      local file = SU.required(options, "file", "loadbibliography")
      parseBibtex(file, SILE.scratch.bibtex.bib)
   end)

   self:registerCommand("bibstyle", function (_, _)
      SU.deprecated("\\bibstyle", "\\set[parameter=bibtex.style]", "0.13.2", "0.14.0")
   end)

   self:registerCommand("cite", function (options, content)
      if not options.key then
         options.key = SU.ast.contentToString(content)
      end
      local entry = SILE.scratch.bibtex.bib[options.key]
      if not entry then
         SU.warn("Unknown reference in citation " .. options.key)
         return
      end
      if entry.type == "xdata" then
         SU.warn("Skipped citation of @xdata entry " .. options.key)
         return
      end
      crossrefAndXDataResolve(SILE.scratch.bibtex.bib, entry)
      local style = SILE.settings:get("bibtex.style")
      local bibstyle = require("packages.bibtex.styles." .. style)
      local cite = Bibliography.produceCitation(options, SILE.scratch.bibtex.bib, bibstyle)
      SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
   end)

   self:registerCommand("reference", function (options, content)
      if not options.key then
         options.key = SU.ast.contentToString(content)
      end
      local entry = SILE.scratch.bibtex.bib[options.key]
      if not entry then
         SU.warn("Unknown reference in citation " .. options.key)
         return
      end
      if entry.type == "xdata" then
         SU.warn("Skipped citation of @xdata entry " .. options.key)
         return
      end
      crossrefAndXDataResolve(SILE.scratch.bibtex.bib, entry)
      local style = SILE.settings:get("bibtex.style")
      local bibstyle = require("packages.bibtex.styles." .. style)
      local cite, err = Bibliography.produceReference(options, SILE.scratch.bibtex.bib, bibstyle)
      if cite == Bibliography.Errors.UNKNOWN_TYPE then
         SU.warn("Unknown type @" .. err .. " in citation for reference " .. options.key)
         return
      end
      SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
   end)
end

package.documentation = [[
\begin{document}
BibTeX is a citation management system.
It was originally designed for TeX but has since been integrated into a variety of situations.

This experimental package allows SILE to read and process BibTeX \code{.bib} files and output citations and full text references.
(It doesn’t currently produce full bibliography listings.)

To load a BibTeX file, issue the command \autodoc:command{\loadbibliography[file=<whatever.bib>]}

To produce an inline citation, call \autodoc:command{\cite{<key>}}, which will typeset something like “Jones 1982”.
If you want to cite a particular page number, use \autodoc:command{\cite[page=22]{<key>}}.

To produce a full reference, use \autodoc:command{\reference{<key>}}.

Currently, the only supported bibliography style is Chicago referencing, but other styles should be easy to implement.
Adapt \code{packages/bibtex/styles/chicago.lua} as necessary.

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
The value is then considered to be a refererence to an abbreviation previously defined in a \code{@string} entry.
If no such abbreviation is found, the value is considered to be a string literal.
(This allows a decent fallback for fields where curly braces or double quotes could historically be omitted, such as numerical values, and one-word strings.)

String values are assumed to be in the UTF-8 encoding, and shall not contain (La)TeX commands.
Special character sequences from TeX (such as \code{`} assumed to be an opening quote) are not supported.
There are exceptions to this rule. Notably, the \code{~} character can be used to represent a non-breaking space (when not backslash-escaped), and the \code{\\&} sequence is accepted (though this implementation does not mandate escaping ampersands).

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
