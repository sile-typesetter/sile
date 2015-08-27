return Bibliography.Style {
  CitationStyle = Bibliography.CitationStyles.AuthorYear,

  Book = function(_ENV)
    return andAuthors, " ", year, ". ", italic(title), ". ",
      optional(transEditor, ". "),
      address, ": ", publisher, "."
  end,

  Article = function(_ENV)
    return andAuthors, ". ", year, ". ", quotes(title, "."), " ", italic(journal), " ",
      parens(volume), number, optional(":", pages)
  end
}