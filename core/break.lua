SILE.settings:declare({ parameter = "linebreak.parShape", type = "boolean", default = false,
  help = "If set to true, the paragraph shaping method is activated." })
SILE.settings:declare({ parameter = "linebreak.tolerance", type = "integer or nil", default = 500 })
SILE.settings:declare({ parameter = "linebreak.pretolerance", type = "integer or nil", default = 100 })
SILE.settings:declare({ parameter = "linebreak.hangIndent", type = "measurement", default = 0 })
SILE.settings:declare({ parameter = "linebreak.hangAfter", type = "integer or nil", default = nil })
SILE.settings:declare({ parameter = "linebreak.adjdemerits", type = "integer", default = 10000,
  help = "Additional demerits which are accumulated in the course of paragraph building when two consecutive lines are visually incompatible. In these cases, one line is built with much space for justification, and the other one with little space." })
SILE.settings:declare({ parameter = "linebreak.looseness", type = "integer", default = 0 })
SILE.settings:declare({ parameter = "linebreak.prevGraf", type = "integer", default = 0 })
SILE.settings:declare({ parameter = "linebreak.emergencyStretch", type = "measurement", default = 0 })
SILE.settings:declare({ parameter = "linebreak.doLastLineFit", type = "boolean", default = false }) -- unimplemented
SILE.settings:declare({ parameter = "linebreak.linePenalty", type = "integer", default = 10 })
SILE.settings:declare({ parameter = "linebreak.hyphenPenalty", type = "integer", default = 50 })
SILE.settings:declare({ parameter = "linebreak.doubleHyphenDemerits", type = "integer", default = 10000 })
SILE.settings:declare({ parameter = "linebreak.finalHyphenDemerits", type = "integer", default = 5000 })

-- doubleHyphenDemerits
-- hyphenPenalty

local classes = { "tight"; "decent"; "loose"; "veryLoose" }
local passSerial = 0
local awful_bad = 1073741823
local inf_bad = 10000
local ejectPenalty = -inf_bad
local lineBreak = {}

--[[
  Basic control flow:
  doBreak:
    init
    for each node:
      checkForLegalBreak
        tryBreak
          createNewActiveNodes
          considerDemerits
            deactivateR (or) recordFeasible
    tryFinalBreak
    postLineBreak
]]

local param = function (key)
  local value = SILE.settings:get("linebreak."..key)
  return type(value) == "table" and value:absolute() or value
end

-- Routines here will be called thousands of times; we micro-optimize
-- to avoid debugging and concat calls.
local debugging = false

function lineBreak:init()
  self:trimGlue() -- 842
  -- 849
  self.activeWidth = SILE.length()
  self.curActiveWidth = SILE.length()
  self.breakWidth = SILE.length()
  -- 853
  local rskip = (SILE.settings:get("document.rskip") or SILE.nodefactory.glue()).width:absolute()
  local lskip = (SILE.settings:get("document.lskip") or SILE.nodefactory.glue()).width:absolute()
  self.background = rskip + lskip
  -- 860
  self.bestInClass = {}
  for i = 1, #classes do
    self.bestInClass[classes[i]] = {
      minimalDemerits = awful_bad
    }
  end
  self.minimumDemerits = awful_bad
  self:setupLineLengths()
end

