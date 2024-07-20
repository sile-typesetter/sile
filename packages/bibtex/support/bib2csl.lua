--- Convert BibTeX entries to CSL
--
-- Experimental/naive implementation
-- Similar to what some citeproc implementations do (e.g. citeproc-java)
-- But some other libraries (e.g. biblatex-csl-converter) do more complex
-- mappings with a rule-based approach.

-- Mappings from BibTeX types to CSL types
-- Notes:
--  (1) Checked against citeproc-java

local BIBTEX2CSL_TYPES = {
   -- BibLaTeX manual v3.20, §2.1.1
   -- Mappings to CSL are somewhat ad-hoc interpretations
   article = "article-journal", -- (1)
   book = "book", -- (1)
   mvbook = "book",
   inbook = "chapter", -- (1)
   -- bookinbook ?
   -- suppbook ?
   booklet = "pamphlet", -- (1)
   -- collection ?
   -- mvcollection ?
   incollection = "chapter", -- (1)
   -- suppcollection ?
   dataset = "dataset",
   manual = "book", -- (1)
   misc = "document",
   online = "webpage", -- (1)
   patent = "patent", -- (1)
   periodical = "article-journal", -- Not sure, (1) has book
   -- suppperiodical ?
   proceedings = "book", -- (1)
   inproceedings = "paper-conference", -- (1)
   reference = "entry-dictionary",
   mvreference = "entry-dictionary",
   report = "report", -- (1) via aliases
   -- set [special case]
   software = "software",
   thesis = "thesis", -- (1) via aliases
   unpublished = "manuscript", -- (1)

   -- BibLaTeX manual v3.20, §2.1.2 (aliases)
   conference = "event", -- not sure, should be equivalent to @inproceedings
   electronic = "webpage", -- as @online
   mastersthesis = "thesis", -- as @thesis
   phdthesis = "thesis", -- as @thesis
   techreport = "report", -- as @report
   www = "webpage", -- as @online

   -- BibLaTeX manual v3.20, §2.1.3 (non-standard)
   -- artwork ?
   -- audio ?
   -- bibnote [special case]
   -- commentary ?
   -- image ?
   -- jurisdiction ?
   legislation = "legislation",
   -- legal ?
   -- letter ?
   -- movie ?
   -- music ?
   -- performance ?
   -- review ?
   standard = "legislation", -- (1)
   -- video ?
}

local function toDate (year, month)
   if not month and not year then
      return nil
   end
   return {
      year = year,
      month = month,
   }
end

--- Convert a BibTeX entry to a CSL item.
-- @tparam table entry The BibTeX entry
-- @treturn table The CSL item
local function bib2csl (entry)
   local csl = {}
   local bibtex = entry.attributes
   local bibtype = entry.type:lower()

   -- BibTeX type
   local t = BIBTEX2CSL_TYPES[bibtype] or "document"
   csl.type = t

   -- BibTeX address / BibLaTeX location
   if bibtex.location then
      csl["event-place"] = bibtex.location
      csl["publisher-place"] = bibtex.location
   else
      csl["event-place"] = bibtex.address
      csl["publisher-place"] = bibtex.address
   end

   -- BibTeX author
   csl.author = bibtex.author

   -- BibTeX translator
   csl.translator = bibtex.translator

   -- BibTex editor
   csl.editor = bibtex.editor
   csl["collection-editor"] = bibtex.editor

   -- BibLaTeX date / BibTeX year and month
   local date = bibtex.date and bibtex.date or toDate(bibtex.year, bibtex.month)
   csl.issued = date

   -- BibLaTeX eventdate [< BibTeX date]
   csl["event-date"] = bibtex.eventdate or date

   -- BibLaTeX urldate
   csl.accessed = bibtex.urldate

   -- BibLaTeX origdate
   csl["original-date"] = bibtex.origdate

   -- BibTeX volume
   csl.volume = bibtex.volume
   -- BibLaTeX volumes
   csl["number-of-volumes"] = bibtex.volumes

   -- BibTeX edition -- FIXME Can be a literal string or a number
   csl.edition = bibtex.edition
   -- BibTeX version
   csl.version = bibtex.revision

   -- BibTeX number and issue
   -- Tricky, see https://github.com/JabRef/jabref/issues/8372#issuecomment-1023768144
   -- Still not sure this is completely correct below.
   if bibtex.series then
      -- Series use number
      -- BibLaTeX says number is for the series number on books, etc.
      -- It says something about articles in a series, not implemented here...
      csl["collection-title"] = bibtex.series
      csl["collection-number"] = bibtex.number
      csl.issue = bibtex.issue
   elseif bibtex.number and bibtex.issue then
      -- Both present, take both and hope the CSL style knows what to do
      csl.number = bibtex.number
      csl.issue = bibtex.issue
   elseif bibtex.number then
      csl.issue = bibtex.number
   elseif bibtex.issue then
      csl.issue = bibtex.issue
   end
   -- BibLaTeX pagetotal
   csl["number-of-pages"] = bibtex.pagetotal

   -- Some standard variables with more or less direct mappings
   csl.abstract = bibtex.abstract
   csl.annote = bibtex.annote
   csl.keyword = bibtex.keywords
   -- csl.language = entry.language -- FIXME language/langid weirdness
   csl.note = bibtex.note
   csl.status = bibtex.status
   csl.ISSN = bibtex.issn
   csl.ISBN = bibtex.isbn
   csl.DOI = bibtex.doi
   csl.URL = bibtex.url

   -- Pages
   csl.page = bibtex.pages

   -- journaltitle / booktitle
   if bibtex.journaltitle then
      csl["container-title"] = bibtex.journaltitle
   elseif bibtex.booktitle then
      csl["container-title"] = bibtex.booktitle
   end

   -- publisher / institution / school / organization
   if bibtex.publisher then
      csl.publisher = bibtex.publisher
   elseif bibtex.institution then
      csl.publisher = bibtex.institution
   else
      csl.publisher = bibtex.organization
   end

   -- title / chapter
   if bibtex.title then
      csl.title = bibtex.title
   else
      csl.title = bibtex.chapter
   end
   -- BibLaTeX origtitle
   if bibtex.origtitle then
      csl["original-title"] = bibtex.origtitle
   end
   return csl
end

return bib2csl
