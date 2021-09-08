local nodefactory = {}

-- This infinity needs to be smaller than an actual infinity but bigger than the infinite stretch
-- added by the typesetter. See https://github.com/sile-typesetter/sile/issues/227
local infinity = SILE.measurement(1e13)

-- NOTE: Normally self:super() would be the way to recurse _init() functions,
-- but due to a Penlight bug this only works for one level. This setup has
-- several levels, and also customizes what happens at each level so we are
-- directly calling back into the _init() functions we want.

local function _maxnode (nodes, dim)
  local dims = SU.map(function (node)
    -- TODO there is a bug here because we shouldn't need to cast to lengths,
    -- somebody is setting a height as a number value (test in Lua 5.1)
    -- return node[dim]
    return SU.cast("length", node[dim])
  end, nodes)
  return SU.max(SILE.length(0), pl.utils.unpack(dims))
end

local _dims = pl.Set { "width", "height", "depth" }

nodefactory.box = pl.class({
    type = "special",
    height = nil,
    depth = nil,
    width = nil,
    misfit = false,
    explicit = false,
    discardable = false,
    value = nil,
    _default_length = "width",

    _init = function (self, spec)
      if type(spec) == "string"
        or type(spec) == "number"
        or SU.type(spec) == "measurement"
        or SU.type(spec) == "length" then
        self[self._default_length] = SU.cast("length", spec)
      elseif SU.type(spec) == "table" then
        if spec._tospec then spec = spec:_tospec() end
        for k, v in pairs(spec) do
          self[k] = _dims[k] and SU.cast("length", v) or v
        end
      elseif type(spec) ~= "nil" and SU.type(spec) ~= self.type then
        SU.error("Unimplemented, creating " .. self.type .. " node from " .. SU.type(spec), 1)
      end
      for dim in pairs(_dims) do
        if not self[dim] then self[dim] = SILE.length() end
      end
      self["is_"..self.type] = true
      self.is_box = self.is_hbox or self.is_vbox or self.is_zerohbox or self.is_alternative or self.is_nnode
      self.is_zero = self.is_zerohbox or self.is_zerovglue
      if self.is_migrating then self.is_hbox, self.is_box = true, true end
    end,

    -- De-init instances by shallow copying properties and removing meta table
    _tospec = function (self)
      return pl.tablex.copy(self)
    end,

    tostring = function (self)
      return  self:__tostring()
    end,

    __tostring = function (self)
      return self.type
    end,

    __concat = function (a, b) return tostring(a) .. tostring(b) end,

    absolute = function (self)
      local clone = nodefactory[self.type](self:_tospec())
      for dim in pairs(_dims) do
        clone[dim] = self[dim]:absolute()
      end
      if self.nodes then
        clone.nodes = pl.tablex.map_named_method("absolute", self.nodes)
      end
      return clone
    end,

    lineContribution = function (self)
      -- Regardless of the orientations, "width" is always in the
      -- writingDirection, and "height" is always in the "pageDirection"
      return self.misfit and self.height or self.width
    end,

    outputYourself = function (self)
      SU.error(self.type.." with no output routine")
    end,

    toText = function (self)
      return self.type
    end,

    isBox = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "hbox" or self.type == "zerohbox" or self.type == "alternative" or self.type == "nnode" or self.type == "vbox"
    end,

    isNnode = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type=="nnode"
    end,

    isGlue = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "glue"
    end,

    isVglue = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "vglue"
    end,

    isZero = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "zerohbox" or self.type == "zerovglue"
    end,

    isUnshaped = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "unshaped"
    end,

    isAlternative = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "alternative"
    end,

    isVbox = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "vbox"
    end,

    isInsertion = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "insertion"
    end,

    isMigrating = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.migrating
    end,

    isPenalty = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "penalty"
    end,

    isDiscretionary = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "discretionary"
    end,

    isKern = function (self)
      SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
      return self.type == "kern"
    end

  })

nodefactory.hbox = pl.class({
    _base = nodefactory.box,
    type = "hbox",

    __tostring = function (self)
      return "H<" .. self.width .. ">^" .. self.height .. "-" .. self.depth .. "v"
    end,

    scaledWidth = function (self, line)
      return SU.rationWidth(self:lineContribution(), self.width, line.ratio)
    end,

    outputYourself = function (self, typesetter, line)
      local outputWidth = self:scaledWidth(line)
      if not self.value.glyphString then return end
      if typesetter.frame:writingDirection() == "RTL" then
        typesetter.frame:advanceWritingDirection(outputWidth)
      end
      SILE.outputter:setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
      SILE.outputter:setFont(self.value.options)
      SILE.outputter:drawHbox(self.value, outputWidth)
      if typesetter.frame:writingDirection() ~= "RTL" then
        typesetter.frame:advanceWritingDirection(outputWidth)
      end
    end

  })

