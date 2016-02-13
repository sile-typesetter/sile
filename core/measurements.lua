SILE.xToPoints = {
  mm = function(m) return 2.8346457 * m end,
  pt = function (i) return i end,
  cm = function (c) return 2.8346457 * 10 * c end,
  ["in"] = function(i) return 72.0 * i end,
  ["%" ]= function(v, dimension)
    return tonumber(v) / 100 * SILE.documentState.paperSize[ dimension == 'w' and 1 or 2]
  end,
  ["ex"] =  function(v) return tonumber(v) * SILE.shaper:measureDim("x") end,
  ["em"] =  function(v) return tonumber(v) * SILE.settings.get("font.size") end,
  ["en"] =  function(v) return 0.5 * tonumber(v) * SILE.settings.get("font.size") end
}

SILE.toPoints = function(num, unit, dimension)
  if (not unit) then
    if (type(num) == "string") then -- split into num and unit parts
      num,unit = string.match(num, "(-?[%d%.]+)%s*([%%%a]+)")
      num = tonumber(num)
    else return tonumber(num) end
  end
  if (not SILE.xToPoints[unit]) then SU.error( "Unknown unit "..unit ) end
  num =  tonumber(string.match(num, "(-?[%d%.]+)"))
  return SILE.xToPoints[unit](num, dimension);
end