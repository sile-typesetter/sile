return Bibliography.Style {
  CitationStyle = Bibliography.CitationStyles.AuthorYear,

  Book = function()
    return andAuthors, " ", year, ". ", italic(title), ". ", 
      optional(transEditor, ". "), 
      address, ": ", publisher, "."
  end,

  Article = function()
    return andAuthors, ". ", year, ". ", quotes(title, "."), " ", italic(journal), " ", 
      parens(volume), number, optional(":", pages)
  end
}