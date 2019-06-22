local nodefactory = require("core/nodefactory")
local hb = require("justenoughharfbuzz")
local ot = require("core/opentype-parser")

local mathMode = {
  display = 0,
  displayCramped = 1,
  text = 2,
  textCramped = 3,
  script = 4,
  scriptCramped = 5,
  scriptScript = 6,
  scriptScriptCramped = 7
}

local atomType = {
  ordinary = 0,
  bigOperator = 1,
  binaryOperator = 2,
  relationalOperator = 3,
  openingSymbol = 4,
  closeSymbol = 5,
  punctuationSymbol = 6,
  inner = 7,
  overlinedSymbol = 8,
  underlinedSymbol = 9,
  accentedSymbol = 10,
  radicalSymbol = 11,
  vcenter = 12
}

local scriptType = {
  upright = 1,
  bold = 2, -- also have Greek and digits
  italic = 3, -- also have Greek
  boldItalic = 4, -- also have Greek
  script = 5,
  boldScript = 6,
  fraktur = 7,
  boldFraktur = 8,
  doubleStruck = 9, -- also have digits
  sansSerif = 10, -- also have digits
  sansSerifBold = 11, -- also have Greek and digits
  sansSerifItalic = 12,
  sansSerifBoldItalic = 13, -- also have Greek
  monospace = 14, -- also have digits
}

local operatorAtomTypes = {
  ['+'] = atomType.binaryOperator,
  ['-'] = atomType.binaryOperator,
  ['<'] = atomType.relationalOperator,
  ['>'] = atomType.relationalOperator,
  ['='] = atomType.relationalOperator,
}

local bigOperators = {'∑','∏','⋀', '⋁', '⋂', '⋃', '⨅', '⨆'}

-- Foward declaration
local newSpace

-- Whether to show debug boxes around mboxes
local debug

local function isCrampedMode(mode)
  return mode % 2 == 1
end

local mathScriptConversionTable = {
  italicLatinUpper = function(codepoint) return codepoint + 0x1D434 - 0x41 end,
  italicLatinLower = function(codepoint) return codepoint == 0x68 and 0x210E or codepoint + 0x1D44E - 0x61 end
}

SILE.settings.declare({name = "math.font.family", type = "string", default = "XITS Math"})

local mathCache

local function getMathMetrics(options)
  if mathCache then
    return mathCache
  end
  local face = SILE.font.cache(options, SILE.shaper.getFace)
  if not face then
    SU.error("Could not find requested font "..options.." or any suitable substitutes")
  end
  local mathTable = ot.parseMath(hb.get_table(face.data, face.index, "MATH"))
  local upem = ot.parseHead(hb.get_table(face.data, face.index, "head")).unitsPerEm
  if mathTable == nil then
    SU.error("You must use a math font for math rendering.")
  end
  local constants = {}
  for k,v in pairs(mathTable.mathConstants) do
    if type(v) == "table" then v = v.value end
    if k:sub(-9) == "ScaleDown" then constants[k] = v / 100
    else constants[k] = v * options.size / upem end
  end
  local italicsCorrection = {}
  for k, v in pairs(mathTable.mathItalicsCorrection) do
    italicsCorrection[k] = v.value * options.size / upem
  end
  mathCache = {
    constants = constants,
    italicsCorrection = italicsCorrection
  }
  return mathCache
end

-- Style transition functions for superscript and subscript
local function getSuperscriptMode(mode)
  if mode == mathMode.display or mode == mathMode.text then return mathMode.script                          -- D, T -> S
  elseif mode == mathMode.displayCramped or mode == mathMode.textCramped then return mathMode.scriptCramped -- D', T' -> S'
  elseif mode == mathMode.script or mode == mathMode.scriptScript then return mathMode.scriptScript         -- S, SS -> SS
  else return mathMode.scriptScriptCramped end                                                              -- S', SS' -> SS'
end
local function getSubscriptMode(mode)
  if mode == mathMode.display or mode == mathMode.text
      or mode == mathMode.displayCramped or mode == mathMode.textCramped then return mathMode.scriptCramped  -- D, T, D', T' -> S'
  else return mathMode.scriptScriptCramped end                                                               -- S, SS, S', SS' -> SS'
end

