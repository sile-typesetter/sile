local nodefactory = require("core.nodefactory")
local hb = require("justenoughharfbuzz")
local ot = require("core.opentype-parser")
local syms = require("packages.math.unicode-symbols")

local atomType = syms.atomType
local symbolDefaults = syms.symbolDefaults

local elements = {}

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
    attr == "bold" and scriptType.bold or
    attr == "italic" and scriptType.italic or
    attr == "bold-italic" and scriptType.boldItalic or
    attr == "double-struck" and scriptType.doubleStruck or
    SU.error("Invalid value \""..attr.."\" for option mathvariant")
end

-- Foward declaration
local newStandardHspace

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
  capital = {
    [scriptType.upright] = function(codepoint) return codepoint end,
    [scriptType.bold] = function(codepoint)
      return codepoint + 0x1D400 - 0x41
    end,
    [scriptType.italic] = function(codepoint) return codepoint + 0x1D434 - 0x41 end,
    [scriptType.boldItalic] = function(codepoint) return codepoint + 0x1D468 - 0x41 end,
    [scriptType.doubleStruck] = function(codepoint)
      return codepoint == 0x43 and 0x2102 or
        codepoint == 0x48 and 0x210D or
        codepoint == 0x4E and 0x2115 or
        codepoint == 0x50 and 0x2119 or
        codepoint == 0x51 and 0x211A or
        codepoint == 0x52 and 0x211D or
        codepoint == 0x5A and 0x2124 or
        codepoint + 0x1D538 - 0x41
    end
  },
  small = {
    [scriptType.upright] = function(codepoint) return codepoint end,
    [scriptType.bold] = function(codepoint) return codepoint + 0x1D41A - 0x61 end,
    [scriptType.italic] = function(codepoint) return codepoint == 0x68 and 0x210E or codepoint + 0x1D44E - 0x61 end,
    [scriptType.boldItalic] = function(codepoint) return codepoint + 0x1D482 - 0x61 end,
    [scriptType.doubleStruck] = function(codepoint) return codepoint + 0x1D552 - 0x61 end,
  }
}

local function retrieveMathTable(options)
  SU.debug("math", "Loading math font: " .. options.family)
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
    family=SILE.settings:get("math.font.family"),
    size=SILE.settings:get("math.font.size")
  }
  local filename = SILE.settings:get("math.font.filename")
  if filename and filename ~= "" then options.filename = filename end
  mathCache = retrieveMathTable(options)
  return mathCache
end

-- Style transition functions for superscript and subscript
local function getSuperscriptMode(mode)
  -- D, T -> S
  if mode == mathMode.display or mode == mathMode.text then
    return mathMode.script
  -- D', T' -> S'
  elseif mode == mathMode.displayCramped or mode == mathMode.textCramped then
    return mathMode.scriptCramped
  -- S, SS -> SS
  elseif mode == mathMode.script or mode == mathMode.scriptScript then
    return mathMode.scriptScript
  -- S', SS' -> SS'
  else return mathMode.scriptScriptCramped end
end
local function getSubscriptMode(mode)
  -- D, T, D', T' -> S'
  if mode == mathMode.display or mode == mathMode.text
      or mode == mathMode.displayCramped or mode == mathMode.textCramped then
      return mathMode.scriptCramped
  -- S, SS, S', SS' -> SS'
  else return mathMode.scriptScriptCramped end
end

-- Style transition functions for fraction (numerator and denominator)
local function getNumeratorMode(mode)
  -- D -> T
  if mode == mathMode.display then
    return mathMode.text
  -- D' -> T'
  elseif mode == mathMode.displayCramped then
    return mathMode.textCramped
  -- T -> S
  elseif mode == mathMode.text then
    return mathMode.script
  -- T' -> S'
  elseif mode == mathMode.textCramped then
    return mathMode.scriptCramped
  -- S, SS -> SS
  elseif mode == mathMode.script or mode == mathMode.scriptScript then
    return mathMode.scriptScript
  -- S', SS' -> SS'
  else return mathMode.scriptScriptCramped end
end
local function getDenominatorMode(mode)
  -- D, D' -> T'
  if mode == mathMode.display or mode == mathMode.displayCramped then
    return mathMode.textCramped
  -- T, T' -> S'
  elseif mode == mathMode.text or mode == mathMode.textCramped then
    return mathMode.scriptCramped
  -- S, SS, S', SS' -> SS'
  else return mathMode.scriptScriptCramped end
end

