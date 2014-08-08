local book = SILE.require("classes/book");
docbook = book { id = "docbook" };
SILE.scratch.docbook = {
  level = "main",
  index = {}
}
SILE.registerCommand("preface", function(options, content)
end)

SILE.registerCommand("indexterm", function(options, content)
  print(content[1])
  local t = {}
  for k,v in pairs(content) do
    if type(v) == "table" then
      if v.tag == "primary"
    end
  end
  error("foo")
end)
SILE.registerCommand("section", function(options, content)
  SILE.scratch.docbook.level = "section"
  SILE.Commands["increment-counter"]({id="section"},{})
  SILE.Commands["set-counter"]({id="subsection", value=""},{})
  SILE.process(content)
end)

SILE.registerCommand("title", function(options, content)
  if SILE.scratch.docbook.level == "main" then
    SILE.Commands["left-running-head"]({}, content)
    SILE.Commands["docbook-title-main"](options, content)
  elseif SILE.scratch.docbook.level == "section" then
    if not SILE.scratch.counters.folio == 1 then
      SILE.Commands["right-running-head"]({}, content)
    end
    SILE.Commands["docbook-title-section"](options, content)
  end
end)

SILE.registerCommand("link", function (options, content)
  SILE.Commands["font"]({style = "italic"}, content)
  SILE.typesetter:typeset(" (")
  SILE.Commands["ttfont"]({}, function()
    SILE.typesetter:typeset(options["xlink:href"])
  end)
  SILE.typesetter:typeset(")")
end)

return docbook