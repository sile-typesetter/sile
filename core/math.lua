local nodefactory = require("core/nodefactory")
local hb = require("justenoughharfbuzz")
local ot = require("core/opentype-parser")
local symbols = require("core/math-symbols")
local epnf = require("epnf")
require("core/parserbits")

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

local mathVariantToScriptType = function(attr)
  return
    attr == "normal" and scriptType.upright or
    attr == "italic" and scriptType.italic or
    attr == "bold-italic" and scriptType.boldItalic or
    SU.error("Invalid value \""..attr.."\" for attribute mathvariant")
end

local operatorAtomTypes = {
  ['+'] = atomType.binaryOperator,
  ['-'] = atomType.binaryOperator,
  ['<'] = atomType.relationalOperator,
  ['>'] = atomType.relationalOperator,
  ['='] = atomType.relationalOperator,
  ['≠'] = atomType.relationalOperator,
  ['∑'] = atomType.bigOperator,
  ['∏'] = atomType.bigOperator,
  ['⋀'] = atomType.bigOperator,
  ['⋁'] = atomType.bigOperator,
  ['⋂'] = atomType.bigOperator,
  ['⋃'] = atomType.bigOperator,
  ['⨅'] = atomType.bigOperator,
  ['⨆'] = atomType.bigOperator,
  ['∫'] = atomType.bigOperator,
  ['∰'] = atomType.bigOperator,
  ['∮'] = atomType.bigOperator
}

local subscriptBigOps =
  {'∫', '∮', '∰'}

-- Foward declaration
local newSpace

local function isDisplayMode(mode)
  return mode <= 1
end

local function isCrampedMode(mode)
  return mode % 2 == 1
end

local function isScriptMode(mode)
  return mode == mathMode.script or mode == mathMode.scriptCramped
end

local function isScriptScriptMode(mode)
  return mode == mathMode.scriptScript or mode == mathMode.scriptScriptCramped
end

local mathScriptConversionTable = {
  italicLatinUpper = function(codepoint) return codepoint + 0x1D434 - 0x41 end,
  italicLatinLower = function(codepoint) return codepoint == 0x68 and 0x210E or codepoint + 0x1D44E - 0x61 end,
  boldItalicLatinUpper = function(codepoint) return codepoint + 0x1D468 - 0x41 end,
  boldItalicLatinLower = function(codepoint) return codepoint + 0x1D482 - 0x61 end
}

SILE.settings.declare({name = "math.font.family", type = "string", default = "XITS Math"})
SILE.settings.declare({name = "math.font.filename", type = "string", default = ""})
SILE.settings.declare({name = "math.font.size", type = "integer", default = 10})
-- Whether to show debug boxes around mboxes
SILE.settings.declare({name = "math.debug.boxes", type = "boolean", default = false})

local function retrieveMathTable(options)
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
    else
      constants[k] = v * options.size / upem
    end
  end
  local italicsCorrection = {}
  for k, v in pairs(mathTable.mathItalicsCorrection) do
    italicsCorrection[k] = v.value * options.size / upem
  end
  return {
    constants = constants,
    italicsCorrection = italicsCorrection,
    mathVariants = mathTable.mathVariants,
    unitsPerEm = upem
  }
end

local mathCache

local function getMathMetrics()
  if mathCache then return mathCache end
  local options = {
    family=SILE.settings.get("math.font.family"),
    size=SILE.settings.get("math.font.size")
  }
  local filename = SILE.settings.get("math.font.filename")
  print("filename = " .. filename)
  if filename and filename ~= "" then options.filename = filename end
  mathCache = retrieveMathTable(options)
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

