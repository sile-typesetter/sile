--[[
 Insertions handling is the most complicated and bug-prone part of
 SILE, and thus deserves to be well documented. If you plan to work
 on this, it would help you a lot to read chapter 29 of "TeX By Topic"
 by Victor Eijkhout.

 Note: While most SILE packages are completely self-contained, this one
 requires some support from the SILE core. We'll get to it later, but
 when the page builder comes across some of the magic boxes that are
 defined as part of insertions handling, it triggers a routine here
 which can alter the page builder's operation. So it is not really an
 optional package.

--]]

SILE.scratch.insertions = { classes = {} }

SILE.insertions = {}

SILE.settings.declare({
  name = "insertion.penalty",
  type = "integer",
  default = -3000,
  help = "Penalty to be applied before insertion"
})


--[[
The typical insertion is a footnote but we provide a generic mechanism for
handling any kind of insertion. An insertion is material which is added from
the main flow of the document into a specific area on the page, and where
moving such material alters the shape of the page.

Because this is a generic mechanism, each insertion is part of a "class"
(just like in TeX.); you may have several different classes putting insertions
in different places on the page. These classes also define how the page shape
is altered by the insertion. So, a class using the footnotes package may specify
that insertions get added into the `footnotes' frame and the space used up by
those insertions also reduces the 'content' frame. If you have two columns but
one footnote frame, then an insertion will steal space equal to half the
insertion's height from each column's frame. This is specified as:

  insertInto = "footnotes",
  stealFrom = { leftColumn = 0.5, rightColumn = 0.5 }

Insertion classes also need to define the maximum height they can stretch to,
the skip or box placed before the first insertion on a page, and the skip placed
between insertions.

--]]

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

  if type(options.insertInto) == "string" then options.insertInto = { frame = options.insertInto, ratio = 1} end

  options.maxHeight = SILE.length.make(options.maxHeight)

  SILE.scratch.insertions.classes[classname] = options
end

--[[

Each insertion class stores a page's worth of content in a box.
In some ways it's a fairly standard vbox, but it also knows its own
typesetter and frame.

--]]

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
    this.frame  = SILE.scratch.insertions.classes[class].insertInto.frame
    insertionsThisPage[class] = this
  end
  return insertionsThisPage[class]
end

--[[

An insertion vbox, on the other hand, is a place where insertion material
is held until we are sure it is going to end up on the current page. (We
might be consuming material that will eventually end up on a future page.)
So we stick the material into an insertion vbox, and when the pagebuilder
sees this, magic will happen.

--]]
local _insertionVbox = SILE.nodefactory.newVbox({
  __tostring = function(self) return "I<"..self.nodes[1].."...>" end,
  outputYourself = function(self) end,
  discardable = true,
  type = "insertionVbox",
  -- And some utility methods to make the insertion processing code
  -- easier to read.
  dropDiscardables = function (self)
    while #self.nodes > 1 and self.nodes[#self.nodes].discardable do
      self.nodes[#self.nodes] = nil
    end
  end,
  split = function(self, materialToSplit, maxsize)
    local s = SILE.pagebuilder.findBestBreak({
      vboxlist = materialToSplit,
      target   = maxsize.length,
      restart  = false,
      force    = true
    })
    if s then
      local newvbox = SILE.pagebuilder.collateVboxes(s)
      self.nodes = {}
      self.height = 0
      self:append(materialToSplit)
      self.contentHeight = self.height
      self.contentDepth = self.depth
      self.depth = 0
      self.height = 0
      return newvbox
    end
  end
})

--[[

Set up a value to track how much smaller/larger to make a frame.
We have to track this on the frame, because different insertion
classes might affect the same frame; so we can't track it per class.
We also have to ensure it's initialized every time because we might
be shrinking a frame further down the page that the typesetter hasn't
entered yet.

--]]

local initShrinkage = function (f)
  if not f.state.totals then f:init() end
  if not f.state.totals.shrinkage then f.state.totals.shrinkage = 0 end
end

--[[ Mark a frame for reduction. --]]

SILE.insertions.setShrinkage = function(classname, amount)
  local reduceList = SILE.scratch.insertions.classes[classname].stealFrom
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if f then
      initShrinkage(f)
      SU.debug("insertions", "Shrinking "..fName.." by "..amount.length*ratio)
      f.state.totals.shrinkage = f.state.totals.shrinkage + amount.length * ratio
    end
  end
end

--[[ Actually shrink the frame. --]]

SILE.insertions.commitShrinkage = function(classname)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  local stealPosition = opts["steal-position"] or "bottom"
  for fName, ratio in pairs(reduceList) do local f = SILE.getFrame(fName)
    if f then
      initShrinkage(f)
      local newHeight = f:height() - f.state.totals.shrinkage
      if stealPosition == "bottom" then f:relax("bottom") else f:relax("top") end
      SU.debug("insertions", "Constraining height of "..fName.." by "..f.state.totals.shrinkage.." to "..newHeight)
      f:constrain("height", newHeight)
      f.state.totals.shrinkage = 0
    end
  end
end

SILE.insertions.increaseInsertionFrame = function(classname, amount)
  local opts = SILE.scratch.insertions.classes[classname]
  SU.debug("insertions", "Increasing insertion frame by "..amount)
  local stealPosition = opts["steal-position"] or "bottom"
  local f = SILE.getFrame(opts["insertInto"].frame)
  local oldHeight = f:height()
  amount = (type(amount)=="table" and amount.length or amount)
  amount = amount * opts["insertInto"].ratio
  f:constrain("height", oldHeight + amount)
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
    local skipSize = options["interInsertionSkip"]
    skipSize = skipSize - stuffSoFar.nodes[#stuffSoFar.nodes].depth
    return SILE.nodefactory.newVglue({ height = skipSize })
  end
end

local debugInsertion = function(ins, insbox, topBox, target, targetFrame, totalHeight)
  if SU.debugging("insertions") then
    local h = ins.contentHeight + topBox.height + topBox.depth + ins.contentDepth
    io.stderr:write("[insertions]", "Incoming insertion")
    -- io.stderr:write("top box height", topBox.height)
    -- io.stderr:write("insertion", ins, ins.height, ins.depth)
    -- io.stderr:write("Total incoming height", h)
    -- io.stderr:write("Insertions already in this class ", insbox.height, insbox.depth)
    io.stderr:write("Page target ", target)
    io.stderr:write(totalHeight.." worth of content on page so far")
  end
end

local min = function (a,b) -- Defined funny to help Lua 5.1 compare overloaded tables
  return SILE.length.make(a).length < SILE.length.make(b).length and a or b
end

local pt = SILE.typesetter.pageTarget
SILE.typesetter.pageTarget = function (self)
  initShrinkage(self.frame)
  return pt(self) - self.frame.state.totals.shrinkage
end

--[[
  So, this is the magic routine called by the page builder to determine what
  do to when an insertion is seen in the vertical list. The key design issue
  about this routine is that it needs to be very careful about state; it may
  end up processing the same list different times. (if the current list of
  vertical items is not tall enough to cause a page break yet) So it should
  not commit itself to anything yet. Another interesting complication is that
  when the page builder restarts, for optimization purposes it is at liberty
  to restart its calculations half-way through the list. So you can't
  completely forget the insertions that you've seen either.

  However, one mitigating factor is: if an insertion fits on the current page,
  it will end up on the current page. So if you've seen an insertion and it
  fits, you can commit to it at this point. If at some later date we have
  page builders which reflow multiple pages, then this may not be true.

  The main job is this routine is to make a decision about whether the
  upcoming insertion can fit on the page; if it needs to be split; or if it
  should not appear on this page at all (and hence force the line which
  caused the insertion off the page as well).

--]]

SILE.insertions.processInsertion = function (vboxlist, i, totalHeight, target)
  local ins = vboxlist[i]
  if ins.seen then return target end
  local targetFrame = SILE.getFrame(ins.frame)
  local options = SILE.scratch.insertions.classes[ins.class]
  totalHeight = totalHeight.length

  ins:dropDiscardables()

  -- We look into the page's insertion box and choose the appropriate skip,
  -- so we know how high the whole insertion is.
  local topBox = nextInterInsertionSkip(ins.class)
  local h = ins.contentHeight + topBox.height + topBox.depth + ins.contentDepth

  local insbox = thisPageInsertionBoxForClass(ins.class)
  initShrinkage(targetFrame)
  initShrinkage(SILE.typesetter.frame)

  debugInsertion(ins, insbox, topBox, target, targetFrame, totalHeight)

  local effectOnThisFrame = options.stealFrom[SILE.typesetter.frame.id]
  if effectOnThisFrame then effectOnThisFrame = effectOnThisFrame * h.length
  else effectOnThisFrame = 0 end

  local newTarget = target - effectOnThisFrame

  -- We only fit if:
  -- the effect of the insertion on this frame doesn't take us over the page target
  -- and this doesn't take the target frame over the max height.

  if not (totalHeight + effectOnThisFrame > target) and
    not ((insbox.height + h).length > options.maxHeight.length) then
    SU.debug("insertions", "fits")
    SILE.insertions.setShrinkage(ins.class, h)
    insbox:append(topBox)
    insbox:append(ins)
    ins.seen = true
    return newTarget
  end

  -- OK, we didn't fit. So now we have to split the insertion to fit the height
  -- we have within the insertion frame.
  SU.debug("insertions", "splitting")
  local maxsize = min(target - totalHeight, options.maxHeight)

  -- If we're going to fit this insertion on the page, we will use the
  -- whole of topbox, so let's subtract the height of that now.
  -- The remaining height will be the amount of inserted material that we
  -- intend to put on this page.
  maxsize = maxsize - topBox.height
  local materialToSplit = {}
  table.append(materialToSplit, ins:unbox())
  local newvbox = ins:split(materialToSplit, maxsize)

  if newvbox then
    SU.debug("insertions", "Split. Remaining insertion is ".. ins)
    SILE.insertions.setShrinkage(ins.class, topBox.height + newvbox.height + newvbox.depth)
    insbox:append(topBox)
    -- newvbox.contentHeight = newvbox.height
    -- newvbox.contentDepth = newvbox.depth
    insbox:append(newvbox)
    newvbox.seen = true

    --[[ The insertion we're dealing with is currently vboxlist[i], and it
    now contains all the material that *didn't* make it onto the current
    page. We've dealt with the material that did fit on the page. We want
    the page builder to a) break the page immediately here - it's full by
    definition, or else we would not have needed to split (XXX This is not
    true, because we might not be stealing from the current frame.) and
    then b) retry the remaining material. By inserting a penalty into the
    vboxlist, when we return from here the pagebuilder will first consider
    the penalty (and break the page) and then consider the rest of the
    insertion. --]]

    table.insert(vboxlist, i, SILE.nodefactory.newPenalty({penalty = -20000 }))
    return target -- Who cares? The penalty is going to cause a split.
  end

  --[[ We couldn't even split the insertion.

  Assume that previously we have seen these nodes on the vboxlist:

    i-2 \vbox{Hello world. I am a footnote mark: 1}
    i-1 \vglue
    i   \insertionbox{1. Footnote}

  This insertion couldn't fit on the page at all. Therefore we need to
  take both the footnote *and* the previous vbox (from which the
  insertion has been migrated) onto a new page. The way we achieve this
  is by finding the most recent vbox and then continually inserting page
  break penalties, pushing the insertion and vbox further down the list
  until they are the next things to be considered. The end result of the
  vboxlist will be:

    i-2 \penalty
    i-1 \penalty
    i   \penalty <- considered now when we return to pagebuilder
    i+1 \vbox{Hello world. I am a footnote mark: 1}
    i+2 \vglue
    i+3 \insertionbox{1. Footnote}

  The page will be broken right now, and the old vbox will no longer
  be part of the material to be output on the page. The new page will
  start with the vbox and the insertion.

  --]]
  local lastbox = i
  while not vboxlist[lastbox]:isVbox() do lastbox = lastbox - 1 end
  while not (vboxlist[i]:isPenalty() and vboxlist[i].penalty == -20000) do
    table.insert(vboxlist, lastbox, SILE.nodefactory.newPenalty({penalty = -20000 }))
  end
  return target
end

SILE.typesetter:registerFrameBreakHook(function (self,nl)
  for class, list in pairs(insertionsThisPage) do
    SILE.insertions.commitShrinkage(class)
  end
  return nl
end)

SILE.typesetter:registerPageEndHook(function (self,nl)
  for class, list in pairs(insertionsThisPage) do
    SILE.insertions.increaseInsertionFrame(class, list.height + list.depth)
  end
  for k,v in pairs(insertionsThisPage) do
    v:outputYourself()
    insertionsThisPage[k] = nil
  end
  if SU.debugging("insertions") then
    for k,v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
  end
  return nl
end)

-- This just puts the insertion vbox into the typesetter's queues.
local insert = function (self, classname, vbox)
  local thisclass = SILE.scratch.insertions.classes[classname]
  if not thisclass then SU.error("Uninitialized insertion class "..classname) end
  SILE.typesetter:pushMigratingMaterial({
    SILE.nodefactory.newPenalty({ penalty = SILE.settings.get("insertion.penalty") })
  })
  SILE.typesetter:pushMigratingMaterial({
    _insertionVbox {
        class = classname,
        nodes = vbox.nodes,
        -- actual height and depth must remain zero for page glue calculations
        contentHeight = vbox.height,
        contentDepth = vbox.depth,
        frame = thisclass.insertInto.frame,
        parent = SILE.typesetter.frame
      }
  })
end

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
  }
}