local function getRightMostGlyphId(node)
  while node and node:is_a(elements.stackbox) and node.direction == 'H' do
    node = node.children[#(node.children)]
  end
  if node and node:is_a(elements.text) then
    return node.value.glyphString[#(node.value.glyphString)]
  else
    return 0
  end
end

-- Compares two SILE length, without considering shrink or stretch values, and
-- returns the biggest.
local function maxLength(...)
  local arg = {...}
  local m
  for i, v in ipairs(arg) do
    if i == 1 then
      m = v
    else
      if v.length:tonumber() > m.length:tonumber() then
        m = v
      end
    end
  end
  return m
end

local function scaleWidth(length, line)
  local number = length.length
  if line.ratio and line.ratio < 0 and length.shrink:tonumber() > 0 then
    number = number + length.shrink * line.ratio
  elseif line.ratio and line.ratio > 0 and length.stretch:tonumber() > 0 then
    number = number + length.stretch * line.ratio
  end
  return number
end

-- math box, box with a horizontal shift value and could contain zero or more
-- mbox'es (or its child classes) the entire math environment itself is
-- a top-level mbox.
-- Typesetting of mbox evolves four steps:
--   1. Determine the mode for each mbox according to their parent.
--   2. Shape the mbox hierarchy from leaf to top. Get the shape and relative position.
--   3. Convert mbox into _nnode's to put in SILE's typesetting framwork
elements.mbox = pl.class({
  _base = nodefactory.box,
  _type = "Mbox",
  __tostring = function (s) return s.type end,
  _init = function(self)
    self.options = {}
    self.children = {} -- The child nodes
    self.relX = SILE.length(0) -- x position relative to its parent box
    self.relY = SILE.length(0) -- y position relative to its parent box
    self.value = {}
    self.mode = mathMode.display
    self.atom = atomType.ordinary
    local options = {
      family=SILE.settings:get("math.font.family"),
      size=SILE.settings:get("math.font.size")
    }
    local filename = SILE.settings:get("math.font.filename")
    if filename and filename ~= "" then options.filename = filename end
    self.options = SILE.font.loadDefaults(options)
  end,

  styleChildren = function(_)
    SU.error("styleChildren is a virtual function that need to be overriden by its child classes")
  end,

  shape = function(_, _, _)
    SU.error("shape is a virtual function that need to be overriden by its child classes")
  end,

  output = function(_, _, _, _)
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
    for _, n in ipairs(self.children) do
      if n then n:styleDescendants() end
    end
  end,

  -- shapeTree shapes the mbox and all its descendants in a recursive fashion
  -- The inner-most leaf nodes determine their shape first, and then propagate to their parents
  -- During the process, each node will determine its size by (width, height, depth)
  -- and (relX, relY) which the relative position to its parent
  shapeTree = function(self)
    for _, n in ipairs(self.children) do
      if n then n:shapeTree() end
    end
    self:shape()
  end,

  -- Output the node and all its descendants
  outputTree = function(self, x, y, line)
    self:output(x, y, line)
    local debug = SILE.settings:get("math.debug.boxes")
    if debug and not (self:is_a(elements.space)) then
      SILE.outputter:setCursor(scaleWidth(x, line), y.length)
      SILE.outputter:debugHbox(
        { height = self.height.length,
          depth = self.depth.length },
        scaleWidth(self.width, line)
      )
    end
    for _, n in ipairs(self.children) do
      if n then n:outputTree(x + n.relX, y + n.relY, line) end
    end
  end
})

local spaceKind = {
  thin = "thin",
  med = "med",
  thick = "thick",
}

-- Indexed by left atom
local spacingRules = {
  [atomType.ordinary] = {
    [atomType.bigOperator] = {spaceKind.thin},
    [atomType.binaryOperator] = {spaceKind.med, notScript = true},
    [atomType.relationalOperator] = {spaceKind.thick, notScript = true},
    [atomType.inner] = {spaceKind.thin, notScript = true}
  },
  [atomType.bigOperator] = {
    [atomType.ordinary] = {spaceKind.thin},
    [atomType.bigOperator] = {spaceKind.thin},
    [atomType.relationalOperator] = {spaceKind.thick, notScript = true},
    [atomType.inner] = {spaceKind.thin, notScript = true},
  },
  [atomType.binaryOperator] = {
    [atomType.ordinary] = {spaceKind.med, notScript = true},
    [atomType.bigOperator] = {spaceKind.med, notScript = true},
    [atomType.openingSymbol] = {spaceKind.med, notScript = true},
    [atomType.inner] = {spaceKind.med, notScript = true}
  },
  [atomType.relationalOperator] = {
    [atomType.ordinary] = {spaceKind.thick, notScript = true},
    [atomType.bigOperator] = {spaceKind.thick, notScript = true},
    [atomType.openingSymbol] = {spaceKind.thick, notScript = true},
    [atomType.inner] = {spaceKind.thick, notScript = true}
  },
  [atomType.closeSymbol] = {
    [atomType.bigOperator] = {spaceKind.thin},
    [atomType.binaryOperator] = {spaceKind.med, notScript = true},
    [atomType.relationalOperator] = {spaceKind.thick, notScript = true},
    [atomType.inner] = {spaceKind.thin, notScript = true}
  },
  [atomType.punctuationSymbol] = {
    [atomType.ordinary] = {spaceKind.thin, notScript = true},
    [atomType.bigOperator] = {spaceKind.thin, notScript = true},
    [atomType.relationalOperator] = {spaceKind.thin, notScript = true},
    [atomType.openingSymbol] = {spaceKind.thin, notScript = true},
    [atomType.closeSymbol] = {spaceKind.thin, notScript = true},
    [atomType.punctuationSymbol] = {spaceKind.thin, notScript = true},
    [atomType.inner] = {spaceKind.thin, notScript = true}
  },
  [atomType.inner] = {
    [atomType.ordinary] = {spaceKind.thin, notScript = true},
    [atomType.bigOperator] = {spaceKind.thin},
    [atomType.binaryOperator] = {spaceKind.med, notScript = true},
    [atomType.relationalOperator] = {spaceKind.thick, notScript = true},
    [atomType.openingSymbol] = {spaceKind.thin, notScript = true},
    [atomType.punctuationSymbol] = {spaceKind.thin, notScript = true},
    [atomType.inner] = {spaceKind.thin, notScript = true}
  }
}

-- _stackbox stacks its content one, either horizontally or vertically
elements.stackbox = pl.class({
  _base = elements.mbox,
  _type = "Stackbox",
  __tostring = function (self)
    local result = self.direction.."Box("
    for i, n in ipairs(self.children) do
      result = result..(i == 1 and "" or ", ")..tostring(n)
    end
    result = result..")"
    return result
  end,

  _init = function(self, direction, children)
    elements.mbox._init(self)
    if not (direction == "H" or direction == "V") then
      SU.error("Wrong direction '"..direction.."'; should be H or V")
    end
    self.direction = direction
    self.children = children
  end,

  styleChildren = function(self)
    for _, n in ipairs(self.children) do
      n.mode = self.mode
    end
    if self.direction == "H" then
      -- Insert spaces according to the atom type, following Knuth's guidelines
      -- in the TeXbook
      local spaces = {}
      for i = 1, #self.children-1 do
        local v = self.children[i]
        local v2 = self.children[i + 1]
        if spacingRules[v.atom] and spacingRules[v.atom][v2.atom] then
          local rule = spacingRules[v.atom][v2.atom]
          if not (rule.notScript and (isScriptMode(self.mode) or isScriptScriptMode(self.mode))) then
            spaces[i+1] = rule[1]
          end
        end
      end

      local spaceIdx = {}
      for i, _ in pairs(spaces) do
        table.insert(spaceIdx, i)
      end
      table.sort(spaceIdx, function(a, b) return a > b end)
      for _, idx in ipairs(spaceIdx) do
        local hsp = newStandardHspace(self.options.size * self:getScaleDown(), spaces[idx])
        table.insert(self.children, idx, hsp)
      end
    end
  end,

  shape = function(self)
    -- For a horizontal stackbox (i.e. mrow):
    -- 1. set self.height and self.depth to max element height & depth
    -- 2. handle stretchy operators
    -- 3. set self.width
    -- For a vertical stackbox:
    -- 1. set self.width to max element width
    -- 2. set self.height
    -- And finally set children's relative coordinates
    self.height = SILE.length(0)
    self.depth = SILE.length(0)
    if self.direction == "H" then
      for i,n in ipairs(self.children) do
        n.relY = SILE.length(0)
        self.height = i == 1 and n.height or maxLength(self.height, n.height)
        self.depth = i == 1 and n.depth or maxLength(self.depth, n.depth)
      end
      -- Handle stretchy operators
      for _,elt in ipairs(self.children) do
        if elt.is_a(elements.text) and elt.kind == 'operator'
            and elt.stretchy then
          elt:stretchyReshape(self.depth, self.height)
        end
      end
      -- Set self.width
      self.width = SILE.length(0)
      for i,n in ipairs(self.children) do
        n.relX = self.width
        self.width = i == 1 and n.width or self.width + n.width
      end
    else -- self.direction == "V"
      for i,n in ipairs(self.children) do
        n.relX = SILE.length(0)
        self.width = i == 1 and n.width or maxLength(self.width, n.width)
      end
      -- Set self.height and self.depth
      for i,n in ipairs(self.children) do
        self.depth = i == 1 and n.depth or self.depth + n.depth
      end
      for i = 1, #self.children do
        local n = self.children[i]
        if i == 1 then
          self.height = n.height
          self.depth = n.depth
        elseif i > 1 then
          n.relY = self.children[i - 1].relY + self.children[i - 1].depth + n.height
          self.depth = self.depth + n.height + n.depth
        end
      end
    end
  end,

  -- Despite of its name, this function actually output the whole tree of nodes recursively.
  outputYourself = function(self, typesetter, line)
    local mathX = typesetter.frame.state.cursorX
    local mathY = typesetter.frame.state.cursorY
    self:outputTree(self.relX + mathX, self.relY + mathY, line)
    typesetter.frame:advanceWritingDirection(scaleWidth(self.width, line))
  end,

  output = function(_, _, _, _) end
})

elements.subscript = pl.class({
  _base = elements.mbox,
  _type = "Subscript",
  _init = function(self, base, sub, sup)
    elements.mbox._init(self)
    self.base = base
    self.sub = sub
    self.sup = sup
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
        return mathMetrics.italicsCorrection[lastGid]
      end
    end
    return 0
  end,
  shape = function(self)
    local mathMetrics = getMathMetrics()
    local constants = mathMetrics.constants
    local scaleDown = self:getScaleDown()
    if self.base then
      self.base.relX = SILE.length(0)
      self.base.relY = SILE.length(0)
      -- Use widthForSubscript of base, if available
      self.width = self.base.widthForSubscript or self.base.width
    else
      self.width = SILE.length(0)
    end
    local itCorr = self:calculateItalicsCorrection() * scaleDown
    local subShift
    local supShift
    if self.sub then
      if self.isUnderOver or self.base.largeop then
        -- Ad hoc correction on integral limits, following LuaTeX's
        -- `\mathnolimitsmode=0` (see LuaTeX Reference Manual).
        subShift = -itCorr
      else
        subShift = 0
      end
      self.sub.relX = self.width + subShift
      self.sub.relY = SILE.length(math.max(
        constants.subscriptShiftDown * scaleDown,
        --self.base.depth + constants.subscriptBaselineDropMin * scaleDown,
        (self.sub.height - constants.subscriptTopMax * scaleDown):tonumber()
      ))
      if (self:is_a(elements.underOver)
          or self:is_a(elements.stackbox) or self.base.largeop) then
        self.sub.relY = maxLength(self.sub.relY,
          self.base.depth + constants.subscriptBaselineDropMin*scaleDown)
      end
    end
    if self.sup then
      if self.isUnderOver or self.base.largeop then
        -- Ad hoc correction on integral limits, following LuaTeX's
        -- `\mathnolimitsmode=0` (see LuaTeX Reference Manual).
        supShift = 0
      else
        supShift = itCorr
      end
      self.sup.relX = self.width + supShift
      self.sup.relY = SILE.length(math.max(
        isCrampedMode(self.mode)
        and constants.superscriptShiftUpCramped * scaleDown
        or constants.superscriptShiftUp * scaleDown, -- or cramped
        --self.base.height - constants.superscriptBaselineDropMax * scaleDown,
        (self.sup.depth + constants.superscriptBottomMin * scaleDown):tonumber()
      )) * (-1)
      if (self:is_a(elements.underOver)
          or self:is_a(elements.stackbox) or self.base.largeop) then
        self.sup.relY = maxLength(
          (0-self.sup.relY),
          self.base.height - constants.superscriptBaselineDropMax
          * scaleDown) * (-1)
        end
    end
    if self.sub and self.sup then
      local gap = self.sub.relY - self.sub.height - self.sup.relY - self.sup.depth
      if gap.length:tonumber() < constants.subSuperscriptGapMin * scaleDown then
        -- The following adjustment comes directly from Appendix G of he
        -- TeXbook (rule 18e).
        self.sub.relY = constants.subSuperscriptGapMin * scaleDown
          + self.sub.height + self.sup.relY + self.sup.depth
        local psi = constants.superscriptBottomMaxWithSubscript*scaleDown
          + self.sup.relY + self.sup.depth
        if psi:tonumber() > 0 then
          self.sup.relY = self.sup.relY - psi
          self.sub.relY = self.sub.relY - psi
        end
      end
    end

    self.width = self.width + maxLength(
      self.sub and self.sub.width + subShift or SILE.length(0),
      self.sup and self.sup.width + supShift or SILE.length(0)
    ) + constants.spaceAfterScript * scaleDown
    self.height = maxLength(
      self.base and self.base.height or SILE.length(0),
      self.sub and (self.sub.height - self.sub.relY) or SILE.length(0),
      self.sup and (self.sup.height - self.sup.relY) or SILE.length(0)
    )
    self.depth = maxLength(
      self.base and self.base.depth or SILE.length(0),
      self.sub and (self.sub.depth + self.sub.relY) or SILE.length(0),
      self.sup and (self.sup.depth + self.sup.relY) or SILE.length(0)
    )
  end,
  output = function(_, _, _, _) end
})

elements.underOver = pl.class({
  _base = elements.subscript,
  _type = "UnderOver",
  _init = function(self, base, sub, sup)
    elements.mbox._init(self)
    self.atom = base.atom
    self.base = base
    self.sub = sub
    self.sup = sup
    if self.sup then table.insert(self.children, self.sup) end
    if self.base then
      table.insert(self.children, self.base)
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
          or self.mode == mathMode.displayCramped) then
      self.isUnderOver = true
      elements.subscript.shape(self)
      return
    end
    local constants = getMathMetrics().constants
    local scaleDown = self:getScaleDown()
    -- Determine relative Ys
    if self.base then
      self.base.relY = SILE.length(0)
    end
    if self.sub then
      self.sub.relY = self.base.depth + SILE.length(math.max(
        (self.sub.height + constants.lowerLimitGapMin * scaleDown):tonumber(),
        constants.lowerLimitBaselineDropMin * scaleDown))
    end
    if self.sup then
      self.sup.relY = 0 - self.base.height - SILE.length(math.max(
        (constants.upperLimitGapMin * scaleDown + self.sup.depth):tonumber(),
        constants.upperLimitBaselineRiseMin * scaleDown))
    end
    -- Determine relative Xs based on widest symbol
    local widest, a, b
    if self.sub and self.sub.width > self.base.width then
      if self.sup and self.sub.width > self.sup.width then
        widest = self.sub
        a = self.base
        b = self.sup
      elseif self.sup then
        widest = self.sup
        a = self.base
        b = self.sub
      else
        widest = self.sub
        a = self.base
        b = nil
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
    widest.relX = SILE.length(0)
    local c = widest.width / 2
    if a then a.relX = c - a.width / 2 end
    if b then b.relX = c - b.width / 2 end
    local itCorr = self:calculateItalicsCorrection() * scaleDown
    if self.sup then self.sup.relX = self.sup.relX + itCorr / 2 end
    if self.sub then self.sub.relX = self.sub.relX - itCorr / 2 end
    -- Determine width and height
    self.width = maxLength(
      self.base and self.base.width or SILE.length(0),
      self.sub and self.sub.width or SILE.length(0),
      self.sup and self.sup.width or SILE.length(0)
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
  calculateItalicsCorrection = function(self)
    local lastGid = getRightMostGlyphId(self.base)
    if lastGid > 0 then
      local mathMetrics = getMathMetrics()
      if mathMetrics.italicsCorrection[lastGid] then
        local c = mathMetrics.italicsCorrection[lastGid]
        -- If this is a big operator, and we are in display style, then the
        -- base glyph may be bigger than the font size. We need to adjust the
        -- italic correction accordingly.
        if self.base.atom == atomType.bigOperator and isDisplayMode(self.mode) then
          c = c * (self.base and self.base.options.size / self.options.size or 1.0)
        end
        return c
      end
    end
    return 0
  end,
  output = function(_, _, _, _) end
})

-- terminal is the base class for leaf node
elements.terminal = pl.class({
  _base = elements.mbox,
  _type = "Terminal",
  styleChildren = function(_) end,
  shape = function(_) end
})

elements.space = pl.class({
  _base = elements.terminal,
  _type = "Space",
  __tostring = function(self)
    return "space{w = "..self.width..", h = "..self.height..", d = "..self.depth.."}"
  end,
  _init = function(self, width, height, depth)
    elements.terminal._init(self)
    self.width = width
    self.height = height
    self.depth = depth
  end,
  shape = function (_) end,
  output = function (_) end
})

-- text node. For any actual text output
elements.text = pl.class({
  _base = elements.terminal,
  _type = "Text",
  __tostring = function(self) return "Text("..(self.originalText or self.text)..")" end,
  _init = function(self, kind, attributes, script, text)
    elements.terminal._init(self)
    if not (kind == "number" or kind == "identifier" or kind == "operator") then
      SU.error("Unknown text node kind '"..kind.."'; should be one of: number, identifier, operator.")
    end
    self.kind = kind
    self.script = script
    self.text = text
    if self.script ~= 'upright' then
      local converted = ""
      for _, uchr in luautf8.codes(self.text) do
        local dst_char = luautf8.char(uchr)
        if uchr >= 0x41 and uchr <= 0x5A then -- Latin capital letter
          dst_char = luautf8.char(mathScriptConversionTable.capital[self.script](uchr))
        elseif uchr >= 0x61 and uchr <= 0x7A then -- Latin non-capital letter
          dst_char = luautf8.char(mathScriptConversionTable.small[self.script](uchr))
        end
        converted = converted..dst_char
      end
      self.originalText = self.text
      self.text = converted
    end
    if self.kind == 'operator' then
      if self.text == "-" then
        self.text = "−"
      end
      if symbolDefaults[self.text] then
        self.atom = symbolDefaults[self.text].atom
        self.stretchy = symbolDefaults[self.text].stretchy
      end
    end
    for attribute,value in pairs(attributes) do
      SU.debug("math", "attribute = " .. attribute .. ", value = " .. tostring(value))
      self[attribute] = value
    end
  end,

  shape = function(self)
    self.options.size = self.options.size * self:getScaleDown()
    local face = SILE.font.cache(self.options, SILE.shaper.getFace)
    local mathMetrics = getMathMetrics()
    local glyphs = SILE.shaper:shapeToken(self.text, self.options)
    -- Use bigger variants for big operators in display style
    if isDisplayMode(self.mode) and self.largeop then
      -- We copy the glyph list to avoid modifying the shaper's cache. Yes.
      glyphs = pl.tablex.deepcopy(glyphs)
      local constructions = mathMetrics.mathVariants
        .vertGlyphConstructions[glyphs[1].gid]
      if constructions then
        local displayVariants = constructions.mathGlyphVariantRecord
        -- We select the biggest variant. TODO: we shoud probably select the
        -- first variant that is higher than displayOperatorMinHeight.
        local biggest
        local m = 0
        for _, v in ipairs(displayVariants) do
          if v.advanceMeasurement > m then
            biggest = v
            m = v.advanceMeasurement
          end
        end
        if biggest then
          glyphs[1].gid = biggest.variantGlyph
          local dimen = hb.get_glyph_dimensions(face.data,
            face.index, self.options.size, biggest.variantGlyph)
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
      self.width = SILE.length(0)
      self.widthForSubscript = SILE.length(0)
      for i = #glyphs, 1, -1 do
        self.width = self.width + glyphs[i].glyphAdvance
      end
      -- Store width without italic correction somewhere
      self.widthForSubscript = self.width
      local itCorr = mathMetrics.italicsCorrection[glyphs[#glyphs].gid]
      if itCorr then
        self.width = self.width + itCorr * self:getScaleDown()
      end
      for i = 1, #glyphs do
        self.height = i == 1 and SILE.length(glyphs[i].height) or SILE.length(math.max(self.height:tonumber(), glyphs[i].height))
        self.depth = i == 1 and SILE.length(glyphs[i].depth) or SILE.length(math.max(self.depth:tonumber(), glyphs[i].depth))
      end
    else
      self.width = SILE.length(0)
      self.height = SILE.length(0)
      self.depth = SILE.length(0)
    end
  end,

  stretchyReshape = function(self, depth, height)
    -- Required depth+height of stretched glyph, in font units
    local mathMetrics = getMathMetrics()
    local upem = mathMetrics.unitsPerEm
    local sz = self.options.size
    local requiredAdvance = (depth + height):tonumber() * upem/sz
    SU.debug("math", "stretch: rA = "..requiredAdvance)
    -- Choose variant of the closest size. The criterion we use is to have
    -- an advance measurement as close as possible as the required one.
    -- The advance measurement is simply the depth+height of the glyph.
    -- Therefore, the selected glyph may be smaller or bigger than
    -- required.  TODO: implement assembly of stretchable glyphs form
    -- their parts for cases when the biggest variant is not big enough.
    -- We copy the glyph list to avoid modifying the shaper's cache. Yes.
    local glyphs = pl.tablex.deepcopy(self.value.items)
    local constructions = getMathMetrics().mathVariants
      .vertGlyphConstructions[glyphs[1].gid]
    if constructions then
      local variants = constructions.mathGlyphVariantRecord
      SU.debug("math", "stretch: variants = " .. tostring(variants))
      local closest
      local closestI
      local m = requiredAdvance - (self.depth+self.height):tonumber() * upem/sz
      SU.debug("math", "strech: m = " .. m)
      for i,v in ipairs(variants) do
        local diff = math.abs(v.advanceMeasurement - requiredAdvance)
        SU.debug("math", "stretch: diff = " .. diff)
        if diff < m then
          closest = v
          closestI = i
          m = diff
        end
      end
      SU.debug("math", "stretch: closestI = " .. tostring(closestI))
      if closest then
        -- Now we have to re-shape the glyph chain. We will assume there
        -- is only one glyph.
        -- TODO: this code is probably wrong when the vertical
        -- variants have a different width than the original, because
        -- the shaping phase is already done. Need to do better.
        glyphs[1].gid = closest.variantGlyph
        local face = SILE.font.cache(self.options, SILE.shaper.getFace)
        local dimen = hb.get_glyph_dimensions(face.data,
          face.index, self.options.size, closest.variantGlyph)
        glyphs[1].width = dimen.width
        glyphs[1].height = dimen.height
        glyphs[1].depth = dimen.depth
        glyphs[1].glyphAdvance = dimen.glyphAdvance
        self.width = SILE.length(dimen.glyphAdvance)
        self.depth = SILE.length(dimen.depth)
        self.height = SILE.length(dimen.height)
        SILE.shaper:preAddNodes(glyphs, self.value)
        self.value.items = glyphs
        self.value.glyphString = {glyphs[1].gid}
      end
    end
  end,

  output = function(self, x, y, line)
    if not self.value.glyphString then return end
    local compensatedY
    if isDisplayMode(self.mode)
        and self.atom == atomType.bigOperator
        and self.value.items[1].fontDepth then
      compensatedY = SILE.length(y.length + self.value.items[1].depth - self.value.items[1].fontDepth)
    else
      compensatedY = y
    end
    SILE.outputter:setCursor(scaleWidth(x, line), compensatedY.length)
    SILE.outputter:setFont(self.options)
    -- There should be no stretch or shrink on the width of a text
    -- element.
    local width = self.width.length
    SILE.outputter:drawHbox(self.value, width)
  end
})

elements.fraction = pl.class({
  _base = elements.mbox,
  _type = "Fraction",
  _init = function(self, numerator, denominator)
    elements.mbox._init(self)
    self.numerator = numerator
    self.denominator = denominator
    table.insert(self.children, numerator)
    table.insert(self.children, denominator)
  end,
  styleChildren = function(self)
    self.numerator.mode = getNumeratorMode(self.mode)
    self.denominator.mode = getDenominatorMode(self.mode)
  end,
  shape = function(self)
    -- Determine relative abscissas and width
    local widest, other
    if self.denominator.width > self.numerator.width then
      widest, other = self.denominator, self.numerator
    else
      widest, other = self.numerator, self.denominator
    end
    widest.relX = SILE.length(0)
    other.relX = (widest.width - other.width) / 2
    self.width = widest.width

    -- Determine relative ordinates and height
    local constants = getMathMetrics().constants
    local scaleDown = self:getScaleDown()
    self.axisHeight = constants.axisHeight * scaleDown
    self.ruleThickness = constants.fractionRuleThickness * scaleDown
    if isDisplayMode(self.mode) then
      self.numerator.relY = -self.axisHeight - self.ruleThickness/2 - SILE.length(math.max(
        (constants.fractionNumDisplayStyleGapMin*scaleDown + self.numerator.depth):tonumber(),
        constants.fractionNumeratorDisplayStyleShiftUp * scaleDown
          - self.axisHeight - self.ruleThickness/2))
    else
      self.numerator.relY = -self.axisHeight - self.ruleThickness/2 - SILE.length(math.max(
        (constants.fractionNumeratorGapMin*scaleDown + self.numerator.depth):tonumber(),
        constants.fractionNumeratorShiftUp * scaleDown - self.axisHeight
          - self.ruleThickness/2))
    end

    if isDisplayMode(self.mode) then
      self.denominator.relY = -self.axisHeight + self.ruleThickness/2 + SILE.length(math.max(
        (constants.fractionDenomDisplayStyleGapMin * scaleDown
          + self.denominator.height):tonumber(),
        constants.fractionDenominatorDisplayStyleShiftDown * scaleDown
          + self.axisHeight - self.ruleThickness/2))
    else
      self.denominator.relY = -self.axisHeight + self.ruleThickness/2 + SILE.length(math.max(
        (constants.fractionDenominatorGapMin * scaleDown
          + self.denominator.height):tonumber(),
        constants.fractionDenominatorShiftDown * scaleDown
         + self.axisHeight - self.ruleThickness/2))
    end

    self.height = self.numerator.height - self.numerator.relY
    self.depth = self.denominator.relY + self.denominator.depth
  end,
  output = function(self, x, y, line)
    SILE.outputter:drawRule(
      scaleWidth(x, line),
      y.length - self.axisHeight - self.ruleThickness / 2,
      scaleWidth(self.width, line), self.ruleThickness)
  end
})

local newSubscript = function(spec)
    return elements.subscript(spec.base, spec.sub, spec.sup)
end

local newUnderOver = function(spec)
  return elements.underOver(spec.base, spec.sub, spec.sup)
end

-- not local, because scope defined further up this file
newStandardHspace = function(fontSize, kind)
  local mu = fontSize / 18
  if kind == "thin" then
    return elements.space(SILE.length({
      length = 3 * mu,
      shrink = 0,
      stretch = 0
    }), SILE.length(0), SILE.length(0))
  elseif kind == "med" then
    return elements.space(SILE.length({
      length = 4 * mu,
      shrink = 4 * mu,
      stretch = 2 * mu
    }), SILE.length(0), SILE.length(0))
  elseif kind == "thick" then
    return elements.space(SILE.length({
      length = 5 * mu,
      shrink = 0,
      stretch = 5 * mu
    }), SILE.length(0), SILE.length(0))
  else
    SU.error("Unknown space type "..kind)
  end
end

-- TODO replace with penlight equivalent
local function mapList(f, l)
  local ret = {}
  for i,x in ipairs(l) do
    ret[i] = f(i, x)
  end
  return ret
end

elements.mtr = pl.class({
  _base = elements.mbox,
  _init = function(self, children)
    self.children = children
  end,
  styleChildren = function(self)
    for _,c in ipairs(self.children) do
      c.mode = self.mode
    end
  end,
  shape = function(_) end, -- done by parent table
  output = function(_) end
})

elements.table = pl.class({
  _base = elements.mbox,
  _type = "table",

  _init = function(self, children, options)
    self.children = children
    self.options = options
    self.nrows = #self.children
    self.ncols = math.max(table.unpack(mapList(function(_, row)
      return #row.children end, self.children)))
    SU.debug("math", "self.ncols = "..self.ncols)
    self.rowspacing = self.options.rowspacing and SILE.length(self.options.rowspacing)
      or SILE.length("7pt")
    self.columnspacing = self.options.columnspacing and SILE.length(self.options.columnspacing)
      or SILE.length("6pt")
    -- Pad rows that do not have enough cells by adding cells to the
    -- right.
    for i,row in ipairs(self.children) do
      for j = 1, (self.ncols - #row.children) do
        SU.debug("math", "padding i = "..i..", j = "..j)
        table.insert(row.children, elements.stackbox('H', {}))
        SU.debug("math", "size "..#row.children)
      end
    end
    if options.columnalign then
      local l = {}
      for w in string.gmatch(options.columnalign, "[^%s]+") do
        if not (w == "left" or w == "center" or w == "right") then
          SU.error("Invalid specifier in `columnalign` attribute: "..w)
        end
        table.insert(l, w)
      end
      -- Pad with last value of l if necessary
      for _ = 1, (self.ncols - #l), 1 do
        table.insert(l, l[#l])
      end
      -- On the contrary, remove excess values in l if necessary
      for _ = 1, (#l - self.ncols), 1 do
        table.remove(l)
      end
      self.options.columnalign = l
    else
      self.options.columnalign = pl.List.range(1, self.ncols):map(function(_) return "center" end)
    end
  end,

  styleChildren = function(self)
    if self.mode == mathMode.display and self.options.displaystyle ~= "false" then
      for _,c in ipairs(self.children) do
        c.mode = mathMode.display
      end
    else
      for _,c in ipairs(self.children) do
        c.mode = mathMode.text
      end
    end
  end,

  shape = function(self)
    -- Determine the height (resp. depth) of each row, which is the max
    -- height (resp. depth) among its elements. Then we only need to add it to
    -- the table's height and center every cell vertically.
    for _,row in ipairs(self.children) do
      row.height = SILE.length(0)
      row.depth = SILE.length(0)
      for _,cell in ipairs(row.children) do
        row.height = maxLength(row.height, cell.height)
        row.depth = maxLength(row.depth, cell.depth)
      end
    end
    self.vertSize = SILE.length(0)
    for i, row in ipairs(self.children) do
      self.vertSize = self.vertSize + row.height + row.depth +
        (i == self.nrows and SILE.length(0) or self.rowspacing) -- Spacing
    end
    local rowHeightSoFar = SILE.length(0)
    for i, row in ipairs(self.children) do
      row.relY = rowHeightSoFar + row.height - self.vertSize
      rowHeightSoFar = rowHeightSoFar + row.height + row.depth +
        (i == self.nrows and SILE.length(0) or self.rowspacing) -- Spacing
    end
    self.width = SILE.length(0)
    local thisColRelX = SILE.length(0)
    -- For every column...
    for i = 1,self.ncols do
      -- Determine its width
      local columnWidth = SILE.length(0)
      for j = 1,self.nrows do
        if self.children[j].children[i].width > columnWidth then
          columnWidth = self.children[j].children[i].width
        end
      end
      -- Use it to align the contents of every cell as required.
      for j = 1,self.nrows do
        local cell = self.children[j].children[i]
        if self.options.columnalign[i] == "left" then
          cell.relX = thisColRelX
        elseif self.options.columnalign[i] == "center" then
          cell.relX = thisColRelX + (columnWidth - cell.width) / 2
        elseif self.options.columnalign[i] == "right" then
          cell.relX = thisColRelX + (columnWidth - cell.width)
        else
          SU.error("invalid columnalign parameter")
        end
      end
      thisColRelX = thisColRelX + columnWidth +
        (i == self.ncols and SILE.length(0) or self.columnspacing) -- Spacing
    end
    self.width = thisColRelX

    -- Center myself vertically around the axis, and update relative Ys of rows accordingly
    local axisHeight = getMathMetrics().constants.axisHeight * self:getScaleDown()
    self.height = self.vertSize / 2 + axisHeight
    self.depth = self.vertSize / 2 - axisHeight
    for _,row in ipairs(self.children) do
      row.relY = row.relY + self.vertSize / 2 - axisHeight
      -- Also adjust width
      row.width = self.width
    end
  end,

  output = function(_) end
})

elements.mathMode = mathMode
elements.atomType = atomType
elements.scriptType = scriptType
elements.mathVariantToScriptType = mathVariantToScriptType
elements.symbolDefaults = symbolDefaults
elements.newSubscript = newSubscript
elements.newUnderOver = newUnderOver
elements.newStandardHspace = newStandardHspace

return elements
