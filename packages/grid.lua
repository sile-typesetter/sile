local gridSpacing -- Should be a setting

local makeUp = function ()
  if not SILE.typesetter.frame.state.totals.gridCursor then SILE.typesetter.frame.state.totals.gridCursor = 0 end
  local toadd = gridSpacing - (SILE.typesetter.frame.state.totals.gridCursor % gridSpacing)
  SILE.typesetter.frame.state.totals.gridCursor = SILE.typesetter.frame.state.totals.gridCursor + toadd
  return SILE.nodefactory.newVglue({ height = SILE.length.new({ length = toadd }) })
end

local leadingFor = function (self, vbox, previous)
  if not self.frame.state.totals.gridCursor then self.frame.state.totals.gridCursor = 0 end
  if not previous then return SILE.nodefactory.newVglue({height=SILE.length.new({})}) end
  if type(vbox.height) == "table" then
    self.frame.state.totals.gridCursor = self.frame.state.totals.gridCursor + vbox.height.length + previous.depth
  else
    self.frame.state.totals.gridCursor = self.frame.state.totals.gridCursor + vbox.height + previous.depth
  end
  return makeUp()
end

local pushVglue = function (self, spec)
  if not self.frame.state.totals.gridCursor then
    self.frame.state.totals.gridCursor = 0
  end
  spec.height.stretch = 0
  spec.height.shrink = 0
  self.frame.state.totals.gridCursor = self.frame.state.totals.gridCursor + SILE.toAbsoluteMeasurement(spec.height.length)
  SILE.defaultTypesetter.pushVglue(self, spec)
  SILE.defaultTypesetter.pushVglue(self, makeUp())
end

local debugGrid = function ()
  local t = SILE.typesetter
  if not t.frame.state.totals.gridCursor then t.frame.state.totals.gridCursor = 0 end
  local g = t.frame.state.totals.gridCursor
  while g < t.frame:bottom() do
    SILE.outputter.rule(t.frame:left(), t.frame:top() + g, t.frame:width(), 0.1)
    g = g + gridSpacing
  end
end

local oldPageBuilder = SILE.pagebuilder
local gridFindBestBreak = function (options)
  local vboxlist = SU.required(options, "vboxlist", "in findBestBreak")
  local target   = SU.required(options, "target", "in findBestBreak")
  local i = 0
  local totalHeight = SILE.length.new()
  local bestBreak = 0
  local started = false
  while not started and i < #vboxlist do
    i = i + 1
    if not vboxlist[i]:isVglue() then
      started = true
      i = i - 1
      break
    end
  end
  SU.debug("pagebuilder", "Page builder for frame "..SILE.typesetter.frame.id.." called with "..#vboxlist.." nodes, "..target)
  while i < #vboxlist do
    i = i + 1
    local vbox = vboxlist[i]
    SU.debug("pagebuilder", "Dealing with VBox " .. vbox)
    if (vbox:isVbox()) then
      totalHeight = totalHeight + vbox.height + vbox.depth
    elseif vbox:isVglue() then
      totalHeight = totalHeight + vbox.height
    end
    if vbox.type == "insertionVbox" then
      target = SILE.insertions.processInsertion(vboxlist, i, totalHeight, target)
      vbox = vboxlist[i]
    end
    local left = target - totalHeight.length
    SU.debug("pagebuilder", "I have " .. tostring(left) .. "pts left")
    SU.debug("pagebuilder", "totalHeight " .. totalHeight .. " with target " .. target)
    local badness = 0
    if left < 0 then badness = 1000000 end
    if vbox:isPenalty() then
      if vbox.penalty < -3000 then badness = 100000
      else badness = -(left * left) - vbox.penalty end
    end
    if badness > 0 then
      local onepage = {}
      for j=1, bestBreak do
        onepage[j] = table.remove(vboxlist, 1)
      end
      while(#onepage > 1 and onepage[#onepage].discardable) do onepage[#onepage] = nil end
      return onepage, 1000
    end
    bestBreak = i
  end
  return false, false
end

SILE.registerCommand("grid:debug", function (_, _)
  debugGrid()
  SILE.typesetter:registerNewFrameHook(debugGrid)
end)

SILE.registerCommand("grid", function (options, _)
  SILE.typesetter.state.grid = true
  SU.required(options, "spacing", "grid package")
  gridSpacing = SILE.parseComplexFrameDimension(options.spacing)
  -- SILE.typesetter:leaveHmode()

  SILE.pagebuilder = std.tree.clone(SILE.pagebuilder)
  SILE.pagebuilder.findBestBreak = gridFindBestBreak

  SILE.typesetter.leadingFor = leadingFor
  SILE.typesetter.pushVglue = pushVglue
  if SILE.typesetter.frame then
      SILE.typesetter.frame.state.totals.gridCursor = 0
      SILE.typesetter.state.previousVbox = SILE.defaultTypesetter.pushVbox(SILE.typesetter, {})
  end
  SILE.typesetter:registerNewFrameHook(function (self)
    self.frame.state.totals.gridCursor = 0
    while self.state.outputQueue[1] and self.state.outputQueue[1].discardable do
      table.remove(self.state.outputQueue, 1)
    end
    if self.state.outputQueue[1] then
      table.insert(self.state.outputQueue, 1, SILE.nodefactory.newVbox({}))
      table.insert(self.state.outputQueue, 2, leadingFor(self, self.state.outputQueue[2], self.state.outputQueue[1]))
    end
  end)

end, "Begins typesetting on a grid spaced at <spacing> intervals.")

SILE.registerCommand("no-grid", function (_, _)
  SILE.typesetter.state.grid = false
  SILE.typesetter.leadingFor = SILE.defaultTypesetter.leadingFor
  SILE.typesetter.pushVglue = SILE.defaultTypesetter.pushVglue
  SILE.typesetter.setVerticalGlue = SILE.defaultTypesetter.setVerticalGlue
  SILE.pagebuilder = oldPageBuilder
  -- SILE.typesetter.state = t.state
end, "Stops grid typesetting.")
