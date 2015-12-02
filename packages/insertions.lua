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
  __tostring = function(self) return "PI<"..self.nodes..">" end,
  outputYourself = function (self)
    if not self.typesetter then
      self.typesetter = SILE.defaultTypesetter {}
      self.typesetter:init(SILE.getFrame(self.frame))
    end
    for i = 1,#self.nodes do local n = self.nodes[i]
      n:outputYourself(self.typesetter, n)
    end
  end
})

local thisPageInsertionBoxForClass = function(class)
  if not insertionsThisPage[class] then
    local this = std.tree.clone(_pageInsertionVbox)
    this.frame  = SILE.scratch.insertions.classes[class].insertInto
    insertionsThisPage[class] = this
  end
  return insertionsThisPage[class]
end

local _insertionVbox = SILE.nodefactory.newVbox({
  __tostring = function(self) return "I<"..self.nodes[1].."...>" end,
  outputYourself = function(self)
    for i = 1,#(self.nodes) do
      thisPageInsertionBoxForClass(self.class):append(self.nodes[i])
    end
  end,
  type = "insertionVbox"
})

-- Set up a value to track how much smaller/larger to make a frame.
-- We have to track this on the frame, because different insertion
-- classes might affect the same frame; so we can't track it per class.
-- We also have to ensure it's initialized every time because we might
-- be shrinking a frame further down the page that the typesetter hasn't
-- entered yet.
local initShrinkage = function (f)
  if not f.state.totals then f:init() end
  if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
end

SILE.insertions.setShrinkage = function(classname, amount)
  local reduceList = SILE.scratch.insertions.classes[classname].stealFrom
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    initShrinkage(f)
    SU.debug("insertions", "Shrinking "..fName.." by "..amount.length*ratio)
    f.state.totals.shrinkage = f.state.totals.shrinkage + amount.length * ratio
  end

  -- Calculate the total size of insertions so far this page as negative shrinkage...
  f = SILE.getFrame(SILE.scratch.insertions.classes[classname].insertInto)
  initShrinkage(f)
  f.state.totals.shrinkage = f.state.totals.shrinkage - amount.length

end

SILE.insertions.commitShrinkage = function(classname)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  local stealPosition = opts["steal-position"] or "bottom"
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    initShrinkage(f)
    local newHeight = f:height() - f.state.totals.shrinkage
    local oldBottom = f:bottom()
    if stealPosition == "bottom" then f:relax("bottom") else f:relax("top") end
    SU.debug("insertions", "Constraining height of "..fName.." by "..f.state.totals.shrinkage.." to "..newHeight)
    f:constrain("height", newHeight)
    f.state.totals.shrinkage = 0
  end
end

SILE.insertions.increaseInsertionFrame = function(classname, amount)
  local opts = SILE.scratch.insertions.classes[classname]
  -- SU.debug("insertions", "Increasing insertion frame by "..amount)
  local stealPosition = opts["steal-position"] or "bottom"
  local f = SILE.getFrame(opts["insertInto"])
  local oldHeight = f:height()
  f:constrain("height", oldHeight + (type(amount)=="table" and amount.length or amount))
  if stealPosition == "bottom" then f:relax("top") end
  -- SU.debug("insertions", "New height is now ".. f:height())
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
  local options = SILE.scratch.insertions.classes[ins.class]

  local topBox = nextInterInsertionSkip(ins.class)
  local h = ins.height + topBox.height

  local leading
  local insbox = thisPageInsertionBoxForClass(ins.class)
  if insbox.height > 0 then
    leading = SILE.typesetter:leadingFor(ins,insbox.nodes[#insbox.nodes])
    h = h + leading.height
  end

  initShrinkage(targetFrame)
  if SU.debugging("insertions") then
    print("[insertions]", "Incoming insertion")
    print("top box height", topBox.height)
    print("insertion", ins)
    print("leading height", leading and leading.height or "no leading")
    print("Total incoming height", h)
    print("Insertions already in this class ", insbox.height)
    print("Page target ", target)
    print(totalHeight.." worth of content on page so far, plus "..-targetFrame.state.totals.shrinkage.." used to make way for insertions")
  end
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
      insbox:append(topBox)
      insbox:append(newvbox)
    else
      -- Split failure
      table.insert(vboxlist, i, SILE.nodefactory.newPenalty({penalty = -20000 }))
      return target
    end
    table.insert(vboxlist, i+1, SILE.nodefactory.newPenalty({penalty = -20000 }))
  end
  SU.debug("insertions", "")
  return target
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
  for class, list in pairs(insertionsThisPage) do
    SILE.insertions.commitShrinkage(class)
    for i=1,#(list.nodes) do n = list.nodes[i]
      SILE.insertions.increaseInsertionFrame(class, n.height + n.depth)
    end
  end
  if SU.debugging("insertions") then
    for k,v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
  end
  return nl
end)

SILE.typesetter:registerHook("noframebreak", function (self)
  SU.debug("insertions", "no frame break, rolling back\n")
  for class,v in pairs(insertionsThisPage) do
    SILE.getFrame(SILE.scratch.insertions.classes[class].insertInto).state.totals.shrinkage = 0
    insertionsThisPage[class] = nil
  end
end)

SILE.typesetter:registerPageEndHook(function(self)
  for k,v in pairs(insertionsThisPage) do
    v:outputYourself()
    insertionsThisPage[k] = nil
  end
end)

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
  }
}
