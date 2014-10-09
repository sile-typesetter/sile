SILE.registerCommand("xmltricks:ignore", function (options, content)
  for token in SU.gtoke(content[1]) do
    if token.string then SILE.call("define", { command = token.string}, function() end) end
  end
end)

SILE.registerCommand("xmltricks:passthru", function (options, content)
  for token in SU.gtoke(content[1]) do
    if token.string then SILE.registerCommand(token.string, function(o,c) SILE.process(c) end) end
  end
end)
