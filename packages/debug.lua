SILE.registerCommand("debug", function (options,c)
  for k,v in pairs(options) do
    if v == "false" or v == "no" or v == "off" then
      SILE.debugFlags[k] = false
    else
      SILE.debugFlags[k] = true
    end
  end
end)

SILE.registerCommand("disable-pushback", function (options,c)
  SILE.typesetter.pushBack = function(self) end
end)