nodefactory.zerohbox = pl.class({
    _base = nodefactory.hbox,
    type = "zerohbox",
    value = { glyph = 0 }
  })

nodefactory.nnode = pl.class({
    _base = nodefactory.hbox,
    type = "nnode",
    language = "",
    pal = nil,
    nodes = {},

    _init = function (self, spec)
      nodefactory.box._init(self, spec)
      if 0 == self.depth:tonumber() then self.depth = _maxnode(self.nodes, "depth")  end
      if 0 == self.height:tonumber() then self.height = _maxnode(self.nodes, "height") end
      if 0 == self.width:tonumber() then self.width = SU.sum(SU.map(function (node) return node.width end, self.nodes)) end
    end,

    __tostring = function (self)
      return "N<" .. self.width .. ">^" .. self.height .. "-" .. self.depth .. "v(" .. self:toText() .. ")";
    end,

    absolute = function (self)
      return self
    end,

    outputYourself = function (self, typesetter, line)
      if self.parent and not self.parent.hyphenated then
        if not self.parent.used then
          self.parent:outputYourself(typesetter, line)
        end
        self.parent.used = true
        return
      end
      for _, node in ipairs(self.nodes) do node:outputYourself(typesetter, line) end
    end,

    toText = function (self)
      return self.text
    end

  })

nodefactory.unshaped = pl.class({
    _base = nodefactory.nnode,
    type = "unshaped",
    width = nil,

    _init = function (self, spec)
      nodefactory.nnode._init(self, spec)
      self.width = nil
    end,

    __tostring = function (self)
      return "U(" .. self:toText() .. ")";
    end,

    __index = function (_, k)
      if k == "width" then SU.error("Can't get width of unshaped node", true) end
    end,

    shape = function (self)
      local node =  SILE.shaper:createNnodes(self.text, self.options)
      for i=1, #node do
        node[i].parent = self.parent
      end
      return node
    end,

    outputYourself = function (_)
      SU.error("An unshaped node made it to output", true)
    end

  })

nodefactory.discretionary = pl.class({
    _base = nodefactory.hbox,
    type = "discretionary",
    prebreak = {},
    postbreak = {},
    replacement = {},
    used = false,
    prebw = nil,

    __tostring = function (self)
      return "D(" .. SU.concat(self.prebreak, "") .. "|" .. SU.concat(self.postbreak, "") .."|" .. SU.concat(self.replacement, "") .. ")";
    end,

    toText = function (self)
      return self.used and "-" or "_"
    end,

    outputYourself = function (self, typesetter, line)
      if self.used then
        local i = 1
        while (line.nodes[i].is_glue and line.nodes[i].value == "lskip")
          or line.nodes[i].type == "zerohbox" do
          i = i + 1
        end
        if (line.nodes[i] == self) then
          for _, node in ipairs(self.postbreak) do node:outputYourself(typesetter, line) end
        else
          for _, node in ipairs(self.prebreak) do node:outputYourself(typesetter, line) end
        end
      else
        for _, node in ipairs(self.replacement) do node:outputYourself(typesetter, line) end
      end
    end,

    prebreakWidth = function (self)
      if self.prebw then return self.prebw end
      self.prebw = SILE.length()
      for _, node in ipairs(self.prebreak) do self.prebw:___add(node.width) end
      return self.prebw
    end,

    postbreakWidth = function (self)
      if self.postbw then return self.postbw end
      self.postbw = SILE.length()
      for _, node in ipairs(self.postbreak) do self.pastbw:___add(node.width) end
      return self.postbw
    end,

    replacementWidth = function (self)
      if self.replacew then return self.replacew end
      self.replacew = SILE.length()
      for _, node in ipairs(self.replacement) do self.replacew:___add(node.width) end
      return self.replacew
    end,

    prebreakHeight = function (self)
      if self.prebh then return self.prebh end
      self.prebh = _maxnode(self.prebreak, "height")
      return self.prebh
    end,

    postbreakHeight = function (self)
      if self.postbh then return self.postbh end
      self.postbh = _maxnode(self.postbreak, "height")
      return self.postbh
    end,

    replacementHeight = function (self)
      if self.replaceh then return self.replaceh end
      self.replaceh = _maxnode(self.replacement, "height")
      return self.replaceh
    end

  })

