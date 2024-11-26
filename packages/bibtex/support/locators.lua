--- Mappings for known CSL 1.0.2 locator types
--
-- For use as option in citation commands, e.g. `\cite[key=doe2022, page=5]`.
-- Note that some CSL locators have '-locator' in their name, to use the
-- corresponding term in the CSL locale file.
--
return {
   act = "act",
   appendix = "appendix",
   app = "appendix", -- Convenience alias
   article = "article-locator", -- See note
   art = "article-locator", -- Convenience alias
   book = "book",
   canon = "canon",
   chapter = "chapter",
   ch = "chapter", -- Convenience alias
   chap = "chapter", -- Convenience alias
   column = "column",
   col = "column", -- Convenience alias
   elocation = "elocation",
   equation = "equation",
   figure = "figure",
   fig = "figure", -- Convenience alias
   folio = "folio",
   fol = "folio", -- Convenience alias
   issue = "issue",
   line = "line",
   note = "note",
   opus = "opus",
   page = "page",
   paragraph = "paragraph",
   part = "part",
   rule = "rule",
   scene = "scene",
   section = "section",
   ["sub-verbo"] = "sub-verbo",
   svv = "sub-verbo", -- Convenience alias
   supplement = "supplement",
   table = "table",
   timestamp = "timestamp",
   title = "title-locator", -- See note
   verse = "verse",
   version = "version",
   volume = "volume",
   vol = "volume", -- Convenience alias
}
