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
   article = 'article-journal', -- (1)
   book = 'book', -- (1)
   mvbook = 'book',
   inbook = 'chapter', -- (1)
   -- bookinbook ?
   -- suppbook ?
   booklet = 'pamphlet', -- (1)
   -- collection ?
   -- mvcollection ?
   incollection = 'chapter', -- (1)
   -- suppcollection ?
   dataset = 'dataset',
   manual = 'book', -- (1)
   misc = 'document',
   online = 'webpage', -- (1)
   patent = 'patent', -- (1)
   periodical = 'article-journal', -- Not sure, (1) has book
   -- suppperiodical ?
   proceedings = 'book', -- (1)
   inproceedings = 'paper-conference', -- (1)
   reference = 'entry-dictionary',
   mvreference = 'entry-dictionary',
   report = 'report', -- (1) via aliases
   -- set [special case]
   software = 'software',
   thesis = 'thesis', -- (1) via aliases
   unpublished = 'manuscript', -- (1)

   -- BibLaTeX manual v3.20, §2.1.2 (aliases)
   conference = 'event', -- not sure, should be equivalent to @inproceedings
   electronic = 'webpage', -- as @online
   mastersthesis = 'thesis', -- as @thesis
   phdthesis = 'thesis', -- as @thesis
   techreport = 'report', -- as @report
   www = 'webpage', -- as @online

   -- BibLaTeX manual v3.20, §2.1.3 (non-standard)
   -- artwork ?
   -- audio ?
   -- bibnote [special case]
   -- commentary ?
   -- image ?
   -- jurisdiction ?
   legislation = 'legislation',
   -- legal ?
   -- letter ?
   -- movie ?
   -- music ?
   -- performance ?
   -- review ?
   standard = 'legislation', -- (1)
   -- video ?
}

local function toDate (year, month)
   local date = {year = year, month = month}
   return date
end

--- Convert a BibTeX entry to a CSL item.
-- @tparam table entry The BibTeX entry
-- @treturn table The CSL item
local function bib2csl (entry)
   local csl = {}

   -- BibTeX type
   local t = BIBTEX2CSL_TYPES[entry.type] or 'document'

   csl.type = t

   -- BibTeX address / BibLaTeX location
   if entry.location then
      csl['event-place'] = entry.location
      csl['publisher-place'] = entry.location
   else
      csl['event-place'] = entry.address
      csl['publisher-place'] = entry.address
   end

   -- BibTeX author
   csl.author = entry.author

   -- BibTex editor
   csl.editor = entry.editor
   csl['collection-editor'] = entry.editor

   -- BibLaTeX date / BibTeX year and month
   local date = entry.date and entry.date or toDate(entry.year, entry.month)
   csl.issued = date

   -- BibLaTeX eventdate [BibTeX date]
   csl['event-date'] = entry.eventdate and toDate(entry.eventdate) or date

   -- BibLaTeX urldate
   csl.accessed = entry.urldate

   -- BibLaTeX origdate
   csl['original-date'] = entry.origdate

   -- BibTeX volume
   csl.volume = entry.volume
   -- BibLaTeX volumes
   csl['number-of-volumes'] = entry.volumes

   -- BibTeX edition -- FIXME Can be a literal string or a number
   csl.edition = entry.edition
   -- BibTeX version
   csl.version = entry.revision

   -- BibTeX number and issue
   csl.number = entry.number
   csl.issue = entry.issue
   -- BibLaTeX pagetotal
   csl['number-of-pages'] = entry.pagetotal


   -- Some standard variables with more or less direct mappings
   csl.abstract = entry.abstract
   csl.annote = entry.annote
   csl.keyword = entry.keywords
   -- csl.language = entry.language -- FIXME language/langid weirdness
   csl.note = entry.note
   csl.status = entry.status
   csl.ISSN = entry.issn
   csl.ISBN = entry.isbn
   csl.DOI = entry.doi
   csl.URL = entry.url

   -- Pages
   csl.page = entry.page

   -- journaltitle / booktitle / series
   if entry.journaltitle then
      csl['container-title'] = entry.journaltitle
   elseif entry.booktitle then
      csl['container-title'] = entry.booktitle
   end
   if entry.series then
      csl['collection-title'] = entry.series
   end

   -- publisher / institution / school / organization
   if entry.publisher then
      csl.publisher = entry.publisher
   elseif entry.institution then
      csl.publisher = entry.institution
   else
      csl.publisher = entry.organization
   end

   -- title / chapter
   if entry.title then
      csl.title = entry.title
   else
      csl.title = entry.chapter
   end
   -- BibLaTeX origtitle
   if entry.origtitle then
      csl['original-title'] = entry.origtitle
   end
   return csl
end

return bib2csl
