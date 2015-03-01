-- Just boxes

_box = std.object {
  _type = "Box",
  height= 0,
  depth= 0,
  width= 0,
  type="special", 
  value=nil,
  migrating=false,
  __tostring = function (s) return s.type end,
  __concat = function (x,y) return tostring(x)..tostring(y) end,
  init = function(self) return self end
}

function _box:outputYourself () SU.error(self.type.." with no output routine") end
function _box:toText ()  return self.type end
function _box:isBox ()   return self.type=="hbox" or self.type == "nnode" or self.type=="vbox" end
function _box:isNnode () return self.type=="nnode" end
function _box:isGlue ()  return self.type == "glue" end
function _box:isVglue ()  return self.type == "vglue" end
function _box:isVbox ()  return self.type == "vbox" end
function _box:isDiscardable () return self:isGlue() or self:isPenalty() end
function _box:isPenalty ()  return self.type == "penalty" end
function _box:isDiscretionary ()  return self.type == "discretionary" end

function _box:isKern ()  return self.type == "kern" end -- Which it never is

-- Hboxes

local _hbox = _box { 
  type = "hbox",
  __tostring = function (this) return "H<" .. tostring(this.width) .. ">^" .. tostring(this.height) .. "-" .. tostring(this.depth) .. "v"; end,
  outputYourself = function(self,typesetter, line)
  if not self.value.glyphString then return end
    local scaledWidth = self.width.length
    if line.ratio < 0 and self.width.shrink > 0 then
      scaledWidth = scaledWidth + self.width.shrink * line.ratio
    elseif line.ratio > 0 and self.width.stretch > 0 then
      scaledWidth = scaledWidth + self.width.stretch * line.ratio
    end
    typesetter.frame:normalize()
    -- Yuck!
    if typesetter.frame.direction == "RTL" then
      typesetter.frame:moveX(scaledWidth)
    end
    SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)

    -- SILE.outputter.debugHbox(typesetter, self, scaledWidth)
    if self.value.glyphNames then
      -- print(self.value.glyphNames[1])
    end
    SILE.outputter.setFont(self.value.options)
    -- SILE.outputter.showGlyphs(self.value.glyphNames)
    SILE.outputter.outputHbox(self.value, self.width.length)
    if typesetter.frame.direction ~= "RTL" then
      typesetter.frame:moveX(scaledWidth)
    end
  end
}

-- Native nodes (clever hboxes)

local _nnode = _hbox {
  type = "nnode",
  text = "",
  language = "",
  pal = nil,
  nodes = {},
  __tostring = function (this) 
  return "N<" .. tostring(this.width) .. ">^" .. this.height .. "-" .. this.depth .. "v(" .. this:toText() .. ")";
end,
  init = function(self)
    if 0 == self.depth then self.depth = math.max(0,unpack(SU.map(function (n) return n.depth end, self.nodes))) end
    if 0 == self.height then self.height = math.max(0,unpack(SU.map(function (n) return n.height end, self.nodes))) end
    if 0 == self.width then self.width = SU.sum(SU.map(function (n) return n.width end, self.nodes)) end
    return self
    end,
  outputYourself = function(self, typesetter, line)
    if self.parent and not self.parent.hyphenated then 
      if not self.parent.used then
        self.parent:outputYourself(typesetter,line)
      end
      self.parent.used = true
      return
    end
    for i, n in ipairs(self.nodes) do n:outputYourself(typesetter, line) end
  end,
  toText = function (self) return self.text end
}

-- Discretionaries

local _disc = _hbox {
  type = "discretionary",
  prebreak = {},
  postbreak = {},
  replacement = {},
  used = 0,
  pbw = nil,
  __tostring = function (this) 
      return "D(" .. SU.concat(this.prebreak,"") .. "|" .. SU.concat(this.postbreak, "") .. ")";
  end,
  toText = function (self) return self.used==1 and "-" or "_" end,
  outputYourself = function(self,typesetter, line)
    if self.used == 1 then
      -- XXX
      for i, n in ipairs(self.prebreak) do n:outputYourself(typesetter,line) end
    end
  end,
  prebreakWidth = function(self)
    -- if self.pbw then return self.pbw end
    local l = 0
    for _,n in pairs(self.prebreak) do l = l + n.width end
    -- self.pbw = l
    return l
  end
}

-- Glue
local _glue = _box {
  _type = "Glue",
  type = "glue",
  __tostring = function (this) return "G<" .. tostring(this.width) .. ">"; end,
  toText = function () return " " end,
  outputYourself = function (self,typesetter, line)
    local scaledWidth = self.width.length
    if line.ratio and line.ratio < 0 and self.width.shrink > 0 then
      scaledWidth = scaledWidth + self.width.shrink * line.ratio
    elseif line.ratio and line.ratio > 0 and self.width.stretch > 0 then
      scaledWidth = scaledWidth + self.width.stretch * line.ratio
    end
    typesetter.frame:moveX(scaledWidth)
  end
}


