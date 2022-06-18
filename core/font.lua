local icu = require("justenoughicu")

SILE.registerCommand("font", function (options, content)
  if SU.hasContent(content) then SILE.settings:pushState() end
  if options.filename then SILE.settings:set("font.filename", options.filename) end
  if options.family then
    SILE.settings:set("font.family", options.family)
    SILE.settings:set("font.filename", "")
  end
  if options.size then
    local size = SU.cast("measurement", options.size)
    if not size then SU.error("Couldn't parse font size "..options.size) end
    SILE.settings:set("font.size", size:absolute())
  end
  if options.weight then SILE.settings:set("font.weight", 0+options.weight) end
  if options.style then SILE.settings:set("font.style", options.style) end
  if options.variant then SILE.settings:set("font.variant", options.variant) end
  if options.features then SILE.settings:set("font.features", options.features) end
  if options.direction then SILE.settings:set("font.direction", options.direction) end
  if (options.language) then
    if icu and icu.canonicalize_language then
      local newlang = icu.canonicalize_language(options.language)
      -- if newlang ~= options.language then
        -- SU.warn("Language '"..options.language.."' not canonical, '"..newlang.."' will be used instead.")
      -- end
      options.language = newlang
    end
    SILE.settings:set("document.language", options.language)
    SILE.fluent:set_locale(options.language)
    SILE.languageSupport.loadLanguage(options.language)
  end
  if options.script then SILE.settings:set("font.script", options.script)
  elseif SILE.settings:get("document.language") then
    local lang = SILE.languageSupport.languages[SILE.settings:get("document.language")]
    if lang and lang.defaultScript then
      SILE.settings:set("font.script", lang.defaultScript)
    end
  end
  if options.hyphenchar then
    -- must be in the form of, for example, "-" or "U+2010" or "0x2010" (Unicode hex codepoint)
    SILE.settings:set("font.hyphenchar", SU.utf8charfromcodepoint(options.hyphenchar))
  end

  -- We must *actually* load the font here, because by the time we're inside
  -- SILE.shaper.shapeToken, it's too late to respond appropriately to things
  -- that the post-load hook might want to do.
  SILE.font.cache(SILE.font.loadDefaults({}), SILE.shaper.getFace)

  if SU.hasContent(content) then
    SILE.process(content)
    SILE.settings:popState()
  end
end, "Set current font family, size, weight, style, variant, script, direction and language")

SILE.settings:declare({ parameter = "font.family", type = "string or nil", default = "Gentium Plus" })
SILE.settings:declare({ parameter = "font.size", type = "number or integer", default = 10 })
SILE.settings:declare({ parameter = "font.weight", type = "integer", default = 400 })
SILE.settings:declare({ parameter = "font.variant", type = "string", default = "normal" })
SILE.settings:declare({ parameter = "font.script", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.style", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.direction", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.filename", type = "string or nil", default = "" })
SILE.settings:declare({ parameter = "font.features", type = "string", default = "" })
SILE.settings:declare({ parameter = "font.hyphenchar", type = "string", default = "-" })

SILE.fontCache = {}

local _key = function (options)
  return table.concat({
      options.family,
      ("%g"):format(SILE.measurement(options.size):tonumber()),
      ("%d"):format(options.weight or 0),
      options.style,
      options.variant,
      options.features,
      options.direction,
      options.filename,
    }, ";")
end

local font = {

  loadDefaults = function (options)
    if not options.family then options.family = SILE.settings:get("font.family") end
    if not options.size then options.size = SILE.settings:get("font.size") end
    if not options.weight then options.weight = SILE.settings:get("font.weight") end
    if not options.style then options.style = SILE.settings:get("font.style") end
    if not options.variant then options.variant = SILE.settings:get("font.variant") end
    if SILE.settings:get("font.filename") ~= "" then
      options.filename = SILE.settings:get("font.filename")
      options.family = ""
    end
    if not options.language then options.language = SILE.settings:get("document.language") end
    if not options.script then options.script = SILE.settings:get("font.script") end
    if not options.direction then
      options.direction = SILE.settings:get("font.direction")
      if not options.direction or options.direction == "" then
        options.direction = SILE.typesetter and SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() or "LTR"
      end
    end
    if not options.features then options.features = SILE.settings:get("font.features") end
    if not options.hyphenchar then options.hyphenchar = SILE.settings:get("font.hyphenchar") end
    return options
  end,

  cache = function (options, callback)
    local key = _key(options)
    if not SILE.fontCache[key] then
      SU.debug("fonts", "Looking for "..key)
      local face = callback(options)
      SILE.font.postLoadHook(face)
      SILE.fontCache[key] = face
    end
    return SILE.fontCache[key]
  end,

  postLoadHook = function(face)
    local ot = require("core.opentype-parser")
    local font = ot.parseFont(face)
    if font.cpal then
      SILE.require("packages.color-fonts")
    end
  end,

  _key = _key
}

return font
