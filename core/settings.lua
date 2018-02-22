local _type = function(v)
  if type(v) == "number" then return math.floor(v)==v and "integer" or "number" end
  if not(type(v) == "table") then return type(v) end
  return v:prototype()
end

SILE.settings = {
  state = {},
  declarations = {},
  stateQueue = {},
  defaults = {},
  pushState = function()
    table.insert(SILE.settings.stateQueue, SILE.settings.state)
    SILE.settings.state = std.table.clone(SILE.settings.state)
  end,
  popState = function()
    SILE.settings.state = table.remove(SILE.settings.stateQueue)
  end,
  declare = function(t)
    SILE.settings.declarations[t.name] = t
    SILE.settings.set(t.name, t.default)
    SILE.settings.defaults[t.name] = t.default
  end,
  reset = function(t)
    for k,_ in pairs(SILE.settings.state) do
      SILE.settings.set(k,SILE.settings.defaults[k])
    end
  end,
  get = function(name)
    if not SILE.settings.declarations[name] then
      SU.error("Undefined setting '"..name.."'")
    end
    return SILE.settings.state[name]
  end,
  set = function(name, value)
    if not SILE.settings.declarations[name] then
      SU.error("Undefined setting '"..name.."'")
    end
    local t = _type(value)
    local wantedType = SILE.settings.declarations[name].type
    if not (string.find(wantedType, t) == 1 or string.find(wantedType, "or "..t) ) then
      SU.error("Setting "..name.." must be of type "..wantedType..", not "..t.." "..value.."\n"..name..": "..SILE.settings.declarations[name].help)
    end
    SILE.settings.state[name] = value
  end,
  temporarily = function(f)
    SILE.settings.pushState()
    f()
    SILE.settings.popState()
  end,
  wrap = function() -- Returns a closure which applies the current state, later
    local clSettings = std.table.clone(SILE.settings.state)
    return function(f)
      table.insert(SILE.settings.stateQueue, SILE.settings.state)
      SILE.settings.state = clSettings
      SILE.process(f)
      SILE.settings.popState()
    end
  end,

}

SILE.settings.declare({
  name = "document.parindent",
  type = "Glue",
  default = SILE.nodefactory.newGlue("20pt"),
  help = "Glue at start of paragraph"
})

SILE.settings.declare({
  name = "document.baselineskip",
  type = "VGlue",
  default = SILE.nodefactory.newVglue("1.2em plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.lineskip",
  type = "VGlue",
  default = SILE.nodefactory.newVglue("1pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.parskip",
  type = "VGlue",
  default = SILE.nodefactory.newVglue("0pt plus 1pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.spaceskip",
  type = "Length or nil",
  default = nil,
  help = "The length of a space (if nil, then measured from the font)"
})

SILE.settings.declare({
  name = "document.rskip",
  type = "Glue or nil",
  default = nil,
  help = "Skip to be added to right side of line"
})

SILE.settings.declare({
  name = "document.lskip",
  type = "Glue or nil",
  default = nil,
  help = "Skip to be added to left side of line"
})

local function toboolean(v)
  if type(v) == "boolean" then return v end
  if type(v) == "string" then return v == "true" end
  if type(v) == "number" or type(v) == "integer" then return not (v == 0) end
  return not not v
end

SILE.registerCommand("set", function(options, content)
  local p = SU.required(options, "parameter", "\\set command")
  local v = options.value -- could be nil!
  local def = SILE.settings.declarations[p]
  if not def then SU.error("Unknown parameter "..p.." in \\set command") end
  if     string.match(def.type, "nil") and type(v) == "nil" then -- ok
  elseif  string.match(def.type, "integer") then v = tonumber(v)
  elseif  string.match(def.type, "number") then v = tonumber(v)
  elseif  string.match(def.type, "boolean") then v = toboolean(v)
  elseif  string.match(def.type, "Length") then v = SILE.length.parse(v)
  elseif string.match(def.type, "VGlue") then v = SILE.nodefactory.newVglue(v)
  elseif string.match(def.type, "Glue") then v = SILE.nodefactory.newGlue(v)
  elseif string.match(def.type, "Kern") then v = SILE.nodefactory.newKern(v) end
  if content and (type(content) == "function" or content[1]) then
    SILE.settings.temporarily(function()
      SILE.settings.set(p,v)
      SILE.process(content)
    end)
  else
    SILE.settings.set(p,v)
  end
end, "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)")
