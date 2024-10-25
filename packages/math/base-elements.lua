local nodefactory = require("types.node")
local hb = require("justenoughharfbuzz")
local ot = require("core.opentype-parser")
local syms = require("packages.math.unicode-symbols")
local mathvariants = require("packages.math.unicode-mathvariants")
local convertMathVariantScript = mathvariants.convertMathVariantScript

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
   scriptScriptCramped = 7,
}

local function isDisplayMode (mode)
   return mode <= 1
end

local function isCrampedMode (mode)
   return mode % 2 == 1
end

local function isScriptMode (mode)
   return mode == mathMode.script or mode == mathMode.scriptCramped
end

local function isScriptScriptMode (mode)
   return mode == mathMode.scriptScript or mode == mathMode.scriptScriptCramped
end

local mathCache = {}

local function retrieveMathTable (font)
   local key = SILE.font._key(font)
   if not mathCache[key] then
      SU.debug("math", "Loading math font", key)
      local face = SILE.font.cache(font, SILE.shaper.getFace)
      if not face then
         SU.error("Could not find requested font " .. font .. " or any suitable substitutes")
      end
      local fontHasMathTable, rawMathTable, mathTableParsable, mathTable
      fontHasMathTable, rawMathTable = pcall(hb.get_table, face, "MATH")
      if fontHasMathTable then
         mathTableParsable, mathTable = pcall(ot.parseMath, rawMathTable)
      end
      if not fontHasMathTable or not mathTableParsable then
         SU.error(([[
            You must use a math font for math rendering

            The math table in '%s' could not be %s.
         ]]):format(face.filename, fontHasMathTable and "parsed" or "loaded"))
      end
      local upem = ot.parseHead(hb.get_table(face, "head")).unitsPerEm
      local constants = {}
      for k, v in pairs(mathTable.mathConstants) do
         if type(v) == "table" then
            v = v.value
         end
         if k:sub(-9) == "ScaleDown" then
            constants[k] = v / 100
         else
            constants[k] = v * font.size / upem
         end
      end
      local italicsCorrection = {}
      for k, v in pairs(mathTable.mathItalicsCorrection) do
         italicsCorrection[k] = v.value * font.size / upem
      end
      mathCache[key] = {
         constants = constants,
         italicsCorrection = italicsCorrection,
         mathVariants = mathTable.mathVariants,
         unitsPerEm = upem,
      }
   end
   return mathCache[key]
end

-- Style transition functions for superscript and subscript
local function getSuperscriptMode (mode)
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
   else
      return mathMode.scriptScriptCramped
   end
end
local function getSubscriptMode (mode)
   -- D, T, D', T' -> S'
   if
      mode == mathMode.display
      or mode == mathMode.text
      or mode == mathMode.displayCramped
      or mode == mathMode.textCramped
   then
      return mathMode.scriptCramped
   -- S, SS, S', SS' -> SS'
   else
      return mathMode.scriptScriptCramped
   end
end

-- Style transition functions for fraction (numerator and denominator)
local function getNumeratorMode (mode)
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
   else
      return mathMode.scriptScriptCramped
   end
end
local function getDenominatorMode (mode)
   -- D, D' -> T'
   if mode == mathMode.display or mode == mathMode.displayCramped then
      return mathMode.textCramped
   -- T, T' -> S'
   elseif mode == mathMode.text or mode == mathMode.textCramped then
      return mathMode.scriptCramped
   -- S, SS, S', SS' -> SS'
   else
      return mathMode.scriptScriptCramped
   end
end

