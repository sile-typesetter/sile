
SILE.settings.declare({ name="linebreak.parShape", type = "string or nil", default = nil}) -- unimplemented
SILE.settings.declare({ name="linebreak.tolerance", type = "integer or nil", default = 500})
SILE.settings.declare({ name="linebreak.pretolerance", type = "integer or nil", default = 100})
SILE.settings.declare({ name="linebreak.hangIndent", type = "nil", default = nil}) -- unimplemented
SILE.settings.declare({ name="linebreak.adjdemerits", type = "integer", default = 10000,
  help = "Additional demerits which are accumulated in the course of paragraph building when two consecutive lines are visually incompatible. In these cases, one line is built with much space for justification, and the other one with little space."})
SILE.settings.declare({ name="linebreak.looseness", type = "integer", default = 0})
SILE.settings.declare({ name="linebreak.prevGraf", type = "integer", default = 0})
SILE.settings.declare({ name="linebreak.emergencyStretch", type = "Length or nil", default = SILE.length.new()})
SILE.settings.declare({ name="linebreak.doLastLineFit", type = "boolean", default = false}) -- unimplemented
SILE.settings.declare({ name="linebreak.linePenalty", type = "integer", default = 10})
SILE.settings.declare({ name="linebreak.hyphenPenalty", type = "integer", default = 50})
SILE.settings.declare({ name="linebreak.doubleHyphenDemerits", type = "integer", default = 10000})
SILE.settings.declare({ name="linebreak.finalHyphenDemerits", type = "integer", default = 5000})

-- doubleHyphenDemerits
-- hyphenPenalty

local classes = {"tight"; "decent"; "loose"; "veryLoose"}
local passSerial = 0
local awful_bad = 1073741823
local inf_bad = 10000
local ejectPenalty = -inf_bad
lineBreak = {}

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

local param = function(x) return SILE.settings.get("linebreak."..x) end

-- Routines here will be called thousands of times; we micro-optimize
-- to avoid debugging and concat calls.
local debugging = false

function lineBreak:init()
  self:trimGlue() -- 842
  -- 849
  self.activeWidth = SILE.length.new()
  self.curActiveWidth = SILE.length.new()
  self.breakWidth = SILE.length.new()
  -- 853
  local rskip = SILE.settings.get("document.rskip")
  if type(rskip) == "table" then rskip = rskip.width else rskip = 0 end
  local lskip = SILE.settings.get("document.lskip")
  if type(lskip) == "table" then lskip = lskip.width else lskip = 0 end
  self.background = SILE.length.new() + rskip + lskip
  -- 860
  self.bestInClass = {}
  for i = 1,#classes do
    self.bestInClass[classes[i]] = {
      minimalDemerits = awful_bad
    }
  end
  self.minimumDemerits = awful_bad
  self.best_place = {}
  self.best_pl_line = {}
  self:setupLineLengths(params)
end

