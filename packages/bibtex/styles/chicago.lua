local Bibliography = require("packages.bibtex.bibliography")

local ChicagoStyles = pl.tablex.merge(Bibliography.Style, {
  CitationStyle = Bibliography.CitationStyles.AuthorYear,

  -- luacheck: push ignore
  ---@diagnostic disable: undefined-global, unused-local
  Article = function(_ENV)
    -- Chicago Citation Style 17th Edition
    --   https://guides.rdpolytech.ca/chicago/citation/article
    --   General format = Author Surname, First Name. "Article Title."
    --                   Journal Title Volume, no. Issue (Year): Page range of article.
    --                   DOI OR URL of journal article web page OR Name of database.
    --   Magazine = Author Surname, First Name. "Article Title." Magazine Title, Month Day, Year. URL.
    --   Newspaper = Author Surname, First Name. "Article Title." Newspaper Title, Month Day, Year.
    -- So we try to match the closest format.
    if number or volume then
      -- General format
      return andAuthors, ". ", quotes(title, "."), " ", italic(journal),
            optional(" ", volume), optional(" no. ", number), optional(" ", parens(optional(month, " "), year)),
            optional(": ", pageRange), ".",
            optional(" ", doi, "."), optional(" ", url, ".")
    end
    -- Magazine or newspaper format
    return andAuthors, ". ", quotes(title, "."), " ", italic(journal),
           optional(", ", month), optional(", ", year ),
           optional(": ", pageRange), ".",
           optional(" ", doi, "."), optional(" ", url, ".")
  end,

  Book = function(_ENV)
    -- Chicago Citation Style 17th Edition
    --   https://guides.rdpolytech.ca/chicago/citation/book
    --   Simple: Author Surname, First Name or Initial. Book Title: Subtitle. Place of Publication: Publisher, Year.
    --   With chapter: Author Surname, First Name or Initial. "Chapter Title in Quotation Marks." In Book Title: Subtitle,
    --      edited by Editor First Name Surname, page range of chapter. Place of Publication: Publisher, Year.
    --   Dictionary etc.: Author Surname, First Name. "Title of Entry." In Title of Reference Book,
    --       edited by Editor First Name Surname. Publisher, Year. URL.
    -- Likewise, we try to match the colsets format...
    local pub = publisher or institution or organization or howpublished
    if booktitle then
      return optional(andAuthors, ", "), quotes(title, "."),  " ",
        optional("In ", italic(booktitle), ". "),
        optional(transEditor, ". "),
        optional(address, ": "), optional(pub, year and ", " or ". "), optional(year, ". "),
        optional(number, ". "), optional(doi, ". "), optional(url, ".")
    end
    return optional(andAuthors, ", "), italic(title), ". ",
      optional(transEditor, ". "),
      optional(address, ": "), optional(pub, year and ", " or ". "), optional(year, ". "),
      optional(number, ". "), optional(doi, ". "), optional(url, ". ")
  end,

  Thesis = function(_ENV)
    local pub = publisher or institution or organization or howpublished or school
    return optional(andSurnames(3), ", "), quotes(title, "."), " ",
      optional(transEditor, ". "),
      optional(bibtype, ". "), -- "type" from BibTeX entry
      optional(address, ": "), optional(pub, ", "), optional(year, ".")
  end,
}, true)
-- luacheck: pop
---@diagnostic enable: undefined-global, unused-local

return pl.tablex.merge(ChicagoStyles, {
  -- Add fallback mappings for usual BibTeX keys not defined above.
  Booklet = ChicagoStyles.Book,
  Conference = ChicagoStyles.Book,
  Inbook = ChicagoStyles.Book,
  Incollection = ChicagoStyles.Book,
  Inproceedings = ChicagoStyles.Book,
  Manual = ChicagoStyles.Book,
  Misc = ChicagoStyles.Book, -- NOTE: So we assume at least a title...
  Proceedings = ChicagoStyles.Book,
  Techreport = ChicagoStyles.Book,
  Phdthesis = ChicagoStyles.Thesis,
  Mastersthesis = ChicagoStyles.Thesis,
  Unpublished = ChicagoStyles.Book,
}, true)
