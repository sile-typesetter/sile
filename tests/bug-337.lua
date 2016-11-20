SILE.registerCommand("printPaperInPoints", function(o,c)
  SILE.typesetter:typeset(("%.0f x %.0f"):format(SILE.toPoints("100%ph"), SILE.toPoints("100%pw")))
end)

local book = SILE.require("book", "classes")
book:loadPackage("masters")
book:defineMaster({ id="right", firstContentFrame="content", frames={
  content = { left="0", right="100%pw", top="0", bottom="top(folio)" },
  folio = { left="left(content)", right="right(content)", height="10pt", bottom="100%ph"}
}})
book:defineMaster({ id="left", firstContentFrame="content", frames={} })
book:loadPackage("twoside", { oddPageMaster="right", evenPageMaster="left" })
book:mirrorMaster("right", "left")
SILE.call("switch-master-one-page", { id="right" })
