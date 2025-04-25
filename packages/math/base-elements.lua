local nodefactory = require("types.node")
local hb = require("justenoughharfbuzz")
local ot = require("core.opentype-parser")
local atoms = require("packages.math.atoms")
local mathvariants = require("packages.math.unicode-mathvariants")
local convertMathVariantScript = mathvariants.convertMathVariantScript

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
      local face = SILE.font.cache(font, SILE.shaper:_getFaceCallback())
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
   self.atom = atoms.types.ord
   local font = {
      family = SILE.settings:get("math.font.family"),
      size = SILE.settings:get("math.font.size"),
      style = SILE.settings:get("math.font.style"),
      weight = SILE.settings:get("math.font.weight"),
      -- https://learn.microsoft.com/en-us/typography/opentype/spec/math#opentype-layout-tags-used-with-the-math-table
      --   "Script tag to be used for features in math layout.
      --   The only language system supported with this tag is the default language system."
      -- Thus, needed for the ssty feature in superscript/subscript to work properly.
      script = "math",
   }
   local filename = SILE.settings:get("math.font.filename")
   if filename and filename ~= "" then
      font.filename = filename
   end
   self.font = SILE.font.loadDefaults(font)
end

function elements.mbox:styleChildren ()
   SU.error("styleChildren is a virtual function that need to be overridden by its child classes")
end

function elements.mbox:shape (_, _)
   SU.error("shape is a virtual function that need to be overridden by its child classes")
end

function elements.mbox:output (_, _, _)
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

