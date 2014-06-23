local _type = function(v)
  if type(v) == "number" then return math.floor(v)==v and "integer" or "number" end
  if not(type(v) == "table") then return type(v) end
  return v:prototype()
end

SILE.settings = {
  state = {},
  declarations = {},
  stateQueue = {},
  pushState = function()
    table.insert(SILE.settings.stateQueue, SILE.settings.state);
    SILE.settings.state = std.table.clone(SILE.settings.state);
  end,
  popState = function()
    SILE.settings.state = table.remove(SILE.settings.stateQueue);  
  end,
  declare = function(t)
    SILE.settings.declarations[t.name] = t
    SILE.settings.set(t.name, t.default)
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
  end
}

SILE.settings.declare({
  name = "typesetter.break.widowPenalty", 
  type = "integer",
  default = 150,
  help = "Penalty to be applied to widow lines (at the start of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.break.orphanPenalty",
  type = "integer",
  default = 150,
  help = "Penalty to be applied to orphan lines (at the end of a paragraph)"
})

SILE.settings.declare({
  name = "document.parindent",
  type = "Glue",
  default = SILE.nodefactory.newGlue("20pt"),
  help = "Glue at start of paragraph"
})

SILE.settings.declare({
  name = "document.baselineskip",
  type = "VGlue",
  default = SILE.nodefactory.newVglue("13pt plus 2pt"),
  help = "Leading"
})

SILE.settings.declare({
  name = "document.lineskip",
  type = "VGlue",
  default = SILE.nodefactory.newVglue("2pt"),
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


SILE.registerCommand("set", function(options, content)
  local p = SU.required(options, "parameter", "\\set command")
  local v = SU.required(options, "value", "\\set command")
  local def = SILE.settings.declarations[p]
  if not def then SU.error("Unknown parameter "..p.." in \\set command") end
  if string.match(def.type, "VGlue") then v = SILE.nodefactory.newVglue(v)
  elseif string.match(def.type, "Glue") then v = SILE.nodefactory.newGlue(v) end
  SILE.settings.set(p,v)
end)