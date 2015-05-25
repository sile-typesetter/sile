local bible = SILE.require("classes/bible");
local usx = bible { id = "usx", base = bible };

SILE.registerCommand("para", function (options, content)
  SILE.call("para-"..options.style,options, content)
end)

SILE.registerCommand("note", function (options, content)
  SILE.call("footnote", options, {options.caller})
end)

SILE.registerCommand("char", function (options, content)
  SILE.call("char-"..options.style,options, content)
end)

SILE.registerCommand("chapter", function(options, content)
  SILE.call("bible:chapter-head",{},{options.number})
  SILE.call("save-chapter-number",{},{options.number})
end)

SILE.registerCommand("verse", function(options,content)
  SILE.call("verse-number", options, {options.number})
end)

return usx
