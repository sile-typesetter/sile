local base = require("packages.base")

local package = pl.class(base)
package._name = "bibtex"

local epnf = require("epnf")

local Bibliography

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
   local myID = C(identifier + P(1)) / function (t) return strings[t] or t end
   local myTag = C(identifier + P(1)) / function (t) return t:lower() end
   local pieces = balanced + quoted + myID
   local value = Ct(pieces * (WS * P("#") * WS * pieces)^0) / function (t) return table.concat(t) end
   local pair = Cg(myTag * _ * "=" * _ * C(value)) * _ * sep^-1   / function (...) local t= {...}; return t[1], t[#t] end
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

local bibcompat = require("packages.bibtex.bibmaps")
local crossrefmap, fieldmap = bibcompat.crossrefmap, bibcompat.fieldmap

local function consolidateEntry (entry, label)
   local consolidated = {}
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
\end{document}
]]

return package
