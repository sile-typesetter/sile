local nodefactory = {}

-- This infinity needs to be smaller than an actual infinity but bigger than the infinite stretch
-- added by the typesetter. See https://github.com/sile-typesetter/sile/issues/227
local inf = 1e13

-- NOTE: Normally self:super() would be the way to recurse _init() functions,
-- but due to a Penlight bug this only works for one level. This setup has
-- several levels, and also customizes what happens at each level so we are
-- directly calling back into the _init() functions we want.

nodefactory.box = pl.class({
    type = "special",
    height = 0,
    depth = 0,
    width = 0,
    misfit = false,
    explicit = false,
    discardable = false,
    value = nil,
    _default_length = "width",

    _init = function (self, spec)
      if type(spec) == "string" then
        local len = SILE.length.parse(spec)
        spec = {}
        spec[self._default_length] = len
      end
      if type(spec) == "table" then
        for k, v in pairs(spec) do
          self[k] = v
        end
      end
    end,

    tostring = function (self)
      return  self:__tostring()
    end,

    __tostring = function (self)
      return self.type
    end,

    __concat = function (a, b) return tostring(a)..tostring(b) end,

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
      return self.type == "hbox" or self.type == "zerohbox" or self.type == "alternative" or self.type == "nnode" or self.type == "vbox"
    end,

    isNnode = function (self)
      return self.type=="nnode"
    end,

    isGlue = function (self)
      return self.type == "glue"
    end,

    isVglue = function (self)
      return self.type == "vglue"
    end,

    isUnshaped = function (self)
      return self.type == "unshaped"
    end,

    isAlternative = function (self)
      return self.type == "alternative"
    end,

    isVbox = function (self)
      return self.type == "vbox"
    end,

    isMigrating = function (self)
      return self.migrating
    end,

    isPenalty = function (self)
      return self.type == "penalty"
    end,

    isDiscretionary = function (self)
      return self.type == "discretionary"
    end,

    isKern = function (self)
      return self.type == "kern"
    end

  })

