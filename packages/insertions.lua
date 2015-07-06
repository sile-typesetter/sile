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
_insertionVbox.outputYourself = function (self)
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
end

SILE.insertions.commitShrinkage = function(classname)
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

SILE.insertions.increaseInsertionFrame = function(classname, amount)
  local opts = SILE.scratch.insertions.classes[classname]
  local stealPosition = opts["steal-position"] or "bottom"
  local f = SILE.getFrame(opts["insertInto"])
  local oldHeight = f:height()
  f:constrain("height", oldHeight + amount.length)
  if stealPosition == "bottom" then f:relax("top") end
end

SILE.insertions.removeAddedSkip = function (ins)
  while ins.material[1] and ins.material[1]:isVglue() and not ins.material[1].explicit do
    table.remove(ins.material, 1)
  end
end

SILE.insertions.processInsertion = function (ins, totalHeight, target)
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

  if targetFrame:height() + h < options.maxHeight then
    SU.debug("insertions", "fits")
    SILE.insertions.setShrinkage(ins.class, h)
    target = ins.parent:height() - ins.parent.state.totals.shrinkage
    ins.actualHeight = ins.actualHeight + vglue.height
  elseif target - (totalHeight + h) < 0 then
    SU.debug("insertions", "no hope")
  else
    SU.debug("insertions", "split")
  end
  return target
end

SILE.insertions.commit = function(nl)
  for i=1,#nl do n = nl[i]
    if n.type == "insertionVbox" then
      SILE.insertions.increaseInsertionFrame(n.class, n.actualHeight)
      SILE.insertions.commitShrinkage(n.class)
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

SILE.typesetter:registerPageBreakHook(function (self,nl)
  SILE.scratch.insertions.typesetters = {}
  SILE.insertions.commit(nl)  
  return nl
end)

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
  }
}
