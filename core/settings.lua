SILE.settings = {
  state = {},
  declarations = {},
  stateQueue = {},
  defaults = {},
  pushState = function()
    table.insert(SILE.settings.stateQueue, SILE.settings.state)
    SILE.settings.state = pl.tablex.copy(SILE.settings.state)
  end,
  popState = function()
    SILE.settings.state = table.remove(SILE.settings.stateQueue)
  end,
  declare = function(spec)
    SILE.settings.declarations[spec.name] = spec
    SILE.settings.defaults[spec.name] = spec.default
    SILE.settings.set(spec.name)
  end,
  reset = function()
    for k,_ in pairs(SILE.settings.state) do
      SILE.settings.set(k, SILE.settings.defaults[k])
    end
  end,
  get = function(name)
    if not SILE.settings.declarations[name] then
      SU.error("Undefined setting '"..name.."'")
    end
    if type(SILE.settings.state[name]) ~= "nil" then
      return SILE.settings.state[name]
    else
      return SILE.settings.defaults[name]
    end
  end,
  set = function(name, value)
    if not SILE.settings.declarations[name] then
      SU.error("Undefined setting '"..name.."'")
    end
    if type(value) == "nil" then
      SILE.settings.state[name] = nil
    else
      SILE.settings.state[name] = SU.cast(SILE.settings.declarations[name].type, value)
    end
  end,
  temporarily = function(func)
    SILE.settings.pushState()
    func()
    SILE.settings.popState()
  end,
  wrap = function() -- Returns a closure which applies the current state, later
    local clSettings = pl.tablex.copy(SILE.settings.state)
    return function(func)
      table.insert(SILE.settings.stateQueue, SILE.settings.state)
      SILE.settings.state = clSettings
      SILE.process(func)
      SILE.settings.popState()
    end
  end,
}

SILE.settings.declare({
  name = "document.parindent",
  type = "glue",
  default = SILE.nodefactory.glue("20pt"),
  help = "Glue at start of paragraph"
})

SILE.settings.declare({
  name = "document.baselineskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("1.2em plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.lineskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("1pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.parskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("0pt plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.spaceskip",
  type = "length or nil",
  default = nil,
  help = "The length of a space (if nil, then measured from the font)"
})

SILE.settings.declare({
  name = "document.rskip",
  type = "glue or nil",
  default = nil,
  help = "Skip to be added to right side of line"
})

SILE.settings.declare({
  name = "document.lskip",
  type = "glue or nil",
  default = nil,
  help = "Skip to be added to left side of line"
})

SILE.registerCommand("set", function(options, content)
  local parameter = SU.required(options, "parameter", "\\set command")
  local makedefault = SU.boolean(options.makedefault, false)
  local value = options.value
  if content and (type(content) == "function" or content[1]) then
    SILE.settings.temporarily(function()
      SILE.settings.set(parameter, value)
      SILE.process(content)
    end)
  else
    SILE.settings.set(parameter, value)
  end
  if makedefault then
    SILE.settings.declarations[parameter].default = value
    SILE.settings.defaults[parameter] = value
  end
end, "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)")
