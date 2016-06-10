SILE.require("packages/infonode")
SILE.scratch.chapterverse = {}

SILE.registerCommand("save-book-title", function (o,c)
  SU.debug("bcv", "book: "..c[1])
  SILE.scratch.chapterverse.book = c[1]
end)

SILE.registerCommand("save-chapter-number", function (o,c)
  SU.debug("bcv", "chapter: "..c[1])
  SILE.scratch.chapterverse.chapter = c[1]
end)

SILE.registerCommand("save-verse-number", function (o,c)
  SU.debug("bcv", "verse: "..c[1])
  SILE.scratch.chapterverse.verse = c[1]
  local ref = { b = SILE.scratch.chapterverse.book, c = SILE.scratch.chapterverse.chapter, v = SILE.scratch.chapterverse.verse }
  SU.debug("bcv", "ref: "..ref)
  SILE.Commands["info"]({ category = "references", value = ref }, {})
end)

SILE.registerCommand("first-reference", function (o,c)
  local refs = SILE.scratch.info.thispage.references
  SU.debug("bcv", "first-reference: "..SILE.scratch.info)
  if refs then 
    SU.debug("bcv", "first-reference: "..refs[1])
    SILE.call("format-reference", {}, refs[1])
  else
    SU.debug("bcv", "first-reference: none")
  end
end)

SILE.registerCommand("last-reference", function (o,c)
  local refs = SILE.scratch.info.thispage.references
  if refs then
    SU.debug("bcv", "last-reference: "..refs[#(refs)])
    SILE.call("format-reference", {}, refs[#(refs)])
  else
    SU.debug("bcv", "last-reference: none")
  end
end)

SILE.registerCommand("format-reference", function (o,c)
  SU.debug("bcv", "formatting: "..c)
  local ref
  if c.b then
    ref =  c.b .. " " .. c.c .. ":" .. c.v
  else
  	ref =  c.c .. ":" .. c.v
  end
  SU.debug("bcv", "formatting: "..ref)
  SILE.typesetter:typeset(ref)
end)