local function minLength(...)
  local args = {...}
  for i, v in ipairs(args) do
    args[i] = args[i] * (-1)
  end
  return -maxLength(args)
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
      family=SILE.settings.get("math.font.family"),
      size=SILE.settings.get("math.font.size")
    }
    local filename = SILE.settings.get("math.font.filename")
    if filename and filename ~= "" then options.filename = filename end
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

  getScaleDown = function(self)
    local constants = getMathMetrics().constants
    local scaleDown
    if isScriptMode(self.mode) then
      scaleDown = constants.scriptPercentScaleDown
    elseif isScriptScriptMode(self.mode) then
      scaleDown = constants.scriptScriptPercentScaleDown
    else
      scaleDown = 1
    end
    return scaleDown
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
    local debug = SILE.settings.get("math.debug.boxes")
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
      print("children = " .. children)
      SU.error('Wrong index of the anchor children: '..self.anchor)
    end
  end,
  styleChildren = function(self)
    for i, n in ipairs(self.children) do
      n.mode = self.mode
    end
    if self.direction == "H" then
      -- Add space between Ord and Bin/Rel
      local spaces = {}
      for i, v in ipairs(self.children) do
        if i < #self.children then
          local v2 = self.children[i + 1]
          if not (isScriptMode(self.mode) or isScriptScriptMode(self.mode)) then
            if (v.atom == atomType.relationalOperator and v2.atom == atomType.ordinary) or
                (v2.atom == atomType.relationalOperator and v.atom == atomType.ordinary) then
              spaces[i + 1] = 'thick'
            elseif (v.atom == atomType.binaryOperator and v2.atom == atomType.ordinary) or
                (v2.atom == atomType.binaryOperator and v.atom == atomType.ordinary) then
              spaces[i + 1] = 'med'
            elseif (v.atom == atomType.bigOperator and v2.atom == atomType.relationalOperator) or
                (v2.atom == atomType.bigOperator and v.atom == atomType.relationalOperator) then
              spaces[i + 1] = 'thick'
            end
          end
          if (v.atom == atomType.bigOperator and v2.atom == atomType.ordinary) then
            spaces[i + 1] = 'thin'
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
  atom = nil,
  init = function(self)
    _mbox.init(self)
    if self.base then table.insert(self.children, self.base) end
    if self.sub then table.insert(self.children, self.sub) end
    if self.sup then table.insert(self.children, self.sup) end
    self.atom = self.base.atom
  end,
  styleChildren = function(self)
    if self.base then self.base.mode = self.mode end
    if self.sub then self.sub.mode = getSubscriptMode(self.mode) end
    if self.sup then self.sup.mode = getSuperscriptMode(self.mode) end
  end,
  calculateItalicsCorrection = function(self)
    local lastGid = getRightMostGlyphId(self.base)
    if lastGid > 0 then
      local mathMetrics = getMathMetrics()
      if mathMetrics.italicsCorrection[lastGid] then
        local c = mathMetrics.italicsCorrection[lastGid]
        -- If this is a big operator, and we are in display style, then the
        -- base glyph may be bigger than the font size. We need to adjust the
        -- italic correction accordingly.
        if typeof(self) == "BigOpSubscript" and isDisplayMode(self.mode) then
          c = c * (self.base and self.base.options.size / self.options.size or 1.0)
        end
        return c
      end
    end
    return 0
  end,
  shape = function(self)
    local mathMetrics = getMathMetrics()
    local constants = mathMetrics.constants
    local scaleDown = self:getScaleDown()
    if self.base then
      self.base.relX = SILE.length.make(0)
      self.base.relY = SILE.length.make(0)
      self.width = self.base.width
    else
      self.width = SILE.length.make(0)
    end
    local itCorr = self:calculateItalicsCorrection() * scaleDown
    if self.sub then
      self.sub.relX = self.width - itCorr / 2
      self.sub.relY = maxLength(
        constants.subscriptShiftDown * scaleDown,
        --self.base.depth + constants.subscriptBaselineDropMin * scaleDown,
        self.sub.height - constants.subscriptTopMax * scaleDown
      )
      local t = typeof(self)
      if (t == "BigOpSubscript" or t == "Stackbox") then
        self.sub.relY = maxLength(self.sub.relY,
          self.base.depth + constants.subscriptBaselineDropMin*scaleDown)
      end
    end
    if self.sup then
      self.sup.relX = self.width + itCorr / 2
      self.sup.relY = maxLength(
        isCrampedMode(self.mode)
        and constants.superscriptShiftUpCramped * scaleDown
        or constants.superscriptShiftUp * scaleDown, -- or cramped
        --self.base.height - constants.superscriptBaselineDropMax * scaleDown,
        self.sup.depth + constants.superscriptBottomMin * scaleDown
      ) * (-1)
      local t = typeof(self)
      if t == "BigOpSubscript" or t == "Stackbox" then
        self.sup.relY = maxLength(
          (0-self.sup.relY),
          self.base.height - constants.superscriptBaselineDropMax
          * scaleDown) * (-1)
        end
    end
    if self.sub and self.sup then
      local gap = self.sub.relY - self.sub.height - self.sup.relY - self.sup.depth
      if gap.length < constants.subSuperscriptGapMin * scaleDown then
        -- The following adjustment comes directly from Appendix G of he
        -- TeXbook (rule 18e).
        self.sub.relY = constants.subSuperscriptGapMin * scaleDown
          + self.sub.height + self.sup.relY + self.sup.depth
        local psi = constants.superscriptBottomMaxWithSubscript*scaleDown
          + self.sup.relY + self.sup.depth
        if psi > 0 then
          self.sup.relY = self.sup.relY - psi
          self.sub.relY = self.sub.relY - psi
        end
      end
    end

    self.width = self.width + maxLength(
      self.sub and self.sub.width - itCorr / 2 or 0,
      self.sup and self.sup.width + itCorr / 2 or 0
    ) + constants.spaceAfterScript * scaleDown
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
  atom = atomType.bigOperator,
  base = nil,
  sub = nil,
  sup = nil,
  init = function(self)
    _mbox.init(self)
    if self.sup then table.insert(self.children, self.sup) end
    if self.base then
      table.insert(self.children, self.base)
      self.base.atom = atomType.bigOperator
    end
    if self.sub then table.insert(self.children, self.sub) end
  end,
  styleChildren = function(self)
    if self.base then self.base.mode = self.mode end
    if self.sub then self.sub.mode = getSubscriptMode(self.mode) end
    if self.sup then self.sup.mode = getSuperscriptMode(self.mode) end
  end,
  shape = function(self)
    if not (self.mode == mathMode.display
          or self.mode == mathMode.displayCramped)
        or (self.base and contains(subscriptBigOps, self.base.text)) then
      _subscript.shape(self)
      return
    end
    local constants = getMathMetrics().constants
    local scaleDown = self:getScaleDown()
    -- Determine relative Ys
    if self.base then
      self.base.relY = SILE.length.make(0)
    end
    if self.sub then
      self.sub.relY = self.base.depth + maxLength(
        self.sub.height + constants.lowerLimitGapMin * scaleDown,
        constants.lowerLimitBaselineDropMin * scaleDown)
    end
    if self.sup then
      self.sup.relY = 0 - self.base.height - maxLength(
        constants.upperLimitGapMin * scaleDown + self.sup.depth,
        constants.upperLimitBaselineRiseMin * scaleDown)
    end
    -- Determine relative Xs based on widest symbol
    local widest, a, b
    if self.sub and self.sub.width > self.base.width then
      if self.sup and self.sub.width > self.sup.width then
        widest = self.sub
        a = self.base
        b = self.sup
      else
        widest = self.sup
        a = self.base
        b = self.sub
      end
    else
      if self.sup and self.base.width > self.sup.width then
        widest = self.base
        a = self.sub
        b = self.sup
      elseif self.sup then
        widest = self.sup
        a = self.base
        b = self.sub
      else
        widest = self.base
        a = self.sub
        b = nil
      end
    end
    widest.relX = SILE.length.make(0)
    local c = widest.width / 2
    if a then a.relX = c - a.width / 2 end
    if b then b.relX = c - b.width / 2 end
    local itCorr = self:calculateItalicsCorrection() * scaleDown
    if self.sup then self.sup.relX = self.sup.relX + itCorr / 2 end
    if self.sub then self.sub.relX = self.sub.relX - itCorr / 2 end
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
  end,
  shape = function(self)
    local fontSize = math.floor(self.options.size * self:getScaleDown())
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
    if symbols[self.text.tag] then self.text = symbols[self.text.tag] end
    if self.kind == 'identifier' then
      local converted = ""
      for uchr in SU.utf8codes(self.text) do
        local dst_char = SU.utf8char(uchr)
        if uchr >= 0x41 and uchr <= 0x5A then -- Latin capital letter
          if self.script == scriptType.italic then
            dst_char = SU.utf8char(mathScriptConversionTable.italicLatinUpper(uchr))
          elseif self.script == scriptType.boldItalic then
            dst_char = SU.utf8char(mathScriptConversionTable.boldItalicLatinUpper(uchr))
          end
        elseif uchr >= 0x61 and uchr <= 0x7A then -- Latin non-capital letter
          if self.script == scriptType.italic then
            dst_char = SU.utf8char(mathScriptConversionTable.italicLatinLower(uchr))
          elseif self.script == scriptType.boldItalic then
            dst_char = SU.utf8char(mathScriptConversionTable.boldItalicLatinLower(uchr))
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
      if self.text == "-" then
        self.text = "−"
      end
    end
  end,
  shape = function(self)
    self.options.size = self.options.size * self:getScaleDown()
    local face = SILE.font.cache(self.options, SILE.shaper.getFace)
    local mathMetrics = getMathMetrics()
    local glyphs = SILE.shaper:shapeToken(self.text, self.options)
    -- Use bigger variants for big operators in display style
    if isDisplayMode(self.mode) and self.atom == atomType.bigOperator then
      -- We copy the glyph list to avoid modifying the shaper's cache. Yes.
      glyphs = std.tree.clone(glyphs)
      local constructions = mathMetrics.mathVariants
        .vertGlyphConstructions[glyphs[1].gid]
      if constructions then
        local displayVariants = constructions.mathGlyphVariantRecord
        -- We select the biggest variant. TODO: we shoud probably select the
        -- first variant that is higher than displayOperatorMinHeight.
        local biggest
        local m = 0
        for i, v in ipairs(displayVariants) do
          if v.advanceMeasurement > m then
            biggest = v
            m = v.advanceMeasurement
          end
        end
        if biggest then
          glyphs[1].gid = biggest.variantGlyph
          local dimen = hb.get_glyph_dimensions(face.data,
            face.index, self.options.size, biggest.variantGlyph)
          print("Dimensions of big glyph for " .. self.text .. ": ")
          print(dimen)
          glyphs[1].width = dimen.width
          glyphs[1].glyphAdvance = dimen.glyphAdvance
          --[[ I am told (https://github.com/alif-type/xits/issues/90) that,
          in fact, the relative height and depth of display-style big operators
          in the font is not relevant, as these should be centered around the
          axis. So the following code does that, while conserving their
          vertical size (distance from top to bottom). ]]
          local axisHeight = mathMetrics.constants.axisHeight * self:getScaleDown()
          local y_size = dimen.height + dimen.depth
          glyphs[1].height = y_size / 2 + axisHeight
          glyphs[1].depth = y_size / 2 - axisHeight
          -- We still need to store the font's height and depth somewhere,
          -- because that's what will be used to draw the glyph, and we will need
          -- to artificially compensate for that.
          glyphs[1].fontHeight = dimen.height
          glyphs[1].fontDepth = dimen.depth
        end
      end
    end
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
    local compensatedY
    if isDisplayMode(self.mode) and self.atom == atomType.bigOperator
        and self.value.items[1].fontDepth then
      compensatedY = SILE.length.make(y.length + self.value.items[1].depth
        - self.value.items[1].fontDepth)
    else
      compensatedY = y
    end
    SILE.outputter.moveTo(getNumberFromLength(x, line), compensatedY.length)
    SILE.outputter.setFont(self.options)
    SILE.outputter.outputHbox(self.value, getNumberFromLength(self.width, line))
  end
}

