SILE.registerCommand("debug", function (options, content)
  for k, v in pairs(options) do
    SILE.debugFlags[k] = SU.boolean(v, true)
  end
end)

SILE.registerCommand("disable-pushback", function (options, content)
  SILE.typesetter.pushBack = function() end
end)
