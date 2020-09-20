local bible = SILE.require("bible", "classes")
local usx = bible { id = "usx" }

SILE.registerCommand("para", function (options, content)
  SILE.call("style-" .. options.style, options, content)
end)

SILE.registerCommand("note", function (options, content)
  local note = content[1] and content or { options.caller } -- USX keeps changing...
  SILE.call("footnote", options, note)
end)

SILE.registerCommand("char", function (options, content)
  SILE.call("style-" .. options.style, options, content)
end)

SILE.registerCommand("chapter", function (options, _)
  SILE.call("bible:chapter-head", {}, { options.number })
  SILE.call("save-chapter-number", {}, { options.number })
end)

SILE.registerCommand("verse", function (options, _)
  SILE.call("verse-number", options, { options.number })
end)

SILE.registerCommand("leftmargin", function (options, content)
  SILE.call("set", {
    parameter = "document.lskip",
    value = options.size
  }, content)
end)

return usx
