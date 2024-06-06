--- SILE unit type.
-- @types unit

local bits = require("core.parserbits")

local unittypes = {
   pt = {
      relative = false,
      value = 1,
   },
}

setmetatable(unittypes, {
   __newindex = function (self, unit, spec)
      local def = SU.required(spec, "definition", "registering unit " .. unit)
      local relative = SU.boolean(spec.relative, false)
      if type(def) == "string" then
         local parsed = bits.measurement:match(def)
         if not parsed then
            SU.error("Could not parse unit definition '" .. def .. "'")
         end
         if not self[parsed.unit] then
            SU.error("Unit " .. unit .. " defined in terms of unknown unit " .. parsed.unit)
         elseif self[parsed.unit].relative then
            rawset(self, unit, {
               relative = true,
               converter = function (value)
                  return value * self[parsed.unit].converter(parsed.amount)
               end,
            })
         else
            rawset(self, unit, {
               relative = false,
               value = parsed.amount * self[parsed.unit].value,
            })
         end
      elseif type(def) == "function" then
         rawset(self, unit, {
            relative = relative,
            converter = def,
         })
      end
   end,
})

unittypes["twip"] = {
   definition = "0.05pt",
}

unittypes["mm"] = {
   definition = "2.8346457pt",
}

unittypes["cm"] = {
   definition = "10mm",
}

unittypes["m"] = {
   definition = "100cm",
}

unittypes["hm"] = {
   definition = "0.01mm",
}

unittypes["in"] = {
   definition = "72pt",
}

unittypes["ft"] = {
   definition = "12in",
}

-- Picas are 1/6 inch, used in Docbook images
unittypes["pc"] = {
   definition = "0.166666667in",
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

unittypes["%pw"] = {
   relative = true,
   definition = function (value)
      checkPaperDefined()
      return value / 100 * SILE.documentState.orgPaperSize[1]
   end,
}

unittypes["%ph"] = {
   relative = true,
   definition = function (value)
      checkPaperDefined()
      return value / 100 * SILE.documentState.orgPaperSize[2]
   end,
}

unittypes["%pmin"] = {
   relative = true,
   definition = function (value)
      checkPaperDefined()
      return value / 100 * SU.min(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
   end,
}

unittypes["%pmax"] = {
   relative = true,
   definition = function (value)
      checkPaperDefined()
      return value / 100 * SU.max(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
   end,
}

unittypes["%fw"] = {
   relative = true,
   definition = function (value)
      checkFrameDefined()
      return value / 100 * SILE.typesetter.frame:width():tonumber()
   end,
}

unittypes["%fh"] = {
   relative = true,
   definition = function (value)
      checkFrameDefined()
      return value / 100 * SILE.typesetter.frame:height():tonumber()
   end,
}

unittypes["%fmin"] = {
   relative = true,
   definition = function (value)
      checkFrameDefined()
      return value / 100 * SU.min(SILE.typesetter.frame:width():tonumber(), SILE.typesetter.frame:height():tonumber())
   end,
}

unittypes["%fmax"] = {
   relative = true,
   definition = function (value)
      checkFrameDefined()
      return value / 100 * SU.max(SILE.typesetter.frame:width():tonumber(), SILE.typesetter.frame:height():tonumber())
   end,
}

unittypes["%lw"] = {
   relative = true,
   definition = function (value)
      local lskip = SILE.settings:get("document.lskip")
      local rskip = SILE.settings:get("document.rskip")
      local left = lskip and lskip.width:tonumber() or 0
      local right = rskip and rskip.width:tonumber() or 0
      checkFrameDefined()
      return value / 100 * SILE.typesetter.frame:getLineWidth():tonumber() - left - right
   end,
}

unittypes["ps"] = {
   relative = true,
   definition = function (value)
      local ps = SILE.settings:get("document.parskip")
      ps = ps.height:tonumber() or 0
      return value * ps
   end,
}

unittypes["bs"] = {
   relative = true,
   definition = function (value)
      local bs = SILE.settings:get("document.baselineskip")
      bs = bs.height:tonumber() or 0
      return value * bs
   end,
}

unittypes["em"] = {
   relative = true,
   definition = function (value)
      return value * SILE.settings:get("font.size")
   end,
}

unittypes["ex"] = {
   relative = true,
   definition = function (value)
      return value * SILE.shaper:measureChar("x").height
   end,
}

unittypes["spc"] = {
   relative = true,
   definition = function (value)
      return value * SILE.shaper:measureChar(" ").width
   end,
}

unittypes["en"] = {
   relative = true,
   definition = "0.5em",
}

-- jlreq measures distances in units of 1em, but also assumes that an em is the
-- width of a full-width character. In SILE terms it isn't: measuring an "m" in
-- a 10pt Japanese font gets you 5 points. So we measure a full-width character
-- and use that as a unit. We call it zw following ptex (zenkaku width)
unittypes["zw"] = {
   relative = true,
   definition = function (v)
      local zenkakuchar = SILE.settings:get("document.zenkakuchar")
      local measureable, zenkaku = pcall(SILE.shaper.measureChar, SILE.shaper, zenkakuchar)
      if not measureable then
         SU.warn(string.format(
            [[Zenkaku width (全角幅) unit zw is falling back to 1em == 1zw as we
  cannot measure %s. Either change this char to one suitable for your
  language, or load a font that has it.]],
            zenkakuchar
         ))
      end
      local width = measureable and zenkaku.width or SILE.settings:get("font.size")
      return v * width
   end,
}

return unittypes
