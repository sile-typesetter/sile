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
    if spec.name then
      SU.deprecated("'name' argument of SILE.settings.declare", "'parameter' argument of SILE.settings.declare", "0.10.10", "0.11.0")
    end
    SILE.settings.declarations[spec.parameter] = spec
    SILE.settings.set(spec.parameter, spec.default, true)
  end,
  reset = function()
    for k,_ in pairs(SILE.settings.state) do
      SILE.settings.set(k, SILE.settings.defaults[k])
    end
  end,
  toplevelState = function()
    if #SILE.settings.stateQueue ~= 0 then
      for k,_ in pairs(SILE.settings.state) do
        SILE.settings.set(k, SILE.settings.stateQueue[1][k])
      end
    end
  end,
  get = function(parameter)
    if not SILE.settings.declarations[parameter] then
      SU.error("Undefined setting '"..parameter.."'")
    end
    if type(SILE.settings.state[parameter]) ~= "nil" then
      return SILE.settings.state[parameter]
    else
      return SILE.settings.defaults[parameter]
    end
  end,
  set = function(parameter, value, makedefault, reset)
    if not SILE.settings.declarations[parameter] then
      SU.error("Undefined setting '"..parameter.."'")
    end
    if reset then
      if makedefault then
        SU.error("Can't set a new default and revert to and old default setting at the same time!")
      end
      value = SILE.settings.defaults[parameter]
    else
      value = SU.cast(SILE.settings.declarations[parameter].type, value)
    end
    SILE.settings.state[parameter] = value
    if makedefault then
      SILE.settings.defaults[parameter] = value
    end
  end,
  temporarily = function(func)
    SILE.settings.pushState()
    func()
    SILE.settings.popState()
  end,
  wrap = function() -- Returns a closure which applies the current state, later
    local clSettings = pl.tablex.copy(SILE.settings.state)
    return function(content)
      table.insert(SILE.settings.stateQueue, SILE.settings.state)
      SILE.settings.state = clSettings
      SILE.process(content)
      SILE.settings.popState()
    end
  end,
}

SILE.settings.declare({
  parameter = "document.language",
  type = "string",
  default = "en",
  help = "Locale for localized language support"
})

SILE.settings.declare({
  parameter = "document.parindent",
  type = "glue",
  default = SILE.nodefactory.glue("20pt"),
  help = "Glue at start of paragraph"
})

SILE.settings.declare({
  parameter = "document.baselineskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("1.2em plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  parameter = "document.lineskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("1pt"),
  help = "Leading"
})

SILE.settings.declare({
  parameter = "document.parskip",
  type = "vglue",
  default = SILE.nodefactory.vglue("0pt plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  parameter = "document.spaceskip",
  type = "length or nil",
  default = nil,
  help = "The length of a space (if nil, then measured from the font)"
})

SILE.settings.declare({
  parameter = "document.rskip",
  type = "glue or nil",
  default = nil,
  help = "Skip to be added to right side of line"
})

SILE.settings.declare({
  parameter = "document.lskip",
  type = "glue or nil",
  default = nil,
  help = "Skip to be added to left side of line"
})

SILE.registerCommand("set", function(options, content)
  local parameter = SU.required(options, "parameter", "\\set command")
  local makedefault = SU.boolean(options.makedefault, false)
  local reset = SU.boolean(options.reset, false)
  local value = options.value
  if content and (type(content) == "function" or content[1]) then
    if makedefault then
      SU.warn("Are you sure meant to set default settings *and* pass content to ostensibly apply them to temporarily?")
    end
    SILE.settings.temporarily(function()
      SILE.settings.set(parameter, value, makedefault, reset)
      SILE.process(content)
    end)
  else
    SILE.settings.set(parameter, value, makedefault, reset)
  end
end, "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)")
