SILE.scratch.insertions = {
  classes = {},
  thispage = {},
  nextpage = {}
}

SILE.typesetter.pageTarget = function (self)
  if not self.frame.state.totals.shrinkage then self.frame.state.totals.shrinkage = 0 end
  return self.frame:height() - self.frame.state.totals.shrinkage
end

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

local setShrinkage = function(classname, amount)
  SU.debug("insertions", "Shrinking main box by "..amount.length)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  if type(reduceList) == "string" then reduceList = { reduceList } end
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
    f.state.totals.shrinkage = f.state.totals.shrinkage + amount.length * ratio
  end
end

local adjustHeights = function(classname, amount)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  local stealPosition = opts["steal-position"] or "bottom"

  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
    local newHeight = f:height() - f.state.totals.shrinkage
    local oldBottom = f:bottom()
    if stealPosition == "bottom" then
      --f:constrain("bottom", oldBottom - amount.length)
      f:relax("bottom")
    else
      --f:constrain("top", f:top() - amount.length)
      f:relax("top")
    end
    --f:relax("height")
    SU.debug("insertions", "Constraining height of "..fName.." to "..newHeight)
    f:constrain("height", newHeight)
    f.state.totals.shrinkage = 0 -- for now
  end

  local f = SILE.getFrame(opts["insertInto"])
  local oldHeight = f:height()

  --f:relax("height")
  f:constrain("height", oldHeight + amount.length)
  if stealPosition == "bottom" then 
    f:relax("top")
  end
end

local addInsertion = function(classname, material)
  setShrinkage(classname, material.height)
  adjustHeights(classname, material.height)
  if material:isVbox() then 
    material.height = SILE.length.new({ length =  0 })
  end
  table.insert(SILE.scratch.insertions.thispage[classname], material)
end

local heightSoFar = function(classname)
  local h = 0
  for i = 1,#(SILE.scratch.insertions.thispage[classname]) do 
    local ins = SILE.scratch.insertions.thispage[classname][i]
    h = h + ins.height.length + ins.depth
  end
  return h
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
  end

  SU.debug("insertions", "Maxheight is "..tostring(thisclass["maxHeight"]))
  SU.debug("insertions", "height is "..tostring((heightSoFar(classname) + vbox.height + vbox.depth)))
  if heightSoFar(classname) + vbox.height + vbox.depth < thisclass["maxHeight"] and
    ( (vbox.height + vbox.depth).length < 0 or
    true -- XXX "\pagetotal plus \pagedepth minus \pageshrink plus the effective
         -- size of the insertion should be less than \pagegoal"
    ) then
    addInsertion(classname, vbox)
    if thisclass["interInsertionSkip"] then
      local vglue = SILE.nodefactory.newVglue({ height = thisclass["interInsertionSkip"] })
      addInsertion(classname, vglue)
    end
  else
    SU.error("I need to split this insertion and I don't know how")
  end
end

local outputInsertions = function(self)
  if self.interInsertionSkip then
    -- Pop off final node
    SILE.scratch.insertions.thispage[#(SILE.scratch.insertions.thispage)] = nil
    reduceHeight(self, 0 - self.interInsertionSkip)
  end
  for classname,vboxes in pairs(SILE.scratch.insertions.thispage) do
    local opts = SILE.scratch.insertions.classes[classname]
    local f = SILE.getFrame(opts["insertInto"])
    local t = SILE.defaultTypesetter {}
    t:init(f)
    for i = 1,#vboxes do 
      SU.debug("insertions", "Cursor now "..t.frame.state.cursorY)
      vboxes[i]:outputYourself(t,vboxes[i])
    end
    SILE.scratch.insertions.thispage[classname] = SILE.scratch.insertions.nextpage[classname]
    -- SILE.outputter:debugFrame(f)
  end
end

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
    outputInsertions = outputInsertions
  }
}