local function getRightMostGlyphId (node)
   while node and node:is_a(elements.stackbox) and node.direction == "H" do
      node = node.children[#node.children]
   end
   if node and node:is_a(elements.text) then
      return node.value.glyphString[#node.value.glyphString]
   else
      return 0
   end
end

-- Compares two SILE.types.length, without considering shrink or stretch values, and
-- returns the biggest.
local function maxLength (...)
   local arg = { ... }
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

local function scaleWidth (length, line)
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
--   3. Convert mbox into _nnode's to put in SILE's typesetting framework
elements.mbox = pl.class(nodefactory.hbox)
elements.mbox._type = "Mbox"

function elements.mbox:__tostring ()
   return self._type
end

function elements.mbox:_init ()
   nodefactory.hbox._init(self)
   self.font = {}
   self.children = {} -- The child nodes
   self.relX = SILE.types.length(0) -- x position relative to its parent box
   self.relY = SILE.types.length(0) -- y position relative to its parent box
   self.value = {}
   self.mode = mathMode.display
   self.atom = atomType.ordinary
   local font = {
      family = SILE.settings:get("math.font.family"),
      size = SILE.settings:get("math.font.size"),
      style = SILE.settings:get("math.font.style"),
      weight = SILE.settings:get("math.font.weight"),
   }
   local filename = SILE.settings:get("math.font.filename")
   if filename and filename ~= "" then
      font.filename = filename
   end
   self.font = SILE.font.loadDefaults(font)
end

function elements.mbox.styleChildren (_)
   SU.error("styleChildren is a virtual function that need to be overridden by its child classes")
end

function elements.mbox.shape (_, _, _)
   SU.error("shape is a virtual function that need to be overridden by its child classes")
end

function elements.mbox.output (_, _, _, _)
   SU.error("output is a virtual function that need to be overridden by its child classes")
end

function elements.mbox:getMathMetrics ()
   return retrieveMathTable(self.font)
end

function elements.mbox:getScaleDown ()
   local constants = self:getMathMetrics().constants
   local scaleDown
   if isScriptMode(self.mode) then
      scaleDown = constants.scriptPercentScaleDown
   elseif isScriptScriptMode(self.mode) then
      scaleDown = constants.scriptScriptPercentScaleDown
   else
      scaleDown = 1
   end
   return scaleDown
end

-- Determine the mode of its descendants
function elements.mbox:styleDescendants ()
   self:styleChildren()
   for _, n in ipairs(self.children) do
      if n then
         n:styleDescendants()
      end
   end
end

-- shapeTree shapes the mbox and all its descendants in a recursive fashion
-- The inner-most leaf nodes determine their shape first, and then propagate to their parents
-- During the process, each node will determine its size by (width, height, depth)
-- and (relX, relY) which the relative position to its parent
function elements.mbox:shapeTree ()
   for _, n in ipairs(self.children) do
      if n then
         n:shapeTree()
      end
   end
   self:shape()
end

-- Output the node and all its descendants
function elements.mbox:outputTree (x, y, line)
   self:output(x, y, line)
   local debug = SILE.settings:get("math.debug.boxes")
   if debug and not (self:is_a(elements.space)) then
      SILE.outputter:setCursor(scaleWidth(x, line), y.length)
      SILE.outputter:debugHbox({ height = self.height.length, depth = self.depth.length }, scaleWidth(self.width, line))
   end
   for _, n in ipairs(self.children) do
      if n then
         n:outputTree(x + n.relX, y + n.relY, line)
      end
   end
end

local spaceKind = {
   thin = "thin",
   med = "med",
   thick = "thick",
}

-- Indexed by left atom
local spacingRules = {
   [atomType.ordinary] = {
      [atomType.bigOperator] = { spaceKind.thin },
      [atomType.binaryOperator] = { spaceKind.med, notScript = true },
      [atomType.relationalOperator] = { spaceKind.thick, notScript = true },
      [atomType.inner] = { spaceKind.thin, notScript = true },
   },
   [atomType.bigOperator] = {
      [atomType.ordinary] = { spaceKind.thin },
      [atomType.bigOperator] = { spaceKind.thin },
      [atomType.relationalOperator] = { spaceKind.thick, notScript = true },
      [atomType.inner] = { spaceKind.thin, notScript = true },
   },
   [atomType.binaryOperator] = {
      [atomType.ordinary] = { spaceKind.med, notScript = true },
      [atomType.bigOperator] = { spaceKind.med, notScript = true },
      [atomType.openingSymbol] = { spaceKind.med, notScript = true },
      [atomType.inner] = { spaceKind.med, notScript = true },
   },
   [atomType.relationalOperator] = {
      [atomType.ordinary] = { spaceKind.thick, notScript = true },
      [atomType.bigOperator] = { spaceKind.thick, notScript = true },
      [atomType.openingSymbol] = { spaceKind.thick, notScript = true },
      [atomType.inner] = { spaceKind.thick, notScript = true },
   },
   [atomType.closeSymbol] = {
      [atomType.bigOperator] = { spaceKind.thin },
      [atomType.binaryOperator] = { spaceKind.med, notScript = true },
      [atomType.relationalOperator] = { spaceKind.thick, notScript = true },
      [atomType.inner] = { spaceKind.thin, notScript = true },
   },
   [atomType.punctuationSymbol] = {
      [atomType.ordinary] = { spaceKind.thin, notScript = true },
      [atomType.bigOperator] = { spaceKind.thin, notScript = true },
      [atomType.relationalOperator] = { spaceKind.thin, notScript = true },
      [atomType.openingSymbol] = { spaceKind.thin, notScript = true },
      [atomType.closeSymbol] = { spaceKind.thin, notScript = true },
      [atomType.punctuationSymbol] = { spaceKind.thin, notScript = true },
      [atomType.inner] = { spaceKind.thin, notScript = true },
   },
   [atomType.inner] = {
      [atomType.ordinary] = { spaceKind.thin, notScript = true },
      [atomType.bigOperator] = { spaceKind.thin },
      [atomType.binaryOperator] = { spaceKind.med, notScript = true },
      [atomType.relationalOperator] = { spaceKind.thick, notScript = true },
      [atomType.openingSymbol] = { spaceKind.thin, notScript = true },
      [atomType.punctuationSymbol] = { spaceKind.thin, notScript = true },
      [atomType.inner] = { spaceKind.thin, notScript = true },
   },
}

-- _stackbox stacks its content one, either horizontally or vertically
elements.stackbox = pl.class(elements.mbox)
elements.stackbox._type = "Stackbox"

function elements.stackbox:__tostring ()
   local result = self.direction .. "Box("
   for i, n in ipairs(self.children) do
      result = result .. (i == 1 and "" or ", ") .. tostring(n)
   end
   result = result .. ")"
   return result
end

function elements.stackbox:_init (direction, children)
   elements.mbox._init(self)
   if not (direction == "H" or direction == "V") then
      SU.error("Wrong direction '" .. direction .. "'; should be H or V")
   end
   self.direction = direction
   self.children = children
end

function elements.stackbox:styleChildren ()
   for _, n in ipairs(self.children) do
      n.mode = self.mode
   end
   if self.direction == "H" then
      -- Insert spaces according to the atom type, following Knuth's guidelines
      -- in the TeXbook
      local spaces = {}
      for i = 1, #self.children - 1 do
         local v = self.children[i]
         local v2 = self.children[i + 1]
         if spacingRules[v.atom] and spacingRules[v.atom][v2.atom] then
            local rule = spacingRules[v.atom][v2.atom]
            if not (rule.notScript and (isScriptMode(self.mode) or isScriptScriptMode(self.mode))) then
               spaces[i + 1] = rule[1]
            end
         end
      end
      local spaceIdx = {}
      for i, _ in pairs(spaces) do
         table.insert(spaceIdx, i)
      end
      table.sort(spaceIdx, function (a, b)
         return a > b
      end)
      for _, idx in ipairs(spaceIdx) do
         local hsp = elements.space(spaces[idx], 0, 0)
         table.insert(self.children, idx, hsp)
      end
   end
end

function elements.stackbox:shape ()
   -- For a horizontal stackbox (i.e. mrow):
   -- 1. set self.height and self.depth to max element height & depth
   -- 2. handle stretchy operators
   -- 3. set self.width
   -- For a vertical stackbox:
   -- 1. set self.width to max element width
   -- 2. set self.height
   -- And finally set children's relative coordinates
   self.height = SILE.types.length(0)
   self.depth = SILE.types.length(0)
   if self.direction == "H" then
      for i, n in ipairs(self.children) do
         n.relY = SILE.types.length(0)
         self.height = i == 1 and n.height or maxLength(self.height, n.height)
         self.depth = i == 1 and n.depth or maxLength(self.depth, n.depth)
      end
      -- Handle stretchy operators
      for _, elt in ipairs(self.children) do
         if elt.is_a(elements.text) and elt.kind == "operator" and elt.stretchy then
            elt:stretchyReshape(self.depth, self.height)
         end
      end
      -- Set self.width
      self.width = SILE.types.length(0)
      for i, n in ipairs(self.children) do
         n.relX = self.width
         self.width = i == 1 and n.width or self.width + n.width
      end
   else -- self.direction == "V"
      for i, n in ipairs(self.children) do
         n.relX = SILE.types.length(0)
         self.width = i == 1 and n.width or maxLength(self.width, n.width)
      end
      -- Set self.height and self.depth
      for i, n in ipairs(self.children) do
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
end

-- Despite of its name, this function actually output the whole tree of nodes recursively.
function elements.stackbox:outputYourself (typesetter, line)
   local mathX = typesetter.frame.state.cursorX
   local mathY = typesetter.frame.state.cursorY
   self:outputTree(self.relX + mathX, self.relY + mathY, line)
   typesetter.frame:advanceWritingDirection(scaleWidth(self.width, line))
end

function elements.stackbox.output (_, _, _, _) end

elements.phantom = pl.class(elements.stackbox) -- inherit from stackbox
elements.phantom._type = "Phantom"

function elements.phantom:_init (children, special)
   -- MathML core 3.3.7:
   -- "Its layout algorithm is the same as the mrow element".
   -- Also not the MathML states that <mphantom> is sort of legacy, "implemented
   -- for compatibility with full MathML. Authors whose only target is MathML
   -- Core are encouraged to use CSS for styling."
   -- The thing is that we don't have CSS in SILE, so supporting <mphantom> is
   -- a must.
   elements.stackbox._init(self, "H", children)
   self.special = special
end

function elements.phantom:shape ()
   elements.stackbox.shape(self)
   -- From https://latexref.xyz:
   -- "The \vphantom variant produces an invisible box with the same vertical size
   -- as subformula, the same height and depth, but having zero width.
   -- And \hphantom makes a box with the same width as subformula but
   -- with zero height and depth."
   if self.special == "v" then
      self.width = SILE.types.length()
   elseif self.special == "h" then
      self.height = SILE.types.length()
      self.depth = SILE.types.length()
   end
end

function elements.phantom:output (_, _, _)
   -- Note the trick here: when the tree is rendered, the node's output
   -- function is invoked, then all its children's output functions.
   -- So we just cancel the list of children here, before it's rendered.
   self.children = {}
end

elements.subscript = pl.class(elements.mbox)
elements.subscript._type = "Subscript"

function elements.subscript:__tostring ()
   return (self.sub and "Subscript" or "Superscript")
      .. "("
      .. tostring(self.base)
      .. ", "
      .. tostring(self.sub or self.super)
      .. ")"
end

function elements.subscript:_init (base, sub, sup)
   elements.mbox._init(self)
   self.base = base
   self.sub = sub
   self.sup = sup
   if self.base then
      table.insert(self.children, self.base)
   end
   if self.sub then
      table.insert(self.children, self.sub)
   end
   if self.sup then
      table.insert(self.children, self.sup)
   end
   self.atom = self.base.atom
end

function elements.subscript:styleChildren ()
   if self.base then
      self.base.mode = self.mode
   end
   if self.sub then
      self.sub.mode = getSubscriptMode(self.mode)
   end
   if self.sup then
      self.sup.mode = getSuperscriptMode(self.mode)
   end
end

function elements.subscript:calculateItalicsCorrection ()
   local lastGid = getRightMostGlyphId(self.base)
   if lastGid > 0 then
      local mathMetrics = self:getMathMetrics()
      if mathMetrics.italicsCorrection[lastGid] then
         return mathMetrics.italicsCorrection[lastGid]
      end
   end
   return 0
end

function elements.subscript:shape ()
   local mathMetrics = self:getMathMetrics()
   local constants = mathMetrics.constants
   local scaleDown = self:getScaleDown()
   if self.base then
      self.base.relX = SILE.types.length(0)
      self.base.relY = SILE.types.length(0)
      -- Use widthForSubscript of base, if available
      self.width = self.base.widthForSubscript or self.base.width
   else
      self.width = SILE.types.length(0)
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
      self.sub.relY = SILE.types.length(math.max(
         constants.subscriptShiftDown * scaleDown,
         --self.base.depth + constants.subscriptBaselineDropMin * scaleDown,
         (self.sub.height - constants.subscriptTopMax * scaleDown):tonumber()
      ))
      if self:is_a(elements.underOver) or self:is_a(elements.stackbox) or self.base.largeop then
         self.sub.relY = maxLength(self.sub.relY, self.base.depth + constants.subscriptBaselineDropMin * scaleDown)
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
      self.sup.relY = SILE.types.length(math.max(
         isCrampedMode(self.mode) and constants.superscriptShiftUpCramped * scaleDown
            or constants.superscriptShiftUp * scaleDown, -- or cramped
         --self.base.height - constants.superscriptBaselineDropMax * scaleDown,
         (self.sup.depth + constants.superscriptBottomMin * scaleDown):tonumber()
      )) * -1
      if self:is_a(elements.underOver) or self:is_a(elements.stackbox) or self.base.largeop then
         self.sup.relY = maxLength(
            (0 - self.sup.relY),
            self.base.height - constants.superscriptBaselineDropMax * scaleDown
         ) * -1
      end
   end
   if self.sub and self.sup then
      local gap = self.sub.relY - self.sub.height - self.sup.relY - self.sup.depth
      if gap.length:tonumber() < constants.subSuperscriptGapMin * scaleDown then
         -- The following adjustment comes directly from Appendix G of he
         -- TeXbook (rule 18e).
         self.sub.relY = constants.subSuperscriptGapMin * scaleDown + self.sub.height + self.sup.relY + self.sup.depth
         local psi = constants.superscriptBottomMaxWithSubscript * scaleDown + self.sup.relY + self.sup.depth
         if psi:tonumber() > 0 then
            self.sup.relY = self.sup.relY - psi
            self.sub.relY = self.sub.relY - psi
         end
      end
   end
   self.width = self.width
      + maxLength(
         self.sub and self.sub.width + subShift or SILE.types.length(0),
         self.sup and self.sup.width + supShift or SILE.types.length(0)
      )
      + constants.spaceAfterScript * scaleDown
   self.height = maxLength(
      self.base and self.base.height or SILE.types.length(0),
      self.sub and (self.sub.height - self.sub.relY) or SILE.types.length(0),
      self.sup and (self.sup.height - self.sup.relY) or SILE.types.length(0)
   )
   self.depth = maxLength(
      self.base and self.base.depth or SILE.types.length(0),
      self.sub and (self.sub.depth + self.sub.relY) or SILE.types.length(0),
      self.sup and (self.sup.depth + self.sup.relY) or SILE.types.length(0)
   )
end

function elements.subscript.output (_, _, _, _) end

elements.underOver = pl.class(elements.subscript)
elements.underOver._type = "UnderOver"

function elements.underOver:__tostring ()
   return self._type .. "(" .. tostring(self.base) .. ", " .. tostring(self.sub) .. ", " .. tostring(self.sup) .. ")"
end

function elements.underOver:_init (base, sub, sup)
   elements.mbox._init(self)
   self.atom = base.atom
   self.base = base
   self.sub = sub
   self.sup = sup
   if self.sup then
      table.insert(self.children, self.sup)
   end
   if self.base then
      table.insert(self.children, self.base)
   end
   if self.sub then
      table.insert(self.children, self.sub)
   end
end

function elements.underOver:styleChildren ()
   if self.base then
      self.base.mode = self.mode
   end
   if self.sub then
      self.sub.mode = getSubscriptMode(self.mode)
   end
   if self.sup then
      self.sup.mode = getSuperscriptMode(self.mode)
   end
end

function elements.underOver:shape ()
   if not (self.mode == mathMode.display or self.mode == mathMode.displayCramped) then
      self.isUnderOver = true
      elements.subscript.shape(self)
      return
   end
   local constants = self:getMathMetrics().constants
   local scaleDown = self:getScaleDown()
   -- Determine relative Ys
   if self.base then
      self.base.relY = SILE.types.length(0)
   end
   if self.sub then
      self.sub.relY = self.base.depth
         + SILE.types.length(
            math.max(
               (self.sub.height + constants.lowerLimitGapMin * scaleDown):tonumber(),
               constants.lowerLimitBaselineDropMin * scaleDown
            )
         )
   end
   if self.sup then
      self.sup.relY = 0
         - self.base.height
         - SILE.types.length(
            math.max(
               (constants.upperLimitGapMin * scaleDown + self.sup.depth):tonumber(),
               constants.upperLimitBaselineRiseMin * scaleDown
            )
         )
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
   widest.relX = SILE.types.length(0)
   local c = widest.width / 2
   if a then
      a.relX = c - a.width / 2
   end
   if b then
      b.relX = c - b.width / 2
   end
   local itCorr = self:calculateItalicsCorrection() * scaleDown
   if self.sup then
      self.sup.relX = self.sup.relX + itCorr / 2
   end
   if self.sub then
      self.sub.relX = self.sub.relX - itCorr / 2
   end
   -- Determine width and height
   self.width = maxLength(
      self.base and self.base.width or SILE.types.length(0),
      self.sub and self.sub.width or SILE.types.length(0),
      self.sup and self.sup.width or SILE.types.length(0)
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
end

function elements.underOver:calculateItalicsCorrection ()
   local lastGid = getRightMostGlyphId(self.base)
   if lastGid > 0 then
      local mathMetrics = self:getMathMetrics()
      if mathMetrics.italicsCorrection[lastGid] then
         local c = mathMetrics.italicsCorrection[lastGid]
         -- If this is a big operator, and we are in display style, then the
         -- base glyph may be bigger than the font size. We need to adjust the
         -- italic correction accordingly.
         if self.base.atom == atomType.bigOperator and isDisplayMode(self.mode) then
            c = c * (self.base and self.base.font.size / self.font.size or 1.0)
         end
         return c
      end
   end
   return 0
end

function elements.underOver.output (_, _, _, _) end

-- terminal is the base class for leaf node
elements.terminal = pl.class(elements.mbox)
elements.terminal._type = "Terminal"

function elements.terminal:_init ()
   elements.mbox._init(self)
end

function elements.terminal.styleChildren (_) end

function elements.terminal.shape (_) end

elements.space = pl.class(elements.terminal)
elements.space._type = "Space"

function elements.space:_init ()
   elements.terminal._init(self)
end

function elements.space:__tostring ()
   return self._type
      .. "(width="
      .. tostring(self.width)
      .. ", height="
      .. tostring(self.height)
      .. ", depth="
      .. tostring(self.depth)
      .. ")"
end

local function getStandardLength (value)
   if type(value) == "string" then
      local direction = 1
      if value:sub(1, 1) == "-" then
         value = value:sub(2, -1)
         direction = -1
      end
      if value == "thin" then
         return SILE.types.length("3mu") * direction
      elseif value == "med" then
         return SILE.types.length("4mu plus 2mu minus 4mu") * direction
      elseif value == "thick" then
         return SILE.types.length("5mu plus 5mu") * direction
      end
   end
   return SILE.types.length(value)
end

function elements.space:_init (width, height, depth)
   elements.terminal._init(self)
   self.width = getStandardLength(width)
   self.height = getStandardLength(height)
   self.depth = getStandardLength(depth)
end

function elements.space:shape ()
   self.width = self.width:absolute() * self:getScaleDown()
   self.height = self.height:absolute() * self:getScaleDown()
   self.depth = self.depth:absolute() * self:getScaleDown()
end

function elements.space.output (_) end

-- text node. For any actual text output
elements.text = pl.class(elements.terminal)
elements.text._type = "Text"

function elements.text:__tostring ()
   return self._type
      .. "(atom="
      .. tostring(self.atom)
      .. ", kind="
      .. tostring(self.kind)
      .. ", script="
      .. tostring(self.script)
      .. (self.stretchy and ", stretchy" or "")
      .. (self.largeop and ", largeop" or "")
      .. ', text="'
      .. (self.originalText or self.text)
      .. '")'
end

function elements.text:_init (kind, attributes, script, text)
   elements.terminal._init(self)
   if not (kind == "number" or kind == "identifier" or kind == "operator" or kind == "string") then
      SU.error("Unknown text node kind '" .. kind .. "'; should be one of: number, identifier, operator, string")
   end
   self.kind = kind
   self.script = script
   self.text = text
   if self.script ~= "upright" then
      local converted = convertMathVariantScript(self.text, self.script)
      self.originalText = self.text
      self.text = converted
   end
   if self.kind == "operator" then
      if self.text == "-" then
         self.text = "−"
      end
   end
   for attribute, value in pairs(attributes) do
      self[attribute] = value
   end
end

function elements.text:shape ()
   self.font.size = self.font.size * self:getScaleDown()
   local face = SILE.font.cache(self.font, SILE.shaper.getFace)
   local mathMetrics = self:getMathMetrics()
   local glyphs = SILE.shaper:shapeToken(self.text, self.font)
   -- Use bigger variants for big operators in display style
   if isDisplayMode(self.mode) and self.largeop then
      -- We copy the glyph list to avoid modifying the shaper's cache. Yes.
      glyphs = pl.tablex.deepcopy(glyphs)
      local constructions = mathMetrics.mathVariants.vertGlyphConstructions[glyphs[1].gid]
      if constructions then
         local displayVariants = constructions.mathGlyphVariantRecord
         -- We select the biggest variant. TODO: we should probably select the
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
            local dimen = hb.get_glyph_dimensions(face, self.font.size, biggest.variantGlyph)
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
      self.width = SILE.types.length(0)
      self.widthForSubscript = SILE.types.length(0)
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
         self.height = i == 1 and SILE.types.length(glyphs[i].height)
            or SILE.types.length(math.max(self.height:tonumber(), glyphs[i].height))
         self.depth = i == 1 and SILE.types.length(glyphs[i].depth)
            or SILE.types.length(math.max(self.depth:tonumber(), glyphs[i].depth))
      end
   else
      self.width = SILE.types.length(0)
      self.height = SILE.types.length(0)
      self.depth = SILE.types.length(0)
   end
end

function elements.text:stretchyReshape (depth, height)
   -- Required depth+height of stretched glyph, in font units
   local mathMetrics = self:getMathMetrics()
   local upem = mathMetrics.unitsPerEm
   local sz = self.font.size
   local requiredAdvance = (depth + height):tonumber() * upem / sz
   SU.debug("math", "stretch: rA =", requiredAdvance)
   -- Choose variant of the closest size. The criterion we use is to have
   -- an advance measurement as close as possible as the required one.
   -- The advance measurement is simply the depth+height of the glyph.
   -- Therefore, the selected glyph may be smaller or bigger than
   -- required.  TODO: implement assembly of stretchable glyphs form
   -- their parts for cases when the biggest variant is not big enough.
   -- We copy the glyph list to avoid modifying the shaper's cache. Yes.
   local glyphs = pl.tablex.deepcopy(self.value.items)
   local constructions = self:getMathMetrics().mathVariants.vertGlyphConstructions[glyphs[1].gid]
   if constructions then
      local variants = constructions.mathGlyphVariantRecord
      SU.debug("math", "stretch: variants =", variants)
      local closest
      local closestI
      local m = requiredAdvance - (self.depth + self.height):tonumber() * upem / sz
      SU.debug("math", "stretch: m =", m)
      for i, v in ipairs(variants) do
         local diff = math.abs(v.advanceMeasurement - requiredAdvance)
         SU.debug("math", "stretch: diff =", diff)
         if diff < m then
            closest = v
            closestI = i
            m = diff
         end
      end
      SU.debug("math", "stretch: closestI =", closestI)
      if closest then
         -- Now we have to re-shape the glyph chain. We will assume there
         -- is only one glyph.
         -- TODO: this code is probably wrong when the vertical
         -- variants have a different width than the original, because
         -- the shaping phase is already done. Need to do better.
         glyphs[1].gid = closest.variantGlyph
         local face = SILE.font.cache(self.font, SILE.shaper.getFace)
         local dimen = hb.get_glyph_dimensions(face, self.font.size, closest.variantGlyph)
         glyphs[1].width = dimen.width
         glyphs[1].height = dimen.height
         glyphs[1].depth = dimen.depth
         glyphs[1].glyphAdvance = dimen.glyphAdvance
         self.width = SILE.types.length(dimen.glyphAdvance)
         self.depth = SILE.types.length(dimen.depth)
         self.height = SILE.types.length(dimen.height)
         SILE.shaper:preAddNodes(glyphs, self.value)
         self.value.items = glyphs
         self.value.glyphString = { glyphs[1].gid }
      end
   end
end

function elements.text:output (x, y, line)
   if not self.value.glyphString then
      return
   end
   local compensatedY
   if isDisplayMode(self.mode) and self.atom == atomType.bigOperator and self.value.items[1].fontDepth then
      compensatedY = SILE.types.length(y.length + self.value.items[1].depth - self.value.items[1].fontDepth)
   else
      compensatedY = y
   end
   SILE.outputter:setCursor(scaleWidth(x, line), compensatedY.length)
   SILE.outputter:setFont(self.font)
   -- There should be no stretch or shrink on the width of a text
   -- element.
   local width = self.width.length
   SILE.outputter:drawHbox(self.value, width)
end

elements.fraction = pl.class(elements.mbox)
elements.fraction._type = "Fraction"

function elements.fraction:__tostring ()
   return self._type .. "(" .. tostring(self.numerator) .. ", " .. tostring(self.denominator) .. ")"
end

function elements.fraction:_init (numerator, denominator)
   elements.mbox._init(self)
   self.numerator = numerator
   self.denominator = denominator
   table.insert(self.children, numerator)
   table.insert(self.children, denominator)
end

function elements.fraction:styleChildren ()
   self.numerator.mode = getNumeratorMode(self.mode)
   self.denominator.mode = getDenominatorMode(self.mode)
end

function elements.fraction:shape ()
   -- MathML Core 3.3.2: "To avoid visual confusion between the fraction bar
   -- and another adjacent items (e.g. minus sign or another fraction's bar),"
   -- By convention, here we use 1px = 1/96in = 0.75pt.
   -- Note that PlainTeX would likely use \nulldelimiterspace (default 1.2pt)
   -- but it would depend on the surrounding context, and might be far too
   -- much in some cases, so we stick to MathML's suggested padding.
   self.padding = SILE.types.length(0.75)

   -- Determine relative abscissas and width
   local widest, other
   if self.denominator.width > self.numerator.width then
      widest, other = self.denominator, self.numerator
   else
      widest, other = self.numerator, self.denominator
   end
   widest.relX = self.padding
   other.relX = self.padding + (widest.width - other.width) / 2
   self.width = widest.width + 2 * self.padding
   -- Determine relative ordinates and height
   local constants = self:getMathMetrics().constants
   local scaleDown = self:getScaleDown()
   self.axisHeight = constants.axisHeight * scaleDown
   self.ruleThickness = constants.fractionRuleThickness * scaleDown

   local numeratorGapMin, denominatorGapMin, numeratorShiftUp, denominatorShiftDown
   if isDisplayMode(self.mode) then
      numeratorGapMin = constants.fractionNumDisplayStyleGapMin * scaleDown
      denominatorGapMin = constants.fractionDenomDisplayStyleGapMin * scaleDown
      numeratorShiftUp = constants.fractionNumeratorDisplayStyleShiftUp * scaleDown
      denominatorShiftDown = constants.fractionDenominatorDisplayStyleShiftDown * scaleDown
   else
      numeratorGapMin = constants.fractionNumeratorGapMin * scaleDown
      denominatorGapMin = constants.fractionDenominatorGapMin * scaleDown
      numeratorShiftUp = constants.fractionNumeratorShiftUp * scaleDown
      denominatorShiftDown = constants.fractionDenominatorShiftDown * scaleDown
   end

   self.numerator.relY = -self.axisHeight
      - self.ruleThickness / 2
      - SILE.types.length(
         math.max(
            (numeratorGapMin + self.numerator.depth):tonumber(),
            numeratorShiftUp - self.axisHeight - self.ruleThickness / 2
         )
      )
   self.denominator.relY = -self.axisHeight
      + self.ruleThickness / 2
      + SILE.types.length(
         math.max(
            (denominatorGapMin + self.denominator.height):tonumber(),
            denominatorShiftDown + self.axisHeight - self.ruleThickness / 2
         )
      )
   self.height = self.numerator.height - self.numerator.relY
   self.depth = self.denominator.relY + self.denominator.depth
end

function elements.fraction:output (x, y, line)
   SILE.outputter:drawRule(
      scaleWidth(x + self.padding, line),
      y.length - self.axisHeight - self.ruleThickness / 2,
      scaleWidth(self.width - 2 * self.padding, line),
      self.ruleThickness
   )
end

local function newSubscript (spec)
   return elements.subscript(spec.base, spec.sub, spec.sup)
end

local function newUnderOver (spec)
   return elements.underOver(spec.base, spec.sub, spec.sup)
end

-- TODO replace with penlight equivalent
local function mapList (f, l)
   local ret = {}
   for i, x in ipairs(l) do
      ret[i] = f(i, x)
   end
   return ret
end

elements.mtr = pl.class(elements.mbox)
-- elements.mtr._type = "" -- TODO why not set?

function elements.mtr:_init (children)
   self.children = children
end

function elements.mtr:styleChildren ()
   for _, c in ipairs(self.children) do
      c.mode = self.mode
   end
end

function elements.mtr.shape (_) end -- done by parent table

function elements.mtr.output (_) end

elements.table = pl.class(elements.mbox)
elements.table._type = "table" -- TODO why case difference?

function elements.table:_init (children, options)
   elements.mbox._init(self)
   self.children = children
   self.options = options
   self.nrows = #self.children
   self.ncols = math.max(pl.utils.unpack(mapList(function (_, row)
      return #row.children
   end, self.children)))
   SU.debug("math", "self.ncols =", self.ncols)
   local spacing = SILE.settings:get("math.font.size") * 0.6 -- arbitrary ratio of the current math font size
   self.rowspacing = self.options.rowspacing and SILE.types.length(self.options.rowspacing) or spacing
   self.columnspacing = self.options.columnspacing and SILE.types.length(self.options.columnspacing) or spacing
   -- Pad rows that do not have enough cells by adding cells to the
   -- right.
   for i, row in ipairs(self.children) do
      for j = 1, (self.ncols - #row.children) do
         SU.debug("math", "padding i =", i, "j =", j)
         table.insert(row.children, elements.stackbox("H", {}))
         SU.debug("math", "size", #row.children)
      end
   end
   if options.columnalign then
      local l = {}
      for w in string.gmatch(options.columnalign, "[^%s]+") do
         if not (w == "left" or w == "center" or w == "right") then
            SU.error("Invalid specifier in `columnalign` attribute: " .. w)
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
      self.options.columnalign = pl.List.range(1, self.ncols):map(function (_)
         return "center"
      end)
   end
end

function elements.table:styleChildren ()
   if self.mode == mathMode.display and self.options.displaystyle ~= "false" then
      for _, c in ipairs(self.children) do
         c.mode = mathMode.display
      end
   else
      for _, c in ipairs(self.children) do
         c.mode = mathMode.text
      end
   end
end

function elements.table:shape ()
   -- Determine the height (resp. depth) of each row, which is the max
   -- height (resp. depth) among its elements. Then we only need to add it to
   -- the table's height and center every cell vertically.
   for _, row in ipairs(self.children) do
      row.height = SILE.types.length(0)
      row.depth = SILE.types.length(0)
      for _, cell in ipairs(row.children) do
         row.height = maxLength(row.height, cell.height)
         row.depth = maxLength(row.depth, cell.depth)
      end
   end
   self.vertSize = SILE.types.length(0)
   for i, row in ipairs(self.children) do
      self.vertSize = self.vertSize
         + row.height
         + row.depth
         + (i == self.nrows and SILE.types.length(0) or self.rowspacing) -- Spacing
   end
   local rowHeightSoFar = SILE.types.length(0)
   for i, row in ipairs(self.children) do
      row.relY = rowHeightSoFar + row.height - self.vertSize
      rowHeightSoFar = rowHeightSoFar
         + row.height
         + row.depth
         + (i == self.nrows and SILE.types.length(0) or self.rowspacing) -- Spacing
   end
   self.width = SILE.types.length(0)
   local thisColRelX = SILE.types.length(0)
   -- For every column...
   for i = 1, self.ncols do
      -- Determine its width
      local columnWidth = SILE.types.length(0)
      for j = 1, self.nrows do
         if self.children[j].children[i].width > columnWidth then
            columnWidth = self.children[j].children[i].width
         end
      end
      -- Use it to align the contents of every cell as required.
      for j = 1, self.nrows do
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
      thisColRelX = thisColRelX + columnWidth + (i == self.ncols and SILE.types.length(0) or self.columnspacing) -- Spacing
   end
   self.width = thisColRelX
   -- Center myself vertically around the axis, and update relative Ys of rows accordingly
   local axisHeight = self:getMathMetrics().constants.axisHeight * self:getScaleDown()
   self.height = self.vertSize / 2 + axisHeight
   self.depth = self.vertSize / 2 - axisHeight
   for _, row in ipairs(self.children) do
      row.relY = row.relY + self.vertSize / 2 - axisHeight
      -- Also adjust width
      row.width = self.width
   end
end

function elements.table.output (_) end

local function getRadicandMode (mode)
   -- Not too sure if we should do something special/
   return mode
end

local function getDegreeMode (mode)
   -- 2 levels smaller, up to scriptScript evntually.
   -- Not too sure if we should do something else.
   if mode == mathMode.display then
      return mathMode.scriptScript
   elseif mode == mathMode.displayCramped then
      return mathMode.scriptScriptCramped
   elseif mode == mathMode.text or mode == mathMode.script or mode == mathMode.scriptScript then
      return mathMode.scriptScript
   end
   return mathMode.scriptScriptCramped
end

elements.sqrt = pl.class(elements.mbox)
elements.sqrt._type = "Sqrt"

function elements.sqrt:__tostring ()
   return self._type .. "(" .. tostring(self.radicand) .. (self.degree and ", " .. tostring(self.degree) or "") .. ")"
end

function elements.sqrt:_init (radicand, degree)
   elements.mbox._init(self)
   self.radicand = radicand
   if degree then
      self.degree = degree
      table.insert(self.children, degree)
   end
   table.insert(self.children, radicand)
   self.relX = SILE.types.length()
   self.relY = SILE.types.length()
end

function elements.sqrt:styleChildren ()
   self.radicand.mode = getRadicandMode(self.mode)
   if self.degree then
      self.degree.mode = getDegreeMode(self.mode)
   end
end

function elements.sqrt:shape ()
   local mathMetrics = self:getMathMetrics()
   local scaleDown = self:getScaleDown()
   local constants = mathMetrics.constants

   self.radicalRuleThickness = constants.radicalRuleThickness * scaleDown
   if self.mode == mathMode.display or self.mode == mathMode.displayCramped then
      self.radicalVerticalGap = constants.radicalDisplayStyleVerticalGap * scaleDown
   else
      self.radicalVerticalGap = constants.radicalVerticalGap * scaleDown
   end
   self.extraAscender = constants.radicalExtraAscender * scaleDown

   -- HACK: We draw own own radical sign in the output() method.
   -- Derive dimensions for the radical sign (more or less ad hoc).
   -- Note: In TeX, the radical sign extends a lot below the baseline,
   -- and MathML Core also has a lot of layout text about it.
   -- Not only it doesn't look good, but it's not very clear vs. OpenType.
   local radicalGlyph = SILE.shaper:measureChar("√")
   local ratio = (self.radicand.height:tonumber() + self.radicand.depth:tonumber())
      / (radicalGlyph.height + radicalGlyph.depth)
   local vertAdHocOffset = (ratio > 1 and math.log(ratio) or 0) * self.radicalVerticalGap
   self.symbolHeight = SILE.types.length(radicalGlyph.height) * scaleDown
   self.symbolDepth = (SILE.types.length(radicalGlyph.depth) + vertAdHocOffset) * scaleDown
   self.symbolWidth = (SILE.types.length(radicalGlyph.width) + vertAdHocOffset) * scaleDown

   -- Adjust the height of the radical sign if the radicand is higher
   self.symbolHeight = self.radicand.height > self.symbolHeight and self.radicand.height or self.symbolHeight
   -- Compute the (max-)height of the short leg of the radical sign
   self.symbolShortHeight = self.symbolHeight * constants.radicalDegreeBottomRaisePercent

   self.offsetX = SILE.types.length()
   if self.degree then
      -- Position the degree
      self.degree.relY = -constants.radicalDegreeBottomRaisePercent * self.symbolHeight
      -- Adjust the height of the short leg of the radical sign to ensure the degree is not too close
      -- (empirically use radicalExtraAscender)
      self.symbolShortHeight = self.symbolShortHeight - constants.radicalExtraAscender * scaleDown
      -- Compute the width adjustment for the degree
      self.offsetX = self.degree.width
         + constants.radicalKernBeforeDegree * scaleDown
         + constants.radicalKernAfterDegree * scaleDown
   end
   -- Position the radicand
   self.radicand.relX = self.symbolWidth + self.offsetX
   -- Compute the dimentions of the whole radical
   self.width = self.radicand.width + self.symbolWidth + self.offsetX
   self.height = self.symbolHeight + self.radicalVerticalGap + self.extraAscender
   self.depth = self.radicand.depth
end

local function _r (number)
   -- Lua 5.3+ formats floats as 1.0 and integers as 1
   -- Also some PDF readers do not like double precision.
   return math.floor(number) == number and math.floor(number) or tonumber(string.format("%.5f", number))
end

function elements.sqrt:output (x, y, line)
   -- HACK:
   -- OpenType might say we need to assemble the radical sign from parts.
   -- Frankly, it's much easier to just draw it as a graphic :-)
   -- Hence, here we use a PDF graphic operators to draw a nice radical sign.
   -- Some values here are ad hoc, but they look good.
   local h = self.height:tonumber()
   local d = self.depth:tonumber()
   local s0 = scaleWidth(self.offsetX, line):tonumber()
   local sw = scaleWidth(self.symbolWidth, line):tonumber()
   local dsh = h - self.symbolShortHeight:tonumber()
   local dsd = self.symbolDepth:tonumber()
   local symbol = {
      _r(self.radicalRuleThickness),
      "w", -- line width
      2,
      "j", -- round line joins
      _r(sw + s0),
      _r(self.extraAscender),
      "m",
      _r(s0 + sw * 0.90),
      _r(self.extraAscender),
      "l",
      _r(s0 + sw * 0.4),
      _r(h + d + dsd),
      "l",
      _r(s0 + sw * 0.2),
      _r(dsh),
      "l",
      s0 + sw * 0.1,
      _r(dsh + 0.5),
      "l",
      "S",
   }
   local svg = table.concat(symbol, " ")
   local xscaled = scaleWidth(x, line)
   SILE.outputter:drawSVG(svg, xscaled, y, sw, h, 1)
   -- And now we just need to draw the bar over the radicand
   SILE.outputter:drawRule(
      s0 + self.symbolWidth + xscaled,
      y.length - self.height + self.extraAscender - self.radicalRuleThickness / 2,
      scaleWidth(self.radicand.width, line),
      self.radicalRuleThickness
   )
end

elements.mathMode = mathMode
elements.atomType = atomType
elements.symbolDefaults = symbolDefaults
elements.newSubscript = newSubscript
elements.newUnderOver = newUnderOver

return elements
