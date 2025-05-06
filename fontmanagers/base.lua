--- SILE fontmanager class.
-- @interfaces fontmanagers

local module = require("types.module")
local fontmanager = pl.class(module)
fontmanager.type = "fontmanager"

local icu = require("justenoughicu")

local bits = require("core.parserbits")
local lpeg = require("lpeg")
local Ct, Cg, P = lpeg.Ct, lpeg.Cg, lpeg.P
local adjust_metric = P("ex-height") + P("cap-height")
-- stylua: ignore start
local adjustment = Ct(Cg(bits.number, "amount")^-1 * bits.ws * Cg(adjust_metric, "unit"))
-- stylua: ignore end

function fontmanager:_init ()
   module._init(self)
end

function fontmanager:face (_) end

function fontmanager:_declareSettings ()
   self.settings:declare({ parameter = "font.family", type = "string or nil", default = "Gentium Plus" })
   self.settings:declare({ parameter = "font.size", type = "number or integer", default = 10 })
   self.settings:declare({ parameter = "font.weight", type = "integer", default = 400 })
   self.settings:declare({ parameter = "font.variant", type = "string", default = "normal" })
   self.settings:declare({ parameter = "font.script", type = "string", default = "" })
   self.settings:declare({ parameter = "font.style", type = "string", default = "" })
   self.settings:declare({ parameter = "font.direction", type = "string", default = "" })
   self.settings:declare({ parameter = "font.filename", type = "string or nil", default = "" })
   self.settings:declare({ parameter = "font.features", type = "string", default = "" })
   self.settings:declare({ parameter = "font.variations", type = "string", default = "" })
   self.settings:declare({ parameter = "font.hyphenchar", type = "string", default = "-" })
end

function fontmanager:_registerCommands ()
   local function measureFontAdjustment (metric)
      if metric == "ex-height" then
         -- Uses the height of lowercase letters.
         -- This is used to normalize lowercase letters across fonts.
         -- The height of the lowercase letter "x" is used as the reference.
         -- Another option would be to use the OS/2 font table sxHeight value when available.
         return SILE.shaper:measureChar("x").height
      end
      if metric == "cap-height" then
         -- Uses the the height of uppercase letters.
         -- This is used to normalize uppercase letters across fonts.
         -- The height of the uppercase letter "H" is used as the reference.
         -- Another option would be to use the OS/2 font table sCapHeight value when available.
         return SILE.shaper:measureChar("H").height
      end
      SU.error("Unknown font adjust metric " .. metric)
   end

   local function adjustedFontSize (options)
      local adjust = options.adjust
      local parsed = adjustment:match(adjust)
      if not parsed then
         SU.error("Couldn't parse font adjust value " .. adjust)
      end
      -- Shallow copy: we don't want to modify the original AST as content may be reused
      -- in other contexts (e.g. running headers) and may need to adapt to different font sizes.
      local baseOpts = pl.tablex.copy(options)
      baseOpts.adjust = nil -- cancel for target font size calculation
      local currentMeasure = measureFontAdjustment(parsed.unit)
      local ratio = parsed.amount or 1
      local newMeasure
      -- Apply the target font size to measure the new font
      SILE.call("font", baseOpts, function ()
         newMeasure = measureFontAdjustment(parsed.unit)
      end)
      return self.settings:get("font.size") * ratio * (currentMeasure / newMeasure)
   end

   self.commands:register("font", function (options, content)
      if SU.ast.hasContent(content) then
         self.settings:pushState()
      end
      if options.adjust then
         if options.size then
            SU.error("Can't specify both 'size' and 'adjust' in a \\font command")
         end
         self.settings:set("font.size", adjustedFontSize(options))
      end
      if options.filename then
         self.settings:set("font.filename", options.filename)
      end
      if options.family then
         self.settings:set("font.family", options.family)
         self.settings:set("font.filename", "")
      end
      if options.size then
         local size = SU.cast("measurement", options.size)
         if not size then
            SU.error("Couldn't parse font size " .. options.size)
         end
         self.settings:set("font.size", size:absolute())
      end
      if options.weight then
         self.settings:set("font.weight", 0 + options.weight)
      end
      if options.style then
         self.settings:set("font.style", options.style)
      end
      if options.variant then
         self.settings:set("font.variant", options.variant)
      end
      if options.features then
         self.settings:set("font.features", options.features)
      end
      if options.variations then
         self.settings:set("font.variations", options.variations)
      end
      if options.direction then
         self.settings:set("font.direction", options.direction)
      end
      if options.language then
         if options.language ~= "und" and icu and icu.canonicalize_language then
            local newlang = icu.canonicalize_language(options.language)
            -- if newlang ~= options.language then
            -- SU.warn("Language '"..options.language.."' not canonical, '"..newlang.."' will be used instead")
            -- end
            options.language = newlang
         end
         self.settings:set("document.language", options.language)
      end
      if options.script then
         self.settings:set("font.script", options.script)
      end
      if options.hyphenchar then
         -- must be in the form of, for example, "-" or "U+2010" or "0x2010" (Unicode hex codepoint)
         self.settings:set("font.hyphenchar", SU.utf8charfromcodepoint(options.hyphenchar))
      end

      -- We must *actually* load the font here, because by the time we're inside
      -- SILE.shaper.shapeToken, it's too late to respond appropriately to things
      -- that the post-load hook might want to do.
      SILE.font.cache(SILE.font.loadDefaults(options), SILE.shaper:_getFaceCallback())

      if SU.ast.hasContent(content) then
         SILE.process(content)
         self.settings:popState()
         if SILE.shaper._name == "harfbuzz-color" and SILE.scratch._lastshaper then
            SU.debug("color-fonts", "Switching from color fonts shaper back to previous shaper")
            SILE.typesetter:leaveHmode(true)
            SILE.scratch._lastshaper, SILE.shaper = nil, SILE.scratch._lastshaper
         end
      end
   end, "Set current font family, size, weight, style, variant, script, direction and language")
end

return fontmanager