-- VGlue
local _vglue = _box {
  type = "vglue",
  _type = "VGlue",
  __tostring = function (this) 
      return "VG<" .. tostring(this.height) .. ">";
  end,
  setGlue = function (self,adjustment)  
    -- XXX
    self.height.length = self.height.length + adjustment
    self.height.stretch = 0
    -- self.shrink = 0
  end,
  outputYourself = function (self,typesetter, line)
    typesetter.frame:moveY(line.depth + line.height)
  end
}

-- Penalties
local _penalty = _box {
  type = "penalty",
  width = SILE.length.new({}),
  flagged = 0,
  penalty = 0,
  __tostring = function (this) 
      return "P(" .. this.flagged .. "|" .. this.penalty .. ")";
  end,
  outputYourself = function() end,
  toText = function() return "(!)" end
}

-- Vbox
local _vbox = _box {
  type = "vbox",
  nodes = {},
  __tostring = function (this) 
      return "VB<" .. tostring(this.height) .. "|" .. this:toText() .. "v"..tostring(this.depth)..")";
  end,
  init = function (self)
    self.depth = 0
    self.height = 0
    for i=1,#(self.nodes) do local n = self.nodes[i]
      local h = type(n.height) == "table" and n.height.length or n.height
      local d = type(n.depth) == "table" and n.depth.length or n.depth
      self.depth = (d > self.depth) and d or self.depth
      self.height = (h > self.height) and h or self.height
    end
    self.depth = SILE.length.new({length = self.depth })
    self.height = SILE.length.new({length = self.height })
    return self
  end,
  toText = function (self) 
    return "VB[" .. SU.concat(SU.map(function (n) return n:toText().."" end, self.nodes), "") .. "]" 
  end,
  outputYourself = function(self, typesetter, line)
    typesetter.frame:moveY(self.height)  
    local initial = true
    for i,node in pairs(self.nodes) do
      if initial and (node:isGlue() or node:isPenalty()) then
        -- do nothing
      else
        initial = false
        node:outputYourself(typesetter, self)
      end
    end
    typesetter.frame:moveY(self.depth)
    typesetter.frame:newLine()
  end  
}

SILE.nodefactory = {}

function SILE.nodefactory.newHbox(spec)   return _hbox(spec) end
function SILE.nodefactory.newNnode(spec)  return _nnode(spec):init() end
function SILE.nodefactory.newDisc(spec)   return _disc(spec) end
function SILE.nodefactory.newGlue(spec)
  if type(spec) == "table" then return _glue(spec) end
  if type(spec) == "string" then return _glue({width = SILE.length.parse(spec)}) end
  SU.error("Unparsable glue spec "..spec)
end
function SILE.nodefactory.newVglue(spec)
  if type(spec) == "table" then return _vglue(spec) end
  if type(spec) == "string" then return _vglue({height = SILE.length.parse(spec)}) end
  SU.error("Unparsable glue spec "..spec)
end
function SILE.nodefactory.newPenalty(spec)  return _penalty(spec) end
function SILE.nodefactory.newDiscretionary(spec)  return _disc(spec) end
function SILE.nodefactory.newVbox(spec)  return _vbox(spec):init() end

-- This infinity needs to be smaller than an actual infinity but bigger than the infinite stretch
-- added by the typesetter.
local inf = 100000 
SILE.nodefactory.zeroGlue = SILE.nodefactory.newGlue({width = SILE.length.new({length = 0})})
SILE.nodefactory.hfillGlue = SILE.nodefactory.newGlue({width = SILE.length.new({length = 0, stretch = inf})})
SILE.nodefactory.vfillGlue = SILE.nodefactory.newVglue({height = SILE.length.new({length = 0, stretch = inf})})
SILE.nodefactory.hssGlue = SILE.nodefactory.newGlue({width = SILE.length.new({length = 0, stretch = inf, shrink = inf})})
SILE.nodefactory.vssGlue = SILE.nodefactory.newVglue({height = SILE.length.new({length = 0, stretch = inf, shrink = inf})})
SILE.nodefactory.zeroHbox = SILE.nodefactory.newHbox({ width = SILE.length.new({length = 0, stretch = 0, shrink = 0}), value = {glyph = 0} });
SILE.nodefactory.zeroVglue = SILE.nodefactory.newVglue({height = SILE.length.new({length = 0, stretch = 0, shrink = 0}) })
return SILE.nodefactory