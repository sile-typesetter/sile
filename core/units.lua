local units = {
  pt = {
    relative = false,
    value = 1
  }
}

setmetatable(units, {
    __newindex = function (self, unit, spec)
      local def = SU.required(spec, "definition", "registering unit " .. unit)
      local relative = SU.boolean(spec.relative, false)
      if type(def) == "string" then
        local parsed = SILE.parserBits.measurement:match(def)
        if not parsed then SU.error("Could not parse unit definition '"..def.."'") end
        if not self[parsed.unit] then
          SU.error("Unit " .. unit .. " defined in terms of unknown unit " .. parsed.unit)
        elseif self[parsed.unit].relative then
          rawset(self, unit, {
              relative = true,
              converter = function (value)
                return  value * self[parsed.unit].converter(parsed.amount)
              end
            })
        else
          rawset(self, unit, {
              relative = false,
              value = parsed.amount * self[parsed.unit].value
            })
        end
      elseif type(def) == "function" then
        rawset(self, unit, {
            relative = relative,
            converter = def
          })
      end
    end
  })

SILE.registerUnit = function (unit, spec)
  -- SU.warn("Use of SILE.registerUnit() is deprecated, add via metamethod SILE.units["unit"] = (spec)"
  units[unit] = spec
end

units["mm"] = {
  definition = "2.8346457pt"
}

units["cm"] = {
  definition = "10mm"
}

units["m"] = {
  definition = "100cm"
}

units["in"] = {
  definition = "72pt"
}

units["ft"] = {
  definition = "12in"
}

local checkPaperDefined = function ()
  if not SILE.documentState or not SILE.documentState.orgPaperSize then
    SU.error("A measurement tried to measure the paper size before the paper was defined", true)
  end
end

local checkFrameDefined = function ()
  if not SILE.typesetter.frame then
    SU.error("A measurement tried to measure the frame before the frame was defined", true)
  end
end

units["%pw"] = {
  relative = true,
  definition = function (value)
    checkPaperDefined()
    return value / 100 * SILE.documentState.orgPaperSize[1]
  end
}

units["%ph"] = {
  relative = true,
  definition = function (value)
    checkPaperDefined()
    return value / 100 * SILE.documentState.orgPaperSize[2]
  end
}

units["%pmin"] = {
  relative = true,
  definition = function (value)
    checkPaperDefined()
    return value / 100 * SU.min(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
  end
}

units["%pmax"] = {
  relative = true,
  definition = function (value)
    checkPaperDefined()
    return value / 100 * SU.max(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
  end
}

units["%fw"] = {
  relative = true,
  definition = function (value)
    checkFrameDefined()
    return value / 100 * SILE.typesetter.frame:width():tonumber()
  end
}

units["%fh"] = {
  relative = true,
  definition = function (value)
    checkFrameDefined()
    return value / 100 * SILE.typesetter.frame:height():tonumber()
  end
}

units["%fmin"] = {
  relative = true,
  definition = function (value)
    checkFrameDefined()
    return value / 100 * SU.min(SILE.typesetter.frame:width():tonumber(), SILE.typesetter.frame:height():tonumber())
  end
}

units["%fmax"] = {
  relative = true,
  definition = function (value)
    checkFrameDefined()
    return value / 100 * SU.max(SILE.typesetter.frame:width():tonumber(), SILE.typesetter.frame:height():tonumber())
  end
}

units["%lw"] = {
  relative = true,
  definition = function (value)
    local lskip = SILE.settings.get("document.lskip")
    local rskip = SILE.settings.get("document.rskip")
    local left = lskip and lskip.width:tonumber() or 0
    local right = rskip and rskip.width:tonumber() or 0
    checkFrameDefined()
    return value / 100 * SILE.typesetter.frame:getLineWidth():tonumber() - left - right
  end
}

units["ps"] = {
  relative = true,
  definition = function (value)
    local ps = SILE.settings.get("document.parskip")
    ps = ps.height:tonumber() or 0
    return value * ps
  end
}

units["bs"] = {
  relative = true,
  definition = function (value)
    local bs = SILE.settings.get("document.baselineskip")
    bs = bs.height:tonumber() or 0
    return value * bs
  end
}

units["em"] = {
  relative = true,
  definition = function (value)
    return value * SILE.settings.get("font.size")
  end
}

units["ex"] = {
  relative = true,
  definition = function (value)
    return value * SILE.shaper:measureChar("x").height
  end
}

units["spc"] = {
  relative = true,
  definition = function (value)
    return value * SILE.shaper:measureChar(" ").width
  end
}

units["en"] = {
  relative = true,
  definition = "0.5em"
}

return units
