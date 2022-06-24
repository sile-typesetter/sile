local deprecator = function ()
  SU.deprecated("SILE.settings.*", "SILE.settings:*", "0.13.0", "0.14.0")
end

local settings = pl.class()

function settings:_init()

  self.state = {}
  self.declarations = {}
  self.stateQueue = {}
  self.defaults = {}

  self:declare({
    parameter = "document.language",
    type = "string",
    default = "en",
    help = "Locale for localized language support"
  })

  self:declare({
    parameter = "document.parindent",
    type = "glue",
    default = SILE.nodefactory.glue("20pt"),
    help = "Glue at start of paragraph"
  })

  self:declare({
    parameter = "document.baselineskip",
    type = "vglue",
    default = SILE.nodefactory.vglue("1.2em plus 1pt"),
    help = "Leading"
  })

  self:declare({
    parameter = "document.lineskip",
    type = "vglue",
    default = SILE.nodefactory.vglue("1pt"),
    help = "Leading"
  })

  self:declare({
    parameter = "document.parskip",
    type = "vglue",
    default = SILE.nodefactory.vglue("0pt plus 1pt"),
    help = "Leading"
  })

  self:declare({
    parameter = "document.spaceskip",
    type = "length or nil",
    default = nil,
    help = "The length of a space (if nil, then measured from the font)"
  })

  self:declare({
    parameter = "document.rskip",
    type = "glue or nil",
    default = nil,
    help = "Skip to be added to right side of line"
  })

  self:declare({
    parameter = "document.lskip",
    type = "glue or nil",
    default = nil,
    help = "Skip to be added to left side of line"
  })

  self:declare({
    parameter = "document.zenkakuchar",
    default = "あ",
    type = "string",
    help = "The character measured to determine the length of a zenkaku width (全角幅)"
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
      self:temporarily(function()
        self:set(parameter, value, makedefault, reset)
        SILE.process(content)
      end)
    else
      self:set(parameter, value, makedefault, reset)
    end
  end, "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)")

end

function settings:pushState ()
  if not self then deprecator() end
  table.insert(self.stateQueue, self.state)
  self.state = pl.tablex.copy(self.state)
end

function settings:popState ()
  if not self then deprecator() end
  self.state = table.remove(self.stateQueue)
end

function settings:declare (spec)
  if not spec then deprecator() end
  if spec.name then
    SU.deprecated("'name' argument of SILE.settings:declare", "'parameter' argument of SILE.settings:declare", "0.10.10", "0.11.0")
  end
  self.declarations[spec.parameter] = spec
  self:set(spec.parameter, spec.default, true)
end

function settings:reset ()
  if not self then deprecator() end
  for k,_ in pairs(self.state) do
    self:set(k, self.defaults[k])
  end
end

function settings:toplevelState ()
  if not self then deprecator() end
  if #self.stateQueue ~= 0 then
    for k,_ in pairs(self.state) do
      self:set(k, self.stateQueue[1][k])
    end
  end
end

function settings:get (parameter)
  if not parameter then deprecator() end
  if not self.declarations[parameter] then
    SU.error("Undefined setting '"..parameter.."'")
  end
  if type(self.state[parameter]) ~= "nil" then
    return self.state[parameter]
  else
    return self.defaults[parameter]
  end
end

function settings:set (parameter, value, makedefault, reset)
  if type(self) ~= "table" then deprecator() end
  if not self.declarations[parameter] then
    SU.error("Undefined setting '"..parameter.."'")
  end
  if reset then
    if makedefault then
      SU.error("Can't set a new default and revert to and old default setting at the same time!")
    end
    value = self.defaults[parameter]
  else
    value = SU.cast(self.declarations[parameter].type, value)
  end
  self.state[parameter] = value
  if makedefault then
    self.defaults[parameter] = value
  end
end

function settings:temporarily (func)
  if not func then deprecator() end
  self:pushState()
  func()
  self:popState()
end

function settings:wrap () -- Returns a closure which applies the current state, later
  if not self then deprecator() end
  local clSettings = pl.tablex.copy(self.state)
  return function(content)
    table.insert(self.stateQueue, self.state)
    self.state = clSettings
    SILE.process(content)
    self:popState()
  end
end

return settings
