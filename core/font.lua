
    SILE.registerCommand("font", function(options, content)
      if (content[1]) then
        SILE.settings.pushState()  
      end
      if (options.family)  then SILE.settings.set("font.family", options.family) end
      if (options.size)  then SILE.settings.set("font.size", 0+options.size) end
      if (options.weight)  then SILE.settings.set("font.weight", 0+options.weight) end
      if (options.rise)  then SILE.settings.set("font.rise", options.rise) end
      if (options.style)  then SILE.settings.set("font.style", options.style) end
      if (options.variant)  then SILE.settings.set("font.variant", options.variant) end
      if (options.underline)  then SILE.settings.set("font.underline", options.underline) end
      if (options.language)  then  SILE.settings.set("document.language", options.language) end
      if (options.color)  then  SILE.settings.set("font.color", SILE.colorparser(options.color)) end
      if (content[1]) then 
        SILE.process(content)
        SILE.settings.popState()
      end
    end)

SILE.settings.declare({name = "font.family", type = "string", default = "Gentium"})
SILE.settings.declare({name = "font.size", type = "integer", default = 10})
SILE.settings.declare({name = "font.weight", type = "integer", default = 200})
SILE.settings.declare({name = "font.variant", type = "string", default = "normal"})

SILE.settings.declare({name = "font.style", type = "string", default = "normal"})
SILE.settings.declare({name = "font.color", type = "string or table", default = "black"})
SILE.settings.declare({name = "font.underline", type = "string", default = ""})

SILE.settings.declare({name = "font.rise", type = "integer", default = 0})

SILE.settings.declare({name = "document.language", type = "string", default = "en"})


SILE.font = {loadDefaults = function(options)
  if not options.font then options.font = SILE.settings.get("font.family") end
  if not options.size then options.size = SILE.settings.get("font.size") end
  if not options.rise then options.rise = SILE.settings.get("font.rise") end
  if not options.weight then options.weight = SILE.settings.get("font.weight") end
  if not options.style then options.style = SILE.settings.get("font.style") end
  if not options.variant then options.variant = SILE.settings.get("font.variant") end
  if not options.language then options.language = SILE.settings.get("document.language") end
  if not options.underline then options.underline = SILE.settings.get("font.underline") end
  if not options.color then options.color = SILE.settings.get("font.color") end
  return options
end
}