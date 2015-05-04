SILE.toPoints = function(num, unit, dimension)
  local toPoints = {
    
    mm = function(m) return 2.8346457 * m end,
    pt = function (i) return i end,
    cm = function (c) return 2.8346457 * 10 * c end,
  }
  toPoints["in"] = function(i) return 72.0 * i end
  toPoints["%"] = function(v, dimension) 
    return tonumber(v) / 100 * SILE.documentState.paperSize[ dimension == 'w' and 1 or 2]
  end
  toPoints["ex"] =  function(v) return tonumber(v) * SILE.shaper:measureDim("x") end
  toPoints["em"] =  function(v) return tonumber(v) * SILE.shaper:measureDim("m") end
  toPoints["en"] =  function(v) return tonumber(v) * SILE.shaper:measureDim("n") end
  if (not unit) then
    if (type(num) == "string") then -- split into num and unit parts
      num,unit = string.match(num, "(-?[%d%.]+)%s*([%%%a]+)")
      num = tonumber(num)
    else return tonumber(num) end
  end
  if (not toPoints[unit]) then SU.error( "Unknown unit "..unit ) end
  num =  tonumber(string.match(num, "(-?[%d%.]+)"))
  return toPoints[unit](num, dimension);
end