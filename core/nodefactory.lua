-- Just boxes

_box = {height= 0, depth= 0, width= 0, type="special", value=nil }
_box.mt = {__tostring = function (s) return s.type end, __index = _box , __concat = function (x,y) return tostring(x)..tostring(y) end }
setmetatable(_box, _box.mt)

function _box:outputYourself () error(self.type.." with no output routine") end
function _box:toText ()  return self.type end
function _box:isBox ()   return self.type=="hbox" or self.type == "nnode" end
function _box:isNnode () return self.type=="nnode" end
function _box:isGlue ()  return self.type == "glue" end
function _box:isVglue ()  return self.type == "vglue" end
function _box:isVbox ()  return self.type == "vbox" end

function _box:isPenalty ()  return self.type == "penalty" end
function _box:isDiscretionary ()  return self.type == "discretionary" end

function _box:isKern ()  return self.type == "kern" end -- Which it never is

function _box:init () end

-- Hboxes

local _hbox = SU.inherit(_box)
_hbox.type = "hbox"
getmetatable(_hbox).__tostring = function (this) 
	return "H<" .. tostring(this.width) .. ">^" .. this.height .. "-" .. this.depth .. "v";
end
function _hbox:outputYourself(typesetter, line)
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

-- Native nodes (clever hboxes)

local _nnode = SU.inherit(_hbox)
_nnode.type = "nnode"
_nnode.text = ""
_nnode.language = ""
_nnode.pal = nil
_nnode.nodes = {}
function _nnode:outputYourself(typesetter, line)
	for i, n in ipairs(self.nodes) do n:outputYourself(typesetter, line) end
end
function _nnode:toText() return self.text end
getmetatable(_nnode).__tostring = function (this) 
	return "N<" .. tostring(this.width) .. ">^" .. this.height .. "-" .. this.depth .. "v(" .. this:toText() .. ")";
end
function _nnode:init()
    if 0 == self.depth then self.depth = math.max(0,unpack(SU.map(function (n) return n.depth end, self.nodes))) end
    if 0 == self.height then self.height = math.max(0,unpack(SU.map(function (n) return n.height end, self.nodes))) end
    if 0 == self.width then self.width = SU.sum(SU.map(function (n) return n.width end, self.nodes)) end
end
-- Discretionaries

local _disc = SU.inherit(_hbox)
_disc.type = "discretionary"
_disc.prebreak = {}
_disc.postbreak = {}
_disc.replacement = {}
_disc.used = 0
_disc.pbw = nil
getmetatable(_disc).__tostring = function (this) 
    return "D(" .. SU.concat(this.prebreak,"") .. "|" .. SU.concat(this.postbreak, "") .. ")";
end
function _disc:toText() return self.used==1 and "-" or "_" end
function _disc:outputYourself(typesetter, line)
  if self.used == 1 then
    -- XXX
    for i, n in ipairs(self.prebreak) do n:outputYourself(typesetter,line) end
  end
end
function _disc:prebreakWidth()
  -- if self.pbw then return self.pbw end
  local l = 0
  for _,n in pairs(self.prebreak) do l = l + n.width end
  -- self.pbw = l
  return l
end

-- Glue
local _glue = SU.inherit(_box)
_glue.type = "glue"
getmetatable(_glue).__tostring = function (this) return "G<" .. tostring(this.width) .. ">"; end
function _glue:toText() return " " end
function _glue:outputYourself(typesetter, line)
    local scaledWidth = self.width.length
    if line.ratio < 0 and self.width.shrink > 0 then
      scaledWidth = scaledWidth + self.width.shrink * line.ratio
    elseif line.ratio > 0 and self.width.stretch > 0 then
      scaledWidth = scaledWidth + self.width.stretch * line.ratio
    end
    typesetter.state.cursorX = typesetter.state.cursorX + scaledWidth
end
-- VGlue
local _vglue = SU.inherit(_box)
_vglue.type = "vglue"
getmetatable(_vglue).__tostring = function (this) 
    return "VG<" .. tostring(this.height) .. ">";
end
function _vglue:setGlue(adjustment)
    -- XXX
    self.height.length = self.height.length + adjustment
    self.height.stretch = 0
    -- self.shrink = 0
end

function _vglue:outputYourself(typesetter, line)
    typesetter.state.cursorY = typesetter.state.cursorY + line.depth + line.height.length;
end
-- Penalties
local _penalty = SU.inherit(_box)
_penalty.type = "penalty"
_penalty.width = SILE.length.new({})
_penalty.flagged = 0
_penalty.penalty = 0
getmetatable(_penalty).__tostring = function (this) 
    return "P(" .. this.flagged .. "|" .. this.penalty .. ")";
end
function _penalty:outputYourself() end
function _penalty:toText ()  return "(!)" end

-- Vbox
local _vbox = SU.inherit(_box)
_vbox.type = "vbox"
_vbox.nodes = {}
getmetatable(_vbox).__tostring = function (this) 
    return "V<" .. tostring(this.height) .. "|" .. this:toText() .. ")";
end
function _vbox:toText() return "VB[" .. SU.concat(SU.map(function (n) return n:toText() end, self.nodes), "") .. "]" end
function _vbox:init()
  d = SU.map(function (n) return tonumber(n.depth) or 0 end, self.nodes)
  h = SU.map(function (n) return tonumber(n.height) or 0 end, self.nodes)
  self.depth = SILE.length.new({length = math.max(unpack(d)) })
  self.height = SILE.length.new({length = math.max(unpack(h)) })
end

function _vbox:outputYourself(typesetter, line)
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

local nodefactory = {}

function nodefactory.newHbox(spec)   return SU.inherit(_hbox,spec) end
function nodefactory.newNnode(spec)  return SU.inherit(_nnode,spec) end
function nodefactory.newDisc(spec)   return SU.inherit(_disc,spec) end
function nodefactory.newGlue(spec)   return SU.inherit(_glue,spec) end
function nodefactory.newVglue(spec)  return SU.inherit(_vglue,spec) end
function nodefactory.newPenalty(spec)  return SU.inherit(_penalty,spec) end
function nodefactory.newDiscretionary(spec)  return SU.inherit(_disc,spec) end
function nodefactory.newVbox(spec)  return SU.inherit(_vbox,spec) end

return nodefactory