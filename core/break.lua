-- Skeletons for nodes:
-- activeNode = { next = nil, breakNode = nil, 
--  lineNumber = 0, fitness = nil, 
--  type = nil, -- "hyphenated", "unhyphenated", "delta" (Delta nodes have a length entry)
--  totalDemerits = nil }
-- passiveNode = { prev = nil, curBreak = nil, prevBreak = nil, serial = 0 }

inspect = require("inspect")
local passSerial = 0
local awful_bad = 1073741823
local inf_bad = 10000
local ejectPenalty = -inf_bad
lineBreak = {}

function lineBreak:init(params)
  self:trimGlue() -- 842
  self.active = { type = "hyphenated", lineNumber = awful_bad, subtype = 0 } -- 846
  -- 849
  self.activeWidth = SILE.length.new()
  self.curActiveWidth = SILE.length.new()
  self.background = SILE.length.new()
  self.breakWidth = SILE.length.new() 
  -- 853
  self.q = params.rightSkip or 0
  self.r = params.leftSkip or 0
  self.background = self.background + self.q + self.r   
  -- 860
  self.minimalDemerits = { tight = awful_bad, decent = awful_bad, loose = awful_bad, veryLoose = awful_bad }
  self.minimumDemerits = awful_bad
  self.best_place = {}
  self.best_pl_line = {}
  self:setupLineLengths(params)
end

