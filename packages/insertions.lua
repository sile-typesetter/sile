SILE.scratch.insertions = {
  classes = {},
  thispage = {},
  typesetters = {},
  nextpage = {}
}

local initInsertionClass = function (self, classname, options)
  SU.required(options, "insertInto", "initializing insertions")
  SU.required(options, "stealFrom", "initializing insertions")
  SU.required(options, "maxHeight", "initializing insertions")
  SU.required(options, "topSkip", "initializing insertions")

  -- Turn stealFrom into a hash, if it isn't one.
  if type(options.stealFrom) == "string" then options.stealFrom = { options.stealFrom } end
  if options.stealFrom[1] then
    local rl = {}
    for i = 1,#(options.stealFrom) do rl[options.stealFrom[i]] = 1 end
    options.stealFrom = rl
  end
  SILE.scratch.insertions.classes[classname] = options
end

local _insertionVbox = SILE.nodefactory.newVbox({})
_insertionVbox.outputYourself = function (self)
  local t = SILE.scratch.insertions.typesetters[self.class]
  if not t then 
    t = SILE.defaultTypesetter {}
    t:init(SILE.getFrame(self.frame))
    SILE.scratch.insertions.typesetters[self.class] = t
  end
  if self.material:isVglue() then
    self.material:outputYourself(t, self.material)
  else  -- Unvbox
    for i,node in pairs(self.material.nodes) do
      node:outputYourself(t, node)
    end
  end
end
_insertionVbox.actualHeight = 0
_insertionVbox.frame = nil
_insertionVbox.isVbox = function () return true end
_insertionVbox.type = "insertionVbox"
_insertionVbox.active = 0
_insertionVbox.class = nil

SILE.typesetter.pageTarget = function (self)
  if not self.frame.state.totals.shrinkage then self.frame.state.totals.shrinkage = 0 end
  return self.frame:height() - self.frame.state.totals.shrinkage
end

local setShrinkage = function(classname, amount)
  SU.debug("insertions", "Shrinking main box by "..amount.length)
  local reduceList = SILE.scratch.insertions.classes[classname].stealFrom
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
    f.state.totals.shrinkage = f.state.totals.shrinkage + amount.length * ratio
  end
end

local commitShrinkage = function(classname)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  local stealPosition = opts["steal-position"] or "bottom"

  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
    local newHeight = f:height() - f.state.totals.shrinkage
    local oldBottom = f:bottom()
    if stealPosition == "bottom" then f:relax("bottom") else f:relax("top") end
    SU.debug("insertions", "Constraining height of "..fName.." to "..newHeight)
    f:constrain("height", newHeight)
    f.state.totals.shrinkage = 0
  end
end

local increaseInsertionFrame = function(classname, amount)
  local opts = SILE.scratch.insertions.classes[classname]
  local stealPosition = opts["steal-position"] or "bottom"
  local f = SILE.getFrame(opts["insertInto"])
  local oldHeight = f:height()
  f:constrain("height", oldHeight + amount.length)
  if stealPosition == "bottom" then f:relax("top") end
end

