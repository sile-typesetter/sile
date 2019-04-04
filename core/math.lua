local nodefactory = require("core/nodefactory")
require("core/typesetter")

local mathStyle = {
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

-- Style transition functions for superscript and subscript
local function getSuperscriptStyle(style)
  if style == mathStyle.display or style == mathStyle.displayCramped then return mathStyle.script                 -- D, T -> S
  elseif style == mathStyle.displayCramped or style == mathStyle.textCramped then return mathStyle.scriptCramped  -- D', T' -> S'
  elseif style == mathStyle.script or style == mathStyle.scriptScript then return mathStyle.scriptScript          -- S, SS -> SS
  else return mathStyle.scriptScriptCramped end                                                                   -- S', SS' -> SS'
end
local function getSubscriptStyle(style)
  if style == mathStyle.display or style == mathStyle.displayCramped
      or style == mathStyle.displayCramped or style == mathStyle.textCramped then return mathStyle.scriptCramped  -- D, T, D', T' -> S'
  else return mathStyle.scriptScriptCramped end                                                                   -- S, SS, S', SS' -> SS'
end

-- Style transition functions for fraction (numerator and denominator)
local function getNumeratorStyle(style)
  if style == mathStyle.display then return mathStyle.text                                                -- D -> T
  elseif style == mathStyle.displayCramped then return mathStyle.textCramped                              -- D' -> T'
  elseif style == mathStyle.text then return mathStyle.script                                             -- T -> S
  elseif style == mathStyle.textCramped then return mathStyle.scriptCramped                               -- T' -> S'
  elseif style == mathStyle.script or style == mathStyle.scriptScript then return mathStyle.scriptScript  -- S, SS -> SS
  else return mathStyle.scriptScriptCramped end                                                           -- S', SS' -> SS'
end
local function getDenominatorStyle(style)
  if style == mathStyle.display or style == mathStyle.displayCramped then return mathStyle.text           -- D, D' -> T'
  elseif style == mathStyle.text or style == mathStyle.textCramped then return mathStyle.script           -- T, T' -> S'
  else return mathStyle.scriptScriptCramped end                                                           -- S, SS, S', SS' -> SS'
end 

function _box:isMathBox () return self.type == "math" end

-- function _box:isRule () return self.type == "rule" end

-- math box, box with a horizontal shift value and could contain zero or more _mbox'es (or its child classes)
-- the entire math environment itself is a top-level mbox.
-- Typesetting of mbox evolves four steps:
--   1. Determine the style for each mbox according to their parent.
--   2. Shape the mbox hierarchy from leaf to top. Get the shape and relative position.
--   3. Recursively determine the position of the mbox's to the root mbox (i.e., add up the relative positions along the tree path)
--   4. Convert mbox into _nnode's to put in SILE's typesetting framwork
local _mbox = _box {
  _type = "Mbox",
  type = "math",
  style = nil,
  options = SILE.font.loadDefaults({}),
  level = 0, -- The level in mbox hierarchy
  children = {}, -- The child nodes
  relX = nil, -- x position relative to its parent box
  relY = nil, -- y position relative to its parent box
  absX = nil, -- x position relative to the root
  absY = nil, -- y position relative to the root
  value = {},
  __tostring = function (s) return s.type end,
  init = function(self) return self end,

  styleChildren = function(self)
    SU.error("This is a virtual function that need to be overriden by its child classes")
  end,

  setChildrenRelXY = function(self)
    SU.error("This is a virtual function that need to be overriden by its child classes")
  end,

  shapeYourself = function(self)
    SU.error("This is a virtual function that need to be overriden by its child classes")
  end,

  outputYourself = function(self, typesetter, line)
    SU.error("This is a virtual function that need to be overriden by its child classes")
  end,

  -- Determine the style of its descendants
  styleDescendants = function(self)
    self:styleChildren()
    for i, n in ipairs(self.children) do
      n:styleDescendants()
    end
  end,

  -- shapeTree shapes the mbox and all its descendants in a recursive fashion
  -- The inner-most leaf nodes determine their shape first, and then propagate to their parents
  -- During the process, each node will determine its size by (width, height, depth)
  -- and (relX, relY) which the relative position to its parent
  shapeTree = function(self)
    for i, n in ipairs(self.children) do
      n:shapeTree()
    end
    self:setChildrenRelXY()
    self:shapeYourself()
  end,

  -- positionDescendants calculates the "absolute" position of the descendants, not including itself.
  positionDescendants = function(self)
    for i, n in ipairs(self.children) do
      n.absX = self.absX + n.relX
      n.absY = self.absY + n.relY
      n:positionDescendants()
    end
  end,

  -- Output the node and all its descendants
  outputTree = function(self, typesetter, line)
    self:outputYourself(typesetter, line)
    for i, n in ipairs(self.children) do
      n:outputTree(typesetter, line)
    end
  end
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
      n.style = self.style
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
  shapeYourself = function(self)
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
  -- Despite of its name, this function actually output the whole tree of nodes recursively
  outputYourself = function(self)
    for i, n in ipairs(self.children) do
      n:outputYourself()
    end
  end
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
  options = SILE.font.loadDefaults({style="Italic"}),
  __tostring = function(self) return "Text("..self.text..")" end,
  shapeYourself = function(self)
    local glyphs = SILE.shaper:shapeToken(self.text, self.options)
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
      print(glyphs)
    else
      self.width = 0
      self.height = 0
      self.depth = 0
    end
  end,
  outputYourself = function(self)
    if not self.value.glyphString then return end
    SILE.outputter.moveTo(SILE.typesetter.frame.state.cursorX, SILE.typesetter.frame.state.cursorY)
    SILE.outputter.setFont(self.options)
    SILE.outputter.outputHbox(self.value, self.width)
  end
}

-- convert MathML into mbox
local function ConvertMathML(content, mbox)
  for i,v in ipairs(content) do
    if type(v) == "string" then
      v = v:gsub("^%s*(.-)%s*$", "%1")
      if v and v ~= "" then
        -- Add text node to mbox
      end
    elseif type(v) == "table" then
      if v.id == 'command' then
        if v.tag == 'mrow' then
          local hbox = std.tree.clone(_stackbox({ direction='H' }))
          ConvertMathML(v, hbox)
          table.insert(mbox.children, hbox)
        elseif v.tag == 'mi' then
          local text = std.tree.clone(_text({ text=v[1] }))
          table.insert(mbox.children, text)
        end
      else
        ConvertMathML(v, mbox)
      end
    end
  end
end

local newText = function(spec)
  return _text(spec):init()
end

local newStackbox = function(spec)
  return std.tree.clone(_stackbox(spec)):init()
end

SILE.nodefactory.math = {
  newText=newText,
  newStackbox = newStackbox
}

SILE.typesetter.pushMath = function(self, mbox)
  return self:pushHorizontal(mbox)
end

SILE.registerCommand("mathml", function (options, content)
  local mbox = newStackbox({ direction='V' })
  ConvertMathML(content, mbox)

  if #(mbox.children) == 1 then
    mbox = mbox.children[1]
  end
  
  SU.debug("math", mbox)
  mbox.style = mathStyle.display -- or text
  mbox:styleDescendants()

  mbox:shapeTree()

  mbox.absX = 0
  mbox.absY = 0
  mbox:positionDescendants()

  print(mbox.width..' '..mbox.height..' '..mbox.depth)

  SILE.typesetter:pushMath(mbox)

end)