nodefactory.hbox = pl.class({
    _base = nodefactory.box,
    type = "hbox",

    __tostring = function (self)
      return "H<" .. tostring(self.width) .. ">^" .. tostring(self.height) .. "-" .. tostring(self.depth) .. "v"
    end,

    scaledWidth = function (self, line)
      local scaledWidth = self:lineContribution()
      if type(scaledWidth) ~= "table" then return scaledWidth end
      if line.ratio < 0 and type(self.width) == "table" and self.width.shrink > 0 then
        scaledWidth = scaledWidth + self.width.shrink * line.ratio
      elseif line.ratio > 0 and type(self.width) == "table" and self.width.stretch > 0 then
        scaledWidth = scaledWidth + self.width.stretch * line.ratio
      end
      return scaledWidth.length
    end,

    outputYourself = function (self, typesetter, line)
      if not self.value.glyphString then return end
      if typesetter.frame:writingDirection() == "RTL" then
        typesetter.frame:advanceWritingDirection(self:scaledWidth(line))
      end
      SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
      SILE.outputter.setFont(self.value.options)
      SILE.outputter.outputHbox(self.value, self:scaledWidth(line))
      if typesetter.frame:writingDirection() ~= "RTL" then
        typesetter.frame:advanceWritingDirection(self:scaledWidth(line))
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
      self.nodes = spec.nodes
      if 0 == self.depth then self.depth = math.max(0, table.unpack(SU.map(function (node) return node.depth end, self.nodes))) end
      if 0 == self.height then self.height = math.max(0, table.unpack(SU.map(function (node) return node.height end, self.nodes))) end
      if 0 == self.width then self.width = SU.sum(SU.map(function (node) return node.width end, self.nodes)) end
    end,

    __tostring = function (self)
      return "N<" .. tostring(self.width) .. ">^" .. self.height .. "-" .. self.depth .. "v(" .. self:toText() .. ")";
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

nodefactory.disc = pl.class({
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
        while (line.nodes[i]:isGlue() and line.nodes[i].value == "lskip")
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
      local width = 0
      for _, node in pairs(self.prebreak) do width = width + node.width end
      self.prebw = width
      return width
    end,
    postbreakWidth = function (self)
      if self.postbw then return self.postbw end
      local width = 0
      for _, node in pairs(self.postbreak) do width = width + node.width end
      self.postbw = width
      return width
    end,

    replacementWidth = function (self)
      if self.replacew then return self.replacew end
      local width = 0
      for _, node in pairs(self.replacement) do width = width + node.width end
      self.replacew = width
      return width
    end,

    prebreakHeight = function (self)
      if self.prebh then return self.prebh end
      local width = 0
      for _, node in pairs(self.prebreak) do if node.height > width then width = node.height end end
      self.prebh = width
      return width
    end,

    postbreakHeight = function (self)
      if self.postbh then return self.postbh end
      local width = 0
      for _, node in pairs(self.postbreak) do if node.height > width then width = node.height end end
      self.postbh = width
      return width
    end,

    replacementHeight = function (self)
      if self.replaceh then return self.replaceh end
      local width = 0
      for _, node in pairs(self.replacement) do if node.height > width then width = node.height end end
      self.replaceh = width
      return width
    end

  })

nodefactory.alt = pl.class({
    _base = nodefactory.hbox,
    type = "alternative",
    options = {},
    selected = nil,

    __tostring = function (self)
      return "A(" .. SU.concat(self.options, " / ") .. ")"
    end,

    minWidth = function (self)
      local minW = function (a, b) return math.min(a.width, b.width) end
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
      return (self.explicit and "E:" or "") .. "G<" .. tostring(self.width) .. ">"
    end,

    toText = function () return " " end,

    outputYourself = function (self, typesetter, line)
      self.width = SU.cast("length", self.width)
      local scaledWidth = self.width.length
      if line.ratio and line.ratio < 0 and self.width.shrink > 0 then
        scaledWidth = scaledWidth + self.width.shrink * line.ratio
      elseif line.ratio and line.ratio > 0 and self.width.stretch > 0 then
        scaledWidth = scaledWidth + self.width.stretch * line.ratio
      end
      typesetter.frame:advanceWritingDirection(scaledWidth)
    end

  })

nodefactory.hfillglue = pl.class({
    _base = nodefactory.glue,
    stretch = inf
  })

nodefactory.hssglue = pl.class({
  -- possible bug, deprecated constructor actually used vglue for this
    _base = nodefactory.glue,
    stretch = inf,
    shrink = inf
  })

nodefactory.kern = pl.class({
    _base = nodefactory.glue,
    type = "kern",
    discardable = false,

    __tostring = function (self)
      return "K<" .. tostring(self.width) .. ">"
    end,
  })

nodefactory.vglue = pl.class({
    _base = nodefactory.box,
    type = "vglue",
    discardable = true,
    _default_length = "height",

    __tostring = function (self)
      return (self.explicit and "E:" or "") .. "VG<" .. tostring(self.height) .. ">";
    end,

    setGlue = function (self, adjustment)
      self.height.length = SILE.toAbsoluteMeasurement(self.height.length) + adjustment
      self.height.stretch = 0
      self.height.shrink = 0
    end,

    adjustGlue = function (self, adjustment)
      self.height.length = self.height.length + adjustment
      self.height.stretch = 0
      self.height.shrink = 0
    end,

    outputYourself = function (_, typesetter, line)
      local depth = line.depth
      depth = depth + SILE.toAbsoluteMeasurement(line.height)
      if type(depth) == "table" then depth = depth.length end
      typesetter.frame:advancePageDirection(depth)
    end,

    unbox = function (self) return { self } end

  })

nodefactory.vfillglue = pl.class({
    _base = nodefactory.vglue,
    stretch = inf
  })

nodefactory.vssglue = pl.class({
    _base = nodefactory.vglue,
    stretch = inf,
    shrink = inf
  })

nodefactory.zerovglue = pl.class({
    _base = nodefactory.vglue,
  })

nodefactory.vkern = pl.class({
    _base = nodefactory.vglue,
    discardable = false,

    __tostring = function (self)
      return "VK<" .. tostring(self.height) .. ">"
    end

  })

nodefactory.penalty = pl.class({
    _base = nodefactory.box,
    type = "penalty",
    discardable = true,
    width = SILE.length.new({}),
    flagged = 0,
    penalty = 0,

    __tostring = function (self)
      return "P(" .. self.flagged .. "|" .. self.penalty .. ")";
    end,

    outputYourself = function () end,

    toText = function () return "(!)" end,

    unbox = function (self) return {self} end

  })

nodefactory.vbox = pl.class({
    _base = nodefactory.box,
    type = "vbox",
    nodes = {},
    _default_length = "height",

    _init = function (self, spec)
      nodefactory.box._init(self, spec)
      self.nodes = spec.nodes
      self.depth = 0
      self.height = 0
      for i=1, #(self.nodes) do
        local node = self.nodes[i]
        local height = type(node.height) == "table" and node.height.length or node.height
        local depth = type(node.depth) == "table" and node.depth.length or node.depth
        self.depth = (depth > self.depth) and depth or self.depth
        self.height = (height > self.height) and height or self.height
      end
    end,

    __tostring = function (self)
      return "VB<" .. tostring(self.height) .. "|" .. self:toText() .. "v"..tostring(self.depth)..")";
    end,

    toText = function (self)
      return "VB[" .. SU.concat(SU.map(function (node) return node:toText() end, self.nodes), "") .. "]"
    end,

    outputYourself = function (self, typesetter, line)
      local advanceamount = self.height
      if type(advanceamount) == "table" then advanceamount = advanceamount.length end
      typesetter.frame:advancePageDirection(advanceamount)
      local initial = true
      for _, node in pairs(self.nodes) do
        if not (initial and (node:isGlue() or node:isPenalty())) then
          initial = false
          node:outputYourself(typesetter, line)
        end
      end
      if self.depth then typesetter.frame:advancePageDirection(self.depth) end
      typesetter.frame:newLine()
    end,

    unbox = function (self)
      for i = 1, #self.nodes do
        if self.nodes[i]:isVbox() or self.nodes[i]:isVglue() then return self.nodes end
      end
      return {self}
    end,

    append = function (self, box)
      local nodes = box
      if not box then SU.error("nil box given", true) end
      if nodes.type then
        nodes = box:unbox()
      end
      local height = self.height + self.depth
      local lastdepth = 0
      for i = 1, #nodes do
        table.insert(self.nodes, nodes[i])
        height = height + nodes[i].height + nodes[i].depth
        if nodes[i]:isVbox() then lastdepth = nodes[i].depth end
      end
      self.ratio = 1
      self.height = height - lastdepth
      self.depth = lastdepth
    end

  })

nodefactory.migrating = pl.class({
    _base = nodefactory.hbox,
    material = {},
    value = {},
    nodes = {},
    migrating = true,

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
  return nodefactory.disc(spec)
end

_deprecated_nodefactory.newAlternative = function (spec)
  return nodefactory.alt(spec)
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
  return nodefactory.disc(spec)
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
      -- SU.warn("Please use new nodefactory class constructors, not: "..prop)
      local old_constructor = _deprecated_nodefactory[prop]
      return string.find(prop, "^new") and old_constructor or old_constructor()
    end
  })

return nodefactory