function lineBreak:trimGlue() -- 842
  local nodes = self.nodes
  if nodes[#nodes]:isGlue() then nodes[#nodes] = nil end
  nodes[#nodes+1] = SILE.nodefactory.newPenalty({penalty = inf_bad})
end

function lineBreak:setupLineLengths(params) -- 874
  self.parShape = param("parShape")
  if not self.parShape then
    if not param("hangIndent") then
      self.lastSpecialLine = 0
      self.secondWidth = self.hsize or SU.error("No hsize")
    else
      self.node875() -- XXX
    end
  else
    self.lastSpecialLine = #param("parShape")
    self.secondWidth = SU.error("Oops")
  end
  if param("looseness") == 0 then self.easy_line = self.lastSpecialLine else self.easy_line = awful_bad end
  -- self.easy_line = awful_bad

end

function lineBreak:tryBreak() -- 855
  local pi,breakType
 
  local n = self.nodes[self.cur_p]
  if not n then pi = ejectPenalty; breakType = "hyphenated"
  elseif n:isDiscretionary() then breakType = "hyphenated"; pi = param("hyphenPenalty")
  else breakType = "unhyphenated"; pi = n.penalty or 0 end

  if debugging then SU.debug("break", "Trying a "..breakType.." break p="..pi) end
  self.no_break_yet = true -- We have to store all this state crap in the object, or it's global variables all the way
  self.prev_prev_r = nil
  self.prev_r = self.activeListHead
  self.old_l = 0
  self.r = nil
  self.curActiveWidth = std.tree.clone(self.activeWidth)

  while true do
    while true do -- allows "break" to function as "continue"
      self.r = self.prev_r.next
      if debugging then SU.debug("break","We have moved the link  forward, ln is now "..(self.r.type == "delta" and "XX" or self.r.lineNumber)) end

      if self.r.type == "delta" then -- 858
        if debugging then SU.debug("break", " Adding delta node width of ".. tostring(self.r.width)) end

        self.curActiveWidth = self.curActiveWidth + self.r.width
        self.prev_prev_r = self.prev_r
        self.prev_r = self.r
        break
      end

      -- 861
      if self.r.lineNumber > self.old_l then
        if debugging then SU.debug("break","Mimimum demerits = " .. self.minimumDemerits) end
        if self.minimumDemerits < awful_bad and (self.old_l ~= self.easy_line or self.r == self.activeListHead) then
          self:createNewActiveNodes(breakType)
        end
        if self.r == self.activeListHead then
          if debugging then SU.debug("break", "<- tryBreak") end
          return
        end
        -- 876
        if self.r.lineNumber > self.easy_line then
          self.lineWidth = self.secondWidth
          self.old_l = awful_bad -1
        else
          self.old_l = self.r.lineNumber
          if self.r.lineNumber > self.lastSpecialLine then self.lineWidth = self.secondWidth
          elseif not self.parShape then self.lineWidth = self.firstWidth else self.lineWidth = self.parShape[self.r.lineNumber]
          end
        end
        if debugging then SU.debug("break", "line width = "..self.lineWidth) end
      end
      if debugging then
        SU.debug("break", " ---> (2) cuaw is ".. self.curActiveWidth.length)
        SU.debug("break", " ---> aw is ".. self.activeWidth.length)
      end
      self:considerDemerits(pi, breakType)
      if debugging then
        SU.debug("break", " <--- cuaw is ".. self.curActiveWidth.length)
        SU.debug("break", " <--- aw is ".. self.activeWidth.length)
      end
    end
  end
 
end

local function fitclass(self, s) -- s =shortfall
  local badness, class
  local stretch = self.curActiveWidth.stretch
  local shrink = self.curActiveWidth.shrink
  if s > 0 then
    if s > 110 and stretch < 25 then
      badness = inf_bad
    else
      badness = lineBreak:badness(s, stretch)
    end
    if     badness > 99 then class = "veryLoose"
    elseif badness > 12 then class = "loose"
    else                     class = "decent"
    end
  else
    s = -s
    if s > shrink then
      badness = inf_bad + 1
    else
      badness = lineBreak:badness(s, shrink)
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
    if self.nodes[i] and self.nodes[i]:isAlternative() then
      alternates[#alternates+1] = self.nodes[i]
      altSizes[#altSizes+1] = #(self.nodes[i].options)
    end
  end
  if #alternates == 0 then return end
  local localMinimum = awful_bad
  local selectedShortfall = 0
  local shortfall = self.lineWidth - self.curActiveWidth.length
  if debugging then SU.debug("break", "Shortfall was ", shortfall) end
  for combination in SU.allCombinations(altSizes) do
    local addWidth = 0
    for i = 1,#(alternates) do local alt = alternates[i]
      addWidth = (addWidth + alt.options[combination[i]].width - alt:minWidth()).length
      if debugging then SU.debug("break", alt.options[combination[i]], " width", addWidth) end
    end
    local ss = shortfall - addWidth
    local b = ss > 0 and lineBreak:badness(ss, self.curActiveWidth.stretch) or lineBreak:badness(math.abs(ss), self.curActiveWidth.shrink)
    if debugging then SU.debug("break", "  badness of "..ss.." ("..self.curActiveWidth.stretch..") is ".. b) end
    if b < localMinimum then
      self.r.alternates = alternates
      self.r.altSelections = combination
      selectedShortfall = addWidth
      localMinimum = b
    end
  end
  if debugging then SU.debug("break", "Choosing ", alternates[1].options[self.r.altSelections[1]]) end
  -- self.curActiveWidth = self.curActiveWidth + selectedShortfall
  shortfall = self.lineWidth - self.curActiveWidth.length
  if debugging then SU.debug("break", "Is now ", shortfall) end
end

function lineBreak:considerDemerits(pi, breakType) -- 877
  self.artificialDemerits = false
  local nodeStaysActive = false
  -- self:dumpActiveRing()
  local shortfall = self.lineWidth - self.curActiveWidth.length
  if self.seenAlternatives then
    self:tryAlternatives(self.r.prevBreak and self.r.prevBreak.curBreak or 1, self.r.curBreak and self.r.curBreak or 1, shortfall)
  end
  shortfall = self.lineWidth - self.curActiveWidth.length
  self.b, self.fitClass = fitclass(self, shortfall)
  if debugging then SU.debug("break", self.b .. " " .. self.fitClass) end
  if (self.b > inf_bad or pi == ejectPenalty) then
    if self.finalpass and self.minimumDemerits == awful_bad and self.r.next == self.activeListHead and self.prev_r == self.activeListHead then
      self.artificialDemerits = true
    else
      if self.b > self.threshold then
        self:deactivateR()
        return
      end
    end
  else
    self.prev_r = self.r
    if self.b > self.threshold then return end
    nodeStaysActive = true
  end

  self.lastRatio = shortfall > 0 and shortfall/(self.curActiveWidth.stretch or awful_bad) or shortfall/(self.curActiveWidth.shrink or awful_bad)
  self:recordFeasible(pi, breakType)
  if not nodeStaysActive then self:deactivateR() end
end

function lineBreak:badness(t,s)
  local bad = 100 * (t/s)^3
  bad = math.floor(bad) -- TeX uses integer math for this stuff, so for compatibility...

  if bad > inf_bad then return inf_bad else return bad end
end

function lineBreak:deactivateR() -- 886
  if debugging then SU.debug("break"," Deactivating r ("..self.r.type..")") end
  self.prev_r.next = self.r.next
  if self.prev_r == self.activeListHead then
    -- 887
    self.r = self.activeListHead.next
    if self.r.type == "delta" then
      self.activeWidth = self.activeWidth + self.r.width
      self.curActiveWidth = std.tree.clone(self.activeWidth)
      self.activeListHead.next = self.r.next
    end
    if debugging then SU.debug("break","  Deactivate, branch 1"); end
  else
    if self.prev_r.type == "delta" then
      self.r = self.prev_r.next
      if self.r == self.activeListHead then
        self.curActiveWidth = self.curActiveWidth - self.r.width
        self.prev_prev_r.next = self.activeListHead
        self.prev_r = self.prev_prev_r
      elseif self.r.type == "delta" then
        self.curActiveWidth = self.curActiveWidth + self.r.width
        self.prev_r.width = self.prev_r.width + self.r.width
        self.prev_r.next = self.r.next
      end
    end
    if debugging then SU.debug("break","  Deactivate, branch 2"); end
  end
end

function lineBreak:computeDemerits(pi, breakType)
  if self.artificialDemerits then return 0 end
  local d = param("linePenalty") + self.b
  if math.abs(d) >= 10000 then d = 100000000 else d = d * d end
  if pi > 0 then d = d + pi * pi
  elseif pi == 0 then -- do nothing
  elseif pi > ejectPenalty then d = d - pi * pi end
  if breakType == "hyphenated" and self.r.type == "hyphenated" then
    if self.nodes[self.cur_p] then
      d = d + param("doubleHyphenDemerits")
    else d = d + param("finalHyphenDemerits") end
  end
  -- XXX adjDemerits not added here
  return d
end

function lineBreak:recordFeasible(pi, breakType) -- 881
  local d = lineBreak:computeDemerits(pi, breakType)
  if debugging then
    if self.nodes[self.cur_p] then
      SU.debug("break", "@" .. self.nodes[self.cur_p] .. " via @@" .. (self.r.serial or "0")  .. " b=" .. self.b .. " d=".. d) -- 882
    else
      SU.debug("break", "@ \\par via @@");
    end
    SU.debug("break"," fit class = "..self.fitClass);
  end
  d = d + self.r.totalDemerits
  if d <= self.bestInClass[self.fitClass].minimalDemerits then
    self.bestInClass[self.fitClass] = {
      minimalDemerits = d,
      node = self.r.serial and self.r,
      line = self.r.lineNumber
    }
    -- XXX do last line fit
    if d < self.minimumDemerits then self.minimumDemerits = d end
  end
end


function lineBreak:createNewActiveNodes(breakType) -- 862
  if self.no_break_yet then
    -- 863
    self.no_break_yet = false
    self.breakWidth = std.tree.clone(self.background)
    local s = self.cur_p
    local n = self.nodes[s]
    if n and n:isDiscretionary() then -- 866
      self.breakWidth = self.breakWidth + n:prebreakWidth() + n:postbreakWidth() - n:replacementWidth()
    end
    while self.nodes[s] and not self.nodes[s]:isBox() do
      if self.sideways and self.nodes[s].height then
        self.breakWidth = self.breakWidth - (self.nodes[s].height + self.nodes[s].depth)
      elseif self.nodes[s].width then -- We use the fact that (a) nodes know if they have width and (b) width subtraction is polymorphic
        self.breakWidth = self.breakWidth - self.nodes[s]:lineContribution()
      end
      s = s + 1
    end
    if debugging then SU.debug("break", "Value of breakWidth = " .. tostring(self.breakWidth)) end
  end
  -- 869 (Add a new delta node)
  if self.prev_r.type == "delta" then self.prev_r.width = self.prev_r.width - self.curActiveWidth + self.breakWidth
  elseif self.prev_r == self.activeListHead then self.activeWidth = std.tree.clone(self.breakWidth)
  else
    local newDelta = { next = self.r, type = "delta", width = self.breakWidth - self.curActiveWidth}
    if debugging then SU.debug("break", "Added new delta node = " .. tostring(newDelta.width)) end
    self.prev_r.next = newDelta
    self.prev_prev_r = self.prev_r
    self.prev_r = newDelta
  end
  if (math.abs(self.adjdemerits) >= awful_bad - self.minimumDemerits) then
    self.minimumDemerits = awful_bad - 1
  else self.minimumDemerits = self.minimumDemerits + math.abs(self.adjdemerits)
  end

  for i = 1,#classes do
    local class = classes[i]
    local best = self.bestInClass[class]
    local value = best.minimalDemerits
    if debugging then SU.debug("break","Class is "..class.." Best value here is " .. value) end

    if value <= self.minimumDemerits then
      -- 871: this is what creates new active notes
      passSerial = passSerial + 1

      local newActive = { next = self.r,
        curBreak = self.cur_p,
        prevBreak = best.node,
        serial = passSerial,
        ratio = self.lastRatio,
        lineNumber = best.line + 1,
        type = breakType,
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

function lineBreak:dumpBreakNode(b)
  if not SU.debugging("break") then return end
  print(lineBreak:describeBreakNode(b))
end

function lineBreak:describeBreakNode(b)
  --print("@@" .. b.serial .. ": line " .. (b.lineNumber -1) .. "." .. b.fitness .. " " .. b.type .. " t=".. b.totalDemerits .. " -> @@ " .. (b.prevBreak and b.prevBreak.serial or "0") )
  if b.sentinel then return b.sentinel end
  if b.type == "delta" then return "delta "..b.width.length.."pt" end
  local before = self.nodes[b.curBreak-1]
  local after = self.nodes[b.curBreak+1]
  local from = b.prevBreak and b.prevBreak.curBreak or 1
  local to = b.curBreak
  return "b "..from.."-"..to.." \""..(before and before:toText()).." | "..(after and after:toText()).."\" [".. b.totalDemerits..", "..b.fitness.."]"
end

function lineBreak:checkForLegalBreak(n) -- 892
  if debugging then SU.debug("break", "considering node "..n); end
  local previous = self.nodes[self.cur_p - 1]
  if n:isAlternative() then self.seenAlternatives = true end
  if self.sideways and n:isBox() then
    self.activeWidth = self.activeWidth + n.height + n.depth
  elseif self.sideways and n:isVglue() then
    if previous and (previous:isBox()) then
      self:tryBreak()
    end
    self.activeWidth = self.activeWidth + n.height + n.depth
  elseif n:isAlternative() then
    self.activeWidth = self.activeWidth + n:minWidth()
  elseif n:isBox() then
    self.activeWidth = self.activeWidth + n:lineContribution()
  elseif n:isGlue() then
    -- 894 (We removed the auto_breaking parameter)
    if previous and previous:isBox() then self:tryBreak() end
    self.activeWidth = self.activeWidth + n.width
  elseif n:isDiscretionary() then -- 895  XXX
    self.activeWidth = self.activeWidth + n:prebreakWidth()
    self:tryBreak()
    self.activeWidth = self.activeWidth - n:prebreakWidth()
    self.activeWidth = self.activeWidth + n:replacementWidth()
  elseif n:isPenalty() then
    self:tryBreak()
  end
end

function lineBreak:tryFinalBreak()      -- 899
  self:tryBreak()
  if self.activeListHead.next == self.activeListHead then return end
  self.r = self.activeListHead.next
  local fewestDemerits = awful_bad
  repeat
    if not(self.r.type == "delta") then
      if (self.r.totalDemerits < fewestDemerits) then
        fewestDemerits = self.r.totalDemerits
        self.bestBet = self.r
      end
    end
    self.r = self.r.next
  until self.r == self.activeListHead
  if param("looseness") == 0 then return "done" end
  -- XXX 901
  if (self.actualLooseness == param("looseness")) or self.finalpass then return "done" end
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
    self.finalpass = (param("emergencyStretch") <= 0)
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
    self.activeListHead = { sentinel="START", type = "hyphenated", lineNumber = awful_bad, subtype = 0 } -- 846
    self.activeListHead.next = { sentinel="END", type = "unhyphenated", fitness = "decent", next = self.activeListHead, lineNumber = param("prevGraf") + 1, totalDemerits = 0}

    -- Not doing 1630
    self.activeWidth = std.tree.clone(self.background)

    self.cur_p = 1
    while self.nodes[self.cur_p] and self.activeListHead.next ~= self.activeListHead do
      self:checkForLegalBreak(self.nodes[self.cur_p])
      self.cur_p = self.cur_p + 1
    end
    if self.cur_p > #(self.nodes) then
      if self:tryFinalBreak() == "done" then break end
    end
    -- (Not doing 891)
    if self.pass ~= "second" then
      self.pass = "second"
      self.threshold = param("tolerance")
    else
      self.pass = "emergency"
      self.background.stretch = self.background.stretch + param("emergencyStretch").length
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
  repeat
    table.insert(breaks, 1,  { position = p.curBreak, width = self.parShape and self.parShape[line] or self.hsize } )
    if p.alternates then
      for i = 1,#p.alternates do
        p.alternates[i].selected = p.altSelections[i]
        p.alternates[i].width = p.alternates[i].options[p.altSelections[i]].width
      end
    end
    p = p.prevBreak
    line = line + 1
  until not p
  return breaks
end

function lineBreak:dumpActiveRing()
  local p = self.activeListHead
  io.write("\n")
  repeat
    if p == self.r then io.write("-> ") else io.write("   ") end
    print(lineBreak:describeBreakNode(p))
    p = p.next
  until p == self.activeListHead
end

return lineBreak