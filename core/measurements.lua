SILE.units = {
  pt = {relative = false, value = 1}
}

SILE.registerUnit = function(unit, spec)
  local def = SU.required(spec, "definition", "registering unit " .. unit)
  local relative = spec.relative or false
  if type(def) == "string" then
    local factor, baseunit = string.match(def, "(-?[%d%.]+)%s*([%%%a]+)")
    if not SILE.units[baseunit] then
      SU.error("Unit " .. unit .. " defined in terms of unknown unit " .. baseunit)
    end
    if SILE.units[baseunit].relative then
      SILE.units[unit] = {relative = true, convertor = function(value)
          return factor * SILE.toPoints(value, baseunit)
        end}
    else
      SILE.units[unit] = {relative = false, value = SILE.toPoints(factor, baseunit)}
    end
  else
    SILE.units[unit] = {relative = relative, convertor = def}
  end
end

SILE.toPoints = function(factor, unit)
  if (not unit) then
    if (type(factor) == "string") then -- split into factor and unit parts
      factor, unit = string.match(factor, "(-?[%d%.]+)%s*([%%%a]+)")
      factor = tonumber(factor)
    else
      return tonumber(factor)
    end
  end
  if (not SILE.units[unit]) then
    SU.error("Unknown unit " .. unit)
  end
  factor = tonumber(string.match(factor, "(-?[%d%.]+)"))
  if SILE.units[unit].convertor then
    return SILE.units[unit].convertor(factor)
  else
    return factor * SILE.units[unit].value
  end
end

SILE.registerUnit("mm", {definition = "2.8346457pt"})

SILE.registerUnit("cm", {definition = "10mm"})

SILE.registerUnit("in", {definition = "72pt"})

local checkPaperDefined = function()
  if not SILE.documentState or not SILE.documentState.orgPaperSize then
    SU.error("A measurement tried to measure the paper size before the paper was defined", true)
  end
end

local checkFrameDefined = function ()
  if not SILE.typesetter.frame then
    SU.error("A measurement tried to measure the frame before the frame was defined", true)
  end
end

SILE.registerUnit("%pw", { relative = true, definition = function (value)
  checkPaperDefined()
  return value / 100 * SILE.documentState.orgPaperSize[1]
end})

SILE.registerUnit("%ph", { relative = true, definition = function (value)
  checkPaperDefined()
  return value / 100 * SILE.documentState.orgPaperSize[2]
end})

SILE.registerUnit("%pmin", { relative = true, definition = function (value)
  checkPaperDefined()
  return value / 100 * math.min(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
end})

SILE.registerUnit("%pmax", { relative = true, definition = function (value)
  checkPaperDefined()
  return value / 100 * math.max(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
end})

SILE.registerUnit("%fw", { relative = true, definition = function (value)
  checkFrameDefined()
  return value / 100 * SILE.typesetter.frame:width()
end})

SILE.registerUnit("%fh", { relative = true, definition = function (value)
  checkFrameDefined()
  return value / 100 * SILE.typesetter.frame:height()
end})

SILE.registerUnit("%fmin", { relative = true, definition = function (value)
  checkFrameDefined()
  return value / 100 * math.min(SILE.typesetter.frame:width(), SILE.typesetter.frame:height())
end})

SILE.registerUnit("%fmax", { relative = true, definition = function (value)
  checkFrameDefined()
  return value / 100 * math.max(SILE.typesetter.frame:width(), SILE.typesetter.frame:height())
end})

SILE.registerUnit("%lw", { relative = true, definition = function (value)
  local lskip = SILE.settings.get("document.lskip") or SILE.length.parse("0")
  local rskip = SILE.settings.get("document.rskip") or SILE.length.parse("0")
  local left = lskip.width and lskip.width:absolute() or lskip:absolute()
  local right = rskip.width and rskip.width:absolute() or rskip:absolute()
  checkFrameDefined()
  local lw = SILE.typesetter.frame:lineWidth() - left - right
  return value / 100 * lw.length
end})

SILE.registerUnit("ps", { relative = true, definition = function (value)
  local ps = SILE.settings.get("document.parskip") or SILE.length.parse("0")
  ps = ps.height and ps.height:absolute() or ps:absolute()
  return value * ps.length
end})

SILE.registerUnit("bs", { relative = true, definition = function (value)
  local bs = SILE.settings.get("document.baselineskip") or SILE.length.parse("0")
  bs = bs.height and bs.height:absolute() or bs:absolute()
  return value * bs.length
end})

SILE.registerUnit("em", { relative = true, definition = function (value)
  return value * SILE.settings.get("font.size")
end})

SILE.registerUnit("ex", { relative = true, definition = function (value)
  return value * SILE.shaper:measureChar("x").height
end})

SILE.registerUnit("spc", { relative = true, definition = function (value)
  return value * SILE.shaper:measureChar(" ").width
end})

SILE.registerUnit("en", { definition = "0.5em" })

local _relativeMeasurement = std.object {
  _type = "RelativeMeasurement",
  __tostring = function (self) return "("..self.number..self.unit..")" end,
  absolute = function(self)
    return SILE.toPoints(self.number, self.unit)
  end,
  __add = function (self, other)
    SU.error("We tried to do arithmetic on a relative measurement without explicitly absolutizing it. (That's a bug)", true)
  end,
  __sub = function (self, other)
    SU.error("We tried to do arithmetic on a relative measurement without explicitly absolutizing it. (That's a bug)", true)
  end
}

SILE.toMeasurement = function (number, unit)
  if not SILE.units[unit].relative then return SILE.toPoints(number,unit) end
  return _relativeMeasurement { number = number, unit = unit }
end

SILE.toAbsoluteMeasurement = function(length)
  if type(length) == "table" and length.prototype
    and (length:prototype() == "RelativeMeasurement" or length:prototype() == "Length") then
    return length:absolute()
  else
    return length
  end
end
