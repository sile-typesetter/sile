SILE.scratch.insertions = { classes = {} }

SILE.insertions = {}

local initInsertionClass = function (self, classname, options)
  SU.required(options, "insertInto", "initializing insertions")
  SU.required(options, "stealFrom", "initializing insertions")
  SU.required(options, "maxHeight", "initializing insertions")
  if not options.topSkip and not options.topBox then
    SU.required(options, "topSkip", "initializing insertions")
  end

  -- Turn stealFrom into a hash, if it isn't one.
  if type(options.stealFrom) == "string" then options.stealFrom = { options.stealFrom } end
  if options.stealFrom[1] then
    local rl = {}
    for i = 1,#(options.stealFrom) do rl[options.stealFrom[i]] = 1 end
    options.stealFrom = rl
  end
  SILE.scratch.insertions.classes[classname] = options
end

-- This initializes a vbox to store all the material in an insertion
-- class for the current page
local insertionsThisPage = {}
local _pageInsertionVbox = SILE.nodefactory.newVbox({
  __tostring = function(self) return "PI<"..self.nodes..">" end
})

_pageInsertionVbox.outputYourself = function (self)
  if not self.typesetter then
    self.typesetter = SILE.defaultTypesetter {}
    self.typesetter:init(SILE.getFrame(self.frame))
  end
  for i = 1,#self.nodes do local n = self.nodes[i]
    n:outputYourself(self.typesetter, n)
  end
end

local thisPageInsertionBoxForClass = function(class)
  if not insertionsThisPage[class] then
    local this = _pageInsertionVbox {}
    this.frame  = SILE.scratch.insertions.classes[class].insertInto
    insertionsThisPage[class] = this
  end
  return insertionsThisPage[class]
end

SILE.insertions.output = function()
  for k,v in pairs(insertionsThisPage) do
    v:outputYourself()
    insertionsThisPage[k] = nil
  end
end

local _insertionVbox = SILE.nodefactory.newVbox({
  __tostring = function(self) return "I<"..self.nodes..">" end,
  outputYourself = function(self)
    for i = 1,#(self.nodes) do
      thisPageInsertionBoxForClass(self.class):append(self.nodes[i])
    end
  end,
  type = "insertionVbox"
})

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
  f:constrain("height", oldHeight + (type(amount)=="table" and amount.length or amount))
  if stealPosition == "bottom" then f:relax("top") end
  SU.debug("insertions", "New height is now ".. f:height())
end

local nextInterInsertionSkip = function (class)
  local options = SILE.scratch.insertions.classes[class]
  local stuffSoFar = thisPageInsertionBoxForClass(class)
  if #(stuffSoFar.nodes) == 0 then
    if options["topBox"] then
      return options["topBox"]
    elseif options["topSkip"] then
      return SILE.nodefactory.newVglue({ height = options["topSkip"] })
    end
  else
    return SILE.nodefactory.newVglue({ height = options["interInsertionSkip"] })
  end
end

SILE.insertions.processInsertion = function (vboxlist, i, totalHeight, target)
  local ins = vboxlist[i]
  local targetFrame = SILE.getFrame(ins.frame)
  local topBox = nextInterInsertionSkip(ins.class)
  local options = SILE.scratch.insertions.classes[ins.class]
  local h = ins.height + topBox.height
  local leading
  local insbox = thisPageInsertionBoxForClass(ins.class)
  if insbox.height > 0 then
    leading = SILE.typesetter:leadingFor(ins,insbox.nodes[#insbox.nodes])
    h = h + leading.height
  end
  if not targetFrame.state.totals then targetFrame:init() end
  if not targetFrame.state.totals.shrinkage then targetFrame.state.totals.shrinkage = 0 end
  SU.debug("insertions", "Total height of insertions so far: ".. (- targetFrame.state.totals.shrinkage))
  SU.debug("insertions", "Incoming insertion content: " .. ins)
  SU.debug("insertions", "Incoming insertion plus topBox height plus leading: " .. ins.height .."+"..topBox.height.."+"..(leading and leading.height or 0).."="..h)
  SU.debug("insertions", "Max allowed height of insertions on page: " .. options.maxHeight)
  SU.debug("insertions", "Total content on page so far: " .. totalHeight)
  SU.debug("insertions", "Page target: "..target)
  SU.debug("insertions", "Page shrinkage: "..ins.parent.state.totals.shrinkage)
  if ((- targetFrame.state.totals.shrinkage) + h.length - options.maxHeight).length < 0
    and (target - (totalHeight + h)).length > 0 then
    SU.debug("insertions", "fits")
    SILE.insertions.setShrinkage(ins.class, h)
    insbox:append(topBox)
    insbox:append(ins)
    if leading then
      insbox:append(leading)
    end
    target = SILE.typesetter.frame:height() - SILE.typesetter.frame.state.totals.shrinkage
  else
    SU.debug("insertions", "splitting")
    local maxsize = target - totalHeight
    if maxsize > options.maxHeight then maxsize = options.maxHeight end
    maxsize = maxsize - topBox.height
    local materialToSplit = {}
    table.append(materialToSplit, ins:unbox())
    local split = SILE.pagebuilder.findBestBreak({
      vboxlist = materialToSplit,
      target   = maxsize.length,
      restart  = false,
      force    = true
    })
    if split then
      ins.nodes = {}
      ins.height = 0
      ins:append(materialToSplit)
      local newvbox = SILE.pagebuilder.collateVboxes(split)
      SU.debug("insertions", "Split. Remaining insertion is ".. ins)
      table.insert(vboxlist, i,
        _insertionVbox {
          class = ins.class,
          nodes = newvbox.nodes,
          height = newvbox.height,
          frame = ins.frame,
          parent = SILE.typesetter.frame
        }
      )
      SILE.insertions.setShrinkage(ins.class, topBox.height + newvbox.height)
      thisPageInsertionBoxForClass(ins.class):append(topBox)
      thisPageInsertionBoxForClass(ins.class):append(newvbox)
    else
      -- Split failure
      table.insert(vboxlist, i, SILE.nodefactory.newPenalty({penalty = -20000 }))
      return target
    end
    table.insert(vboxlist, i+1, SILE.nodefactory.newPenalty({penalty = -20000 }))
  end
  return target
end

SILE.insertions.commit = function()
  for class, list in pairs(insertionsThisPage) do
    SILE.insertions.commitShrinkage(class)
    for i=1,#(list.nodes) do n = list.nodes[i]
      SILE.insertions.increaseInsertionFrame(class, n.height + n.depth)
    end
  end
end

local insert = function (self, classname, vbox)
  local thisclass = SILE.scratch.insertions.classes[classname]
  if not thisclass then SU.error("Uninitialized insertion class "..classname) end
  SILE.typesetter:pushMigratingMaterial({
    _insertionVbox {
        class = classname,
        nodes = vbox.nodes,
        height = vbox.height,
        frame = thisclass.insertInto,
        parent = SILE.typesetter.frame
      }
  })
end

SILE.typesetter:registerFrameBreakHook(function (self,nl)
  SILE.insertions.commit()
  return nl
end)

SILE.typesetter:registerHook("noframebreak", function (self)
  SU.debug("insertions", "no frame break, rolling back\n")
  for class,v in pairs(insertionsThisPage) do
    SILE.getFrame(SILE.scratch.insertions.classes[class].insertInto).state.totals.shrinkage = 0
    v.nodes = {}
  end
  -- insertionsThisPage = {}
end)

SILE.typesetter:registerPageEndHook(SILE.insertions.output)

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
  }
}
