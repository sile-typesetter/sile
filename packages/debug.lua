SILE.registerCommand("debug", function (options, _)
  for k, v in pairs(options) do
    SILE.debugFlags[k] = SU.boolean(v, true)
  end
end)

SILE.registerCommand("disable-pushback", function (_, _)
  SILE.typesetter.pushBack = function() end
end)
