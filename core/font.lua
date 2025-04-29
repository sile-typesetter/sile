--- font
-- @module SILE.font

SILE.settings:declare({ parameter = "font.family", type = "string or nil", default = "Gentium Plus" })
SILE.settings:declare({ parameter = "font.size", type = "number or integer", default = 10 })
SILE.settings:declare({ parameter = "font.weight", type = "integer", default = 400 })
SILE.settings:declare({ parameter = "font.variant", type = "string", default = "normal" })
SILE.settings:declare({ parameter = "font.script", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.style", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.direction", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.filename", type = "string or nil", default = "" })
SILE.settings:declare({ parameter = "font.features", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.variations", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.hyphenchar", type = "string", default = "-" })

SILE.fontCache = {}

local _key = function (options)
   return table.concat({
      options.family or "",
      ("%g"):format(SILE.types.measurement(options.size):tonumber()),
      ("%d"):format(options.weight or 0),
      options.style,
      options.variant,
      options.features,
      options.variations,
      options.direction,
      options.filename or "",
   }, ";")
end

local font = {

   loadDefaults = function (options)
      if not options.family then
         options.family = SILE.settings:get("font.family")
      end
      if not options.size then
         options.size = SILE.settings:get("font.size")
      end
      if not options.weight then
         options.weight = SILE.settings:get("font.weight")
      end
      if not options.style then
         options.style = SILE.settings:get("font.style")
      end
      if not options.variant then
         options.variant = SILE.settings:get("font.variant")
      end
      if SILE.settings:get("font.filename") ~= "" then
         options.filename = SILE.settings:get("font.filename")
         options.family = ""
      end
      if not options.language then
         options.language = SILE.settings:get("document.language")
      end
      if not options.script then
         options.script = SILE.settings:get("font.script")
      end
      if not options.direction then
         options.direction = SILE.settings:get("font.direction")
         if not options.direction or options.direction == "" then
            options.direction = SILE.typesetter and SILE.typesetter.frame and SILE.typesetter.frame:writingDirection()
               or "LTR"
         end
      end
      if not options.features then
         options.features = SILE.settings:get("font.features")
      end
      if not options.variations then
         options.variations = SILE.settings:get("font.variations")
      end
      if not options.hyphenchar then
         options.hyphenchar = SILE.settings:get("font.hyphenchar")
      end
      return options
   end,

   -- TODO: See _getFaceCallback workaround in shaper, work on a better interaction
   cache = function (options, callback)
      local key = _key(options)
      if not SILE.fontCache[key] then
         SU.debug("fonts", "Looking for", key)
         local face = callback(options)
         SILE.fontCache[key] = face
      end
      local cached = SILE.fontCache[key]
      SILE.font.postLoadHook(cached)
      return cached
   end,

   finish = function ()
      for key, font in pairs(SILE.fontCache) do
         -- Don't do anything for Pango fonts
         if type(font) ~= "userdata" and type(font.insert) ~= "function" then
            if font.tempfilename ~= font.filename then
               SU.debug("fonts", "Removing temporary file of", key, ":", font.tempfilename)
               os.remove(font.tempfilename)
            end
         end
      end
   end,

   postLoadHook = function (face)
      -- Don't do anything for Pango fonts (here face could be a Pango Attribute Lists)
      if type(face) == "userdata" and type(face.insert) == "function" then
         return
      end
      local ot = require("core.opentype-parser")
      local font = ot.parseFont(face)
      if font.cpal then
         if SILE.shaper._name ~= "harfbuzz-color" then
            SU.debug("color-fonts", "Switching to color font Shaper")
            SILE.typesetter:leaveHmode(true)
            SILE.scratch._lastshaper, SILE.shaper = SILE.shaper, SILE.shapers["harfbuzz-color"]()
         end
      end
   end,

   _key = _key,
}

return font
