-- This is the default typesetter. You are, of course, welcome to create your own.
local awful_bad = 1073741823
local inf_bad = 10000
local eject_penalty = -inf_bad
local deplorable = 100000

SILE.settings.declare({
  name = "typesetter.widowpenalty", 
  type = "integer",
  default = 150,
  help = "Penalty to be applied to widow lines (at the start of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.orphanpenalty",
  type = "integer",
  default = 150,
  help = "Penalty to be applied to orphan lines (at the end of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.parfillskip",
  type = "Glue",
  default = SILE.nodefactory.newGlue("0pt plus 10000pt"),
  help = "Glue added at the end of a paragraph"
})

SILE.defaultTypesetter = std.object {
  -- Setup functions
  init = function(self, frame)
    self:initState();
    self.stateQueue = {};
    self:initFrame(frame);
    return self
  end,
  initFrame = function(self, f)
    self.frame = f;
    self.state.cursorX = self.frame:left(); -- XXX for bidi
    self.state.cursorY = self.frame:top();
    self.state.frameTotals = { height= 0 };
  end,
  initState = function(self)
    self.state = {
      nodes = {},
      outputQueue = {},
      lastBadness = awful_bad,
      frameTotals = { height = 0 },
      frameLines = {}
    };
    self:initline()
  end,
  pushState = function(self)
    table.insert(self.stateQueue, self.state);
    self:initState();
  end,
  popState = function(self)
    self.state = table.remove(self.stateQueue);
  end,

  -- Boxy stuff
  pushHbox = function (self, spec) table.insert(self.state.nodes, SILE.nodefactory.newHbox(spec)); end,
  pushGlue = function (self, spec) return table.insert(self.state.nodes, SILE.nodefactory.newGlue(spec)); end,
  pushPenalty = function (self, spec) return table.insert(self.state.nodes, SILE.nodefactory.newPenalty(spec)); end,
  pushVbox = function (self, spec) local v = SILE.nodefactory.newVbox(spec); table.insert(self.state.outputQueue,v); return v; end,
  pushVglue = function (self, spec) return table.insert(self.state.outputQueue, SILE.nodefactory.newVglue(spec)); end,
  pushVpenalty = function (self, spec) return table.insert(self.state.outputQueue, SILE.nodefactory.newPenalty(spec)); end,

  parSepPattern = "\n\n+",

  -- Actual typesetting functions
  typeset = function (self, text)
    for t in SU.gtoke(text,self.parSepPattern) do
      if (t.separator) then self:leaveHmode();
      else self:setpar(t.string)
      end
    end
  end,

  initline = function (self)
    if (#self.state.nodes == 0) then
      self:pushHbox({ width = SILE.length.new({length = 0}), value = {glyph = 0} });
    end
  end,

  -- Takes string, writes onto self.state.nodes
  setpar = function (self, t)
    t = string.gsub(t,"\n", " ");
    --t = string.gsub(t,"^%s+", "");
    if (#self.state.nodes == 0) then
      self:initline()
      SILE.documentState.documentClass.newPar(self); -- XXX ?
    end
    for token in SU.gtoke(t, "-") do
      local t2= token.separator and token.separator or token.string
      local newNodes = SILE.shaper.shape(t2)
      for i=1,#newNodes do
          self.state.nodes[#(self.state.nodes)+1] = newNodes[i]
      end
    end
  end,

  -- Empties self.state.nodes, breaks into lines, puts lines into vbox, adds vbox to
  -- outputqueue, calls pageBuilder
  boxUpNodes = function (self, nl, suppressFinalGlue)
    -- Question: If final discardables are discardable, how does "\hss foo \hss" work?
    --while (#nl > 0 and (nl[#nl]:isPenalty() or nl[#nl]:isGlue())) do
    --  table.remove(nl);
    --end

    while (#nl >0 and nl[1]:isPenalty()) do table.remove(nl,1) end
    self:pushGlue(SILE.settings.get("typesetter.parfillskip"));
    self:pushPenalty({ flagged= 1, penalty= -inf_bad });
    SU.debug("typesetter", "Boxed up "..nl);
    local breaks = SILE.linebreak:doBreak( nl, self.frame:width() );
    if (#breaks == 0) then
      SILE.SU.error("Couldn't break :(")
    end
    local lines = self:breakpointsToLines(breaks);
    local vboxes = {}
    local previousVbox = nil
    for index=1, #lines do
      local l = lines[index]
      local v = SILE.nodefactory.newVbox({ nodes = l.nodes, ratio = l.ratio });
      local pageBreakPenalty = 0
      if (#lines > 1 and index == 1) then
        pageBreakPenalty = SILE.settings.get("typesetter.widowpenalty")
      elseif (#lines > 1 and index == (#lines-1)) then
        pageBreakPenalty = SILE.settings.get("typesetter.orphanpenalty")
      end
      vboxes[#vboxes+1] = self:leadingFor(v, previousVbox)
      vboxes[#vboxes+1] = v
      previousVbox = v
      if pageBreakPenalty > 0 then
        vboxes[#vboxes+1] = SILE.nodefactory.newPenalty({ penalty = pageBreakPenalty})
      end
    end
    return vboxes
  end,

  leaveHmode = function(self, independent)
    SU.debug("typesetter", "Leaving hmode");
    local vboxlist = self:boxUpNodes(self.state.nodes)
    self.state.nodes = {};
    -- Push output lines into boxes and ship them to the page builder
    for index=1, #vboxlist do
      self.state.outputQueue[#(self.state.outputQueue)+1] = vboxlist[index]
    end
    self:pageBuilder(independent);
  end,
  leadingFor = function(self, v, previous)
    -- Insert leading
   SU.debug("typesetter", "   Considering leading between self two lines");
   local prevDepth = 0
   if previous then prevDepth = previous.depth end
   SU.debug("typesetter", "   Depth of previous line was "..tostring(prevDepth));
   local bls = SILE.settings.get("document.baselineskip")
   local d = bls.height - v.height - prevDepth;
   d = d.length
   SU.debug("typesetter", "   Leading height = " .. tostring(bls.height) .. " - " .. v.height .. " - " .. prevDepth .. " = "..d) ;

    if (d > SILE.settings.get("document.lineskip").height.length) then
      len = SILE.length.new({ length = d, stretch = bls.height.stretch, shrink = bls.height.shrink })
      return SILE.nodefactory.newVglue({height = len});
    else
      return SILE.nodefactory.newVglue(SILE.settings.get("document.lineskip"));
    end
  end,
  pageBuilder = function (self, independent)
    local target = SILE.length.new({ length = self.frame:height() }) -- XXX Floats
    local vbox;
    local function luaSucks (a) vbox = a return a end
    while #self.state.outputQueue > 0 and luaSucks(table.remove(self.state.outputQueue,1)) do 
      SU.debug("typesetter", "Dealing with VBox " .. vbox)
      if (vbox:isVbox()) then
        self.state.frameTotals.height = self.state.frameTotals.height + vbox.height + vbox.depth;
      elseif vbox:isVglue() then
        self.state.frameTotals.height = self.state.frameTotals.height + vbox.height;
      end
      local left = (target - self.state.frameTotals.height).length;
      SU.debug("typesetter", "I have " .. tostring(left) .. "pts left");
      -- if (left < -20) then SU.error("\nCatastrophic page breaking failure!"); end 
      local pi = 0
      if vbox:isPenalty() then
        pi = vbox.penalty
      end 
      if vbox:isPenalty() and vbox.penalty < inf_bad  or vbox:isVglue() then
        local badness = left > 0 and left * left * left or awful_bad;
        local c
        if badness < awful_bad then 
          if pi <= eject_penalty then c = pi
          elseif badness < inf_bad then c = badness + pi -- plus insert
          else c = deplorable
          end
        else c = badness end

       SU.debug("typesetter", "Badness: "..c);
        if (c < self.state.lastBadness) then
          self.state.lastBadness = c;
        end
        if c == awful_bad or pi <= eject_penalty then
         SU.debug("typesetter", "outputting");
          self.state.lastBadness = awful_bad
          self:shipOut(target, independent);
          return
        end
      end
      table.insert(self.state.frameLines,vbox);
    end
  end,

  shipOut = function (self, target, independent)
    SU.debug("typesetter", "Height total is " .. tostring(self.state.frameTotals.height));
    SU.debug("typesetter", "Target is " .. tostring(target));
    local adjustment = (target - self.state.frameTotals.height)
    if type(adjustment) == "table" then adjustment = adjustment.length end
    local glues = {};
    local gTotal = SILE.length.new()
    for i,b in pairs(self.state.frameLines) do
      if b:isVglue() then 
        table.insert(glues,b);
        gTotal = gTotal + b.height
      end
    end

    if (adjustment > gTotal.stretch) then adjustment = gTotal.stretch end
    if (adjustment / gTotal.stretch > 0) then 
      for i,g in pairs(glues) do
        g:setGlue(adjustment * g.length.stretch / gTotal.stretch)
      end
    end

   SU.debug("typesetter", "Glues for self page adjusted by "..(adjustment/gTotal.stretch) )
    self:outputLinesToPage(self.state.frameLines);
    self.state.frameLines = {};
    --self.state.frameTotals.height = 0;
    --self.state.frameTotals.prevDepth = 0;
    if not independent then
        local cwidth = self.frame:width();
        if (self.frame.next) then
          self:initFrame(SILE.getFrame(self.frame.next));
        else
          self:initFrame(SILE.documentState.documentClass:newPage()); -- XXX Hack
        end
        -- Always push back and recalculate. The frame may have a different shape, or
        -- we may be doing clever things like grid typesetting. CPU time is cheap.
        -- self:pushBack();
    end
  end,
  pushBack = function (self)
    --self:pushHbox({ width = SILE.length.new({}), value = {glyph = 0} });
    local v
    local function luaSucks (a) v=a return a end

    while luaSucks(table.remove(self.state.outputQueue,1)) do
      if not v:isVglue() and not v:isPenalty() then
        for i=1,#(v.nodes) do
            self.state.nodes[#(self.state.nodes)+1] = v.nodes[i]
        end
      end
    end
    -- self:leaveHmode();
  end,
  outputLinesToPage = function (self, lines)
   SU.debug("typesetter", "OUTPUTTING");
   -- Suppress top-of-frame-glue/penalties. This is a slight hack.
    while #lines > 0 and (lines[1]:isVglue() or
      lines[1]:isPenalty()) do
      table.remove(lines,1)
    end
    for i,line in pairs(lines) do
      line:outputYourself(self, line)
    end
  end,
  addrskip = function (self, slice)
    local rskip = SILE.settings.get("document.rskip")
    if rskip then table.insert(slice, rskip) end
  end,
  breakpointsToLines = function(self, bp)
    local linestart = 0;
    local lines = {};
    local nodes = self.state.nodes;

    for i,point in pairs(bp) do
      if not(point.position == 0) then

        -- Toss initial glue? XXX
        --while(nodes[linestart] and not nodes[linestart]:isBox()) do
        --  linestart = linestart + 1
        --end

        slice = {}
        local seenHbox = 0
        local toss = 1
        for j = linestart, point.position do
          slice[#slice+1] = nodes[j]
          if nodes[j] then
            toss = 0
            if nodes[j]:isBox() then seenHbox = 1 end
          end
        end
        if seenHbox == 0 then break end
        self:addrskip(slice)

        local naturalTotals = SILE.length.new({length =0 , stretch =0, shrink = 0})
        for i,node in ipairs(slice) do
          if (node:isBox() or (node:isPenalty() and node.penalty == -inf_bad)) then
            skipping = 0
            if node:isBox() then
              naturalTotals = naturalTotals + node.width
            end
          elseif skipping == 0 then-- and not(node:isGlue() and i == #slice) then
            naturalTotals = naturalTotals + node.width
          end
        end
        if (slice[#(slice)]:isDiscretionary()) then -- This is broken by rskip. It's wrong anyway.
         slice[#(slice)].used = 1;
         naturalTotals = naturalTotals + slice[#slice]:prebreakWidth()
        end
        local left = (point.width - naturalTotals.length)

        if left < 0 then
          left = left / naturalTotals.shrink
        else
          left = left / naturalTotals.stretch
        end
        if left < -1 then left = -1 end
        local thisLine = { ratio = left, nodes = slice };
        lines[#lines+1] = thisLine
        linestart = point.position+1
      end
    end
    --self.state.nodes = nodes.slice(linestart+1,nodes.length);
    return lines;
  end
};

SILE.typesetter = SILE.defaultTypesetter {};

SILE.typesetNaturally = function (frame, nodes)
  local saveTypesetter = SILE.typesetter
  SILE.typesetter = SILE.defaultTypesetter {};
  SILE.typesetter:init(frame);
  SILE.typesetter.state.nodes = nodes;
  SILE.typesetter:leaveHmode(1);  
  SILE.typesetter:shipOut(0,1);  
  SILE.typesetter = saveTypesetter
end;