-- Style transition functions for fraction (numerator and denominator)
local function getNumeratorMode(mode)
  if mode == mathMode.display then return mathMode.text                                                -- D -> T
  elseif mode == mathMode.displayCramped then return mathMode.textCramped                              -- D' -> T'
  elseif mode == mathMode.text then return mathMode.script                                             -- T -> S
  elseif mode == mathMode.textCramped then return mathMode.scriptCramped                               -- T' -> S'
  elseif mode == mathMode.script or mode == mathMode.scriptScript then return mathMode.scriptScript  -- S, SS -> SS
  else return mathMode.scriptScriptCramped end                                                           -- S', SS' -> SS'
end
local function getDenominatorMode(mode)
  if mode == mathMode.display or mode == mathMode.displayCramped then return mathMode.textCramped    -- D, D' -> T'
  elseif mode == mathMode.text or mode == mathMode.textCramped then return mathMode.scriptCramped    -- T, T' -> S'
  else return mathMode.scriptScriptCramped end                                                           -- S, SS, S', SS' -> SS'
end 

local function typeof(var)
  local _type = type(var)
  if(_type ~= "table" and _type ~= "userdata") then
      return _type
  end
  local _meta = getmetatable(var)
  if(_meta ~= nil and _meta._type ~= nil) then
      return _meta._type;
  else
      return _type;
  end
end

