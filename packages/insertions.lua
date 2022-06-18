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

if not SILE.scratch.insertions then
  SILE.scratch.insertions = { classes = {} }
end

if not SILE.insertions then
  SILE.insertions = {}
end

SILE.settings:declare({
  parameter = "insertion.penalty",
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

local initInsertionClass = function (_, classname, options)
  SU.required(options, "insertInto", "initializing insertions")
  SU.required(options, "stealFrom", "initializing insertions")
  SU.required(options, "maxHeight", "initializing insertions")
  if not options.topSkip and not options.topBox then
    SU.required(options, "topSkip", "initializing insertions")
  end

  -- Turn stealFrom into a hash, if it isn't one.
  if SU.type(options.stealFrom) ~= "table" then
    options.stealFrom = { options.stealFrom }
  end
  if options.stealFrom[1] then
    local rl = {}
    for i = 1, #(options.stealFrom) do rl[options.stealFrom[i]] = 1 end
    options.stealFrom = rl
  end

  if SU.type(options.insertInto) ~= "table" then
    options.insertInto = { frame = options.insertInto, ratio = 1 }
  end

  options.maxHeight = SILE.length(options.maxHeight)

  SILE.scratch.insertions.classes[classname] = options
end

--[[

Each insertion class stores a page's worth of content in a box.
In some ways it's a fairly standard vbox, but it also knows its own
typesetter and frame.

--]]

local insertionsThisPage = {}
SILE.nodefactory.insertionlist = pl.class(SILE.nodefactory.vbox)

SILE.nodefactory.insertionlist.type = "insertionlist"
SILE.nodefactory.insertionlist.frame = nil

function SILE.nodefactory.insertionlist:_init (spec)
  SILE.nodefactory.vbox._init(self, spec)
  self.typesetter = SILE.defaultTypesetter()
end

function SILE.nodefactory.insertionlist:__tostring ()
  return "PI<" .. self.nodes .. ">"
end

function SILE.nodefactory.insertionlist:outputYourself ()
  self.typesetter:initFrame(SILE.getFrame(self.frame))
  for _, node in ipairs(self.nodes) do
    node:outputYourself(self.typesetter, node)
  end
end

local thisPageInsertionBoxForClass = function (class)
  if not insertionsThisPage[class] then
    insertionsThisPage[class] = SILE.nodefactory.insertionlist({
      frame = SILE.scratch.insertions.classes[class].insertInto.frame
    })
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
SILE.nodefactory.insertion = pl.class(SILE.nodefactory.vbox)

SILE.nodefactory.insertion.discardable = true
SILE.nodefactory.insertion.type = "insertion"
SILE.nodefactory.insertion.seen = false

function SILE.nodefactory.insertion:__tostring ()
  return "I<"..self.nodes[1].."...>"
end

function SILE.nodefactory.insertion.outputYourself (_)
end

-- And some utility methods to make the insertion processing code
-- easier to read.
function SILE.nodefactory.insertion:dropDiscardables ()
  while #self.nodes > 1 and self.nodes[#self.nodes].discardable do
    self.nodes[#self.nodes] = nil
  end
end

function SILE.nodefactory.insertion:split (materialToSplit, maxsize)
  local firstpage = SILE.pagebuilder:findBestBreak({
      vboxlist = materialToSplit,
      target   = maxsize,
      restart  = false,
      force    = true
    })
  if firstpage then
    self.nodes = {}
    self:append(materialToSplit)
    self.contentHeight = self.height
    self.contentDepth = self.depth
    self.depth = SILE.length(0)
    self.height = SILE.length(0)
    return SILE.pagebuilder:collateVboxes(firstpage)
  end
end

--[[

Set up a value to track how much smaller/larger to make a frame.
We have to track this on the frame, because different insertion
classes might affect the same frame; so we can't track it per class.
We also have to ensure it's initialized every time because we might
be shrinking a frame further down the page that the typesetter hasn't
entered yet.

--]]

local initShrinkage = function (frame)
  if not frame.state or not frame.state.totals then frame:init() end
  if not frame.state.totals.shrinkage then frame.state.totals.shrinkage = SILE.measurement(0) end
end

--[[ Mark a frame for reduction. --]]

SILE.insertions.setShrinkage = function (classname, amount)
  local reduceList = SILE.scratch.insertions.classes[classname].stealFrom
  for fName, ratio in pairs(reduceList) do
    local frame = SILE.getFrame(fName)
    if frame then
      initShrinkage(frame)
      SU.debug("insertions", "Shrinking " .. fName .. " by " .. tostring(amount * ratio))
      frame.state.totals.shrinkage = frame.state.totals.shrinkage + amount * ratio
    end
  end
end

--[[ Actually shrink the frame. --]]

SILE.insertions.commitShrinkage = function (_, classname)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  local stealPosition = opts["steal-position"] or "bottom"
  for fName, _ in pairs(reduceList) do
    local frame = SILE.getFrame(fName)
    if frame then
      initShrinkage(frame)
      local newHeight = frame:height() - frame.state.totals.shrinkage
      if stealPosition == "bottom" then frame:relax("bottom") else frame:relax("top") end
      SU.debug("insertions", "Constraining height of " .. fName .. " by " .. frame.state.totals.shrinkage .. " to " .. newHeight)
      frame:constrain("height", newHeight)
      frame.state.totals.shrinkage = SILE.measurement(0)
    end
  end
end

SILE.insertions.increaseInsertionFrame = function (insertionvbox, classname)
  local amount = insertionvbox.height + insertionvbox.depth
  local opts = SILE.scratch.insertions.classes[classname]
  SU.debug("insertions", "Increasing insertion frame by " .. tostring(amount))
  local stealPosition = opts["steal-position"] or "bottom"
  local insertionFrame = SILE.getFrame(opts["insertInto"].frame)
  local oldHeight = insertionFrame:height()
  amount = amount * opts["insertInto"].ratio
  insertionFrame:constrain("height", oldHeight + amount)
  if stealPosition == "bottom" then insertionFrame:relax("top") end
  SU.debug("insertions", "New height is now " .. insertionFrame:height())
end

local nextInterInsertionSkip = function (class)
  local options = SILE.scratch.insertions.classes[class]
  local stuffSoFar = thisPageInsertionBoxForClass(class)
  if #stuffSoFar.nodes == 0 then
    if options["topBox"] then
      return options["topBox"]:absolute()
    elseif options["topSkip"] then
      return SILE.nodefactory.vglue(options["topSkip"]:tonumber())
    end
  else
    local skipSize = options["interInsertionSkip"]:tonumber()
    skipSize = skipSize - stuffSoFar.nodes[#stuffSoFar.nodes].depth:tonumber()
    return SILE.nodefactory.vglue(skipSize)
  end
end

local debugInsertion = function (ins, insbox, topBox, target, targetFrame, totalHeight)
  local insertionsHeight = ins.contentHeight:absolute() + topBox.height:absolute() + topBox.depth:absolute() + ins.contentDepth:absolute()
  SU.debug("insertions", "## Incoming insertion")
  SU.debug("insertions", "Top box height", topBox.height)
  SU.debug("insertions", "Insertion", ins, ins.height, ins.depth)
  SU.debug("insertions", "Total incoming height", insertionsHeight)
  SU.debug("insertions", "Insertions already in this class ", insbox.height, insbox.depth)
  SU.debug("insertions", "Page target ", target)
  SU.debug("insertions", "Page frame ", targetFrame)
  SU.debug("insertions", tostring(totalHeight) .. " worth of content on page so far")
end

local function init (_, _)

  local typesetter = SILE.typesetter

  if not typesetter.noinsertion_getTargetLength then
    typesetter.noinsertion_getTargetLength = typesetter.getTargetLength
    typesetter.getTargetLength = function (self)
      initShrinkage(self.frame)
      return typesetter.noinsertion_getTargetLength(self) - self.frame.state.totals.shrinkage
    end
  end

  typesetter:registerFrameBreakHook(function (_, nodelist)
    pl.tablex.foreach(insertionsThisPage, SILE.insertions.commitShrinkage)
    return nodelist
  end)

  typesetter:registerPageEndHook(function (_)
    pl.tablex.foreach(insertionsThisPage, SILE.insertions.increaseInsertionFrame)
    for class, insertionlist in pairs(insertionsThisPage) do
      insertionlist:outputYourself()
      insertionsThisPage[class] = nil
    end
    if SU.debugging("insertions") then
      for _, frame in pairs(SILE.frames) do SILE.outputter:debugFrame(frame) end
    end
  end)

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

  ins:dropDiscardables()

  -- We look into the page's insertion box and choose the appropriate skip,
  -- so we know how high the whole insertion is.
  local topBox = nextInterInsertionSkip(ins.class)
  local insertionsHeight = SILE.length()
  insertionsHeight:___add(ins.contentHeight)
  insertionsHeight:___add(topBox.height)
  insertionsHeight:___add(topBox.depth)
  insertionsHeight:___add(ins.contentDepth)

  local insbox = thisPageInsertionBoxForClass(ins.class)
  initShrinkage(targetFrame)
  initShrinkage(SILE.typesetter.frame)

  if SU.debugging("insertions") then
    debugInsertion(ins, insbox, topBox, target, targetFrame, totalHeight)
  end

  local effectOnThisFrame = options.stealFrom[SILE.typesetter.frame.id]
  if effectOnThisFrame then effectOnThisFrame = insertionsHeight * effectOnThisFrame
  else effectOnThisFrame = SILE.measurement(0) end

  local newTarget = target - effectOnThisFrame

  -- We only fit if:
  -- the effect of the insertion on this frame doesn't take us over the page target
  -- and this doesn't take the target frame over the max height.

  if totalHeight + effectOnThisFrame <= target and
    insbox.height + insertionsHeight <= options.maxHeight then
    SU.debug("insertions", "fits")
    SILE.insertions.setShrinkage(ins.class, insertionsHeight)
    insbox:append(topBox)
    insbox:append(ins)
    ins.seen = true
    return newTarget
  end

  -- OK, we didn't fit. So now we have to split the insertion to fit the height
  -- we have within the insertion frame.
  SU.debug("insertions", "splitting")
  local maxsize = SU.min(target - totalHeight, options.maxHeight)

  -- If we're going to fit this insertion on the page, we will use the
  -- whole of topbox, so let's subtract the height of that now.
  -- The remaining height will be the amount of inserted material that we
  -- intend to put on this page.
  maxsize = maxsize - topBox.height
  local materialToSplit = {}
  pl.tablex.insertvalues(materialToSplit, ins:unbox())
  local deferredInsertions = ins:split(materialToSplit, maxsize)

  if deferredInsertions then
    SU.debug("insertions", "Split. Remaining insertion is " .. ins)
    SILE.insertions.setShrinkage(ins.class, topBox.height:absolute() + deferredInsertions.height:absolute() + deferredInsertions.depth:absolute())
    insbox:append(topBox)
    -- deferredInsertions.contentHeight = deferredInsertions.height
    -- deferredInsertions.contentDepth = deferredInsertions.depth
    insbox:append(deferredInsertions)
    deferredInsertions.seen = true

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

    table.insert(vboxlist, i, SILE.nodefactory.penalty(-20000))
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
  while not vboxlist[lastbox].is_vbox do lastbox = lastbox - 1 end
  while not (vboxlist[i].is_penalty and vboxlist[i].penalty == -20000) do
    table.insert(vboxlist, lastbox, SILE.nodefactory.penalty(-20000))
  end
  return target
end

-- This just puts the insertion vbox into the typesetter's queues.
local insert = function (_, classname, vbox)
  local insertion = SILE.scratch.insertions.classes[classname]
  if not insertion then SU.error("Uninitialized insertion class " .. classname) end
  SILE.typesetter:pushMigratingMaterial({
      SILE.nodefactory.penalty(SILE.settings:get("insertion.penalty"))
    })
  SILE.typesetter:pushMigratingMaterial({
      SILE.nodefactory.insertion({
          class = classname,
          nodes = vbox.nodes,
          -- actual height and depth must remain zero for page glue calculations
          contentHeight = vbox.height,
          contentDepth = vbox.depth,
          frame = insertion.insertInto.frame,
          parent = SILE.typesetter.frame
        })
    })
end

return {
  init = init,
  exports = {
    initInsertionClass = initInsertionClass,
    thisPageInsertionBoxForClass = thisPageInsertionBoxForClass,
    insert = insert,
  },
  documentation = [[
\begin{document}
The \autodoc:package{footnotes} package works by taking auxiliary material (the
footnote content), shrinking the current frame and inserting it into the
footnote frame. This is powered by the \autodoc:package{insertions} package; it doesn’t
provide any user-visible SILE commands, but provides Lua functionality to
other packages. TeX wizards may be interested to realise that insertions are
implemented by an external add-on package, rather than being part of the SILE core.
\end{document}
]]
}