local _fraction = _mbox {
  _type = "Fraction",
  init = function(self)
    _mbox.init(self)
    if self.numerator then table.insert(self.children, self.numerator)
    end
    if self.denominator then table.insert(self.children, self.denominator)
    end
  end,
  styleChildren = function(self)
    if not (self.numerator or self.denominator) then
      SU.error("Fraction cannot have both no numerator and no denominator")
    end
    if self.numerator then
      self.numerator.mode = getNumeratorMode(self.mode)
    end
    if self.denominator then
      self.denominator.mode = getDenominatorMode(self.mode)
    end
  end,
  shape = function(self)
    -- Determine relative abscissas and width
    local widest, other
    if self.numerator and self.denominator then
      if self.denominator.width > self.numerator.width then
        widest, other = self.denominator, self.numerator
      else
        widest, other = self.numerator, self.denominator
      end
    elseif self.numerator then widest, other = self.numerator, nil
    elseif self.denominator then widest, other = self.denominator, nil
    else
      error("Fraction cannot have both no numerator and no denominator")
    end
    widest.relX = SILE.length.make(0)
    other.relX = (widest.width - other.width) / 2
    self.width = widest.width

    -- Determine relative ordinates and height
    local constants = getMathMetrics().constants
    local scaleDown = self:getScaleDown()
    self.axisHeight = constants.axisHeight * scaleDown
    self.ruleThickness = constants.fractionRuleThickness * scaleDown
    if self.numerator then
      if isDisplayMode(self.mode) then
        self.numerator.relY = -self.axisHeight - self.ruleThickness/2 - maxLength(
          constants.fractionNumDisplayStyleGapMin*scaleDown + self.numerator.depth,
          constants.fractionNumeratorDisplayStyleShiftUp * scaleDown
            - self.axisHeight - self.ruleThickness/2)
      else
        self.numerator.relY = -self.axisHeight - self.ruleThickness/2 - maxLength(
          constants.fractionNumeratorGapMin*scaleDown + self.numerator.depth,
          constants.fractionNumeratorShiftUp * scaleDown - self.axisHeight
            - self.ruleThickness/2)
      end
    end
    if self.denominator then
      if isDisplayMode(self.mode) then
        self.denominator.relY = -self.axisHeight + self.ruleThickness/2 + maxLength(
          constants.fractionDenomDisplayStyleGapMin * scaleDown
            + self.denominator.height,
          constants.fractionDenominatorDisplayStyleShiftDown * scaleDown
            + self.axisHeight - self.ruleThickness/2)
      else
        self.denominator.relY = -self.axisHeight + self.ruleThickness/2 + maxLength(
          constants.fractionDenominatorGapMin * scaleDown
            + self.denominator.height,
          constants.fractionDenominatorShiftDown * scaleDown
           + self.axisHeight - self.ruleThickness/2)
      end
    end
    if self.numerator then
      self.height = 0 - self.numerator.relY + self.numerator.height
    else
      self.height = self.axisHeight + self.ruleThickness / 2
    end
    if self.denominator then
      self.depth = self.denominator.relY + self.denominator.depth
    else
      self.depth = SILE.length.make(0)
    end
  end,
  output = function(self, x, y, line)
    SILE.outputter.rule(
      getNumberFromLength(x, line),
      y.length - self.axisHeight - self.ruleThickness / 2,
      getNumberFromLength(self.width, line), self.ruleThickness)
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
      and operatorAtomTypes[spec.base.text] == atomType.bigOperator then
    ret = std.tree.clone(_bigOpSubscript(spec))
  else
    ret = std.tree.clone(_subscript(spec))
  end
  ret:init()
  return ret
end

-- not local, because used further up this file
newSpace = function(spec)
  local ret = std.tree.clone(_space(spec))
  ret:init()
  return ret
end

local newFraction = function(spec)
  local ret = std.tree.clone(_fraction(spec))
  ret:init()
  return ret
end

-- convert MathML into mbox
local function ConvertMathML(content)
  if content == nil or content.tag == nil then return nil end
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
    local script = content.attr.mathvariant and
      mathVariantToScriptType(content.attr.mathvariant) or scriptType.italic
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mi tag contains "..text..", which is not text")
    end
    return newText({ kind='identifier', script=script, text=text })
  elseif content.tag == 'mo' then
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mo tag contains "..text..", which is not text")
    end
    return newText({ kind='operator', script=scriptType.upright, text=text })
  elseif content.tag == 'mn' then
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mn tag contains "..text..", which is not text")
    end
    return newText({ kind='number', script=scriptType.upright, text=text })
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
  elseif content.tag == 'mfrac' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in mfrac: '
      ..#children)
    end
    return newFraction({ numerator=children[1], denominator=children[2] })
  else
    SU.error("Unknown math command " .. content.tag)
  end
end

-- Grammar to parse TeX-like math
local mathGrammar = function(_ENV)
  local _ = WS^0
  local eol = S"\r\n"
  local digit = R("09")
  local natural = digit^1 / tonumber
  local pos_natural = R("19") * digit^0 / tonumber
  local ctrl_word = R("AZ", "az")^1
  local ctrl_symbol = P(1)
  local ctrl_sequence_name = C(ctrl_word + ctrl_symbol) / 1
  local comment = (
      P"%" *
      P(1-eol)^0 *
      eol^-1
    )
  local utf8cont = R("\128\191")
  local utf8code = lpeg.R("\0\127")
    + lpeg.R("\194\223") * utf8cont
    + lpeg.R("\224\239") * utf8cont * utf8cont
    + lpeg.R("\240\244") * utf8cont * utf8cont * utf8cont
  -- Identifiers inside \mo and \mi tags
  local sileID = C(SILE.inputs.TeXlike.identifier + P(1)) / 1
  local mathMLID = (utf8code - S"\\{}%")^1 / function(...)
    local ret = ""
    local t = {...}
    for _,b in ipairs(t) do
      ret = ret .. b
    end
    return ret
  end
  local group = P"{" * V"mathlist" * (P"}" + E("`}` expected"))
  local element_no_infix =
    V"def" +
    V"command" +
    group +
    V"argument" +
    V"atom"
  local element =
    V"supsub" +
    V"subsup" +
    V"sup" +
    V"sub" +
    element_no_infix
  local sep = S",;" * _
  local quotedString = (P'"' * C((1-P'"')^1) * P'"')
  local value = ( quotedString + (1-S",;]")^1 )
  local pair = Cg(sileID * _ * "=" * _ * C(value)) * sep^-1 / function (...)
    local t = {...}; return t[1], t[#t] end
  local list = Cf(Ct"" * pair^0, rawset)
  local parameters = (
      P"[" *
      list *
      P"]"
    )^-1 / function (a) return type(a)=="table" and a or {} end

  START "texlike_math"
  texlike_math = V"mathlist" * EOF"Unexpected character at end of math code"
  mathlist = (comment + (WS * _) + element)^0
  supsub = element_no_infix * _ * P"^" * _ * element_no_infix * _ *
    P"_" * _ * element_no_infix
  subsup = element_no_infix * _ * P"_" * _ * element_no_infix * _ *
    P"^" * _ * element_no_infix
  sup = element_no_infix * _ * P"^" * _ * element_no_infix
  sub = element_no_infix * _ * P"_" * _ * element_no_infix
  atom = C(utf8code - S"\\{}%^_")
  command = (
      P"\\" *
      Cg(ctrl_sequence_name, "tag") *
      Cg(parameters, "attr") *
      (
        group
      )^0
    )
  def = P"\\def" * _ * P"{" *
    Cg(ctrl_sequence_name, "command-name") * P"}" * _ *
    --P"[" * Cg(digit^1, "arity") * P"]" * _ *
    P"{" * V"mathlist" * P"}"
  argument = P"#" * Cg(pos_natural, "index")
end
local mathParser = epnf.define(mathGrammar)

local function massageMathAst(tree)
  if type(tree) == "string" then return tree end
  for i,child in ipairs(tree) do
    tree[i] = massageMathAst(tree[i])
  end
  if tree.id == "texlike_math" then
    tree.tag = "math"
  elseif tree.id == "mathlist" then
    -- Turn mathlist into mrow except if it has exactly one child
    if #tree == 1 then return tree[1]
    else tree.tag = "mrow" end
  end

  return tree
end

local commands = {}

-- A command type is a type for each argument it takes: either string or MathML
-- tree. If a command has no type, it is assumed to take only trees.
-- Tags like <mi>, <mo>, <mn> take a string, and this needs to be propagated in
-- commands that use them.

local objType = {
  tree = 1,
  str = 2
}

local function inferArgTypes_aux(acc, typeRequired, body)
  print("inferArgTypes_aux")
  print("  acc = "..acc)
  print("  typeRequired = "..typeRequired)
  print("  body = "..body)
  if type(body) == "table" then
    if body.id == "argument" then
      local ret = acc
      table.insert(ret, body.index, typeRequired)
      return ret
    elseif body.id == "command" then
      if commands[body.tag] then
        local cmdArgTypes = commands[body.tag][1]
        if #cmdArgTypes ~= #body then
          SU.error("Wrong number of arguments (" .. #body ..
            ") for command " .. body.tag .. " (should be " ..
            #cmdArgTypes .. ")")
        else
          for i = 1, #cmdArgTypes do
            acc = inferArgTypes_aux(acc, cmdArgTypes[i], body[i])
          end
        end
        return acc
      elseif body.tag == "mi" or body.tag == "mo" or body.tag == "mn" then
        if #body ~= 1 then
          SU.error("Wrong number of arguments ("..#body..") for tag "..
            body.tag.." (should be 1)")
        end
        acc = inferArgTypes_aux(acc, objType.str, body[1])
        return acc
      else
        -- Not a macro, recurse on children assuming tree type for all
        -- arguments
        for _, child in ipairs(body) do
          acc = inferArgTypes_aux(acc, objType.tree, child)
        end
        return acc
      end
    elseif body.id == "atom" then
      return acc
    else
      -- Simply recurse on children
      for _, child in ipairs(body) do
        acc = inferArgTypes_aux(acc, typeRequired, child)
      end
      return acc
    end
  else SU.error("invalid argument to inferArgTypes_aux") end
end

local inferArgTypes = function(body)
  return inferArgTypes_aux({}, objType.tree, body)
end

local function registerCommand(name, argTypes, fun)
  commands[name] = {argTypes, fun}
end

local function fold_pairs(fun, init, table)
  local acc = init
  for k,x in pairs(table) do
    acc = fun(acc, k, x)
  end
  return acc
end

local function fold_tree(fun, init, tree)
  local acc = init
  if type(tree) == "table" then
    for i, child in ipairs(tree) do
      acc = fold_tree(fun, acc, child)
    end
  end
  return fun(acc, tree)
end

local compileToStr = function(argEnv, atomlist)
  print("compileToStr "..atomlist)
  if #atomlist == 1 and atomlist.id == "atom" then
    -- List is a single atom
    return atomlist[1]
  elseif atomlist.id == "argument" then
    return argEnv[atomlist.index]
  else
    local ret = ""
    for _,atom in ipairs(atomlist) do
      if atom.id ~= "atom" then
        SU.error("Encountered non-character token in command that takes a string")
      end
      ret = ret .. atom[1]
    end
    return ret
  end
end

local function compileToMathML(arg_env, tree)
  print("compileToMathML "..tree)
  if type(tree) == "string" then return tree end
  tree = fold_pairs(function(acc, key, child)
    if type(key) ~= "number" then
      acc[key] = child
      return acc
    -- Compile all children, except if this node is a macro definition (no
    -- evaluation "under lambda") or the application of a registered macro
    -- (since evaluating the nodes depends on the macro's signature, it is more
    -- complex and done below)..
    elseif tree.id == "def" or (tree.id == "command" and commands[tree.tag]) then
      -- Conserve unevaluated children.
      table.insert(acc, child)
    else
      -- Compile all children.
      local comp = compileToMathML(arg_env, child)
      if comp then table.insert(acc, comp) end
    end
    return acc
  end, {}, tree)
  if tree.id == "atom" then
    if lpeg.match(lpeg.R("az","AZ"), tree[1]) then
      tree.tag = "mi"
    elseif lpeg.match(lpeg.R("09")^1, tree[1]) then
      tree.tag = "mn"
    else
      tree.tag = "mo"
    end
    tree.attr = {}
  elseif tree.id == "sup" then
    tree.tag = "msup"
  elseif tree.id == "sub" then
      tree.tag = "msub"
  elseif tree.id == "subsup" then
    tree.tag = "msubsup"
  elseif tree.id == "supsub" then
    tree.tag = "msubsup"
    local tmp = tree[2]
    tree[2] = tree[3]
    tree[3] = tmp
  elseif tree.id == "def" then
    local commandName = tree["command-name"]
    print("defining command " .. commandName)
    local argTypes = inferArgTypes(tree[1])
    print("argtypes inferred: "..argTypes)
    registerCommand(commandName, argTypes, function(compiledArgs)
      print("evaluating command ".. commandName .." with body "..tree[1].." on compiled args "..compiledArgs)
      print("compiling body "..tree[1].." under env: "..compiledArgs)
      return compileToMathML(compiledArgs, tree[1])
    end)
    return nil
  elseif tree.id == "command" and commands[tree.tag] then
    local argTypes = commands[tree.tag][1]
    local cmdFun = commands[tree.tag][2]
    local applicationTree = tree
    local cmdName = tree.tag
    print("evaluating command ".. cmdName .." with body "..tree[1].." on app. tree "..applicationTree)
    print("argTypes = "..argTypes)
    if #applicationTree ~= #argTypes then
      SU.error("Wrong number of arguments (" .. #applicationTree ..
        ") for command " .. cmdName .. " (should be " ..
        #argTypes .. ")")
    end
    -- Compile every argument
    local compiledArgs = {}
    for i,arg in pairs(applicationTree) do
      if type(i) == "number" then
        if argTypes[i] == objType.tree then
          table.insert(compiledArgs, compileToMathML(arg_env, arg))
        else
          local x = compileToStr(arg_env, arg)
          print("compileToStr returned "..x)
          table.insert(compiledArgs, x)
        end
      else
        -- Not an argument but an attribute. Add it to the compiled
        -- argument tree as-is
        compiledArgs[i] = applicationTree[i]
      end
    end
    return cmdFun(compiledArgs)
  elseif tree.id == "argument" then
    print("Encountered arg #"..tree.index..", arg_env = "..arg_env)
    print("type(tree.index) == "..type(tree.index))
    if arg_env[tree.index] then
      print("in if")
      return arg_env[tree.index]
    else
      print("in else")
      SU.error("Argument #"..tree.index.." has escaped its scope (probably not fully applied command).")
    end
  end
  tree.id = nil
  print("compileToMathML results in "..tree)
  return tree
end

local function convertTexlike(content)
  local ret = epnf.parsestring(mathParser, content[1])
  print("convertTexlike: before massaging: \n"..ret)
  ret = massageMathAst(ret)
  print("convertTexlike: after massaging: \n"..ret)
  return ret
end

SILE.nodefactory.math = {
  newText = newText,
  newStackbox = newStackbox
}

local function handleMath(mbox, mode)
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
end

SILE.registerCommand("math", function (options, content)
  local mode = (options and options.mode) and options.mode or 'text'

  local mbox
  xpcall(function()
      mbox = ConvertMathML(content, mbox)
  end, function(err) print(err); print(debug.traceback()) end)

  handleMath(mbox, mode)
end)

SILE.registerCommand("texmath", function(options, content)
  local mode = (options and options.mode) and options.mode or "text"

  local mbox
  xpcall(function()
    mbox = ConvertMathML(compileToMathML({}, convertTexlike(content)))
  end, function(err) print(err); print(debug.traceback()) end)

  handleMath(mbox, mode)
end)

registerCommand("mi", {[1]=objType.str}, function(x) return x end)
registerCommand("mo", {[1]=objType.str}, function(x) return x end)
registerCommand("mn", {[1]=objType.str}, function(x) return x end)
