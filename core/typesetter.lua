-- This is the default typesetter. You are, of course, welcome to create your own.
local awful_bad = 1073741823
local inf_bad = 10000
local eject_penalty = -inf_bad
local supereject_penalty = 2 * -inf_bad
local deplorable = 100000

if std.string.monkey_patch then -- stdlib >= 40
  std.string.monkey_patch()
end

SILE.settings.declare({
  name = "typesetter.widowpenalty",
  type = "integer",
  default = 3000,
  help = "Penalty to be applied to widow lines (at the start of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.parseppattern",
  type = "string or integer",
  default = "\r?\n[\r\n]+",
  help = "Lua pattern used to separate paragraphs"
})

SILE.settings.declare({
  name = "typesetter.obeyspaces",
  type = "boolean or nil",
  default = nil,
  help = "Whether to ignore paragraph initial spaces"
})

SILE.settings.declare({
  name = "typesetter.orphanpenalty",
  type = "integer",
  default = 3000,
  help = "Penalty to be applied to orphan lines (at the end of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.parfillskip",
  type = "Glue",
  default = SILE.nodefactory.newGlue("0pt plus 10000pt"),
  help = "Glue added at the end of a paragraph"
})

SILE.settings.declare({
  name = "document.letterspaceglue",
  type = "Glue or nil",
  default = nil,
  help = "Glue added between tokens"
})

SILE.settings.declare({
  name = "typesetter.underfulltolerance",
  type = "Length or nil",
  default = SILE.length.parse("1em"),
  help = "Amount a page can be underfull without warning"
})

SILE.settings.declare({
  name = "typesetter.overfulltolerance",
  type = "Length or nil",
  default = SILE.length.parse("5pt"),
  help = "Amount a page can be overfull without warning"
})

SILE.settings.declare({
  name = "typesetter.breakwidth",
  type = "Length or nil",
  default = nil,
  help = "Width to break lines at"
})

local _margins = std.object {
  __eq = function(self, other)
    return SILE.toAbsoluteMeasurement(self.lskip.width) == SILE.toAbsoluteMeasurement(other.lskip.width)
      and SILE.toAbsoluteMeasurement(self.rskip.width) == SILE.toAbsoluteMeasurement(other.rskip.width)
  end
}