nodefactory.alternative = pl.class({
    _base = nodefactory.hbox,
    type = "alternative",
    options = {},
    selected = nil,

    __tostring = function (self)
      return "A(" .. SU.concat(self.options, " / ") .. ")"
    end,

    minWidth = function (self)
      local minW = function (a, b) return SU.min(a.width, b.width) end
      return pl.tablex.reduce(minW, self.options)
    end,

    deltas = function (self)
      local minWidth = self:minWidth()
      local rv = {}
      for i = 1, #self.options do rv[#rv+1] = self.options[i].width - minWidth end
      return rv
    end,

    outputYourself = function (self, typesetter, line)
      if self.selected then
        self.options[self.selected]:outputYourself(typesetter, line)
      end
    end

  })

nodefactory.glue = pl.class({
    _base = nodefactory.box,
    type = "glue",
    discardable = true,

    __tostring = function (self)
      return (self.explicit and "E:" or "") .. "G<" .. self.width .. ">"
    end,

    toText = function () return " " end,

    outputYourself = function (self, typesetter, line)
      local outputWidth = SU.rationWidth(self.width:absolute(), self.width:absolute(), line.ratio)
      typesetter.frame:advanceWritingDirection(outputWidth)
    end

  })

nodefactory.hfillglue = pl.class({
    _base = nodefactory.glue,

    _init = function (self, spec)
      self.width = SILE.length(0, infinity)
      nodefactory.glue._init(self, spec)
    end
  })

nodefactory.hssglue = pl.class({
  -- possible bug, deprecated constructor actually used vglue for this
    _base = nodefactory.glue,

    _init = function (self, spec)
      self.width = SILE.length(0, infinity, infinity)
      nodefactory.glue._init(self, spec)
    end
  })

nodefactory.kern = pl.class({
    _base = nodefactory.glue,
    type = "kern",
    discardable = false,

    __tostring = function (self)
      return "K<" .. self.width .. ">"
    end,
  })

nodefactory.vglue = pl.class({
    _base = nodefactory.box,
    type = "vglue",
    discardable = true,
    _default_length = "height",
    adjustment = nil,

    _init = function (self, spec)
      self.adjustment = SILE.measurement()
      nodefactory.box._init(self, spec)
    end,

    __tostring = function (self)
      return (self.explicit and "E:" or "") .. "VG<" .. self.height .. ">";
    end,

    adjustGlue = function (self, adjustment)
      self.adjustment = adjustment
    end,

    outputYourself = function (self, typesetter, line)
      typesetter.frame:advancePageDirection(line.height:absolute() + line.depth:absolute() + self.adjustment)
    end,

    unbox = function (self) return { self } end

  })

nodefactory.vfillglue = pl.class({
    _base = nodefactory.vglue,

    _init = function (self, spec)
      self.height = SILE.length(0, infinity)
      nodefactory.vglue._init(self, spec)
    end
  })

nodefactory.vssglue = pl.class({
    _base = nodefactory.vglue,
    height = SILE.length(0, infinity, infinity)
  })

nodefactory.zerovglue = pl.class({
    _base = nodefactory.vglue
  })

nodefactory.vkern = pl.class({
    _base = nodefactory.vglue,
    discardable = false,

    __tostring = function (self)
      return "VK<" .. self.height .. ">"
    end

  })

nodefactory.penalty = pl.class({
    _base = nodefactory.box,
    type = "penalty",
    discardable = true,
    penalty = 0,

    _init = function (self, spec)
      nodefactory.box._init(self, spec)
      if type(spec) ~= "table" then
        self.penalty = SU.cast("number", spec)
      end
    end,

    __tostring = function (self)
      return "P(" .. self.penalty .. ")";
    end,

    outputYourself = function () end,
    toText = function () return "(!)" end,
    unbox = function (self) return { self } end

  })