local function getRightMostGlyphId(node)
  local textNode = node
  while typeof(node) == "Stackbox" and node.direction == 'H' do
    node = node.children[#(node.children)]
  end
  if typeof(node) == "Text" then
    return node.value.glyphString[#(node.value.glyphString)]
  else
    return 0
  end
end

local function contains(table, elt)
  for _,x in pairs(table) do
    if x == elt then return true end
  end
  return false
end

local function maxLength(...)
  local arg = {...}
  local result
  for i, v in ipairs(arg) do
    if typeof(v) == "number" then v = SILE.length.make(v) end
    if i == 1 then
      result = v
    elseif typeof(v) == "Length" then
      result = SILE.length.new({
        length = math.max(result.length, v.length),
        shrink = math.max(result.length, v.length) - math.max(result.length - result.shrink, v.length - v.shrink),
        stretch = math.max(result.length + result.stretch, v.length + v.stretch) - math.max(result.length, v.length),
      })
    else
      SU.error("Unknown type: "..typeof(v))
    end
  end
  return result
end

local function getNumberFromLength(length, line)
  local number = length.length
  if line.ratio and line.ratio < 0 and length.shrink > 0 then
    number = number + length.shrink * line.ratio
  elseif line.ratio and line.ratio > 0 and length.stretch > 0 then
    number = number + length.stretch * line.ratio
  end
  return number
end

-- math box, box with a horizontal shift value and could contain zero or more _mbox'es (or its child classes)
-- the entire math environment itself is a top-level mbox.
-- Typesetting of mbox evolves four steps:
--   1. Determine the mode for each mbox according to their parent.
--   2. Shape the mbox hierarchy from leaf to top. Get the shape and relative position.
--   3. Convert mbox into _nnode's to put in SILE's typesetting framwork
local _mbox = _box {
  _type = "Mbox",
  options = {},
  children = {}, -- The child nodes
  relX = SILE.length.make(0), -- x position relative to its parent box
  relY = SILE.length.make(0), -- y position relative to its parent box
  value = {},
  mode = mathMode.display,
  atom = atomType.ordinary,
  __tostring = function (s) return s.type end,
  init = function(self)
    local options = {
      family=SILE.settings.get("math.font.family")
    }
    self.options = SILE.font.loadDefaults(options)
  end,

  styleChildren = function(self)
    SU.error("styleChildren is a virtual function that need to be overriden by its child classes")
  end,

  shape = function(self, x, y)
    SU.error("shape is a virtual function that need to be overriden by its child classes")
  end,

  output = function(self, x, y, line)
    SU.error("output is a virtual function that need to be overriden by its child classes")
  end,

  -- Determine the mode of its descendants
  styleDescendants = function(self)
    self:styleChildren()
    for i, n in ipairs(self.children) do
      if n then n:styleDescendants() end
    end
  end,

  -- shapeTree shapes the mbox and all its descendants in a recursive fashion
  -- The inner-most leaf nodes determine their shape first, and then propagate to their parents
  -- During the process, each node will determine its size by (width, height, depth)
  -- and (relX, relY) which the relative position to its parent
  shapeTree = function(self)
    for i, n in ipairs(self.children) do
      if n then n:shapeTree() end
    end
    self:shape()
  end,

  -- Output the node and all its descendants
  outputTree = function(self, x, y, line)
    self:output(x, y, line)
    if debug and typeof(self) ~= "Space" then
      SILE.outputter.moveTo(getNumberFromLength(x, line), y.length)
      SILE.outputter.debugHbox(
        { height = self.height.length,
          depth = self.depth.length },
        getNumberFromLength(self.width, line)
      )
    end
    for i, n in ipairs(self.children) do
      if n then n:outputTree(x + n.relX, y + n.relY, line) end
    end
  end
}

-- _stackbox stacks its content one, either horizontally or vertically
local _stackbox = _mbox {
  _type = "Stackbox",
  direction = "H", -- 'H' for horizontal, 'V' for vertical
  anchor = 1, -- The index of the child whose relX and relY will be 0
  __tostring = function (self)
    local result = self.direction.."Box("
    for i, n in ipairs(self.children) do
      result = result..(i == 1 and "" or ", ")..tostring(n)
    end
    result = result..")"
    return result
  end,

  init = function(self)
    _mbox.init(self)
    if self.anchor < 1 or self.anchor > #(self.children) then
      SU.error('Wrong index of the anchor children')
    end
  end,
  styleChildren = function(self)
    for i, n in ipairs(self.children) do
      n.mode = self.mode
    end
    if self.direction == "H" then
      -- Add space between Ord and Bin/Rel
      local spaces = {}
      if self.mode == mathMode.display or self.mode == mathMode.displayCramped or
          self.mode == mathMode.text or self.mode == mathMode.textCramped then
        for i, v in ipairs(self.children) do
          if i < #self.children then
            local v2 = self.children[i + 1]
            if (v.atom == atomType.relationalOperator and v2.atom == atomType.ordinary) or
                (v2.atom == atomType.relationalOperator and v.atom == atomType.ordinary) then
              spaces[i + 1] = 'thick'
            elseif (v.atom == atomType.binaryOperator and v2.atom == atomType.ordinary) or
                (v2.atom == atomType.binaryOperator and v.atom == atomType.ordinary) then
              spaces[i + 1] = 'med'
            end
          end
        end
      end

      local spaceIdx = {}
      for i, _ in pairs(spaces) do
        table.insert(spaceIdx, i)
      end
      table.sort(spaceIdx, function(a, b) return a > b end)
      for _, idx in ipairs(spaceIdx) do
        table.insert(self.children, idx, newSpace({kind = spaces[idx]}))
        if idx <= self.anchor then self.anchor = self.anchor + 1 end
      end
    end
  end,
  shape = function(self)
    if self.children and #(self.children) > 0 then
      for i, n in ipairs(self.children) do
        if self.direction == "H" then
          -- Horizontal stackbox
          if i == self.anchor then
            n.relX = SILE.length.make(0)
          elseif i > self.anchor then
            n.relX = self.children[i - 1].relX + self.children[i - 1].width
          end
          n.relY = SILE.length.make(0)
          self.width = i == 1 and self.children[i].width or (self.width + self.children[i].width)
          self.height = i == 1 and self.children[i].height or maxLength(self.height, self.children[i].height)
          self.depth = i == 1 and self.children[i].depth or maxLength(self.depth, self.children[i].depth)
        else -- self.direction == "V"
          n.relX = SILE.length.make(0)
          if i == self.anchor then
            n.relY = SILE.length.make(0)
            self.height = n.height
            self.depth = n.depth
          elseif i > self.anchor then
            n.relY = self.children[i - 1].relY + self.children[i - 1].depth + n.height
            self.depth = self.depth + n.height + n.depth
          end
          self.width = i == 1 and self.children[i].width or maxLength(self.width, self.children[i].width)
        end
      end
      for i = self.anchor - 1, 1, -1 do
        local n = self.children[i]
        if self.direction == "H" then
          n.relX = self.children[i + 1].relX - n.width
        else -- self.direction == "V"
          n.relY = self.children[i + 1].relY - self.children[i + 1].height - n.depth
          self.height  = self.height + n.depth + n.height
        end
      end
    end
  end,
  -- Despite of its name, this function actually output the whole tree of nodes recursively.
  outputYourself = function(self, typesetter, line)
    local mathX = typesetter.frame.state.cursorX
    local mathY = typesetter.frame.state.cursorY
    self:outputTree(self.relX + mathX, self.relY + mathY, line)
    typesetter.frame:advanceWritingDirection(getNumberFromLength(self.width, line))
  end,
  output = function(self, x, y, line) end
}

local _subscript = _mbox {
  _type = "Subscript",
  kind = "sub",
  base = nil,
  sub = nil,
  sup = nil,
  init = function(self)
    _mbox.init(self)
    if self.base then table.insert(self.children, self.base) end
    if self.sub then table.insert(self.children, self.sub) end
    if self.sup then table.insert(self.children, self.sup) end
  end,
  styleChildren = function(self)
    if self.base then self.base.mode = self.mode end
    if self.sub then self.sub.mode = getSubscriptMode(self.mode) end
    if self.sup then self.sup.mode = getSuperscriptMode(self.mode) end
  end,
  calculateItalicsCorrection = function(self)
    local lastGid = getRightMostGlyphId(self.base)
    if lastGid > 0 then
      local mathMetrics = getMathMetrics(self.options)
      if mathMetrics.italicsCorrection[lastGid] then
        return mathMetrics.italicsCorrection[lastGid]
      end
    end
    return 0
  end,
  shape = function(self)
    local mathMetrics = getMathMetrics(self.options)
    local constants = mathMetrics.constants
    if self.base then
      self.base.relX = SILE.length.make(0)
      self.base.relY = SILE.length.make(0)
      self.width = self.base.width
    else
      self.width = SILE.length.make(0)
    end
    if self.sub then
      self.sub.relX = self.width
      self.sub.relY = maxLength(
        constants.subscriptShiftDown,
        self.base.depth + constants.subscriptBaselineDropMin,
        self.sub.height - constants.subscriptTopMax
      )
    end
    if self.sup then
      self.sup.relX = self.width + self:calculateItalicsCorrection()
      self.sup.relY = maxLength(
        isCrampedMode(self.mode) and constants.superscriptShiftUpCramped or constants.superscriptShiftUp, -- or cramped
        self.base.height - constants.superscriptBaselineDropMax,
        self.sup.depth + constants.superscriptBottomMin
      ) * (-1)
    end
    if self.sub and self.sup then
      local gap = self.sub.relY - self.sub.height - self.sup.relY - self.sup.depth
      if gap.length < constants.subSuperscriptGapMin then
        local supShift, subShift = gap - constants.subSuperscriptGapMin, SILE.length.make(0)
        if -supShift.length > constants.superscriptBottomMaxWithSubscript then
          subShift = supShift * (-1) - constants.superscriptBottomMaxWithSubscript
          supShift = -constants.superscriptBottomMaxWithSubscript
        end
        self.sup.relY = self.sup.relY + supShift
        self.sub.relY = self.sub.relY + subShift
      end
    end

    self.width = self.width + maxLength(
      self.sub and self.sub.width or 0,
      self.sup and (self.sup.width + self:calculateItalicsCorrection()) or 0
    )
    self.height = maxLength(
      self.base and self.base.height or 0,
      self.sub and (self.sub.height - self.sub.relY) or 0,
      self.sup and (self.sup.height - self.sup.relY) or 0
    )
    self.depth = maxLength(
      self.base and self.base.depth or 0,
      self.sub and (self.sub.depth + self.sub.relY) or 0,
      self.sup and (self.sup.depth + self.sup.relY) or 0
    )
  end,
  output = function(self, x, y, line) end
}

local _bigOpSubscript = _subscript {
  _type = "BigOpSubscript",
  kind = "sub",
  base = nil,
  sub = nil,
  sup = nil,
  init = function(self)
    _mbox.init(self)
    if self.sup then table.insert(self.children, self.sup) end
    if self.base then table.insert(self.children, self.base) end
    if self.sub then table.insert(self.children, self.sub) end
  end,
  styleChildren = function(self)
    if self.base then self.base.mode = self.mode end
    if self.sub then self.sub.mode = getSubscriptMode(self.mode) end
    if self.sup then self.sup.mode = getSuperscriptMode(self.mode) end
  end,
  calculateItalicsCorrection = function(self)
    local lastGid = getRightMostGlyphId(self.base)
    if lastGid > 0 then
      local mathMetrics = getMathMetrics(self.options)
      if mathMetrics.italicsCorrection[lastGid] then
        return mathMetrics.italicsCorrection[lastGid]
      end
    end
    return 0
  end,
  shape = function(self)
    local constants = getMathMetrics(self.options).constants
    -- Determine relative Ys
    if self.base then
      self.base.relY = SILE.length.make(0)
    end
    if self.sub then
      self.sub.relY = self.base.depth + maxLength(
        self.sub.height + constants.lowerLimitGapMin,
        constants.lowerLimitBaselineDropMin)
    end
    if self.sup then
      self.sup.relY = maxLength(
        self.base.height + constants.upperLimitGapMin,
        constants.upperLimitBaselineRiseMin) * (-1)
    end
    -- Determine relative Xs based on widest symbol
    local widest, a, b
    if self.sub.width > self.base.width then
      if self.sub.width > self.sup.width then
        widest = self.sub
        a = self.base
        b = self.sup
      else
        widest = self.sup
        a = self.base
        b = self.sub
      end
    else
      if self.base.width > self.sup.width then
        widest = self.base
        a = self.sub
        b = self.sup
      else
        widest = self.sup
        a = self.base
        b = self.sub
      end
    end
    widest.relX = SILE.length.make(0)
    local c = widest.width / 2
    a.relX = c - a.width / 2
    b.relX = c - b.width / 2
    -- Determine width and height
    self.width = maxLength(
      self.base and self.base.width or 0,
      maxLength(
        self.sub and self.sub.width or 0,
        self.sup and self.sup.width or 0
      )
    )
    if self.sup then
      self.height = 0 - self.sup.relY + self.sup.height
    else
      self.height = self.base and self.base.height or 0
    end
    if self.sub then
      self.depth = self.sub.relY + self.sub.depth
    else
      self.depth = self.base and self.base.depth or 0
    end
  end,
  output = function(self, x, y, line) end
}

-- _terminal is the base class for leaf node
local _terminal = _mbox {
  _type = "Terminal",
  styleChildren = function(self) end,
  shape = function(self) end
}

local _space = _terminal {
  _type = "Space",
  __tostring = function(self) return self.kind.."space" end,
  kind = "thin",
  init = function(self)
    _terminal.init(self)
    local fontSize = math.floor(self.options.size * ((self.mode == mathMode.script or self.mode == mathMode.scriptCramped) and 0.7 or 0.5))
    local mu = fontSize / 18
    if self.kind == "thin" then
      self.length = SILE.length.new({
        length = 3 * mu,
        shrink = 0,
        stretch = 0
      })
    elseif self.kind == "med" then
      self.length = SILE.length.new({
        length = 4 * mu,
        shrink = 4 * mu,
        stretch = 2 * mu
      })
    elseif self.kind == "thick" then
      self.length = SILE.length.new({
        length = 5 * mu,
        shrink = 0,
        stretch = 5 * mu
      })
    else
      SU.error("Unknown space type "..kind)
    end
  end,
  shape = function(self)
    self.width = self.length
    -- Spaces say that they have height zero because they cannot guess
    -- what the maximum height in the surrounding text is
    self.height = SILE.length.make(0)
    self.depth = SILE.length.make(0)
  end,
  output = function(self) end
}

-- text node. For any actual text output
local _text = _terminal {
  _type = "Text",
  text = "",
  kind = "number", -- may also be identifier or operator
  script = scriptType.upright,
  __tostring = function(self) return "Text("..(self.originalText or self.text)..")" end,
  init = function(self)
    _terminal.init(self)
    if self.kind == 'identifier' then
      local converted = ""
      for uchr in SU.utf8codes(self.text) do
        local dst_char = SU.utf8char(uchr)
        if uchr >= 0x41 and uchr <= 0x5A then -- Latin capital letter
          if self.script == scriptType.italic then
            dst_char = SU.utf8char(mathScriptConversionTable.italicLatinUpper(uchr))
          end
        elseif uchr >= 0x61 and uchr <= 0x7A then -- Latin non-capital letter
          if self.script == scriptType.italic then
            dst_char = SU.utf8char(mathScriptConversionTable.italicLatinLower(uchr))
          end
        end
        converted = converted..dst_char
      end
      self.originalText = self.text
      self.text = converted
    elseif self.kind == 'operator' then
      if operatorAtomTypes[self.text] then
        self.atom = operatorAtomTypes[self.text]
      end
    end
  end,
  shape = function(self)
    local face = SILE.font.cache(self.options, SILE.shaper.getFace)
    if self.mode == mathMode.script or self.mode == mathMode.scriptCramped or
        self.mode == mathMode.scriptScript or self.mode == mathMode.scriptScriptCramped then
      local constants = getMathMetrics(self.options).constants
      local fontSize = math.floor(self.options.size * ((self.mode == mathMode.script or self.mode == mathMode.scriptCramped) and 0.7 or 0.5))
      face.size = fontSize
      self.options.size = fontSize
    end
    local glyphs = SILE.shaper:shapeToken(self.text, self.options)
    SILE.shaper:preAddNodes(glyphs, self.value)
    self.value.items = glyphs
    self.value.glyphString = {}
    if glyphs and #glyphs > 0 then
      for i = 1, #glyphs do
        table.insert(self.value.glyphString, glyphs[i].gid)
      end
      for i = #glyphs, 1, -1 do
        self.width = i == #glyphs and SILE.length.make(glyphs[#glyphs].width) or self.width + glyphs[i].glyphAdvance
      end
      for i = 1, #glyphs do
        self.height = i == 1 and SILE.length.make(glyphs[i].height) or maxLength(self.height, glyphs[i].height)
        self.depth = i == 1 and SILE.length.make(glyphs[i].depth) or maxLength(self.depth, glyphs[i].depth)
      end
    else
      self.width = SILE.length.make(0)
      self.height = SILE.length.make(0)
      self.depth = SILE.length.make(0)
    end
  end,
  output = function(self, x, y, line)
    if not self.value.glyphString then return end
    -- print('Output '..self.value.glyphString.." to "..x..", "..y)
    SILE.outputter.moveTo(getNumberFromLength(x, line), getNumberFromLength(y, line))
    SILE.outputter.setFont(self.options)
    SILE.outputter.outputHbox(self.value, getNumberFromLength(self.width, line))
  end
}

local newText = function(spec)
  local ret = std.tree.clone(_text(spec))
  ret:init()
  return ret
end

local newStackbox = function(spec)
  local ret = std.tree.clone(_stackbox(spec))
  ret:init()
  return ret
end

local newSubscript = function(spec)
  local ret
  if spec.base and typeof(spec.base) == "Text"
      and spec.base.kind == "operator"
      and contains(bigOperators, spec.base.text) then
    ret = std.tree.clone(_bigOpSubscript(spec))
  else
    ret = std.tree.clone(_subscript(spec))
  end
  ret:init()
  return ret
end

newSpace = function(spec)
  local ret = std.tree.clone(_space(spec))
  ret:init()
  return ret
end

-- convert MathML into mbox
local function ConvertMathML(content)
  if content == nil or content.id == nil or content.tag == nil then return nil end
  local convertChildren = function(content)
    local mboxes = {}
    for i, n in ipairs(content) do
      local box = ConvertMathML(n)
      if box then table.insert(mboxes, box) end
    end
    return mboxes
  end
  if content.tag == 'math' then -- toplevel
    return newStackbox({ direction='V', children=convertChildren(content) })
  elseif content.tag == 'mrow' then
    return newStackbox({ direction='H', children=convertChildren(content) })
  elseif content.tag == 'mi' then
    return newText({ kind='identifier', script=scriptType.italic, text=content[1] })
  elseif content.tag == 'mo' then
    return newText({ kind='operator', script=scriptType.upright, text=content[1] })
  elseif content.tag == 'mn' then
    return newText({ kind='number', script=scriptType.upright, text=content[1] })
  elseif content.tag == 'msub' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in msub') end
    return newSubscript({ kind="sub", base=children[1], sub=children[2] })
  elseif content.tag == 'msup' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in msup') end
    return newSubscript({ kind="sup", base=children[1], sup=children[2] })
  elseif content.tag == 'msubsup' then
    local children = convertChildren(content)
    if #children ~= 3 then SU.error('Wrong number of children in msubsup') end
    return newSubscript({ kind="subsup", base=children[1], sub=children[2], sup=children[3] })
  else
    return nil
  end
end

SILE.nodefactory.math = {
  newText = newText,
  newStackbox = newStackbox
}

SILE.registerCommand("math", function (options, content)
  local mode = (options and options.mode) and options.mode or 'text'
  debug = options and options.debug

  local mbox = ConvertMathML(content, mbox)

  if #(mbox.children) == 1 then
    mbox = mbox.children[1]
  end

  if mode == 'display' then
    mbox.mode = mathMode.display
  elseif mode == 'text' then
    mbox.mode = mathMode.textCramped
  else
    SU.error('Unknown math mode '..mode)
  end
  mbox:styleDescendants()

  mbox:shapeTree()

  SILE.typesetter:pushHorizontal(mbox)

end)