SILE.defaultTypesetter = std.object {
  -- Setup functions
  hooks = {},
  breadcrumbs = SU.breadcrumbs(),
  init = function(self, frame)
    self.stateQueue = {}
    self:initFrame(frame)
    self:initState()
    return self
  end,
  initState = function(self)
    self.state = {
      nodes = {},
      outputQueue = {},
      lastBadness = awful_bad,
    }
  end,
  initFrame = function(self, frame)
    self.frame = frame
    self.frame:init()
  end,
  getMargins = function(self)
    local lskip = SILE.settings.get("document.lskip") or SILE.nodefactory.zeroGlue
    local rskip = SILE.settings.get("document.rskip") or SILE.nodefactory.zeroGlue
    return _margins { lskip=lskip, rskip=rskip }
  end,
  setMargins = function(self, margins)
    SILE.settings.set("document.lskip", margins.lskip)
    SILE.settings.set("document.rskip", margins.rskip)
  end,
  pushState = function(self)
    self.stateQueue[#self.stateQueue+1] = self.state
    self:initState()
  end,
  popState = function(self, ncount)
    local offset = ncount and #self.stateQueue - ncount or nil
    self.state = table.remove(self.stateQueue, offset)
    if not self.state then SU.error("Typesetter state queue empty") end
  end,
  vmode = function(self)
    return #self.state.nodes == 0
  end,

  debugState = function(self)
    print("\n---\nI am in "..(self:vmode() and "vertical" or "horizontal").." mode")
    print("Writing into "..self.frame:toString())
    print("Recent contributions: ")
    for i = 1,#(self.state.nodes) do
      io.stderr:write(self.state.nodes[i].. " ")
    end
    print("\nVertical list: ")
    for i = 1,#(self.state.outputQueue) do
      print("  "..self.state.outputQueue[i])
    end
  end,

  -- Boxy stuff
  pushHorizontal = function (self, node)
    self:initline()
    self.state.nodes[#self.state.nodes+1] = node
    return node
  end,
  pushVertical = function (self, vbox)
    self.state.outputQueue[#self.state.outputQueue+1] = vbox
    return vbox
  end,
  pushHbox = function (self, spec)
    return self:pushHorizontal(SILE.nodefactory.newHbox(spec))
  end,
  pushUnshaped = function (self, spec)
    return self:pushHorizontal(SILE.nodefactory.newUnshaped(spec))
  end,
  pushGlue = function (self, spec)
    return self:pushHorizontal(SILE.nodefactory.newGlue(spec))
  end,
  pushExplicitGlue = function (self, spec)
    spec.explicit = true
    spec.discardable = false
    return self:pushHorizontal(SILE.nodefactory.newGlue(spec))
  end,
  pushPenalty = function (self, spec)
    return self:pushHorizontal(SILE.nodefactory.newPenalty(spec))
  end,
  pushMigratingMaterial = function (self, material)
    return self:pushHorizontal(SILE.nodefactory.newMigrating({ material = material }))
  end,
  pushVbox = function (self, spec)
    return self:pushVertical(SILE.nodefactory.newVbox(spec))
  end,
  pushVglue = function (self, spec)
    return self:pushVertical(SILE.nodefactory.newVglue(spec))
  end,
  pushExplicitVglue = function (self, spec)
    spec.explicit = true
    spec.discardable = false
    return self:pushVglue(spec)
  end,
  pushVpenalty = function (self, spec)
    return self:pushVertical(SILE.nodefactory.newPenalty(spec))
  end,

  -- Actual typesetting functions
  typeset = function (self, text)
    if text:match("^%\r?\n$") then return end
    for t in SU.gtoke(text,SILE.settings.get("typesetter.parseppattern")) do
      if (t.separator) then
        self:endline()
      else
        self:setpar(t.string)
      end
    end
  end,

  initline = function (self)
    if (#self.state.nodes == 0) then
      self.state.nodes[#self.state.nodes+1] = SILE.nodefactory.zeroHbox
      SILE.documentState.documentClass.newPar(self)
    end
  end,
  endline = function (self)
    self:leaveHmode()
    SILE.documentState.documentClass.endPar(self)
  end,

  -- Takes string, writes onto self.state.nodes
  setpar = function (self, t)
    t = string.gsub(t,"\r?\n", " ")
    if (#self.state.nodes == 0) then
      if not SILE.settings.get("typesetter.obeyspaces") then
        t = string.gsub(t,"^%s+", "")
      end
      self:initline()
    end
    if #t >0 then
      self:pushUnshaped({ text = t, options= SILE.font.loadDefaults({})})
    end
  end,
  breakIntoLines = function (self, nl, breakWidth)
    self:shapeAllNodes(nl)
    local breaks = SILE.linebreak:doBreak( nl, breakWidth)
    return self:breakpointsToLines(breaks)
  end,
  shapeAllNodes = function(self, nl)
    local newNl = {}
    for i = 1,#nl do
      if nl[i]:isUnshaped() then
        table.append(newNl, nl[i]:shape())
      else
        newNl[#newNl+1] = nl[i]
      end
    end
    for i =1,#newNl do nl[i]=newNl[i] end
    if #nl > #newNl then
      for i=#newNl+1,#nl do nl[i]=nil end
    end
  end,
  -- Empties self.state.nodes, breaks into lines, puts lines into vbox, adds vbox to
  -- Turns a node list into a list of vboxes
  boxUpNodes = function (self)
    local nl = self.state.nodes
    if #nl == 0 then return {} end
    for j=#nl,1,-1 do
      if nl[j]:isMigrating() then
        -- pass
      elseif nl[j].discardable then
        table.remove(nl,j)
      else
        break
      end
    end
    while (#nl >0 and nl[1]:isPenalty()) do table.remove(nl,1) end
    if #nl == 0 then return {} end
    self:shapeAllNodes(nl)
    self:pushGlue(SILE.settings.get("typesetter.parfillskip"))
    self:pushPenalty({ flagged= 1, penalty= -inf_bad })
    SU.debug("typesetter", "Boxed up "..(#nl > 500 and (#nl).." nodes" or SU.contentToString(nl)))
    local breakWidth = SILE.settings.get("typesetter.breakwidth") or self.frame:lineWidth()
    if (type(breakWidth) == "table") then breakWidth = breakWidth.length end
    local lines = self:breakIntoLines(nl, breakWidth)
    local vboxes = {}
    for index=1, #lines do
      local l = lines[index]
      local migrating = {}
      -- Move any migrating material
      local nodes = {}
      for i =1, #l.nodes do local n = l.nodes[i]
        if n:isMigrating() then
          for j=1,#n.material do migrating[#migrating+1] = n.material[j] end
        else
          nodes[#nodes+1] = n
        end
      end
      local vbox = SILE.nodefactory.newVbox({ nodes = nodes, ratio = l.ratio })
      local pageBreakPenalty = 0
      if (#lines > 1 and index == 1) then
        pageBreakPenalty = SILE.settings.get("typesetter.widowpenalty")
      elseif (#lines > 1 and index == (#lines-1)) then
        pageBreakPenalty = SILE.settings.get("typesetter.orphanpenalty")
      end
      vboxes[#vboxes+1] = self:leadingFor(vbox, self.state.previousVbox)
      vboxes[#vboxes+1] = vbox
      for i=1,#migrating do vboxes[#vboxes+1] = migrating[i] end
      self.state.previousVbox = vbox
      if pageBreakPenalty > 0 then
        SU.debug("typesetter", "adding penalty of "..pageBreakPenalty.." after "..vbox)
        vboxes[#vboxes+1] = SILE.nodefactory.newPenalty({ penalty = pageBreakPenalty})
      end
    end
    return vboxes
  end,

  pageTarget = function(self)
    return self.frame:pageTarget()
  end,
  registerHook = function (self, category, f)
    if not self.hooks[category] then self.hooks[category] = {} end
    self.hooks[category][1+#(self.hooks[category])] = f
  end,
  runHooks = function(self, category, data)
    if not self.hooks[category] then return data end
    for i = 1,#self.hooks[category] do
      data = self.hooks[category][i](self, data)
    end
    return data
  end,
  registerFrameBreakHook = function (self, f)
    self:registerHook("framebreak", f)
  end,
  registerNewFrameHook = function (self, f)
    self:registerHook("newframe", f)
  end,
  registerPageEndHook = function (self, f)
    self:registerHook("pageend", f)
  end,
  pageBuilder = function (self)
    local vbox
    local pageNodeList
    local res
    if #(self.state.outputQueue) == 0 then return end
    if SILE.scratch.insertions then SILE.scratch.insertions.thisPage = {} end

    pageNodeList, res = SILE.pagebuilder.findBestBreak({
      vboxlist = self.state.outputQueue,
      target   = self:pageTarget(),
      restart  = self.frame.state.pageRestart
    })

    if not pageNodeList then -- No break yet
      -- self.frame.state.pageRestart = res
      self:runHooks("noframebreak")
      return false
    end
    self.state.lastPenalty = res
    self.frame.state.pageRestart = nil
    pageNodeList = self:runHooks("framebreak",pageNodeList)
    self:setVerticalGlue(pageNodeList, self:pageTarget())
    self:outputLinesToPage(pageNodeList)
    return true
  end,

  setVerticalGlue = function (self, pageNodeList, target)
    -- Do some sums on that list
    local glues = {}
    local gTotal = SILE.length.new()
    local totalHeight = SILE.length.new()

    for i=1,#pageNodeList do
      totalHeight = totalHeight + pageNodeList[i].height + pageNodeList[i].depth
      if pageNodeList[i]:isVglue() then
        table.insert(glues,pageNodeList[i])
        gTotal = gTotal + pageNodeList[i].height
      end
    end

    local adjustment = (target - totalHeight).length

    if adjustment > 0 then
      if adjustment > gTotal.stretch then
        if (adjustment - gTotal.stretch) > SILE.settings.get("typesetter.underfulltolerance"):absolute().length then
          SU.warn("Underfull frame: ".. adjustment .. " extra space required but "..gTotal.stretch.. " stretchiness available")
        end
        adjustment = gTotal.stretch
      end
      if gTotal.stretch > 0 then
        for i = 1,#glues do local g= glues[i]
          g:setGlue(adjustment * g.height:absolute().stretch / gTotal.stretch)
        end
      end
    elseif adjustment < 0 then
      adjustment = 0 - adjustment
      if adjustment > gTotal.shrink then
        if (adjustment - gTotal.shrink) > SILE.settings.get("typesetter.overfulltolerance"):absolute().length then
          SU.warn("Overfull frame: ".. adjustment .. " extra space required but "..gTotal.shrink.. " shrink available")
        end
        adjustment = gTotal.shrink
      end
      if gTotal.shrink > 0 then
        for i = 1,#glues do local g= glues[i]
          g:setGlue(0 - (adjustment * g.height:absolute().shrink / gTotal.shrink))
        end
      end
    end

    SU.debug("pagebuilder", "Glues for self page adjusted by "..(adjustment/gTotal.stretch) )
  end,

  initNextFrame = function(self)
    local oldframe = self.frame
    self.frame:leave()
    if #self.state.outputQueue == 0 then
      self.state.previousVbox = nil
    end
    if (self.frame.next and not (self.state.lastPenalty <= supereject_penalty )) then
      self:initFrame(SILE.getFrame(self.frame.next))
    elseif not self.frame:isMainContentFrame() then
      SU.warn("Overfull content for frame "..self.frame.id)
      self:chuck()
    else
      self:runHooks("pageend")
      SILE.documentState.documentClass:endPage()
      self:initFrame(SILE.documentState.documentClass:newPage())
    end

    if not SU.feq(oldframe:lineWidth(), self.frame:lineWidth()) then
      self:pushBack()
    else
      -- If I have some things on the vertical list already, they need
      -- proper top-of-frame leading applied.
      if #(self.state.outputQueue) > 0 then
        local lead = self:leadingFor(self.state.outputQueue[1],nil)
        if lead then table.insert(self.state.outputQueue,1,lead) end
      end
    end
    self:runHooks("newframe")

  end,

  pushBack = function (self)
    SU.debug("typesetter", "Pushing back "..#(self.state.outputQueue).." nodes")
    local oldqueue = self.state.outputQueue
    self.state.outputQueue = {}
    self.state.previousVbox = nil
    local lastMargins = self:getMargins()
    for _, vbox in ipairs(oldqueue) do
      SU.debug("pushback", { "process box", vbox })
      if vbox.margins and vbox.margins ~= lastMargins then
        SU.debug("pushback", { "new margins", lastMargins, vbox.margins })
        if not self.state.grid then self:endline() end
        self:setMargins(vbox.margins)
      end
      if vbox.explicit then
        SU.debug("pushback", { "explicit", vbox })
        self:endline()
        self:pushExplicitVglue(vbox)
      elseif vbox.type == "insertionVbox" then
        SU.debug("pushback", { "pushBack", "insertion", vbox })
        SILE.typesetter:pushMigratingMaterial({vbox})
      elseif not vbox:isVglue() and not vbox:isPenalty() then
        SU.debug("pushback", { "not vglue or penalty", vbox.type })
        local discardedFistInitLine = false
        if (#self.state.nodes == 0) then
          -- Setup queue but avoid calling newPar
          self.state.nodes[#self.state.nodes+1] = SILE.nodefactory.zeroHbox
        end
        for i, node in ipairs(vbox.nodes) do
          if node:isGlue() and not node.discardable then
            self:pushHorizontal(node)
          elseif node:isGlue() and (node.value == "lskip" or node.value == "rskip") then
            SU.debug("pushback", { "discard", node.value, node })
          elseif node:isDiscretionary() then
            SU.debug("pushback", { "re-mark discretionary as unused", node })
            node.used = false
            if i == 1 then
              SU.debug("pushback", { "keep first discretionary", node })
              self:pushHorizontal(node)
            else
              SU.debug("pushback", { "discard all other discretionaries", node })
            end
          elseif node == SILE.nodefactory.zeroHbox then
            if discardedFistInitLine then self:pushHorizontal(node)
            else SU.debug("que", { "discard zero hbox" }) end
            discardedFistInitLine = true
          elseif node:isPenalty() then
            if not discardedFistInitLine then self:pushHorizontal(node) end
            SU.debug("que", { "discard penalty"  })
          else
            node.bidiDone = true
            self:pushHorizontal(node)
          end
        end
      else
        SU.debug("pushback", { "discard", vbox.type })
      end
      lastMargins = vbox.margins
      -- self:debugState()
    end
    while self.state.nodes[#self.state.nodes]
      and self.state.nodes[#self.state.nodes]:isPenalty()
       or self.state.nodes[#self.state.nodes] == SILE.nodefactory.zeroHbox do
      self.state.nodes[#self.state.nodes] = nil
    end
  end,

  outputLinesToPage = function (self, lines)
    SU.debug("pagebuilder", "OUTPUTTING frame "..self.frame.id)
    local i
    for i = 1,#lines do local l = lines[i]
      -- Annoyingly, explicit glue *should* disappear at the top of a page.
      -- if you don't want that, add an empty vbox or something.
      if not self.frame.state.totals.pastTop and not l.discardable and not l.explicit then
        self.frame.state.totals.pastTop = true
      end
      if self.frame.state.totals.pastTop then
        l:outputYourself(self, l)
      end
    end
  end,
  leaveHmode = function(self, independent)
    SU.debug("typesetter", "Leaving hmode")
    local vboxlist = self:boxUpNodes()
    local margins = self:getMargins()
    self.state.nodes = {}
    -- Push output lines into boxes and ship them to the page builder
    for i = 1, #vboxlist do
      vboxlist[i].margins = margins
      self:pushVertical(vboxlist[i])
    end
    if independent then return end
    if self:pageBuilder() then
      self:initNextFrame()
    end
  end,
  inhibitLeading = function (self)
    self.state.previousVbox = nil
  end,
  leadingFor = function(self, vbox, previous)
    -- Insert leading
    SU.debug("typesetter", "   Considering leading between two lines:")
    SU.debug("typesetter", "   1) "..previous)
    SU.debug("typesetter", "   2) "..vbox)
    if not previous then return SILE.nodefactory.newVglue({height=SILE.length.new({})}) end
    local prevDepth = previous.depth
    SU.debug("typesetter", "   Depth of previous line was "..tostring(prevDepth))
    local bls = SILE.settings.get("document.baselineskip")
    local d = bls.height:absolute() - vbox.height - prevDepth
    d = d.length
    SU.debug("typesetter", "   Leading height = " .. tostring(bls.height) .. " - " .. tostring(vbox.height) .. " - " .. tostring(prevDepth) .. " = "..d)

    if (d > SILE.settings.get("document.lineskip").height:absolute().length) then
      len = SILE.length.new({ length = d, stretch = bls.height.stretch, shrink = bls.height.shrink })
      return SILE.nodefactory.newVglue({height = len})
    else
      local lead = SILE.nodefactory.newVglue(SILE.settings.get("document.lineskip"))
      lead.height = lead.height:absolute()
      return lead
    end
  end,
  addrlskip = function (self, slice)
    local rskip= SILE.settings.get(
      self.frame:writingDirection() == "LTR"
        and "document.rskip"
        or  "document.lskip"
    )
    if rskip then
      rskip.value = "rskip"
      table.insert(slice, rskip)
      table.insert(slice, SILE.nodefactory.zeroHbox)
    end
    local lskip= SILE.settings.get(
      self.frame:writingDirection() == "LTR"
        and "document.lskip"
        or  "document.rskip"
    )
    if lskip then
      while slice[1].discardable do
        table.remove(slice,1)
      end
      lskip.value = "lskip"
      table.insert(slice, 1, lskip)
      table.insert(slice, 1, SILE.nodefactory.zeroHbox)
    end
  end,
  breakpointsToLines = function(self, bp)
    local linestart = 0
    local lines = {}
    local nodes = self.state.nodes

    for i = 1,#bp do local point = bp[i]
      if not(point.position == 0) then
        slice = {}
        local seenHbox = 0
        local toss = 1
        for j = linestart, point.position do
          slice[#slice+1] = nodes[j]
          if nodes[j] then
            toss = 0
            if nodes[j]:isBox() or nodes[j]:isDiscretionary() then seenHbox = 1 end
          end
        end
        if seenHbox == 0 then break end
        self:addrlskip(slice)
        local ratio = self:computeLineRatio(point.width, slice)
        local thisLine = { ratio = ratio, nodes = slice }
        lines[#lines+1] = thisLine
        if slice[#slice]:isDiscretionary() then
          linestart = point.position
        else
          linestart = point.position+1
        end
      end
    end
    --self.state.nodes = nodes.slice(linestart+1,nodes.length)
    return lines
  end,
  computeLineRatio = function(self, breakwidth, slice)
    local naturalTotals = SILE.length.new({length =0 , stretch =0, shrink = 0})
    local skipping = 1
    for i = 1,#slice do node=slice[i]
      if (node:isBox() or (node:isPenalty() and node.penalty == -inf_bad)) then
        skipping = 0
        if node:isBox() then
          naturalTotals = naturalTotals + node:lineContribution()
        end
      elseif node:isDiscretionary() then
        skipping = 0
        naturalTotals = naturalTotals + node:replacementWidth()
        slice[i].height = slice[i]:replacementHeight()
      elseif skipping == 0 then
        naturalTotals = naturalTotals + node.width
      end
    end
    local i = #slice
    while i > 1 do
      if slice[i]:isGlue() or slice[i] == SILE.nodefactory.zeroHbox then
        if not slice[i].value then
          naturalTotals = naturalTotals - slice[i].width
        end
      elseif (slice[i]:isDiscretionary()) then
        slice[i].used = true
        if slice[i].parent then slice[i].parent.hyphenated = true end
        naturalTotals = naturalTotals - slice[i]:replacementWidth()
        naturalTotals = naturalTotals + slice[i]:prebreakWidth()
        slice[i].height = slice[i]:prebreakHeight()
        break
      else
        break
      end
      i = i -1
    end
    if slice[1]:isDiscretionary() then
      naturalTotals = naturalTotals - slice[1]:replacementWidth()
      naturalTotals = naturalTotals + slice[1]:postbreakWidth()
      slice[1].height = slice[1]:postbreakHeight()
    end
    local left = (breakwidth - naturalTotals.length)
    if left < 0 then
      left = left / naturalTotals.shrink
    else
      left = left / naturalTotals.stretch
    end
    if left < -1 then left = -1 end
    return left
  end,
  chuck = function(self) -- emergency shipout everything
    self:leaveHmode(true)
    self:outputLinesToPage(self.state.outputQueue)
    self.state.outputQueue = {}
  end
}

SILE.typesetter = SILE.defaultTypesetter {}

SILE.typesetNaturally = function (frame, f)
  local saveTypesetter = SILE.typesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:leave() end
  SILE.typesetter = SILE.defaultTypesetter {}
  SILE.typesetter:init(frame)
  SILE.settings.temporarily(f)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:chuck()
  SILE.typesetter.frame:leave()
  SILE.typesetter = saveTypesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:enter() end
end
