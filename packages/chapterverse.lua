SILE.require("packages/infonode")
SILE.scratch.chapterverse = {}

SILE.registerCommand("save-book-title", function (options, content)
  SU.debug("bcv", "book: " .. content[1])
  SILE.scratch.chapterverse.book = content[1]
end)

SILE.registerCommand("save-chapter-number", function (options, content)
  SU.debug("bcv", "chapter: " .. content[1])
  SILE.scratch.chapterverse.chapter = content[1]
end)

SILE.registerCommand("save-verse-number", function (options, content)
  SU.debug("bcv", "verse: " .. content[1])
  SILE.scratch.chapterverse.verse = content[1]
  local ref = {
    book = SILE.scratch.chapterverse.book,
    chapter = SILE.scratch.chapterverse.chapter,
    verse = SILE.scratch.chapterverse.verse
  }
  SU.debug("bcv", "ref: " .. ref)
  SILE.Commands["info"]({ category = "references", value = ref }, {})
end)

SILE.registerCommand("first-reference", function (options, content)
  local refs = SILE.scratch.info.thispage.references
  SU.debug("bcv", "first-reference: " .. SILE.scratch.info)
  if refs then
    SU.debug("bcv", "first-reference: " .. refs[1])
    SILE.call("format-reference", {}, refs[1])
  else
    SU.debug("bcv", "first-reference: none")
  end
end)

SILE.registerCommand("last-reference", function (options, content)
  local refs = SILE.scratch.info.thispage.references
  if refs then
    SU.debug("bcv", "last-reference: " .. refs[#(refs)])
    SILE.call("format-reference", options, refs[#(refs)])
  else
    SU.debug("bcv", "last-reference: none")
  end
end)

SILE.registerCommand("format-reference", function (options, content)
  if type(options.showbook) == "nil" then options.showbook = true end
  SU.debug("bcv", "formatting: " .. content)
  local ref
  if content.book and options.showbook then
    ref = content.book .. " " .. content.chapter .. ":" .. content.verse
  else
    ref = content.chapter .. ":" .. content.verse
  end
  SU.debug("bcv", "formatting: " .. ref)
  SILE.typesetter:typeset(ref)
end)