function lineBreak:trimGlue() -- 842
  local nodes = self.nodes
  if nodes[#nodes].is_glue then nodes[#nodes] = nil end
  nodes[#nodes+1] = SILE.nodefactory.penalty(inf_bad)
end

-- NOTE FOR DEVELOPERS: this method is called when the linebreak.parShape
-- setting is true. The arguments passed are self (the linebreaker instance)
-- and a counter representing the current line number.
--
-- The default implementation does nothing but waste a function call, resulting
-- in normal paragraph shapes. Extended paragraph shapes are intended to be
-- provided by overriding this method.
--
-- The expected return is three values, any of which may be nil to use default
-- values or a measurement to override the defaults. The values are considered
-- as left, width, and right respectively.
--
-- Since self.hsize holds the current line width, these three values should add
-- up to the that total. Returning values that don't add up may produce
-- unexpected results.
--
-- TeX wizards shall also note that this is slighty different from
-- Knuth's definition "nline l1 i1 l2 i2 ... lN iN".
function lineBreak:parShape(_)
  return 0, self.hsize, 0
end

local parShapeCache = {}

local grantLeftoverWidth = function (hsize, l, w, r)
  local width = SILE.measurement(w or hsize)
  if not w and l then width = width - SILE.measurement(l) end
  if not w and r then width = width - SILE.measurement(r) end
  local remaining = hsize:tonumber() - width:tonumber()
  local left = SU.cast("number", l or (r and (remaining - SU.cast("number", r))) or 0)
  local right = SU.cast("number", r or (l and (remaining - SU.cast("number", l))) or remaining)
  return left, width, right
end

-- Wrap linebreak:parShape in a memoized table for fast access
function lineBreak:parShapeCache(n)
  local cache = parShapeCache[n]
  if not cache then
    local l, w, r = self:parShape(n)
    local left, width, right = grantLeftoverWidth(self.hsize, l, w, r)
    cache = { left, width, right }
  end
  return cache[1], cache[2], cache[3]
end

function lineBreak.parShapeCacheClear(_)
  pl.tablex.clear(parShapeCache)
end

function lineBreak:setupLineLengths() -- 874
  self.parShaping = param("parShape") or false
  if self.parShaping then
    self.lastSpecialLine = nil
    self.easy_line = nil
  else
    self.hangAfter = param("hangAfter") or 0
    self.hangIndent = param("hangIndent"):tonumber()
    if self.hangIndent == 0 then
      self.lastSpecialLine = 0
      self.secondWidth = self.hsize or SU.error("No hsize")
    else -- 875
      self.lastSpecialLine = math.abs(self.hangAfter)
      if self.hangAfter < 0 then
        self.secondWidth = self.hsize or SU.error("No hsize")
        self.firstWidth = self.hsize - math.abs(self.hangIndent)
      else
        self.firstWidth = self.hsize or SU.error("No hsize")
        self.secondWidth = self.hsize - math.abs(self.hangIndent)
      end
    end
    if param("looseness") == 0 then self.easy_line = self.lastSpecialLine else self.easy_line = awful_bad end
    -- self.easy_line = awful_bad
  end
end

function lineBreak:tryBreak() -- 855
  local pi, breakType
  local node = self.nodes[self.place]
  if not node then pi = ejectPenalty; breakType = "hyphenated"
  elseif node.is_discretionary then breakType = "hyphenated"; pi = param("hyphenPenalty")
  else breakType = "unhyphenated"; pi = node.penalty or 0 end
  if debugging then SU.debug("break", "Trying a ", breakType, "break p =", pi) end
  self.no_break_yet = true -- We have to store all this state crap in the object, or it's global variables all the way
  self.prev_prev_r = nil
  self.prev_r = self.activeListHead
  self.old_l = 0
  self.r = nil
  self.curActiveWidth = SILE.length(self.activeWidth)
  while true do
    while true do -- allows "break" to function as "continue"
      self.r = self.prev_r.next
      if debugging then SU.debug("break", "We have moved the link  forward, ln is now", self.r.type == "delta" and "XX" or self.r.lineNumber) end
      if self.r.type == "delta" then -- 858
        if debugging then SU.debug("break", " Adding delta node width of", self.r.width) end
        self.curActiveWidth:___add(self.r.width)
        self.prev_prev_r = self.prev_r
        self.prev_r = self.r
        break
      end
      -- 861
      if self.r.lineNumber > self.old_l then
        if debugging then SU.debug("break", "Mimimum demerits = " .. self.minimumDemerits) end
        if self.minimumDemerits < awful_bad and (self.old_l ~= self.easy_line or self.r == self.activeListHead) then
          self:createNewActiveNodes(breakType)
        end
        if self.r == self.activeListHead then
          if debugging then SU.debug("break", "<- tryBreak") end
          return
        end
        -- 876
        if self.easy_line and self.r.lineNumber > self.easy_line then
          self.lineWidth = self.secondWidth
          self.old_l = awful_bad -1
        else
          self.old_l = self.r.lineNumber
          if self.lastSpecialLine and self.r.lineNumber > self.lastSpecialLine then
            self.lineWidth = self.secondWidth
          elseif self.parShaping then
            local _
            _, self.lineWidth, _ = self:parShapeCache(self.r.lineNumber)
          else
            self.lineWidth = self.firstWidth
          end
        end
        if debugging then SU.debug("break", "line width = " .. tostring(self.lineWidth)) end
      end
      if debugging then
        SU.debug("break", " ---> (2) cuaw is " .. tostring(self.curActiveWidth))
        SU.debug("break", " ---> aw is " .. tostring(self.activeWidth))
      end
      self:considerDemerits(pi, breakType)
      if debugging then
        SU.debug("break", " <--- cuaw is " .. tostring(self.curActiveWidth))
        SU.debug("break", " <--- aw is " .. tostring(self.activeWidth))
      end
    end
  end
end

-- Note: This function gets called a lot and to optimize it we're assuming that
-- the lengths being passed are already absolutized. This is not a safe
-- assumption to make universally.
local function fitclass(self, shortfall)
  shortfall = shortfall.amount
  local badness, class
  local stretch = self.curActiveWidth.stretch.amount
  local shrink = self.curActiveWidth.shrink.amount
  if shortfall > 0 then
    if shortfall > 110 and stretch < 25 then
      badness = inf_bad
    else
      badness = SU.rateBadness(inf_bad, shortfall, stretch)
    end
    if     badness > 99 then class = "veryLoose"
    elseif badness > 12 then class = "loose"
    else                     class = "decent"
    end
  else
    shortfall = -shortfall
    if shortfall > shrink then
      badness = inf_bad + 1
    else
      badness = SU.rateBadness(inf_bad, shortfall, shrink)
    end
    if badness > 12 then class = "tight"
    else                 class = "decent"
    end
  end
  return badness, class
end

function lineBreak:tryAlternatives(from, to)
  local altSizes = {}
  local alternates = {}
  for i = from, to do
    if self.nodes[i] and self.nodes[i].is_alternative then
      alternates[#alternates+1] = self.nodes[i]
      altSizes[#altSizes+1] = #(self.nodes[i].options)
    end
  end
  if #alternates == 0 then return end
  local localMinimum = awful_bad
  -- local selectedShortfall
  local shortfall = self.lineWidth - self.curActiveWidth
  if debugging then SU.debug("break", "Shortfall was ", shortfall) end
  for combination in SU.allCombinations(altSizes) do
    local addWidth = 0
    for i = 1, #(alternates) do local alternative = alternates[i]
      addWidth = (addWidth + alternative.options[combination[i]].width - alternative:minWidth())
      if debugging then SU.debug("break", alternative.options[combination[i]], " width", addWidth) end
    end
    local ss = shortfall - addWidth
    -- Warning, assumes abosolute
    local badness = SU.rateBadness(inf_bad, ss.length.amount, self.curActiveWidth[ss > 0 and "stretch" or "shrink"].length.amount)
    if debugging then SU.debug("break", "  badness of " .. ss .. " (" .. self.curActiveWidth .. ") is " .. badness) end
    if badness < localMinimum then
      self.r.alternates = alternates
      self.r.altSelections = combination
      -- selectedShortfall = addWidth
      localMinimum = badness
    end
  end
  if debugging then SU.debug("break", "Choosing ", alternates[1].options[self.r.altSelections[1]]) end
  -- self.curActiveWidth:___add(selectedShortfall)
  shortfall = self.lineWidth - self.curActiveWidth
  if debugging then SU.debug("break", "Is now ", shortfall) end
end

function lineBreak:considerDemerits(pi, breakType) -- 877
  self.artificialDemerits = false
  local nodeStaysActive = false
  -- self:dumpActiveRing()
  local shortfall = self.lineWidth - self.curActiveWidth
  if self.seenAlternatives then
    self:tryAlternatives(self.r.prevBreak and self.r.prevBreak.curBreak or 1, self.r.curBreak and self.r.curBreak or 1, shortfall)
  end
  shortfall = self.lineWidth - self.curActiveWidth
  self.badness, self.fitClass = fitclass(self, shortfall)
  if debugging then SU.debug("break", self.badness .. " " .. self.fitClass) end
  if (self.badness > inf_bad or pi == ejectPenalty) then
    if self.finalpass and self.minimumDemerits == awful_bad and self.r.next == self.activeListHead and self.prev_r == self.activeListHead then
      self.artificialDemerits = true
    else
      if self.badness > self.threshold then
        self:deactivateR()
        return
      end
    end
  else
    self.prev_r = self.r
    if self.badness > self.threshold then return end
    nodeStaysActive = true
  end

  local _shortfall = shortfall:tonumber()
  local function shortfallratio (metric)
    local prop = self.curActiveWidth[metric]:tonumber()
    local factor = prop ~= 0 and prop or awful_bad
    return _shortfall / factor
  end
  self.lastRatio = shortfallratio(_shortfall > 0 and "stretch" or "shrink")
  self:recordFeasible(pi, breakType)
  if not nodeStaysActive then self:deactivateR() end
end

function lineBreak:deactivateR() -- 886
  if debugging then SU.debug("break", " Deactivating r ("..self.r.type..")") end
  self.prev_r.next = self.r.next
  if self.prev_r == self.activeListHead then
    -- 887
    self.r = self.activeListHead.next
    if self.r.type == "delta" then
      self.activeWidth:___add(self.r.width)
      self.curActiveWidth = SILE.length(self.activeWidth)
      self.activeListHead.next = self.r.next
    end
    if debugging then SU.debug("break", "  Deactivate, branch 1"); end
  else
    if self.prev_r.type == "delta" then
      self.r = self.prev_r.next
      if self.r == self.activeListHead then
        self.curActiveWidth:___sub(self.prev_r.width)
        -- FIXME It was crashing here, so changed from:
        -- self.curActiveWidth:___sub(self.r.width)
        -- But I'm not so sure reading Knuth here...
        self.prev_prev_r.next = self.activeListHead
        self.prev_r = self.prev_prev_r
      elseif self.r.type == "delta" then
        self.curActiveWidth:___add(self.r.width)
        self.prev_r.width:___add(self.r.width)
        self.prev_r.next = self.r.next
      end
    end
    if debugging then SU.debug("break", "  Deactivate, branch 2"); end
  end
end

function lineBreak:computeDemerits(pi, breakType)
  if self.artificialDemerits then return 0 end
  local demerit = param("linePenalty") + self.badness
  if math.abs(demerit) >= 10000 then
    demerit = 100000000
  else
    demerit = demerit * demerit
  end
  if pi > 0 then
    demerit = demerit + pi * pi
  -- elseif pi == 0 then
  --   -- do nothing
  elseif pi > ejectPenalty then
    demerit = demerit - pi * pi
  end
  if breakType == "hyphenated" and self.r.type == "hyphenated" then
    if self.nodes[self.place] then
      demerit = demerit + param("doubleHyphenDemerits")
    else
      demerit = demerit + param("finalHyphenDemerits")
    end
  end
  -- XXX adjDemerits not added here
  return demerit
end

function lineBreak:recordFeasible(pi, breakType) -- 881
  local demerit = lineBreak:computeDemerits(pi, breakType)
  if debugging then
    if self.nodes[self.place] then
      SU.debug("break", "@" .. self.nodes[self.place] .. " via @@" .. (self.r.serial or "0")  .. " badness=" .. self.badness .. " demerit=".. demerit) -- 882
    else
      SU.debug("break", "@ \\par via @@")
    end
    SU.debug("break", " fit class = "..self.fitClass)
  end
  demerit = demerit + self.r.totalDemerits
  if demerit <= self.bestInClass[self.fitClass].minimalDemerits then
    self.bestInClass[self.fitClass] = {
      minimalDemerits = demerit,
      node = self.r.serial and self.r,
      line = self.r.lineNumber
    }
    -- XXX do last line fit
    if demerit < self.minimumDemerits then self.minimumDemerits = demerit end
  end
end


function lineBreak:createNewActiveNodes(breakType) -- 862
  if self.no_break_yet then
    -- 863
    self.no_break_yet = false
    self.breakWidth = SILE.length(self.background)
    local place = self.place
    local node = self.nodes[place]
    if node and node.is_discretionary then -- 866
      self.breakWidth:___add(node:prebreakWidth())
      self.breakWidth:___add(node:postbreakWidth())
      self.breakWidth:___sub(node:replacementWidth())
    end
    while self.nodes[place] and not self.nodes[place].is_box do
      if self.sideways and self.nodes[place].height then
        self.breakWidth:___sub(self.nodes[place].height)
        self.breakWidth:___sub(self.nodes[place].depth)
      elseif self.nodes[place].width then -- We use the fact that (a) nodes know if they have width and (b) width subtraction is polymorphic
        self.breakWidth:___sub(self.nodes[place]:lineContribution())
      end
      place = place + 1
    end
    if debugging then SU.debug("break", "Value of breakWidth = " .. tostring(self.breakWidth)) end
  end
  -- 869 (Add a new delta node)
  if self.prev_r.type == "delta" then
    self.prev_r.width:___sub(self.curActiveWidth)
    self.prev_r.width:___add(self.breakWidth)
  elseif self.prev_r == self.activeListHead then
    self.activeWidth = SILE.length(self.breakWidth)
  else
    local newDelta = { next = self.r, type = "delta", width = self.breakWidth - self.curActiveWidth }
    if debugging then SU.debug("break", "Added new delta node = " .. tostring(newDelta.width)) end
    self.prev_r.next = newDelta
    self.prev_prev_r = self.prev_r
    self.prev_r = newDelta
  end
  if math.abs(self.adjdemerits) >= (awful_bad - self.minimumDemerits) then
    self.minimumDemerits = awful_bad - 1
  else
    self.minimumDemerits = self.minimumDemerits + math.abs(self.adjdemerits)
  end

  for i = 1, #classes do
    local class = classes[i]
    local best = self.bestInClass[class]
    local value = best.minimalDemerits
    if debugging then SU.debug("break", "Class is "..class.." Best value here is " .. value) end

    if value <= self.minimumDemerits then
      -- 871: this is what creates new active notes
      passSerial = passSerial + 1

      local newActive = {
        type = breakType,
        next = self.r,
        curBreak = self.place,
        prevBreak = best.node,
        serial = passSerial,
        ratio = self.lastRatio,
        lineNumber = best.line + 1,
        fitness = class,
        totalDemerits = value
      }
      -- DoLastLineFit? 1636 XXX
      self.prev_r.next = newActive
      self.prev_r = newActive
      self:dumpBreakNode(newActive)

    end
    self.bestInClass[class] = { minimalDemerits = awful_bad }
  end

  self.minimumDemerits = awful_bad
  -- 870
  if self.r ~= self.activeListHead then
    local newDelta = { next = self.r, type = "delta", width = self.curActiveWidth - self.breakWidth }
    self.prev_r.next = newDelta
    self.prev_prev_r = self.prev_r
    self.prev_r = newDelta
  end
end

function lineBreak.dumpBreakNode(_, node)
  if not SU.debugging("break") then return end
  SU.debug("break", lineBreak:describeBreakNode(node))
end

function lineBreak:describeBreakNode(node)
  --print("@@" .. b.serial .. ": line " .. (b.lineNumber -1) .. "." .. b.fitness .. " " .. b.type .. " t=".. b.totalDemerits .. " -> @@ " .. (b.prevBreak and b.prevBreak.serial or "0") )
  if node.sentinel then return node.sentinel end
  if node.type == "delta" then return "delta "..node.width.."pt" end
  local before = self.nodes[node.curBreak-1]
  local after = self.nodes[node.curBreak+1]
  local from = node.prevBreak and node.prevBreak.curBreak or 1
  local to = node.curBreak
  return ("b %s-%s \"%s | %s\" [%s, %s]"):format(from, to, before and before:toText() or "", after and after:toText() or "", node.totalDemerits, node.fitness)
end

-- NOTE: this function is called many thousands of times even in single
-- page documents. Speed is more important than pretty code here.
function lineBreak:checkForLegalBreak(node) -- 892
  if debugging then SU.debug("break", "considering node "..node); end
  local previous = self.nodes[self.place - 1]
  if node.is_alternative then self.seenAlternatives = true end
  if self.sideways and node.is_box then
    self.activeWidth:___add(node.height)
    self.activeWidth:___add(node.depth)
  elseif self.sideways and node.is_vglue then
    if previous and previous.is_box then
      self:tryBreak()
    end
    self.activeWidth:___add(node.height)
    self.activeWidth:___add(node.depth)
  elseif node.is_alternative then
    self.activeWidth:___add(node:minWidth())
  elseif node.is_box then
    self.activeWidth:___add(node:lineContribution())
  elseif node.is_glue then
    -- 894 (We removed the auto_breaking parameter)
    if previous and previous.is_box then self:tryBreak() end
    self.activeWidth:___add(node.width)
  elseif node.is_kern then
    self.activeWidth:___add(node.width)
  elseif node.is_discretionary then -- 895
    self.activeWidth:___add(node:prebreakWidth())
    self:tryBreak()
    self.activeWidth:___sub(node:prebreakWidth())
    self.activeWidth:___add(node:replacementWidth())
  elseif node.is_penalty then
    self:tryBreak()
  end
end

function lineBreak:tryFinalBreak()      -- 899
  -- XXX TeX has self:tryBreak() here. But this doesn't seem to work
  -- for us. If we call tryBreak(), we end up demoting all break points
  -- to veryLoose (possibly because the active width gets reset - why?).
  -- This means we end up doing unnecessary passes.
  -- However, there doesn't seem to be any downside to not calling it
  -- (how scary is that?) so I have removed it for now. With this
  -- "fix", we only perform hyphenation and emergency passes when necessary
  -- instead of every single time. If things go strange with the break
  -- algorithm in the future, this should be the first place to look!
  -- self:tryBreak()
  if self.activeListHead.next == self.activeListHead then return end
  self.r = self.activeListHead.next
  local fewestDemerits = awful_bad
  repeat
    if self.r.type ~= "delta" and self.r.totalDemerits < fewestDemerits then
      fewestDemerits = self.r.totalDemerits
      self.bestBet = self.r
    end
    self.r = self.r.next
  until self.r == self.activeListHead
  if param("looseness") == 0 then return true end
  -- XXX node 901 not implemented
  if self.actualLooseness == param("looseness") or self.finalpass then
    return true
  end
end

function lineBreak:doBreak (nodes, hsize, sideways)
  passSerial = 1
  debugging = SILE.debugFlags["break"]
  self.seenAlternatives = false
  self.nodes = nodes
  self.hsize = hsize
  self.sideways = sideways
  self:init()
  self.adjdemerits = param("adjdemerits")
  self.threshold = param("pretolerance")
  if self.threshold >= 0 then
    self.pass = "first"
    self.finalpass = false
  else
    self.threshold = param("tolerance")
    self.pass = "second"
    self.finalpass = param("emergencyStretch") <= 0
  end
  -- 889
  while 1 do
    if debugging then SU.debug("break", "@" .. self.pass .. "pass") end
    if self.threshold > inf_bad then self.threshold = inf_bad end
    if self.pass == "second" then
      self.nodes = SILE.hyphenate(self.nodes)
      SILE.typesetter.state.nodes = self.nodes -- Horrible breaking of separation of concerns here. :-(
    end
    -- 890
    self.activeListHead = {
      sentinel="START",
      type = "hyphenated",
      lineNumber = awful_bad,
      subtype = 0
    } -- 846
    self.activeListHead.next = {
      sentinel="END",
      type = "unhyphenated",
      fitness = "decent",
      next = self.activeListHead,
      lineNumber = param("prevGraf") + 1,
      totalDemerits = 0
    }

    -- Not doing 1630
    self.activeWidth = SILE.length(self.background)

    self.place = 1
    while self.nodes[self.place] and self.activeListHead.next ~= self.activeListHead do
      self:checkForLegalBreak(self.nodes[self.place])
      self.place = self.place + 1
    end
    if self.place > #self.nodes then
      if self:tryFinalBreak() then break end
    end
    -- (Not doing 891)
    if self.pass ~= "second" then
      self.pass = "second"
      self.threshold = param("tolerance")
    else
      self.pass = "emergency"
      self.background.stretch:___add(param("emergencyStretch"))
      self.finalpass = true
    end
  end
  -- Not doing 1638
  return self:postLineBreak()
end

function lineBreak:postLineBreak() -- 903
  local p = self.bestBet
  local breaks = {}
  local line  = 1

  local nbLines = 0
  local p2 = p
  repeat
    nbLines = nbLines + 1
    p2 = p2.prevBreak
  until not p2

  repeat
    local left, _, right
    -- SILE handles the actual line width differently than TeX,
    -- so below always return a width of self.hsize. Would they
    -- be needed at some point, the exact width are commented out
    -- below.
    if self.parShaping then
      left, _, right = self:parShapeCache(nbLines + 1 - line)
    else
      if self.hangAfter == 0 then
        -- width = self.hsize
        left = 0
        right = 0
      else
        local indent
        if self.hangAfter > 0 then
          -- width = line > nbLines - self.hangAfter and self.firstWidth or self.secondWidth
          indent = line > nbLines - self.hangAfter and 0 or self.hangIndent
        else
          -- width = line > nbLines + self.hangAfter and self.firstWidth or self.secondWidth
          indent = line > nbLines + self.hangAfter and self.hangIndent or 0
        end
        if indent > 0 then
          left = indent
          right = 0
        else
          left = 0
          right = -indent
        end
      end
    end

    table.insert(breaks, 1,  {
        position = p.curBreak,
        width = self.hsize,
        left = left,
        right = right
      })
    if p.alternates then
      for i = 1, #p.alternates do
        p.alternates[i].selected = p.altSelections[i]
        p.alternates[i].width = p.alternates[i].options[p.altSelections[i]].width
      end
    end
    p = p.prevBreak
    line = line + 1
  until not p
  self:parShapeCacheClear()
  return breaks
end

function lineBreak:dumpActiveRing()
  local p = self.activeListHead
  io.stderr:write("\n")
  repeat
    if p == self.r then io.stderr:write("-> ") else io.stderr:write("   ") end
    SU.debug("break", lineBreak:describeBreakNode(p))
    p = p.next
  until p == self.activeListHead
end

return lineBreak
