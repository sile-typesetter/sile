-- Just boxes

_box = std.object {
  height= 0, 
  depth= 0, 
  width= 0, 
  type="special", 
  value=nil,
  __tostring = function (s) return s.type end,
  __concat = function (x,y) return tostring(x)..tostring(y) end,
  init = function(self) return self end
}

function _box:outputYourself () SU.error(self.type.." with no output routine") end
function _box:toText ()  return self.type end
function _box:isBox ()   return self.type=="hbox" or self.type == "nnode" end
function _box:isNnode () return self.type=="nnode" end
function _box:isGlue ()  return self.type == "glue" end
function _box:isVglue ()  return self.type == "vglue" end
function _box:isVbox ()  return self.type == "vbox" end

function _box:isPenalty ()  return self.type == "penalty" end
function _box:isDiscretionary ()  return self.type == "discretionary" end

function _box:isKern ()  return self.type == "kern" end -- Which it never is

-- Hboxes

local _hbox = _box { 
  type = "hbox",
  __tostring = function (this) return "H<" .. tostring(this.width) .. ">^" .. this.height .. "-" .. this.depth .. "v"; end,
  outputYourself = function(self,typesetter, line)
  if not self.value.glyphString then return end
    local scaledWidth = self.width.length
    if line.ratio < 0 and self.width.shrink > 0 then
      scaledWidth = scaledWidth + self.width.shrink * line.ratio
    elseif line.ratio > 0 and self.width.stretch > 0 then
      scaledWidth = scaledWidth + self.width.stretch * line.ratio
    end
    if (type(typesetter.state.cursorY)) == "table" then typesetter.state.cursorY  =typesetter.state.cursorY.length end
    if (type(typesetter.state.cursorX)) == "table" then typesetter.state.cursorX  =typesetter.state.cursorX.length end
    SILE.outputter.moveTo(typesetter.state.cursorX, typesetter.state.cursorY)
    SILE.outputter.showGlyphString(self.value.font, self.value.glyphString)
    -- XXX should be a property of the frame
    typesetter.state.cursorX = typesetter.state.cursorX + scaledWidth
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
  type = "glue",
  __tostring = function (this) return "G<" .. tostring(this.width) .. ">"; end,
  toText = function () return " " end,
  outputYourself = function (self,typesetter, line)
    local scaledWidth = self.width.length
    if line.ratio < 0 and self.width.shrink > 0 then
      scaledWidth = scaledWidth + self.width.shrink * line.ratio
    elseif line.ratio > 0 and self.width.stretch > 0 then
      scaledWidth = scaledWidth + self.width.stretch * line.ratio
    end
    typesetter.state.cursorX = typesetter.state.cursorX + scaledWidth
  end
}


-- VGlue
local _vglue = _box {
  type = "vglue",
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
    typesetter.state.cursorY = typesetter.state.cursorY + line.depth + line.height.length;
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
      return "VB<" .. tostring(this.height) .. "|" .. this:toText() .. ")";
  end,
  init = function (self)
    d = SU.map(function (n) return tonumber(n.depth) or 0 end, self.nodes)
    h = SU.map(function (n) return tonumber(n.height) or 0 end, self.nodes)
    self.depth = SILE.length.new({length = math.max(unpack(d)) })
    self.height = SILE.length.new({length = math.max(unpack(h)) })
    return self
  end,
  toText = function (self) 
    return "VB[" .. SU.concat(SU.map(function (n) return n:toText() end, self.nodes), "") .. "]" 
  end,
  outputYourself = function(self, typesetter, line)
    typesetter.state.cursorY =  typesetter.state.cursorY + line.height
    local initial = true
    for i,node in pairs(self.nodes) do
      if initial and (node:isGlue() or node:isPenalty()) then
        -- do nothing
      else
        initial = false
        node:outputYourself(typesetter, line)
      end
    end
    typesetter.state.cursorY = typesetter.state.cursorY + line.depth;
    typesetter.state.cursorX = typesetter.frame:left(); -- XXX bidi
  end  
}

local nodefactory = {}

function nodefactory.newHbox(spec)   return _hbox(spec) end
function nodefactory.newNnode(spec)  return _nnode(spec):init() end
function nodefactory.newDisc(spec)   return _disc(spec) end
function nodefactory.newGlue(spec)   return _glue(spec) end
function nodefactory.newVglue(spec)  return _vglue(spec) end
function nodefactory.newPenalty(spec)  return _penalty(spec) end
function nodefactory.newDiscretionary(spec)  return _disc(spec) end
function nodefactory.newVbox(spec)  return _vbox(spec):init() end

return nodefactory