nodefactory.vbox = pl.class({
    _base = nodefactory.box,
    type = "vbox",
    nodes = {},
    _default_length = "height",

    _init = function (self, spec)
      self.nodes = {}
      nodefactory.box._init(self, spec)
      self.depth = _maxnode(self.nodes, "depth")
      self.height = _maxnode(self.nodes, "height")
    end,

    __tostring = function (self)
      return "VB<" .. self.height .. "|" .. self:toText() .. "v".. self.depth ..")";
    end,

    toText = function (self)
      return "VB[" .. SU.concat(SU.map(function (node) return node:toText() end, self.nodes), "") .. "]"
    end,

    outputYourself = function (self, typesetter, line)
      typesetter.frame:advancePageDirection(self.height)
      local initial = true
      for _, node in ipairs(self.nodes) do
        if not (initial and (node.is_glue or node.is_penalty)) then
          initial = false
          node:outputYourself(typesetter, line)
        end
      end
      typesetter.frame:advancePageDirection(self.depth)
      typesetter.frame:newLine()
    end,

    unbox = function (self)
      for i = 1, #self.nodes do
        if self.nodes[i].is_vbox or self.nodes[i].is_vglue then return self.nodes end
      end
      return {self}
    end,

    append = function (self, box)
      local nodes = box
      if not box then SU.error("nil box given", true) end
      if nodes.type then
        nodes = box:unbox()
      end
      self.height = self.height:absolute()
      self.height:___add(self.depth)
      local lastdepth = SILE.length()
      for i = 1, #nodes do
        table.insert(self.nodes, nodes[i])
        self.height:___add(nodes[i].height)
        self.height:___add(nodes[i].depth:absolute())
        if nodes[i].is_vbox then lastdepth = nodes[i].depth end
      end
      self.height:___sub(lastdepth)
      self.ratio = 1
      self.depth = lastdepth
    end

  })

nodefactory.migrating = pl.class({
    _base = nodefactory.hbox,
    type = "migrating",
    material = {},
    value = {},
    nodes = {},

    __tostring = function (self)
      return "<M: "..self.material .. ">"
    end

  })

local _deprecated_nodefactory = {}

_deprecated_nodefactory.newHbox = function (spec)
  return nodefactory.hbox(spec)
end

_deprecated_nodefactory.newNnode = function (spec)
  return nodefactory.nnode(spec)
end

_deprecated_nodefactory.newUnshaped = function (spec)
  return nodefactory.unshaped(spec)
end

_deprecated_nodefactory.newDisc = function (spec)
  return nodefactory.discretionary(spec)
end

_deprecated_nodefactory.disc = function (spec)
  return nodefactory.discretionary(spec)
end

_deprecated_nodefactory.newAlternative = function (spec)
  return nodefactory.alternative(spec)
end

_deprecated_nodefactory.newGlue = function (spec)
  return nodefactory.glue(spec)
end

_deprecated_nodefactory.newKern = function (spec)
  return nodefactory.kern(spec)
end

_deprecated_nodefactory.newVglue = function (spec)
  return nodefactory.vglue(spec)
end

_deprecated_nodefactory.newVKern = function (spec)
  return nodefactory.vkern(spec)
end

_deprecated_nodefactory.newPenalty = function (spec)
  return nodefactory.penalty(spec)
end

_deprecated_nodefactory.newDiscretionary = function (spec)
  return nodefactory.discretionary(spec)
end

_deprecated_nodefactory.newVbox = function (spec)
  return nodefactory.vbox(spec)
end

_deprecated_nodefactory.newMigrating = function (spec)
  return nodefactory.migrating(spec)
end

_deprecated_nodefactory.zeroGlue = function ()
  return nodefactory.glue()
end

_deprecated_nodefactory.hfillGlue = function ()
  return nodefactory.hfillglue()
end

_deprecated_nodefactory.vfillGlue = function ()
  return nodefactory.vfillglue()
end

_deprecated_nodefactory.hssGlue = function ()
  return nodefactory.hssglue()
end

_deprecated_nodefactory.vssGlue = function ()
  return nodefactory.vssglue()
end

_deprecated_nodefactory.zeroHbox = function ()
  return nodefactory.zerohbox()
end

_deprecated_nodefactory.zeroVglue = function ()
  return nodefactory.zerovglue()
end

setmetatable(nodefactory, {
    __index = function (_, prop)
      if _deprecated_nodefactory[prop] then
        SU.deprecated("SILE.nodefactory." .. prop, "SILE.nodefactory." .. prop:match("n?e?w?(.*)"):lower(), "0.10.0")
        local old_constructor = _deprecated_nodefactory[prop]
        return string.find(prop, "^new") and old_constructor or old_constructor()
      else
        SU.error("Attempt to access non-existent SILE.nodefactory." .. prop)
      end
    end
  })

return nodefactory
