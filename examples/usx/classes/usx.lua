local book = SILE.require("classes/book");
local usx = book { id = "usx" };

SILE.registerCommand("para", function (options, content)
  SILE.call("para-"..options.style,options, content)
end)

SILE.registerCommand("char", function (options, content)
  SILE.call("char-"..options.style,options, content)
end)

SILE.registerCommand("chapter", function(options, content)
  SILE.call("goodbreak")
  SILE.call("dropcap",{},function() SILE.typesetter:typeset(options.number) end)
end)

SILE.registerCommand("verse", function(options,content)
  SILE.call("vref", options, function() SILE.typesetter:typeset(options.number) end)
end)

return usx