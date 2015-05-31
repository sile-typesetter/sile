SILE.require("packages/infonode")
SILE.scratch.chapterverse = {}

SILE.registerCommand("save-chapter-number", function (o,c)
  SILE.scratch.chapterverse.chapter = c[1]
end)

SILE.registerCommand("save-verse-number", function (o,c)
  SILE.scratch.chapterverse.verse = c[1]
  local ref = SILE.scratch.chapterverse.chapter .. ":" .. SILE.scratch.chapterverse.verse
  SILE.Commands["info"]({ category = "references", value = ref }, {})
end)

SILE.registerCommand("first-reference", function (o,c)
  local refs = SILE.scratch.info.thispage.references
  if refs then SILE.typesetter:typeset(refs[1]) end
end)

SILE.registerCommand("last-reference", function (o,c)
  local refs = SILE.scratch.info.thispage.references
  if refs then SILE.typesetter:typeset(refs[#refs]) end
end)