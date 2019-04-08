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

-- local scriptConversionTable {
--   scriptType.bold =
-- }

local function isCrampedMode(mode)
  return mode % 2 == 1
end

local mathScriptConversionTable = {
  italicLatinUpper = function(codepoint) return codepoint + 0x1D434 - 0x41 end,
  italicLatinLower = function(codepoint) return codepoint == 0x68 and 0x210E or codepoint + 0x1D44E - 0x61 end
}

SILE.settings.declare({name = "math.font.family", type = "string", default = "XITS Math"})

local mathCache = {}

local function getMathMetrics(options)
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
  return {
    constants = constants
  }
end

-- Style transition functions for superscript and subscript
local function getSuperscriptMode(mode)
  if mode == mathMode.display or mode == mathMode.displayCramped then return mathMode.script                 -- D, T -> S
  elseif mode == mathMode.displayCramped or mode == mathMode.textCramped then return mathMode.scriptCramped  -- D', T' -> S'
  elseif mode == mathMode.script or mode == mathMode.scriptScript then return mathMode.scriptScript          -- S, SS -> SS
  else return mathMode.scriptScriptCramped end                                                                   -- S', SS' -> SS'
end
local function getSubscriptMode(mode)
  if mode == mathMode.display or mode == mathMode.displayCramped
      or mode == mathMode.displayCramped or mode == mathMode.textCramped then return mathMode.scriptCramped  -- D, T, D', T' -> S'
  else return mathMode.scriptScriptCramped end                                                                   -- S, SS, S', SS' -> SS'
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
  if mode == mathMode.display or mode == mathMode.displayCramped then return mathMode.text           -- D, D' -> T'
  elseif mode == mathMode.text or mode == mathMode.textCramped then return mathMode.script           -- T, T' -> S'
  else return mathMode.scriptScriptCramped end                                                           -- S, SS, S', SS' -> SS'
end 

function _box:isMathBox () return self.type == "math" end

-- function _box:isRule () return self.type == "rule" end

-- math box, box with a horizontal shift value and could contain zero or more _mbox'es (or its child classes)
-- the entire math environment itself is a top-level mbox.
-- Typesetting of mbox evolves four steps:
--   1. Determine the mode for each mbox according to their parent.
--   2. Shape the mbox hierarchy from leaf to top. Get the shape and relative position.
--   3. Convert mbox into _nnode's to put in SILE's typesetting framwork
local _mbox = _box {
  _type = "Mbox",
  type = "math",
  options = {},
  children = {}, -- The child nodes
  relX = 0, -- x position relative to its parent box
  relY = 0, -- y position relative to its parent box
  value = {},
  __tostring = function (s) return s.type end,
  init = function(self)
    local options = {
      family=SILE.settings.get("math.font.family")
    }
    self.options = SILE.font.loadDefaults(options)
  end,

  styleChildren = function(self)
    SU.error("This is a virtual function that need to be overriden by its child classes")
  end,

  setChildrenRelXY = function(self)
    SU.error("This is a virtual function that need to be overriden by its child classes")
  end,

  output = function(self, x, y)
    SU.error("This is a virtual function that need to be overriden by its child classes")
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
    self:setChildrenRelXY()
    self:shape()
  end,

  shape = function(self)
    local minX, maxX, minY, maxY = 0, 0, 0, 0
    for i, n in ipairs(self.children) do
      if n then
        minX = math.min(minX, n.relX)
        maxX = math.max(maxX, n.relX + n.width)
        minY = math.min(minY, n.relY - n.height)
        maxY = math.max(maxY, n.relY + n.depth)
      end
    end
    self.width = maxX - minX
    self.height = -minY
    self.depth = maxY
  end,

  -- Output the node and all its descendants
  outputTree = function(self, x, y)
    self:output(x, y)
    for i, n in ipairs(self.children) do
      if n then n:outputTree(x + n.relX, y + n.relY) end
    end
  end
}

local _nil = _mbox {
  _type = 'Nil'
}