-- Spacing table indexed by left atom, as in TeXbook p. 170.
-- Notes
--  - the "notScript" key is used to prevent spaces in script and scriptscript modes
--    (= parenthesized non-zero value in The TeXbook's table).
--  - Cases commented are as expected, just listed for clarity and completeness.
--    (= no space i.e. 0 in in The TeXbook's table)
--  - Cases marked as impossible are not expected to happen (= stars in the TeXbook):
--    "... such cases never arise, because binary atoms must be preceded and followed
--    by atoms compatible with the nature of binary operations."
--    This must be understood with the context explained onp. 133:
--     "... binary operations are treated as ordinary symbols if they don’t occur
--     between two quantities that they can operate on." (a rule which notably helps
--     addressing binary atoms used as unary operators.)
local spacingRules = {
   [atoms.types.ord] = {
      -- [atoms.types.ord] = nil
      [atoms.types.op] = { spaceKind.thin },
      [atoms.types.bin] = { spaceKind.med, notScript = true },
      [atoms.types.rel] = { spaceKind.thick, notScript = true },
      -- [atoms.types.open] = nil
      -- [atoms.types.close] = nil
      -- [atoms.types.punct] = nil
      [atoms.types.inner] = { spaceKind.thin, notScript = true },
   },
   [atoms.types.op] = {
      [atoms.types.ord] = { spaceKind.thin },
      [atoms.types.op] = { spaceKind.thin },
      [atoms.types.bin] = { impossible = true },
      [atoms.types.rel] = { spaceKind.thick, notScript = true },
      -- [atoms.types.open] = nil
      -- [atoms.types.close] = nil
      -- [atoms.types.punct] = nil
      [atoms.types.inner] = { spaceKind.thin, notScript = true },
   },
   [atoms.types.bin] = {
      [atoms.types.ord] = { spaceKind.med, notScript = true },
      [atoms.types.op] = { spaceKind.med, notScript = true },
      [atoms.types.bin] = { impossible = true },
      [atoms.types.rel] = { impossible = true },
      [atoms.types.open] = { spaceKind.med, notScript = true },
      [atoms.types.close] = { impossible = true },
      [atoms.types.punct] = { impossible = true },
      [atoms.types.inner] = { spaceKind.med, notScript = true },
   },
   [atoms.types.rel] = {
      [atoms.types.ord] = { spaceKind.thick, notScript = true },
      [atoms.types.op] = { spaceKind.thick, notScript = true },
      [atoms.types.bin] = { impossible = true },
      -- [atoms.types.rel] = nil
      [atoms.types.open] = { spaceKind.thick, notScript = true },
      -- [atoms.types.close] = nil
      -- [atoms.types.punct] = nil
      [atoms.types.inner] = { spaceKind.thick, notScript = true },
   },
   [atoms.types.open] = {
      -- [atoms.types.ord] = nil
      -- [atoms.types.op] = nil
      [atoms.types.bin] = { impossible = true },
      -- [atoms.types.rel] = nil
      -- [atoms.types.open] = nil
      -- [atoms.types.close] = nil
      -- [atoms.types.punct] = nil
      -- [atoms.types.inner] = nil
   },
   [atoms.types.close] = {
      -- [atoms.types.ord] = nil
      [atoms.types.op] = { spaceKind.thin },
      [atoms.types.bin] = { spaceKind.med, notScript = true },
      [atoms.types.rel] = { spaceKind.thick, notScript = true },
      -- [atoms.types.open] = nil
      -- [atoms.types.close] = nil
      -- [atoms.types.punct] = nil
      [atoms.types.inner] = { spaceKind.thin, notScript = true },
   },
   [atoms.types.punct] = {
      [atoms.types.ord] = { spaceKind.thin, notScript = true },
      [atoms.types.op] = { spaceKind.thin, notScript = true },
      [atoms.types.bin] = { impossible = true },
      [atoms.types.rel] = { spaceKind.thin, notScript = true },
      [atoms.types.open] = { spaceKind.thin, notScript = true },
      [atoms.types.close] = { spaceKind.thin, notScript = true },
      [atoms.types.punct] = { spaceKind.thin, notScript = true },
      [atoms.types.inner] = { spaceKind.thin, notScript = true },
   },
   [atoms.types.inner] = {
      [atoms.types.ord] = { spaceKind.thin, notScript = true },
      [atoms.types.op] = { spaceKind.thin },
      [atoms.types.bin] = { spaceKind.med, notScript = true },
      [atoms.types.rel] = { spaceKind.thick, notScript = true },
      [atoms.types.open] = { spaceKind.thin, notScript = true },
      [atoms.types.punct] = { spaceKind.thin, notScript = true },
      -- [atoms.types.close] = nil
      [atoms.types.inner] = { spaceKind.thin, notScript = true },
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
      -- in The TeXbook, p. 170 (amended with p. 133 for binary operators)
      -- FIXME: This implementation is not using the atom form and the MathML logic (lspace/rspace).
      -- (This is notably unsatisfactory for <mphantom> elements)
      local spaces = {}
      if #self.children >= 1 then
         -- An interpretation of the TeXbook p. 133 for binary operator exceptions:
         -- A binary operator at the beginning of the expression is treated as an ordinary atom
         -- (so as to be considered as a unary operator, without more context).
         local v = self.children[1]
         if v.atom == atoms.types.bin then
            v.atom = atoms.types.ord
         end
      end
      for i = 1, #self.children - 1 do
         local v = self.children[i]
         local v2 = self.children[i + 1]
         -- Handle re-wrapped paired open/close symbols
         v = v.is_paired and v.children[#v.children] or v
         v2 = v2.is_paired and v2.children[1] or v2
         if spacingRules[v.atom] and spacingRules[v.atom][v2.atom] then
            local rule = spacingRules[v.atom][v2.atom]
            if rule.impossible then
               -- Another interpretation of the TeXbook p. 133 for binary operator exceptions:
               if v2.atom == atoms.types.bin then
                  -- If a binary atom follows an atom that is not compatible with it, make it an ordinary.
                  -- (so as to be conidered as a unary operator).
                  -- Typical case: "a = -b" (ord rel bin ord), "a + -b" (ord bin bin ord)
                  v2.atom = atoms.types.ord
               else
                  -- If a binary atom precedes an atom that is not compatible with it, make it an ordinary.
                  -- Quite unusual case (bin, rel/close/punct) unlikely to happen in practice.
                  -- (Not seen in 80+ test formulas)
                  -- We might address it a bit late here, the preceding atom has already based its spacing
                  -- on the binary atom... but this might not be a big deal.
                  -- (i.e. rather than add an extra look-ahead just for this case).
                  -- Artificial example: "a + = b" (ord bin rel ord)
                  v.atom = atoms.types.ord
               end
               rule = spacingRules[v.atom][v2.atom]
               if rule and rule.impossible then
                  -- Should not occur if we did our table based on the TeXbook correctly?
                  -- We can still handle it by ignoring the rule: no spacing sounds logical.
                  -- But let's have a warning so it might be investigated further.
                  SU.warn("Impossible spacing rule for (" .. v.atom .. ", " .. v2.atom .. "), please report this issue")
                  rule = nil
               end
            end
            if rule and not (rule.notScript and (isScriptMode(self.mode) or isScriptScriptMode(self.mode))) then
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
         if elt:is_a(elements.text) and elt.kind == "operator" and SU.boolean(elt.stretchy, false) then
            elt:_vertStretchyReshape(self.depth, self.height)
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

function elements.stackbox:output (_, _, _) end

elements.phantom = pl.class(elements.stackbox) -- inherit from stackbox
elements.phantom._type = "Phantom"

function elements.phantom:_init (children)
   -- MathML core 3.3.7:
   -- "Its layout algorithm is the same as the mrow element".
   -- Also not the MathML states that <mphantom> is sort of legacy, "implemented
   -- for compatibility with full MathML. Authors whose only target is MathML
   -- Core are encouraged to use CSS for styling."
   -- The thing is that we don't have CSS in SILE, so supporting <mphantom> is
   -- a must.
   elements.stackbox._init(self, "H", children)
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
   local isBaseSymbol = not self.base or self.base:is_a(elements.terminal)
   local isBaseLargeOp = SU.boolean(self.base and self.base.largeop, false)
   local subShift
   local supShift
   if self.sub then
      if self.isUnderOver or isBaseLargeOp then
         -- Ad hoc correction on integral limits, following LuaTeX's
         -- `\mathnolimitsmode=0` (see LuaTeX Reference Manual).
         subShift = -itCorr
      else
         subShift = 0
      end
      self.sub.relX = self.width + subShift
      self.sub.relY = SILE.types.length(
         math.max(
            constants.subscriptShiftDown * scaleDown,
            isBaseSymbol and 0 -- TeX (σ19) is more finicky than MathML Core
               or (self.base.depth + constants.subscriptBaselineDropMin * scaleDown):tonumber(),
            (self.sub.height - constants.subscriptTopMax * scaleDown):tonumber()
         )
      )
      if self:is_a(elements.underOver) or self:is_a(elements.stackbox) or isBaseLargeOp then
         self.sub.relY = maxLength(self.sub.relY, self.base.depth + constants.subscriptBaselineDropMin * scaleDown)
      end
   end
   if self.sup then
      if self.isUnderOver or isBaseLargeOp then
         -- Ad hoc correction on integral limits, following LuaTeX's
         -- `\mathnolimitsmode=0` (see LuaTeX Reference Manual).
         supShift = 0
      else
         supShift = itCorr
      end
      self.sup.relX = self.width + supShift
      self.sup.relY = SILE.types.length(
         math.max(
            isCrampedMode(self.mode) and constants.superscriptShiftUpCramped * scaleDown
               or constants.superscriptShiftUp * scaleDown,
            isBaseSymbol and 0 -- TeX (σ18) is more finicky than MathML Core
               or (self.base.height - constants.superscriptBaselineDropMax * scaleDown):tonumber(),
            (self.sup.depth + constants.superscriptBottomMin * scaleDown):tonumber()
         )
      ) * -1
      if self:is_a(elements.underOver) or self:is_a(elements.stackbox) or isBaseLargeOp then
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

function elements.subscript:output (_, _, _) end

elements.underOver = pl.class(elements.subscript)
elements.underOver._type = "UnderOver"

function elements.underOver:__tostring ()
   return self._type .. "(" .. tostring(self.base) .. ", " .. tostring(self.sub) .. ", " .. tostring(self.sup) .. ")"
end

local function isNotEmpty (element)
   -- The MathML test suite uses <munderover> with an empty <mrow> as sub/sup.
   -- I don't know why they didn't use a <munder> or <mover> instead...
   -- But the expectation is to behave as if the empty element was not there,
   -- so that height and depth are not affected by the axis height.
   -- See notably:
   --   MathML3 "complex1" torture test: Maxwell's Equations (vectors in fractions)
   return element and (element:is_a(elements.terminal) or #element.children > 0)
end

local function getAccentMode (mode)
   -- Size unchanged but leave display mode
   -- See MathML Core §3.4.3
   if mode == mathMode.display then
      return mathMode.text
   end
   if mode == mathMode.displayCramped then
      return mathMode.textCramped
   end
   return mode
end

local function unwrapSingleElementMrow (elt)
   -- CODE SMELL.
   -- For \overset or \underset in LaTeX, MathML would use <mover> or <munder>.
   -- It would need to inherit the base's atom type, especially if the later is an operator
   -- (binary, relational etc.), which is a fairly common case, e.g.
   --   \overset{R}{=} (equality with a R above the equal in some Ramanujan summations),
   -- but we can't remove 1-element mrow's in the math typesetter, or have them inherit
   -- their base's atom type here above, because it breaks tables for some reasons
   -- that I couldn't figure out.
   if elt:is_a(elements.stackbox) and elt.direction == "H" and #elt.children == 1 then
      return unwrapSingleElementMrow(elt.children[1])
   else
      return elt
   end
end

function elements.underOver:_init (attributes, base, sub, sup)
   elements.mbox._init(self)
   base = unwrapSingleElementMrow(base)
   self.atom = base.atom
   self.attributes = attributes or {}
   self.attributes.accent = SU.boolean(self.attributes.accent, false)
   self.attributes.accentunder = SU.boolean(self.attributes.accentunder, false)
   self.base = base
   self.sub = isNotEmpty(sub) and sub or nil
   self.sup = isNotEmpty(sup) and sup or nil
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
      self.sub.mode = self.attributes.accentunder and getAccentMode(self.mode) or getSubscriptMode(self.mode)
   end
   if self.sup then
      self.sup.mode = self.attributes.accent and getAccentMode(self.mode) or getSuperscriptMode(self.mode)
   end
end

function elements.underOver:_stretchyReshapeToBase (part)
   -- FIXME: Big leap of faith here.
   -- MathML Core only mentions stretching along the inline axis in 3.4.2.2,
   -- i.e. under the section on <mover>, <munder>, <munderover>.
   -- So we are "somewhat" good here, but... the algorithm is totally unclear
   -- to me and seems to imply a lot of recursion and reshaping.
   -- The implementation below is NOT general and only works for the cases
   -- I checked:
   --   Mozilla MathML tests: braces in f19, f22
   --   Personal tests: vectors in d19, d22, d23
   --   Joe Javawaski's tests: braces in 8a, 8b
   --   MathML3 "complex1" torture test: Maxwell's Equations (vectors in fractions)
   if #part.children == 0 then
      local elt = part
      if elt:is_a(elements.text) and elt.kind == "operator" and SU.boolean(elt.stretchy, false) then
         elt:_horizStretchyReshape(self.base.width)
      end
   elseif part:is_a(elements.underOver) then
      -- Big assumption here: only considering one level of stacked under/over.
      local hasStretched = false
      for _, elt in ipairs(part.children) do
         if elt:is_a(elements.text) and elt.kind == "operator" and SU.boolean(elt.stretchy, false) then
            local stretched = elt:_horizStretchyReshape(self.base.width)
            if stretched then
               hasStretched = true
            end
         end
      end
      if hasStretched then
         -- We need to re-calculate the shape so positions are re-calculated on each
         -- of its own parts.
         -- (Added after seeing that Mozilla test f19 was not rendering correctly.)
         part:shape()
      end
   end
end

function elements.underOver:shape ()
   local constants = self:getMathMetrics().constants
   local scaleDown = self:getScaleDown()
   local isMovableLimits = SU.boolean(self.base and self.base.movablelimits, false)
   local itCorr = self:calculateItalicsCorrection() * scaleDown
   if not (self.mode == mathMode.display or self.mode == mathMode.displayCramped) and isMovableLimits then
      -- When the base is a movable limit, the under/over scripts are not placed under/over the base,
      -- but other to the right of it, when display mode is not used.
      -- Notable effects:
      --   Mozilla MathML test 19 (on "k times" > overbrace > base)
      --   Maxwell's Equations in MathML3 Test Suite "complex1" (on the vectors in fractions)
      self.isUnderOver = true
      elements.subscript.shape(self)
      return
   end
   -- Determine relative Ys
   if self.base then
      self.base.relY = SILE.types.length(0)
   end
   if self.sub then
      self:_stretchyReshapeToBase(self.sub)
      -- TODO These rules are incomplete and even wrong if we were to fully implement MathML Core.
      if self.attributes.accentunder then
         self.sub.relY = self.base.depth
            + SILE.types.length(
               (self.sub.height + constants.lowerLimitGapMin * scaleDown):tonumber()
               -- We assume that the accent is aligned on the base.
            )
      else
         self.sub.relY = self.base.depth
            + SILE.types.length(
               math.max(
                  (self.sub.height + constants.lowerLimitGapMin * scaleDown):tonumber(),
                  constants.lowerLimitBaselineDropMin * scaleDown
               )
            )
      end
   end
   if self.sup then
      self:_stretchyReshapeToBase(self.sup)
      -- TODO These rules are incomplete if we were to fully implement MathML Core.
      if self.attributes.accent then
         self.sup.relY = 0 - self.base.height
         -- MathML Core wants to align on the accentBaseHeight...
         local overShift = math.max(0, constants.accentBaseHeight * scaleDown - self.base.height:tonumber())
         self.sup.relY = self.sup.relY - SILE.types.length(overShift)
         -- HACK: .... but improperly dimensioned accents can overshoot the base glyph.
         -- So we try some guesswork to correct this.
         -- Typically some non-combining symbols are in this case...
         local heuristics = 0.5 * constants.flattenedAccentBaseHeight + 0.5 * constants.accentBaseHeight
         if self.sup.height > SILE.types.length(heuristics * scaleDown) then
            self.sup.relY = self.sup.relY + SILE.types.length(constants.accentBaseHeight * scaleDown)
         end
      else
         self.sup.relY = 0
            - self.base.height
            - SILE.types.length(
               math.max(
                  (constants.upperLimitGapMin * scaleDown + self.sup.depth):tonumber(),
                  constants.upperLimitBaselineRiseMin * scaleDown
               )
            )
      end
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
         if SU.boolean(self.base.largeop) and isDisplayMode(self.mode) then
            c = c * (self.base and self.base.font.size / self.font.size or 1.0)
         end
         return c
      end
   end
   return 0
end

function elements.underOver:output (_, _, _) end

-- terminal is the base class for leaf node
elements.terminal = pl.class(elements.mbox)
elements.terminal._type = "Terminal"

function elements.terminal:_init ()
   elements.mbox._init(self)
end

function elements.terminal:styleChildren () end

function elements.terminal:shape () end

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

function elements.space:output (_, _, _) end

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
      .. (SU.boolean(self.stretchy, false) and ", stretchy" or "")
      .. (SU.boolean(self.largeop, false) and ", largeop" or "")
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
   if isScriptMode(self.mode) then
      local scriptFeature = SILE.settings:get("math.font.script.feature")
      if scriptFeature then
         self.font.features = ("+%s=1"):format(scriptFeature)
      end
   elseif isScriptScriptMode(self.mode) then
      local scriptFeature = SILE.settings:get("math.font.script.feature")
      if scriptFeature then
         self.font.features = ("+%s=2"):format(scriptFeature)
      end
   end
   local face = SILE.font.cache(self.font, SILE.shaper:_getFaceCallback())
   local mathMetrics = self:getMathMetrics()
   local glyphs = SILE.shaper:shapeToken(self.text, self.font)
   -- Use bigger variants for big operators in display style
   if isDisplayMode(self.mode) and SU.boolean(self.largeop, false) then
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

function elements.text:findClosestVariant (variants, requiredAdvance, currentAdvance)
   local closest
   local closestI
   local m = requiredAdvance - currentAdvance
   for i, variant in ipairs(variants) do
      local diff = math.abs(variant.advanceMeasurement - requiredAdvance)
      SU.debug("math", "stretch: diff =", diff)
      if diff < m then
         closest = variant
         closestI = i
         m = diff
      end
   end
   return closest, closestI
end

function elements.text:_reshapeGlyph (glyph, closestVariant, sz)
   local face = SILE.font.cache(self.font, SILE.shaper:_getFaceCallback())
   local dimen = hb.get_glyph_dimensions(face, sz, closestVariant.variantGlyph)
   glyph.gid = closestVariant.variantGlyph
   glyph.width, glyph.height, glyph.depth, glyph.glyphAdvance =
      dimen.width, dimen.height, dimen.depth, dimen.glyphAdvance
   return dimen
end

function elements.text:_stretchyReshape (target, direction)
   -- direction is the required direction of stretching: true for vertical, false for horizontal
   -- target is the required dimension of the stretched glyph, in font units
   local mathMetrics = self:getMathMetrics()
   local upem = mathMetrics.unitsPerEm
   local sz = self.font.size
   local requiredAdvance = target:tonumber() * upem / sz
   SU.debug("math", "stretch: rA =", requiredAdvance)
   -- Choose variant of the closest size. The criterion we use is to have
   -- an advance measurement as close as possible as the required one.
   -- The advance measurement is simply the dimension of the glyph.
   -- Therefore, the selected glyph may be smaller or bigger than
   -- required.
   -- TODO: implement assembly of stretchable glyphs from their parts for cases
   -- when the biggest variant is not big enough.
   -- We copy the glyph list to avoid modifying the shaper's cache. Yes.
   local glyphs = pl.tablex.deepcopy(self.value.items)
   local glyphConstructions = direction and mathMetrics.mathVariants.vertGlyphConstructions
      or mathMetrics.mathVariants.horizGlyphConstructions
   local constructions = glyphConstructions[glyphs[1].gid]
   if constructions then
      local variants = constructions.mathGlyphVariantRecord
      SU.debug("math", "stretch: variants =", variants)
      local currentAdvance = (direction and (self.depth + self.height):tonumber() or self.width:tonumber()) * upem / sz
      local closest, closestI = self:findClosestVariant(variants, requiredAdvance, currentAdvance)
      SU.debug("math", "stretch: closestI =", closestI)
      if closest then
         -- Now we have to re-shape the glyph chain. We will assume there
         -- is only one glyph.
         -- TODO: this code is probably wrong when the vertical
         -- variants have a different width than the original, because
         -- the shaping phase is already done. Need to do better.
         local dimen = self:_reshapeGlyph(glyphs[1], closest, sz)
         self.width, self.depth, self.height =
            SILE.types.length(dimen.glyphAdvance), SILE.types.length(dimen.depth), SILE.types.length(dimen.height)
         SILE.shaper:preAddNodes(glyphs, self.value)
         self.value.items = glyphs
         self.value.glyphString = { glyphs[1].gid }
         return true
      end
   end
   return false
end

function elements.text:_vertStretchyReshape (depth, height)
   local hasStretched = self:_stretchyReshape(depth + height, true)
   if hasStretched then
      -- RESCALING HACK: see output routine
      -- We only do it if the scaling logic found constructions on the vertical block axis.
      -- It's a dirty hack until we properly implement assembly of glyphs in the case we couldn't
      -- find a big enough variant.
      self.vertExpectedSz = height + depth
      self.vertScalingRatio = (depth + height):tonumber() / (self.height:tonumber() + self.depth:tonumber())
      self.height = height
      self.depth = depth
   end
   return hasStretched
end

function elements.text:_horizStretchyReshape (width)
   local hasStretched = self:_stretchyReshape(width, false)
   if not hasStretched and width:tonumber() < self.width:tonumber() then
      -- Never shrink glyphs, it looks ugly
      return false
   end
   -- But if stretching couldn't be done, it will be ugly anyway, so we will force
   -- a re-scaling of the glyph.
   -- (So it slightly different from the vertical case, 'cause MathML just has one stretchy
   -- attribute, whether for stretching on the vertical (block) or horizontal (inline) axis,
   -- and we cannot know which axis is meant unless we implement yet another mapping table
   -- as the one in the MathML Core appendices. Frankly, how many non-normative appendices
   -- do we need to implement MathML correctly?)
   -- RESCALING HACK: see output routine
   self.horizScalingRatio = width:tonumber() / self.width:tonumber()
   self.width = width
   return true
end

function elements.text:output (x, y, line)
   if not self.value.glyphString then
      return
   end
   local compensatedY
   if isDisplayMode(self.mode) and SU.boolean(self.largeop, false) and self.value.items[1].fontDepth then
      compensatedY = SILE.types.length(y.length + self.value.items[1].depth - self.value.items[1].fontDepth)
   else
      compensatedY = y
   end
   SILE.outputter:setCursor(scaleWidth(x, line), compensatedY.length)
   SILE.outputter:setFont(self.font)
   -- There should be no stretch or shrink on the width of a text
   -- element.
   local width = self.width.length
   -- HACK: For stretchy operators, MathML Core and OpenType define how to build large glyphs
   -- from an assembly of smaller ones. It's fairly complex and idealistic...
   -- Anyhow, we do not have that yet, so we just stretch the glyph artificially.
   -- There are cases where this will not look very good.
   -- Call that a compromise, so that long vectors or large matrices look "decent" without assembly.
   if SILE.outputter.scaleFn and (self.horizScalingRatio or self.vertScalingRatio) then
      local xratio = self.horizScalingRatio or 1
      local yratio = self.vertScalingRatio or 1
      SU.debug("math", "fake glyph stretch: xratio =", xratio, "yratio =", yratio)
      SILE.outputter:scaleFn(x, y, xratio, yratio, function ()
         SILE.outputter:drawHbox(self.value, width)
      end)
   else
      SILE.outputter:drawHbox(self.value, width)
   end
end

elements.fraction = pl.class(elements.mbox)
elements.fraction._type = "Fraction"

function elements.fraction:__tostring ()
   return self._type .. "(" .. tostring(self.numerator) .. ", " .. tostring(self.denominator) .. ")"
end

function elements.fraction:_init (attributes, numerator, denominator)
   elements.mbox._init(self)
   self.numerator = numerator
   self.denominator = denominator
   self.attributes = attributes
   table.insert(self.children, numerator)
   table.insert(self.children, denominator)
end

function elements.fraction:styleChildren ()
   self.numerator.mode = getNumeratorMode(self.mode)
   self.denominator.mode = getDenominatorMode(self.mode)
end

function elements.fraction:shape ()
   -- MathML Core 3.3.2: "To avoid visual confusion between the fraction bar
   -- and another adjacent items (e.g. minus sign or another fraction's bar),
   -- a default 1-pixel space is added around the element."
   -- Note that PlainTeX would likely use \nulldelimiterspace (default 1.2pt)
   -- but it would depend on the surrounding context, and might be far too
   -- much in some cases, so we stick to MathML's suggested padding.
   self.padding = SILE.types.length("1px"):absolute()

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
   self.ruleThickness = self.attributes.linethickness
         and SU.cast("measurement", self.attributes.linethickness):tonumber()
      or constants.fractionRuleThickness * scaleDown

   -- MathML Core 3.3.2.2 ("Fraction with zero line thickness") uses
   -- stack(DisplayStyle)GapMin, stackTop(DisplayStyle)ShiftUp and stackBottom(DisplayStyle)ShiftDown.
   -- TODO not implemented
   -- The most common use cases for zero line thickness are:
   --  - Binomial coefficients
   --  - Stacked subscript/superscript on big operators such as sums.

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
   if self.ruleThickness > 0 then
      SILE.outputter:drawRule(
         scaleWidth(x + self.padding, line),
         y.length - self.axisHeight - self.ruleThickness / 2,
         scaleWidth(self.width - 2 * self.padding, line),
         self.ruleThickness
      )
   end
end

local function newSubscript (spec)
   return elements.subscript(spec.base, spec.sub, spec.sup)
end

local function newUnderOver (spec)
   return elements.underOver(spec.attributes, spec.base, spec.sub, spec.sup)
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

function elements.mtr:shape () end -- done by parent table

function elements.mtr:output () end

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

function elements.table:output () end

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
   local radicalGlyph, found = SILE.shaper:measureChar("√")
   if not found then
      SU.error("Math font does not contain a square root glyph")
   end
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
   -- Compute the dimensions of the whole radical
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
      1,
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

elements.padded = pl.class(elements.mbox)
elements.padded._type = "Padded"

function elements.padded:__tostring ()
   return self._type .. "(" .. tostring(self.impadded) .. ")"
end

function elements.padded:_init (attributes, impadded)
   elements.mbox._init(self)
   self.impadded = impadded
   self.attributes = attributes or {}
   table.insert(self.children, impadded)
end

function elements.padded:styleChildren ()
   self.impadded.mode = self.mode
end

function elements.padded:shape ()
   -- TODO MathML allows percentages font-relative units (em, ex) for padding
   -- But our units work with font.size, not math.font.size (possibly adjusted by scaleDown)
   -- so the expectations might not be met.
   local width = self.attributes.width and SU.cast("measurement", self.attributes.width)
   local height = self.attributes.height and SU.cast("measurement", self.attributes.height)
   local depth = self.attributes.depth and SU.cast("measurement", self.attributes.depth)
   local lspace = self.attributes.lspace and SU.cast("measurement", self.attributes.lspace)
   local voffset = self.attributes.voffset and SU.cast("measurement", self.attributes.voffset)
   -- Clamping for width, height, depth, lspace
   width = width and (width:tonumber() > 0 and width or SILE.types.measurement())
   height = height and (height:tonumber() > 0 and height or SILE.types.measurement())
   depth = depth and (depth:tonumber() > 0 and depth or SILE.types.measurement())
   lspace = lspace and (lspace:tonumber() > 0 and lspace or SILE.types.measurement())
   -- No clamping for voffset
   voffset = voffset or SILE.types.measurement(0)
   -- Compute the dimensions
   self.width = width and SILE.types.length(width) or self.impadded.width
   self.height = height and SILE.types.length(height) or self.impadded.height
   self.depth = depth and SILE.types.length(depth) or self.impadded.depth
   self.impadded.relX = lspace and SILE.types.length(lspace) or SILE.types.length()
   self.impadded.relY = voffset and SILE.types.length(voffset):negate() or SILE.types.length()
end

function elements.padded:output (_, _, _) end

-- Bevelled fractions are not part of MathML Core, and MathML4 does not
-- exactly specify how to compute the layout.
elements.bevelledFraction = pl.class(elements.fraction) -- Inherit from fraction
elements.fraction._type = "BevelledFraction"

function elements.bevelledFraction:shape ()
   local constants = self:getMathMetrics().constants
   local scaleDown = self:getScaleDown()
   local hSkew = constants.skewedFractionHorizontalGap * scaleDown
   -- OpenType has properties which are not totally explicit.
   -- The definition of skewedFractionVerticalGap (and its value in fonts
   -- such as Libertinus Math) seems to imply that it is measured from the
   -- bottom of the numerator to the top of the denominator.
   -- This does not seem to be a nice general layout.
   -- So we will use superscriptShiftUp(Cramped) for the numerator:
   local vSkewUp = isCrampedMode(self.mode) and constants.superscriptShiftUpCramped * scaleDown
      or constants.superscriptShiftUp * scaleDown
   -- And all good books say that the denominator should not be shifted down:
   local vSkewDown = 0

   self.ruleThickness = self.attributes.linethickness
         and SU.cast("measurement", self.attributes.linethickness):tonumber()
      or constants.fractionRuleThickness * scaleDown
   self.numerator.relX = SILE.types.length(0)
   self.numerator.relY = SILE.types.length(-vSkewUp)
   self.denominator.relX = self.numerator.width + hSkew
   self.denominator.relY = SILE.types.length(vSkewDown)
   self.width = self.numerator.width + self.denominator.width + hSkew
   self.height = maxLength(self.numerator.height + vSkewUp, self.denominator.height - vSkewDown)
   self.depth = maxLength(self.numerator.depth - vSkewUp, self.denominator.depth + vSkewDown)
   self.barWidth = SILE.types.length(hSkew)
   self.barX = self.numerator.relX + self.numerator.width
end

function elements.bevelledFraction:output (x, y, line)
   local h = self.height:tonumber()
   local d = self.depth:tonumber()
   local barwidth = scaleWidth(self.barWidth, line):tonumber()
   local xscaled = scaleWidth(x + self.barX, line)
   local rd = self.ruleThickness / 2
   local symbol = {
      _r(self.ruleThickness),
      "w", -- line width
      1,
      "J", -- round line caps
      _r(0),
      _r(d + h - rd),
      "m",
      _r(barwidth),
      _r(rd),
      "l",
      "S",
   }
   local svg = table.concat(symbol, " ")
   SILE.outputter:drawSVG(svg, xscaled, y, barwidth, h, 1)
end

elements.mathMode = mathMode
elements.newSubscript = newSubscript
elements.newUnderOver = newUnderOver

return elements