local addInsertion = function(classname, material)
  setShrinkage(classname, material.height)
  if not SILE.scratch.insertions.thispage[classname] then SILE.scratch.insertions.thispage[classname] = {} end
  local ins = SILE.scratch.insertions.thispage[classname]
  ins[#ins+1] = material
  table.insert(SILE.typesetter.state.nodes, _insertionVbox {
    class = classname,
    material = material,
    actualHeight = material.height,
    frame = SILE.scratch.insertions.classes[classname].insertInto
  })
end

local heightSoFar = function(classname)
  local h = 0
  for i = 1,#(SILE.scratch.insertions.thispage[classname]) do 
    local ins = SILE.scratch.insertions.thispage[classname][i]
    h = h + ins.height.length + ins.depth
  end
  return h
end

local mainFrameHeightSoFar = function()
  local heightOfBodySoFar = SILE.pagebuilder.collateVboxes(SILE.typesetter.state.outputQueue)
  local nodes = std.tree.clone(SILE.typesetter.state.nodes)
  SILE.typesetter:pushState()
  SILE.typesetter.state.nodes = nodes
  SILE.typesetter:leaveHmode()
  local upcomingHeight = SILE.pagebuilder.collateVboxes(SILE.typesetter.state.outputQueue)
  SILE.typesetter:popState()
  SU.debug("insertions", "Height on the main list is ".. (heightOfBodySoFar.height +heightOfBodySoFar.depth) .. ", upcoming height is "..(upcomingHeight.height + upcomingHeight.depth))
  return heightOfBodySoFar.height + upcomingHeight.height + heightOfBodySoFar.depth + upcomingHeight.depth
end

local insert = function (self, classname, vbox)
  local thisclass = SILE.scratch.insertions.classes[classname]
  if not thisclass then SU.error("Uninitialized insertion class "..classname) end
  local opts = SILE.scratch.insertions.classes[classname]

  if not SILE.scratch.insertions.thispage[classname] then
    SILE.scratch.insertions.thispage[classname] = {}
    if thisclass["topSkip"] then
      local vglue = SILE.nodefactory.newVglue({ height = thisclass["topSkip"] })
      addInsertion(classname, vglue)
    end
  elseif thisclass["interInsertionSkip"] then
    local vglue = SILE.nodefactory.newVglue({ height = thisclass["interInsertionSkip"] })
    addInsertion(classname, vglue)
  end

  local mfhsf = mainFrameHeightSoFar()
  SU.debug("insertions", "Incoming vbox is "..tostring(vbox))
  SU.debug("insertions", "Maxheight is "..tostring(thisclass["maxHeight"]))
  SU.debug("insertions", "Insertion height is "..tostring((heightSoFar(classname) + vbox.height + vbox.depth)))
  -- If the current frame is in the steal list
  SU.debug("insertions", "Target is "..SILE.typesetter:pageTarget())
  if heightSoFar(classname) + vbox.height + vbox.depth < thisclass["maxHeight"] and
    ( (vbox.height + vbox.depth).length < 0 or
    (mfhsf + vbox.height + vbox.depth - SILE.typesetter:pageTarget()).length < 0
    ) then
    addInsertion(classname, vbox)
  else
    -- No hope; defer until next time
    SU.debug("insertions", "Deferring to next page")
    SILE.scratch.insertions.nextpage[#(SILE.scratch.insertions.nextpage)+1] = {class=classname, material=vbox}
  end
end


SILE.typesetter:registerPageBreakHook(function (self,nl)
  -- Find the insertion vboxes
  local totals = {}
  for i = 1,#nl do local node = nl[i]
    if node.nodes then
      for i = 1,#node.nodes do local node = node.nodes[i]
        if node.type == "insertionVbox" then
          if not totals[node.class] then totals[node.class] = 0 end
          totals[node.class] = totals[node.class] + node.actualHeight
        end
      end
    end
  end
  -- Commit the size changes
  for class, opts in pairs(SILE.scratch.insertions.classes) do
    if totals[class] then increaseInsertionFrame(class, totals[class]) end
  end
  SILE.scratch.insertions.thispage = {}
  SILE.scratch.insertions.typesetters = {}
  return nl
end)

SILE.typesetter:registerNewPageHook(function(self)
  -- Process deferred insertions
  SILE.scratch.insertions.thispage = {}
  if 0 == #SILE.scratch.insertions.nextpage then return end
  SILE.typesetter:initline()
  for i = 1,#SILE.scratch.insertions.nextpage do local ins = SILE.scratch.insertions.nextpage[i]
    insert(self,ins.class, ins.material)
  end
  SILE.scratch.insertions.nextpage = {}  
end)

local outputInsertions = function(self)end

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
    outputInsertions = outputInsertions
  }
}