-- _stackbox stacks its content one, either horizontally or vertically
local _stackbox = _mbox {
  _type = "Stackbox",
  direction = "H", -- 'H' for horizontal, 'V' for vertical
  __tostring = function (self)
    local result = self.direction.."Box("
    for i, n in ipairs(self.children) do
      result = result..(i == 1 and "" or ", ")..tostring(n)
    end
    result = result..")"
    return result
  end,

  styleChildren = function(self)
    for i, n in ipairs(self.children) do
      n.mode = self.mode
    end
  end,
  setChildrenRelXY = function(self)
    if self.children and #(self.children) > 0 then
      for i, n in ipairs(self.children) do
        if i == 1 then
          -- Assuming the first children has the same anchor point as the parent
          n.relX = 0
          n.relY = 0
        else
          if self.direction == "H" then
            -- Horizontal stackbox
            n.relX = self.children[i - 1].relX + self.children[i - 1].width
            n.relY = 0
          else -- self.direction == "V"
            n.relX = 0
            n.relY = self.children[i - 1].relY + self.children[i - 1].depth + n.height
          end
        end
      end
    else
      self.relX = 0
      self.relY = 0
    end
  end,
  shape = function(self)
    -- Get the minimum box that contains all children. Baseline is determined by relX, relY.
    -- Along the stacking direction, the size of computed as last.end - first.start.
    -- On the other direction, the size is max(end) - min(start).
    -- Note that width/height/depth of children can all be negative.
    if self.children and #(self.children) > 0 then
      local first = self.children[1]
      local last = self.children[#(self.children)]
      if self.direction == 'H' then
        self.width = last.relX + last.width - first.relX
        for i, n in ipairs(self.children) do
          if i == 1 then
            self.height = n.height - n.relY
            self.depth = n.depth + n.relY
          else
            if n.height - n.relY > self.height then self.height = n.height - n.relY end
            if n.depth + n.relY > self.depth then self.depth = n.depth + n.relY end
          end
        end
      else -- self.direction == 'V"
        self.height = first.height - first.relY
        self.depth = last.depth + first.relY
        local minX = self.children[0].relX
        local maxX = self.children[0].relX
        for i, n in ipairs(self.children) do
          if n.relX < minX then minX = n.relX end
          if n.relX > maxX then maxX = n.relX end
        end
        self.width = maxX - minX
      end
    else
      self.width = 0
      self.height = 0
      self.depth = 0
    end
  end,
  -- Despite of its name, this function actually output the whole tree of nodes recursively.
  outputYourself = function(self, typesetter, line)
    local mathX = typesetter.frame.state.cursorX
    local mathY = typesetter.frame.state.cursorY
    self:outputTree(mathX + self.relX, mathY + self.relY)
    typesetter.frame.state.cursorX = mathX + self.width
    typesetter.frame.state.curosrY = mathY
  end,
  output = function(self, x, y) end
}

local _subscript = _mbox {
  _type = "Subscript",
  kind = "sub",
  init = function(self)
    _mbox.init(self)
    if self.kind == "sup" then
      self.children[3] = self.children[2]
      self.children[2] = false
    end
  end,
  styleChildren = function(self)
    self.children[1].mode = self.mode
    if self.children[2] then self.children[2].mode = getSubscriptMode(self.mode) end
    if self.children[3] then self.children[3].mode = getSuperscriptMode(self.mode) end
  end,
  setChildrenRelXY = function(self)
    local constants = getMathMetrics(self.options).constants
    print(constants)
    self.children[1].relX = 0
    self.children[1].relY = 0
    if self.children[2] then
      self.children[2].relX = self.children[1].width
      self.children[2].relY = table.maxn({
        constants.subscriptShiftDown,
        self.children[1].depth + constants.subscriptBaselineDropMin,
        self.children[2].height - constants.subscriptTopMax
      })
    end
    if self.children[3] then
      self.children[3].relX = self.children[1].width
      self.children[3].relY = -table.maxn({
        isCrampedMode(self.children[3].mode) and constants.superscriptShiftUpCramped or constants.superscriptShiftUp, -- or cramped
        self.children[1].height - constants.superscriptBaselineDropMax,
        self.children[3].depth + constants.superscriptBottomMin
      })
    end
    if self.children[2] and self.children[3] then
      local gap = self.children[2].relY - self.children[2].height - self.children[3].relY - self.children[3].depth
      if gap < constants.subSuperscriptGapMin then
        local supShift, subShift = constants.subSuperscriptGapMin - gap, 0
        if supShift > constants.superscriptBottomMaxWithSubscript then
          subShift = supShift - constants.superscriptBottomMaxWithSubscript
          supShift = constants.superscriptBottomMaxWithSubscript
        end
        self.children[3].relY = self.children[3].relY - supShift
        self.children[2].relY = self.children[2].relY + subShift
      end
    end
  end,
  output = function(self, x, y) end
}

-- _terminal is the base class for leaf node
local _terminal = _mbox {
  type = "terminal",
  styleChildren = function(self) end,
  setChildrenRelXY = function(self) end
}

-- text node
local _text = _terminal {
  _type = "Text",
  text = "",
  script = scriptType.upright,
  __tostring = function(self) return "Text("..(self.originalText or self.text)..")" end,
  init = function(self)
    _terminal.init(self)
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
  end,
  shape = function(self)
    local face = SILE.font.cache(self.options, SILE.shaper.getFace)
    if self.mode == mathMode.script or self.mode == mathMode.scriptCramped then
      local fontSize = math.floor(self.options.size * 0.7)
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
      self.width = glyphs[#glyphs].width
      for i = 1, #glyphs-1 do
        self.width = self.width + glyphs[i].glyphAdvance
      end
      self.height = glyphs[1].height
      self.depth = glyphs[1].depth
      for i = 2, #glyphs do
        if glyphs[i].height > self.height then self.height = glyphs[i].height end
        if glyphs[i].depth > self.depth then self.depth = glyphs[i].depth end
      end
    else
      self.width = 0
      self.height = 0
      self.depth = 0
    end
  end,
  output = function(self, x, y)
    if not self.value.glyphString then return end
    print('Output '..self.value.glyphString.." to "..x..", "..y)
    SILE.outputter.moveTo(x, y)
    SILE.outputter.setFont(self.options)
    SILE.outputter.outputHbox(self.value, self.width)
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
  local ret = std.tree.clone(_subscript(spec))
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
    return newStackbox({
      direction='V', children=convertChildren(content) })
  elseif content.tag == 'mrow' then
    return newStackbox({
      direction='H', children=convertChildren(content) })
  elseif content.tag == 'mi' then
    return newText({ script=scriptType.italic, text=content[1] })
  elseif content.tag == 'mo' then
    return newText({ script=scriptType.upright, text=content[1] })
  elseif content.tag == 'mn' then
    return newText({ script=scriptType.upright, text=content[1] })
  elseif content.tag == 'msub' then
    return newSubscript({
      kind="sub", children=convertChildren(content) })
  elseif content.tag == 'msup' then
    return newSubscript({
      kind="sup", children=convertChildren(content) })
  elseif content.tag == 'msubsup' then
    return newSubscript({
      kind="subsup", children=convertChildren(content) })
  else
    return nil
  end
end

SILE.nodefactory.math = {
  newText=newText,
  newStackbox = newStackbox
}

SILE.typesetter.pushMath = function(self, mbox)
  return self:pushHorizontal(mbox)
end

SILE.registerCommand("math", function (options, content)
  local mode = (options and options.mode) and options.mode or 'text'

  local mbox = ConvertMathML(content, mbox)

  if #(mbox.children) == 1 then
    mbox = mbox.children[1]
  end

  mbox.mode = mathMode.display -- or text
  mbox:styleDescendants()

  mbox:shapeTree()

  SILE.typesetter:pushMath(mbox)

end)