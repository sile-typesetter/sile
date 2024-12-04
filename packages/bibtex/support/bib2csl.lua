--- Convert BibTeX entries to CSL
--
-- Experimental/naive implementation
-- Similar to what some citeproc implementations do (e.g. citeproc-java)
-- But some other libraries (e.g. biblatex-csl-converter) do more complex
-- mappings with a rule-based approach.

-- Mappings from BibTeX types to CSL types
-- Notes:
--  (1) Checked against citeproc-java (source code)
--  (2) Checked against citeproc-lua (scripts/bib-csl-mapping.md)

local BIBTEX2CSL_TYPES = {
   -- BibLaTeX manual v3.20, §2.1.1
   -- Mappings to CSL are somewhat ad-hoc interpretations
   article = "article-journal", -- (1) (2), but "article-magazine" or "article-newspaper" are also possible
   book = "book", -- (1) (2)
   mvbook = "book", -- (2)
   inbook = "chapter", -- (1) (2)
   bookinbook = "chapter", -- (2)
   suppbook = "chapter", -- (2) but noted as "lossy mapping"
   booklet = "pamphlet", -- (1) (2)
   collection = "book", -- (2)
   mvcollection = "book", -- (2)
   incollection = "chapter", -- (1)
   suppcollection = "chapter", -- (2) but noted as "lossy mapping"
   dataset = "dataset", -- (2)
   manual = "book", -- (1) has "book" but (2) has "report"
   misc = "document", -- (2)
   online = "webpage", -- (1) (2)
   patent = "patent", -- (1) (2)
   periodical = "periodical", -- (1) has "book", (2) has "periodical" ("new in CSL 1.0.2")
   -- suppperiodical ? (2) maps to article (not CSL?) but "see article"
   proceedings = "book", -- (1) (2)
   inproceedings = "paper-conference", -- (1)
   reference = "book", -- (2)
   inreference = "entry", -- Unclear, but (2) noting "entry, entry-dictionary or entry-encyclopedia"...
   mvreference = "book", -- (2)
   report = "report", -- (1) (2)
   -- set [special case]
   software = "software", -- (2)
   thesis = "thesis", -- (1) (2)
   unpublished = "manuscript", -- (1) (2)

   -- BibLaTeX manual v3.20, §2.1.2 (aliases)
   conference = "event", -- not sure, should be equivalent to @inproceedings? And (2) has "paper-conference" indeed...
   electronic = "webpage", -- as @online, (2) agrees
   mastersthesis = "thesis", -- as @thesis, (2) agrees
   phdthesis = "thesis", -- as @thesis, (2) agrees
   techreport = "report", -- as @report, (2) agrees
   www = "webpage", -- as @online, (2) agrees

   -- BibLaTeX manual v3.20, §2.1.3 (non-standard)
   artwork = "graphic", -- (2)
   audio = "song", -- (2)
   -- bibnote [special case]
   -- commentary ? -- "book" in (2) but marked as not supported?
   image = "graphic", -- (2)
   jurisdiction = "legal_case", -- (2)
   legislation = "legislation", -- (2)
   legal = "treaty", -- (2)
   letter = "personal_communication", -- (2)
   movie = "motion_picture", -- (2)
   music = "song", -- (2)
   performance = "performance", -- (2)
   review = "review", -- (2) "A more specific variant of the @@article type"
   standard = "legislation", -- (1) But (2) has "standard" ("new in CSL 1.0.2")
   video = "motion_picture", -- (2)
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
-- @tparam number citnum The citation number (computed, not from BibTeX but from actual citation order)
-- @treturn table The CSL item
local function bib2csl (entry, citnum)
   local csl = {}
   local bibtex = entry.attributes
   local bibtype = entry.type:lower()

   -- BibTeX type
   local t = BIBTEX2CSL_TYPES[bibtype]
   if not t then
      SU.warn(("No CSL type mapping for BibTeX type '%s', using 'document'"):format(bibtype))
      t = "document"
   end
   csl.type = t

   -- Citation key may be wanted by some styles
   csl["citation-key"] = entry.label
   -- Citation number is used by some styles such as ACS
   csl["citation-number"] = citnum

   -- BibLaTeX label / shorthand
   -- The label "provides a substitute for any missing data"
   -- it relates to shorthand, which overrides the label.
   -- Some CSL styles such as USITC use citation-label in priority over author, etc.
   csl["citation-label"] = bibtex.shorthand or bibtex.label

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
   -- N.B. BibLaTeX does not have a "collection-editor".
   -- Using some editora and editoratype hint is sometimes mentioned on forums
   -- but it's ad hoc and not part of any 'standard' recommendation.
   -- Biber would allow to define extra fields (e.g. serieseditor) but the issue
   -- is the same: lack of standardization.
   -- csl["collection-editor"] = bibtex.editoratype == "serieseditor" and bibtex.editora

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
   -- BibLaTex issuetitle (title of a specific issue of a journal or other periodical)
   csl["volume-title"] = bibtex.issuetitle
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
