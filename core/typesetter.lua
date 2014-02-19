-- This is the default typesetter. You are, of course, welcome to create your own.
local awful_bad = 1073741823
local inf_bad = 10000

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
    self.state.frameTotals = { height= 0, prevDepth= 0 };
  end,
  initState = function(self)
    self.state = {
      nodes = {},
      outputQueue = {},
      lastBadness = awful_bad,
      frameTotals = { height = 0, prevDepth = 0, },
      frameLines = {}
    };
  end,
  pushState = function(self)
    table.insert(self.stateQueue, self.state);
    self.initState();
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
  setpar = function (self, t)
    t = string.gsub(t,"\n", " ");
    --t = string.gsub(t,"^%s+", "");
    if (#self.state.nodes == 0) then
      self:pushHbox({ width = SILE.length.new({length = 0}), value = {glyph = 0} });
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
  leaveHmode = function(self, independent)
   SU.debug("typesetter", "Leaving hmode");
    local nl = self.state.nodes;
    while (#nl > 0 and (nl[#nl]:isPenalty() or nl[#nl]:isGlue())) do
      table.remove(nl);
    end

    while (#nl >0 and nl[1]:isPenalty()) do table.remove(nl,1) end
    self:pushGlue({ width = SILE.length.new({ length = 0, stretch =  10000 })});
    self:pushPenalty({ flagged= 1, penalty= -inf_bad });
    -- Run the KP algorithm
    --var breaks = SILE.linebreak(self.state.nodes,[ self.frame.width() ]);
    --if (1 || breaks.length == 0) {
      --SILE.hyphenate(self);
      local breaks = SILE.linebreak:doBreak({ nodes = nl, hsize = self.frame:width(), pretolerance = 400 });
      if (#breaks == 0) then
        SILE.error("Couldn't break :(")
      end
    --}
    local lines = self:breakpointsToLines(breaks);
    -- Push output lines into boxes and ship them to the page builder
    for index, l in pairs(lines) do
      local v = SILE.nodefactory.newVbox({ nodes = l.nodes, ratio = l.ratio });
      self:insertLeading(v);
      local pageBreakPenalty = 0
      if (#lines > 1 and index == 1) then
        pageBreakPenalty = SILE.documentState.documentClass.settings.widowPenalty
      elseif (#lines > 1 and index == #lines) then
        pageBreakPenalty = SILE.documentState.documentClass.settings.clubPenalty
      end
      self:pushVpenalty({ penalty = pageBreakPenalty})
      self:pushVbox(v);

    end
    self:pageBuilder(independent);
  end,
  insertLeading = function(self, v)
    -- Insert leading
   SU.debug("typesetter", "   Considering leading between self two lines");
   SU.debug("typesetter", "   Depth of previous line was "..tostring(self.state.frameTotals.prevDepth));
   local d = SILE.documentState.documentClass.state.baselineSkip.height - v.height - self.state.frameTotals.prevDepth;
   d = d.length
   --SU.debug("typesetter", "   Leading height = " .. tostring(SILE.documentState.documentClass.state.baselineSkip.height) .. " - " .. v.height .. " - " .. self.state.frameTotals.prevDepth .. " = "..d) ;

    if (d > SILE.documentState.documentClass.state.lineSkip.height.length) then
      len = SILE.length.new({ length = d, stretch = SILE.documentState.documentClass.state.baselineSkip.height.stretch, shrink = SILE.documentState.documentClass.state.baselineSkip.height.shrink })
      self:pushVglue({height = len});
    else
      self:pushVglue(SILE.documentState.documentClass.state.lineSkip);
    end
    self.state.frameTotals.prevDepth = v.depth;
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
        self.state.frameTotals.height = self.state.frameTotals.height + vbox.height.length;
      end
      local left = (target - self.state.frameTotals.height).length;
     SU.debug("typesetter", "I have " .. tostring(left) .. "pts left");
      if vbox:isPenalty() then
        local badness = left > 0 and left * left * left or inf_bad;
        local c = badness < inf_bad and vbox.penalty + badness or inf_bad;
       SU.debug("typesetter", "Badness: "..c);
        if (c > self.state.lastBadness) then
         SU.debug("typesetter", "self is worse");
          self.state.lastBadness = awful_bad;
          self:shipOut(target, independent);
        else
          self.state.lastBadness = c;
        end
      end
      table.insert(self.state.frameLines,vbox);
    end
  end,

  shipOut = function (self, target, independent)
    SU.debug("typesetter", "Height total is " .. tostring(self.state.frameTotals.height));
    SU.debug("typesetter", "Target is " .. tostring(target));
    local adjustment = (target - self.state.frameTotals.height).length;
    local glues = {};
    local gTotal = SILE.length.new()
    for i,b in pairs(self.state.frameLines) do
      if b:isVglue() then 
        table.insert(glues,b);
        gTotal = gTotal + b.height.length
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
          self:initFrame(SILE:getFrame(self.frame.next));
        else
          self:initFrame(SILE.documentState.documentClass:newPage()); -- XXX Hack
        end
        -- Always push back and recalculate. The frame may have a different shape, or
        -- we may be doing clever things like grid typesetting. CPU time is cheap.
        self:pushBack();
    end
  end,
  pushBack = function (self)
    --self:pushHbox({ width = SILE.length.new({}), value = {glyph = 0} });
    local v
    local function luaSucks (a) v=a return a end

    while luaSucks(table.remove(self.state.outputQueue,1)) do
      if not v:isVglue() and not v:isPenalty() then
      -- v.nodes.forEach(function(n){ 
      --   if (n.isDiscretionary()) n.used = 0;
      -- });
        for i=1,#(v.nodes) do
            self.state.nodes[#(self.state.nodes)+1] = v.nodes[i]
        end
      end
    end
    self:leaveHmode();
  end,
  outputLinesToPage = function (self, lines)
   SU.debug("typesetter", "OUTPUTTING");
    for i,line in pairs(lines) do
      line:outputYourself(self, line)
    end
  end,
  addrskip = function (self, slice)
    if SILE.documentState.documentClass.state.rskip then
      table.insert(slice, SILE.documentState.documentClass.state.rskip)
    end
  end,
  breakpointsToLines = function(self, bp)
    local linestart = 0;
    local lines = {};
    local nodes = self.state.nodes;

    for i,point in pairs(bp) do
      if not(point.position == 0) then
        for j = linestart, #nodes do
          -- XXX TeX would toss initial line glue. We don't, because we'll often put it
          -- back again. Instead we ignore it when we call the output routine. This may not be correct.

          --if (nodes[j].isBox() || (nodes[j].isPenalty && nodes[j].penalty == -Infinity)) {
            linestart = j
          --}
          break
        end

        slice = {}
        for j = linestart, point.position do
          slice[#slice+1] = nodes[j]
        end

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
        if (slice[#(slice)]:isDiscretionary()) then 
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
    self.state.nodes = {};
    return lines;
  end
};

SILE.typesetter = SILE.defaultTypesetter;

SILE.typesetNaturally = function (frame, nodes)
  local newTypesetter = SILE.defaultTypesetter {};
  newTypesetter:init(frame);
  newTypesetter.state.nodes = nodes;
  newTypesetter:leaveHmode(1);  
  newTypesetter:shipOut(0,1);  

end;