function lineBreak:trimGlue() -- 842
  nodes = self.nodes
  if nodes[#nodes]:isGlue() then
    nodes[#nodes] = SILE.nodefactory.newPenalty({penalty = inf_bad})
  else
    nodes[#nodes+1] = SILE.nodefactory.newPenalty({penalty = inf_bad})
  end 
  -- XXX Add parskipfill glue here  
end

function lineBreak:setupLineLengths(params) -- 874
  self.parShape = params.parShape
  if not self.parShape then
    if not params.hangIndent then
      self.lastSpecialLine = 0
      self.secondWidth = params.hsize or SU.error("No hsize")
    else
      self.node875() -- XXX
    end
  else
    self.lastSpecialLine = #params.parShape
    self.secondWidth = SU.error("Oops")
  end
  if params.looseness == 0 then self.easy_line = self.lastSpecialLine else self.easy_line = awful_bad end
  -- self.easy_line = awful_bad

end

function lineBreak:tryBreak(pi, breakType) -- 855
  SU.debug("break", "Trying a "..breakType.." break p="..pi)
  self.no_break_yet = true -- We have to store all this state crap in the object, or it's global variables all the way
  self.prev_prev_r = nil
  self.prev_r = self.active
  self.old_l = 0
  self.r = nil
  self.curActiveWidth = std.tree.clone(self.activeWidth)
  while true do
    while true do -- allows "break" to function as "continue"
      self.r = self.prev_r.next
      SU.debug("break","We have moved the link  forward, ln is now "..(self.r.type == "delta" and "XX" or self.r.lineNumber))

      if self.r.type == "delta" then -- 858
        SU.debug("break", " Adding delta node width of ".. tostring(self.r.width))

        self.curActiveWidth = self.curActiveWidth + self.r.width
        self.prev_prev_r = self.prev_r
        self.prev_r = self.r
        break
      end

      -- 861
      if self.r.lineNumber > self.old_l then
        SU.debug("break","Mimimum demerits = " .. self.minimumDemerits)
        if self.minimumDemerits < awful_bad and (not (self.old_l == self.easy_line) or self.r == self.active) then
          self:createNewActiveNodes(breakType)          
        end
        if self.r == self.active then
          SU.debug("break", "<- tryBreak") 
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
        SU.debug("break", "line width = "..self.lineWidth)
      end 
      SU.debug("break", " ---> (2) cuaw is ".. self.curActiveWidth.length)
      SU.debug("break", " ---> aw is ".. self.activeWidth.length)
      local continuing = self:considerDemerits(pi, breakType)
      SU.debug("break", " <--- cuaw is ".. self.curActiveWidth.length)
      SU.debug("break", " <--- aw is ".. self.activeWidth.length)
    end
  end
  
end

function lineBreak:considerDemerits(pi, breakType) -- 877
  self.artificialDemerits = false
  local nodeStaysActive = false
  local shortfall = self.lineWidth - self.curActiveWidth.length
  SU.debug("break", "Considering demerits, shortfall is "..shortfall)
  if shortfall > 0 then

    -- 878
    -- We do not currently deal with infinities, so we don't implement the "quick" side of this
    if shortfall > 110 and self.curActiveWidth.stretch < 25 then -- Blame Knuth for the magic numbers
      self.b = inf_bad; self.fitClass = "veryLoose";
    else self.b = lineBreak:badness(shortfall, self.curActiveWidth.stretch) end
    if self.b > 12 then 
      if self.b > 99 then self.fitClass = "veryLoose" else self.fitClass = "loose" end
    else self.fitClass = "decent" 
    end
  else
    if -shortfall > self.curActiveWidth.shrink then self.b = inf_bad + 1
      else self.b = lineBreak:badness(-shortfall, self.curActiveWidth.shrink) end
    if self.b > 12 then self.fitClass = "tight" else self.fitClass = "decent" end
  end
  SU.debug("break", self.b .. " " .. self.fitClass)
  if (self.b > inf_bad or pi == ejectPenalty) then
    if self.finalpass and self.minimumDemerits == awful_bad and self.r.next == self.active and self.prev_r == self.active then
      self.artificialDemerits = true
    else
      if self.b > self.threshold then 
        self:deactivateR()
        return false
      end
      self.nodeStaysActive = false
    end
  else
    self.prev_r = self.r
    if self.b > self.threshold then return true end
    nodeStaysActive = true
  end

  self.lastRatio = shortfall > 0 and shortfall/(self.curActiveWidth.stretch or awful_bad) or shortfall/(self.curActiveWidth.shrink or awful_bad)
  self:recordFeasible(pi, breakType)
  if nodeStaysActive then return true end
  self:deactivateR()
  return false
end

function lineBreak:badness(t,s)
  local bad = 100 * (t/s)^3
  bad = math.floor(bad) -- TeX uses integer math for this stuff, so for compatibility...

  if bad > inf_bad then return inf_bad else return bad end
end

function lineBreak:deactivateR() -- 886
  SU.debug("break"," Deactivating r ("..self.r.type..")")
  self.prev_r.next = self.r.next
  if self.prev_r == self.active then
    -- 887
    self.r = self.active.next
    if self.r.type == "delta" then
      self.activeWidth = self.activeWidth + self.r.width
      self.curActiveWidth = std.tree.clone(self.activeWidth)
      self.active.next = self.r.next
    end
    SU.debug("break","  Deactivate, branch 1");
  else
    if self.prev_r.type == "delta" then
      self.r = self.prev_r.next
      if self.r == self.active then
        self.curActiveWidth = self.curActiveWidth - self.r.width
        self.prev_prev_r.next = self.active
        self.prev_r = self.prev_prev_r
      elseif self.r.type == "delta" then
        self.curActiveWidth = self.curActiveWidth + self.r.width
        self.prev_r.width = self.prev_r.width + self.r.width
        self.prev_r.next = self.r.next
      end
    end
    SU.debug("break","  Deactivate, branch 2");
  end
end

function lineBreak:recordFeasible(pi, breakType) -- 881
  local d
  if self.artificialDemerits then d = 0
  else
    d = self.params.linePenalty + self.b
    if math.abs(d) >= 10000 then d = 100000000 else d = d * d end
    if not(pi == 0) then 
      if pi > 0 then d = d + pi * pi elseif pi > ejectPenalty then d = d - pi * pi end
    end
    if breakType == "hyphenated" and self.r.type == "hyphenated" then
      if self.nodes[self.cur_p] then d = d + self.params.doubleHyphenDemerits else d = d + self.params.finalHyphenDemerits end
    end
    -- XXX adjDemerits not added here
  end
  if self.nodes[self.cur_p] then
    SU.debug("break", "@" .. self.nodes[self.cur_p] .. " via @@" .. (self.r.breakNode and self.r.breakNode.serial or "0")  .. " b=" .. self.b .. " d=".. d) -- 882
  else
    SU.debug("break", "@ \\par via @@");
  end
  SU.debug("break"," fit class = "..self.fitClass);
  d = d + self.r.totalDemerits
  if d < self.minimalDemerits[self.fitClass] then
    self.minimalDemerits[self.fitClass] = d
    self.best_place[self.fitClass] = self.r.breakNode
    self.best_pl_line[self.fitClass] = self.r.lineNumber
    -- XXX do last line fit
    if d < self.minimumDemerits then self.minimumDemerits = d end
  end
end

function lineBreak:computeDiscBreakWidth() -- 866
  local rep = self.nodes[self.cur_p].replacement
  for _,n in pairs(rep) do self.breakWidth = self.breakWidth - n.width end
  local s = self.nodes[self.cur_p].postbreak
  for _,n in pairs(s) do self.breakWidth = self.breakWidth + n.width end
  self.breakWidth = self.breakWidth + self.discWidth
end


function lineBreak:createNewActiveNodes(breakType) -- 862
  if self.no_break_yet then
    -- 863
    self.no_break_yet = false
    self.breakWidth = std.tree.clone(self.background)
    local s = self.cur_p
    if breakType == "hyphenated" and self.nodes[self.cur_p] then self:computeDiscBreakWidth() end
    while self.nodes[s] and not self.nodes[s]:isBox() do
      if self.nodes[s].width then -- We use the fact that (a) nodes know if they have width and (b) width subtraction is polymorphic
        self.breakWidth = self.breakWidth - self.nodes[s].width
      end
      s = s + 1
    end
    SU.debug("break", "Value of breakWidth = " .. tostring(self.breakWidth))
  end
  -- 869 (Add a new delta node)
  if self.prev_r.type == "delta" then self.prev_r.width = self.prev_r.width - self.curActiveWidth + self.breakWidth
  elseif self.prev_r == self.active then self.activeWidth = std.tree.clone(self.breakWidth)
  else
    local newDelta = { next = self.r, type = "delta", width = self.breakWidth - self.curActiveWidth}
    SU.debug("break", "Added new delta node = " .. tostring(newDelta.width))
    self.prev_r.next = newDelta
    self.prev_prev_r = self.prev_r
    self.prev_r = newDelta
  end
  if (math.abs(self.adjdemerits) >= awful_bad - self.minimumDemerits) then self.minimumDemerits = awful_bad - 1
  else self.minimumDemerits = self.minimumDemerits + math.abs(self.adjdemerits)
  end

  for class, value in pairs(self.minimalDemerits) do
    SU.debug("break","Class is "..class.." Best value here is " .. value)

    if value <= self.minimumDemerits then
      -- 871: this is what creates new active notes
      passSerial = passSerial + 1

      local newPassive = { prev = self.passive, curBreak = self.cur_p, prevBreak = self.best_place[class], serial = passSerial, ratio = self.lastRatio }
      self.passive = newPassive

      local newActive = { next = self.r, breakNode = newPassive, lineNumber = self.best_pl_line[class] + 1, type = breakType, fitness = class, totalDemerits = value }
      -- DoLastLineFit? 1636 XXX
      self.prev_r.next = newActive
      self.prev_r = newActive
      self:dumpBreakNode(newActive)

    end
    self.minimalDemerits[class] = awful_bad
  end

  self.minimumDemerits = awful_bad
  -- 870
  if not (self.r == self.active) then
    local newDelta = { next = self.r, type = "delta", width = self.curActiveWidth - self.breakWidth }
    self.prev_r.next = newDelta
    self.prev_prev_r = self.prev_r
    self.prev_r = newDelta    
  end  
end

function lineBreak:dumpBreakNode(b)
  if not SU.debugging("break") then return end
  print("@@" .. b.breakNode.serial .. ": line " .. (b.lineNumber -1) .. "." .. b.fitness .. " " .. b.type .. " t=".. b.totalDemerits .. " -> @@ " .. (b.breakNode.prevBreak and b.breakNode.prevBreak.serial or "0") )
end

function lineBreak:checkForLegalBreak(n) -- 892
  SU.debug("break", "considering node "..n);
  if n:isBox() then
    self.activeWidth = self.activeWidth + n.width
  elseif n:isGlue() then
    -- 894
    if self.auto_breaking then
      if self.nodes[self.prev_p] and (self.nodes[self.prev_p]:isBox()) then
        --self.nodes[self.prev_p]:precedesBreak() or 
        --self.nodes[self.prev_p]:isKern()) then
        self:tryBreak(0, "unhyphenated")
      end
      self.activeWidth = self.activeWidth + n.width -- Length version
    end
  elseif n:isDiscretionary() then
    -- 895  XXX
    self.discWidth = 0
    if not n.prebreak then 
      tryBreak(self.params.hyphenPenalty, "hyphenated")
    else
      self.discWidth = n:prebreakWidth()
      self.activeWidth = self.activeWidth + self.discWidth
      self:tryBreak(self.params.hyphenPenalty, "hyphenated")
      self.activeWidth = self.activeWidth - self.discWidth
    end
  elseif n:isPenalty() then
    self:tryBreak(n.penalty, "unhyphenated")
  end
  self:updatePrevP()
  self.cur_p = self.cur_p + 1
end

function lineBreak:updatePrevP()
  self.prev_p = self.cur_p
  global_prev_p = self.cur_p
end

function lineBreak:tryFinalBreak()      -- 899
  self:tryBreak(ejectPenalty, "hyphenated")
  if not(self.active.next == self.active) then
    self.r = self.active.next
    self.fewestDemerits = awful_bad
    repeat
      if not(self.r.type == "delta") then
        if (self.r.totalDemerits < self.fewestDemerits) then
          self.bestBet = self.r
        end
      end
      self.r = self.r.next
    until self.r == self.active
    self.bestLine = self.bestBet.lineNumber
    if self.params.looseness == 0 then return "done" end
    -- XXX 901
    if (self.actualLooseness == self.params.looseness) or self.finalpass then return "done" end
  end
end

function lineBreak:doBreak (params)
  self.nodes = params.nodes
  self.auto_breaking = 1
  if not params.pretolerance then params.pretolerance = 0 end
  if not params.tolerance then params.tolerance = 1000 end
  if not params.emergencyStretch then params.emergencyStretch = 0 end
  if not params.prevGraf then params.prevGraf = 0 end
  if not params.linePenalty then params.linePenalty = 10 end
  if not params.looseness then params.looseness = 0 end
  if not params.hyphenPenalty then params.hyphenPenalty = 50 end
  if not params.doubleHyphenDemerits then params.doubleHyphenDemerits = awful_bad end
  self.params = params
  self:init(params)
  if params.adjdemerits then self.adjdemerits = params.adjdemerits else self.adjdemerits = 10000 end
  self.threshold = params.pretolerance
  if self.threshold >= 0 then 
    self.pass = "first"
    self.finalpass = false
  else
    self.threshold = params.tolerance
    self.pass = "second"
    self.finalpass = (params.emergencyStretch <= 0)
  end
  -- 889
  while 1 do
    SU.debug("break", "@" .. self.pass .. "pass")
    if self.threshold > inf_bad then self.threshold = inf_bad end
    if self.pass == "second" then 
      self.nodes = SILE.hyphenate(self.nodes) 
    end
    -- 890
    self.active.next = { type = "unhyphenated", fitness = "decent", next = self.active, breakNode = nil, lineNumber = params.prevGraf + 1, totalDemerits = 0}

    if params.doLastLineFit then
      --1630
    end
    self.activeWidth = std.tree.clone(self.background)
    self.passive = nil

    self.cur_p = 1
    self.auto_breaking = true
    self:updatePrevP()
    self.first_p = self.cur_p
    while self.nodes[self.cur_p] and not (self.active.next == self.active) do
      self:checkForLegalBreak(self.nodes[self.cur_p])
    end
    if not self.nodes[self.cur_p] then
      if self:tryFinalBreak() == "done" then break end
    end
    -- (Not doing 891)
    if not (self.pass == "second") then
      self.pass = "second"
      self.threshold = params.tolerance
    else
      self.pass = "emergency"
      self.background.stretch = self.background.stretch + params.emergencyStretch
      self.finalpass = true
    end    
  end
  if params.doLastLineFit then 
    -- 1638
  end
  return self:postLineBreak()
end

function lineBreak:postLineBreak() -- 903
  local p = self.bestBet.breakNode
  local breaks = {}
  local line  = 1
  repeat
    table.insert(breaks, 1,  { position = p.curBreak, width = self.parShape and self.parShape[line] or self.params.hsize } )
    p = p.prevBreak
    line = line + 1
  until not p
  return breaks
end

return lineBreak