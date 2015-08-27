SILE.scratch.insertions = {
  classes = {},
  thispage = {},
  typesetters = {},
  nextpage = {}
}

SILE.insertions = {}

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

local _insertionVbox = SILE.nodefactory.newVbox({
  __tostring = function(self) return "I<"..self.material..">" end
})
local insertionsThisPage = {}
_insertionVbox.outputYourself = function(self)
  insertionsThisPage[#insertionsThisPage+1] = self
end
SILE.insertions.output = function()
  for i = 1,#insertionsThisPage do
    insertionsThisPage[i]:realOutputYourself()
  end
  insertionsThisPage = {}
end

_insertionVbox.realOutputYourself = function (self)
  local t = SILE.scratch.insertions.typesetters[self.class]
  if not t then
    t = SILE.defaultTypesetter {}
    t:init(SILE.getFrame(self.frame))
    SILE.scratch.insertions.typesetters[self.class] = t
  end
  for i = 1,#self.material do local n = self.material[i]
    if n:isVglue() then
      n:outputYourself(t, n)
    else  -- Unvbox
      for i,node in pairs(n.nodes) do
        node:outputYourself(t, node)
      end
    end
  end
end
_insertionVbox.actualHeight = 0
_insertionVbox.frame = nil
_insertionVbox.active = 0
_insertionVbox.type = "insertionVbox"
_insertionVbox.class = nil

SILE.insertions.setShrinkage = function(classname, amount)
  SU.debug("insertions", "Shrinking main box by "..amount.length)
  local reduceList = SILE.scratch.insertions.classes[classname].stealFrom
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if not f.state.totals then f:init() end -- May be a frame that has not been entered yet
    if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
    f.state.totals.shrinkage = f.state.totals.shrinkage + amount.length * ratio
  end

  -- Calculate the total size of insertions so far this page as negative shrinkage...
  f = SILE.getFrame(SILE.scratch.insertions.classes[classname].insertInto)
  if not f.state.totals then f:init() end
  if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
  f.state.totals.shrinkage = f.state.totals.shrinkage - amount.length

end

SILE.insertions.commitShrinkage = function(classname)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  local stealPosition = opts["steal-position"] or "bottom"
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if not f.state.totals then f:init() end -- May be a frame that has not been entered yet
    if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
    local newHeight = f:height() - f.state.totals.shrinkage
    local oldBottom = f:bottom()
    if stealPosition == "bottom" then f:relax("bottom") else f:relax("top") end
    SU.debug("insertions", "Constraining height of "..fName.." by "..f.state.totals.shrinkage.." to "..newHeight)
    f:constrain("height", newHeight)
    f.state.totals.shrinkage = 0
  end

  f = SILE.getFrame(SILE.scratch.insertions.classes[classname].insertInto)
  if not f.state.totals then f:init() end -- May be a frame that has not been entered yet
  if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
end

SILE.insertions.increaseInsertionFrame = function(classname, amount)
  local opts = SILE.scratch.insertions.classes[classname]
  SU.debug("insertions", "Increasing insertion frame by "..amount)
  local stealPosition = opts["steal-position"] or "bottom"
  local f = SILE.getFrame(opts["insertInto"])
  local oldHeight = f:height()
  f:constrain("height", oldHeight + amount.length)
  if stealPosition == "bottom" then f:relax("top") end
  SU.debug("insertions", "New height is now ".. f:height())
end

SILE.insertions.removeAddedSkip = function (ins)
  while ins.material[1] and ins.material[1]:isVglue() and not ins.material[1].explicit do
    table.remove(ins.material, 1)
  end
  local h = SILE.length.new()
  for i= 1,#(ins.material) do h = h + ins.material[i].height end
  ins.actualHeight = h
end

SILE.insertions.processInsertion = function (vboxlist, i, totalHeight, target)
  local ins = vboxlist[i]
  local options = SILE.scratch.insertions.classes[ins.class]
  local targetFrame = SILE.getFrame(ins.frame)
  local vglue
  SILE.insertions.removeAddedSkip(ins)
  if not SILE.scratch.insertions.thispage[ins.class] or not SILE.scratch.insertions.thispage[ins.class][1] then
    SILE.scratch.insertions.thispage[ins.class] = {ins}
    if options["topSkip"] then
      vglue = SILE.nodefactory.newVglue({ height = options["topSkip"] })
      table.insert(ins.material,1,vglue)
    end
  else
    vglue = SILE.nodefactory.newVglue({ height = options["interInsertionSkip"] })
    table.insert(ins.material,1,vglue)
  end
  local h = ins.actualHeight + vglue.height
  ins.actualHeight = h
  if not targetFrame.state.totals then targetFrame:init() end
  if not targetFrame.state.totals.shrinkage then targetFrame.state.totals.shrinkage = 0 end
  SU.debug("insertions", "Total height so far: ".. (- targetFrame.state.totals.shrinkage))
  SU.debug("insertions", "Incoming insertion: " .. h)
  SU.debug("insertions", "Incoming insertion: " .. ins)
  SU.debug("insertions", "Max height: " .. options.maxHeight)
  SU.debug("insertions", "Page target: "..target)
  SU.debug("insertions", "Page shrinkage: "..ins.parent.state.totals.shrinkage)
  SU.debug("insertions", "Total height: "..h)
  if ((- targetFrame.state.totals.shrinkage) + h.length - options.maxHeight).length < 0
    and (target - (totalHeight + h)).length > 0 then
    SU.debug("insertions", "fits")
    SILE.insertions.setShrinkage(ins.class, h)
    target = SILE.typesetter.frame:height() - SILE.typesetter.frame.state.totals.shrinkage
  else
    SU.debug("insertions", "split")
    local maxsize = target - totalHeight
    if maxsize > options.maxHeight then maxsize = options.maxHeight end
    local split = SILE.pagebuilder.findBestBreak(ins.material[2].nodes, maxsize.length)
    if split then
      ins.material[2] = SILE.pagebuilder.collateVboxes(ins.material[2].nodes)
      ins.actualHeight = ins.material[1].height + ins.material[2].height
      local newvbox = SILE.pagebuilder.collateVboxes(split)
      table.insert(vboxlist, i,
        _insertionVbox {
          class = ins.class,
          material = { newvbox },
          actualHeight = newvbox.height,
          frame = ins.frame,
          parent = SILE.typesetter.frame
        }
      )
    end
    table.insert(vboxlist, i+1, SILE.nodefactory.newPenalty({penalty = -20000 }))
  end
  return target
end

SILE.insertions.commit = function(nl)
  local done = {}
  for i=1,#nl do n = nl[i]
    if n.type == "insertionVbox" then

      SILE.insertions.increaseInsertionFrame(n.class, n.actualHeight)
      if not done[n.class] then
        SILE.insertions.commitShrinkage(n.class)
        done[n.class] = true
      end
    end
  end
end

local insert = function (self, classname, vbox)
  local thisclass = SILE.scratch.insertions.classes[classname]
  if not thisclass then SU.error("Uninitialized insertion class "..classname) end
  SILE.typesetter:pushMigratingMaterial({
    _insertionVbox {
        class = classname,
        material = { vbox },
        actualHeight = vbox.height,
        frame = thisclass.insertInto,
        parent = SILE.typesetter.frame
      }
  })
end

SILE.typesetter:registerFrameBreakHook(function (self,nl)
  SILE.scratch.insertions.typesetters = {}
  SILE.scratch.insertions.thispage = {}
  SILE.insertions.commit(nl)
  return nl
end)

SILE.typesetter:registerHook("noframebreak", function (self)
  for k,v in pairs(SILE.scratch.insertions.thispage) do
    local thisclass = SILE.scratch.insertions.classes[k]
    SILE.getFrame(thisclass.insertInto).state.totals.shrinkage = 0
  end
  SILE.scratch.insertions.thispage = {}
end)

SILE.typesetter:registerPageEndHook(SILE.insertions.output)

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
  }
}
