local function init (class, _)

  class:loadPackage("infonode")

  if not SILE.scratch.chapterverse then
    SILE.scratch.chapterverse = {}
  end

end

local function registerCommands (_)

  SILE.registerCommand("save-book-title", function (_, content)
    SU.debug("chapterverse", "book: " .. content[1])
    SILE.scratch.chapterverse.book = content[1]
  end)

  SILE.registerCommand("save-chapter-number", function (_, content)
    SU.debug("chapterverse", "chapter: " .. content[1])
    SILE.scratch.chapterverse.chapter = content[1]
  end)

  SILE.registerCommand("save-verse-number", function (_, content)
    SU.debug("chapterverse", "verse: " .. content[1])
    SILE.scratch.chapterverse.verse = content[1]
    local ref = {
      book = SILE.scratch.chapterverse.book,
      chapter = SILE.scratch.chapterverse.chapter,
      verse = SILE.scratch.chapterverse.verse
    }
    SU.debug("chapterverse", "ref: " .. tostring(ref))
    SILE.call("info", { category = "references", value = ref }, {})
  end)

  SILE.registerCommand("first-reference", function (_, _)
    local refs = SILE.scratch.info.thispage.references
    SU.debug("chapterverse", "first-reference: " .. tostring(SILE.scratch.info))
    if refs then
      SU.debug("chapterverse", "first-reference: " .. tostring(refs[1]))
      SILE.call("format-reference", {}, refs[1])
    else
      SU.debug("chapterverse", "first-reference: none")
    end
  end)

  SILE.registerCommand("last-reference", function (options, _)
    local refs = SILE.scratch.info.thispage.references
    if refs then
      SU.debug("chapterverse", "last-reference: " .. tostring(refs[#(refs)]))
      SILE.call("format-reference", options, refs[#(refs)])
    else
      SU.debug("chapterverse", "last-reference: none")
    end
  end)

  SILE.registerCommand("format-reference", function (options, content)
    if type(options.showbook) == "nil" then options.showbook = true end
    SU.debug("chapterverse", "formatting: " .. tostring(content))
    local ref
    if content.book and options.showbook then
      ref = tostring(content.book) .. " " .. tostring(content.chapter) .. ":" .. tostring(content.verse)
    else
      ref = tostring(content.chapter) .. ":" .. tostring(content.verse)
    end
    SU.debug("chapterverse", "formatting: " .. tostring(ref))
    SILE.typesetter:typeset(ref)
  end)

end

return {
  init = init,
  registerCommands = registerCommands,
  documentation = [[
\begin{document}
The \autodoc:package{chapterverse} package is designed as a helper package for
book classes which deal with versified content such as scriptures. It
provides commands which will generally be called by the higher-level
\code{\\verse} and \code{\\chapter} (or moral equivalent) commands of the
classes which handle this kind of content:

\begin{itemize}
\item{\autodoc:command{\save-book-title} takes its argument and squirrels
      it away as the current book name.}
\item{\autodoc:command{\save-chapter-number} and \autodoc:command{\save-verse-number}
      does the same but for the chapter and verse reference respectively.}
\item{\autodoc:command{\format-reference} is expected to be called from
      Lua code with a content table of \code{\{book = ..., chapter = ..., verse = ...\}}
      and typesets the reference in the form \code{cc:vv}.
      If the parameter \autodoc:parameter{showbook=true} is given then the book name
      is also output. (You can override this command to output your references
      in a different format.)}
\item{\autodoc:command{\first-reference} and \autodoc:command{\last-reference}
      typeset (using \autodoc:command{\format-reference}) the first reference
      on the page and the last reference on the page respectively. This is helpful
      for running headers.}
\end{itemize}
\end{document}
]]
}
