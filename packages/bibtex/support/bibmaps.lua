-- Mappings for aliases and inheritance rules

-- Partial implementation of the Biber/BibLaTeX data inheritance rules
-- (derived from the biblatex package manual v3.20, appendix A)
-- FIXME: This is not complete
local crossrefmap = {
   book = {
      inbook = {
         author = "author", -- inbook inherits author from book author
         bookauthor = "author", -- inbook inherits bookauthor from book author
         indexsorttitle = false, -- inbook skips (=does not inherit) indexsorttitle from book
         indextitle = false,
         shorttitle = false,
         sorttitle = false,
         subtitle = "booksubtitle",
         title = "booktitle",
         titleaddon = "booktitleaddon",
      },
   },
   periodical = {
      article = {
         indexsorttitle = false,
         indextitle = false,
         shorttitle = false,
         sorttitle = false,
         subtitle = "journalsubtitle",
         title = "journaltitle",
         titleaddon = "journaltitleaddon",
      },
   },
   proceedings = {
      inproceedings = {
         indexsorttitle = false,
         indextitle = false,
         shorttitle = false,
         sorttitle = false,
         subtitle = "booksubtitle",
         title = "booktitle",
         titleaddon = "booktitleaddon",
      },
   },
}

-- biblatex field aliases
-- From biblatex package manual v3.20, section 2.2.5
local fieldmap = {
   address = "location",
   -- typos: ignore start
   annote = "annotation",
   -- typos: ignore end
   archiveprefix = "eprinttype",
   key = "sortkey",
   pdf = "file",
   journal = "journaltitle",
   primaryclass = "eprintclass",
   school = "institution",
}

return {
   crossrefmap = crossrefmap,
   fieldmap = fieldmap,
}
