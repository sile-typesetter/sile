
    SILE.registerCommand("font", function(options, content)
      if (type(content)=="function" or content[1]) then
        SILE.settings.pushState() 
      end
      if (options.family)  then SILE.settings.set("font.family", options.family) end
      if (options.size)  then
        local size = SILE.parserBits.dimensioned_string:match(options.size)
        if not size then SU.error("Couldn't parse font size "..options.size) end
        SILE.settings.set("font.size", size)
      end
      if (options.weight)  then SILE.settings.set("font.weight", 0+options.weight) end
      if (options.style)  then SILE.settings.set("font.style", options.style) end
      if (options.variant)  then SILE.settings.set("font.variant", options.variant) end
      if (options.features)  then SILE.settings.set("font.features", options.features) end

      if (options.language)  then 
        SILE.settings.set("document.language", options.language)
        SILE.languageSupport.loadLanguage(options.language)
      end
      if (options.script)  then SILE.settings.set("font.script", options.script)
      elseif SILE.settings.get("document.language") then
        local lang = SILE.languageSupport.languages[SILE.settings.get("document.language")]
        if lang and lang.defaultScript then
          SILE.settings.set("font.script", lang.defaultScript)
        end
      end

      if (type(content)=="function" or content[1]) then
        SILE.process(content)
        SILE.settings.popState()
      end
    end, "Set current font family, size, weight, style, variant, script, direction and language")

SILE.settings.declare({name = "font.family", type = "string", default = "Gentium"})
SILE.settings.declare({name = "font.size", type = "number or integer", default = 10})
SILE.settings.declare({name = "font.weight", type = "integer", default = 200})
SILE.settings.declare({name = "font.variant", type = "string", default = "normal"})
SILE.settings.declare({name = "font.script", type = "string", default = ""})
SILE.settings.declare({name = "font.style", type = "string", default = "normal"})
SILE.settings.declare({name = "font.direction", type = "string", default = ""})
SILE.settings.declare({name = "font.features", type = "string", default = ""})
SILE.settings.declare({name = "document.language", type = "string", default = "en"})

SILE.fontCache = {}

local _key = function(options)
  return table.concat({options.font;options.size;("%d"):format(options.weight);options.style;options.variant;options.features;options.direction},";")
end


SILE.font = {loadDefaults = function(options)
  if not options.font then options.font = SILE.settings.get("font.family") end
  if not options.size then options.size = SILE.settings.get("font.size") end
  if not options.weight then options.weight = SILE.settings.get("font.weight") end
  if not options.style then options.style = SILE.settings.get("font.style") end
  if not options.variant then options.variant = SILE.settings.get("font.variant") end
  if not options.language then options.language = SILE.settings.get("document.language") end
  if not options.script then options.script = SILE.settings.get("font.script") end
  if not options.direction then 
    options.direction = SILE.settings.get("font.direction") 
    if not options.direction or options.direction == "" then
      options.direction = SILE.typesetter.frame and SILE.typesetter.frame.direction or "LTR"
    end
  end
  if not options.features then options.features = SILE.settings.get("font.features") end
  return options
end,
  cache = function(options, callback)
    if not SILE.fontCache[_key(options)] then
      SILE.fontCache[_key(options)] = callback(options)
    end
    return SILE.fontCache[_key(options)]
  end,
  _key = _key
}