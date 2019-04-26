
local inlineOutputter = function (self,typesetter,line)
  local top = typesetter.frame.state.cursorY -- XXX
  local left = typesetter.frame.state.cursorX -- XXX
  local initial = true
  for i,node in pairs(self.nodes) do
    if not (initial and (node:isGlue() or node:isPenalty())) then
      initial = false
      node:outputYourself(typesetter, node)
      typesetter.frame.state.cursorX = left
    end
  end
  typesetter.frame:advancePageDirection(self.height.length * -1)
  typesetter.frame:advanceWritingDirection(self.width.length)
end

local sumHeightOfList = function(vboxes, from, to)
  if from  == nil then from = 1 end
  if to  == nil then to = #vboxes end
  local h = 0
  for i = from,to do
    h = h + vboxes[i].height + vboxes[i].depth
  end
  return SILE.length.make(h)
end

local correctGlues = function(vboxes, height)
  SILE.typesetter:setVerticalGlue(vboxes,height)
  return sumHeightOfList(vboxes)
end

local splitVbox = function(vboxes,cols, target)
  local splits = {}
  local breaks = SILE.linebreak:doBreak( vboxes, target.length, true)
  if #breaks < cols then breaks[#breaks+1] = {position = #vboxes-1} end
  local first = 1
  local maxheight = 0
  local last = 0
  for i = 1, cols do
    while vboxes[first]:isVglue() do first = first + 1 end
    local thisbreak = breaks[i].position
    if i == #breaks then
      thisbreak = #vboxes
    end
    while vboxes[thisbreak]:isVglue() do thisbreak = thisbreak - 1 end
    splits[#splits+1] = {first, thisbreak}
    local thisheight = sumHeightOfList(vboxes, first, thisbreak)
    if thisheight > maxheight then maxheight = thisheight end
    first = thisbreak+1
    last = thisbreak
    if first > #vboxes then break end
  end
  if maxheight > target then maxheight = target end
  return splits, maxheight, last
end

local balanceSplit = function (vboxes, cols)
  local height = sumHeightOfList(vboxes)
  return splitVbox(vboxes, cols, height / cols)
end

local remainingSplit = function (vboxes, cols, heightSoFar)
  local heightAvail = SILE.typesetter.frame:pageTarget() - heightSoFar
  heightAvail = SILE.length.make(heightAvail.length + heightAvail.stretch)
  return splitVbox(vboxes, cols, heightAvail)
end

SILE.registerCommand("columns", function(options,content)
  SILE.typesetter:leaveHmode()
  local heightSoFar = SILE.pagebuilder.collateVboxes(SILE.typesetter.state.outputQueue).height
  local numcols = tonumber(SU.required(options, "number", "setting up columns"))
  local balanced = options.balanced and true or false
  local gutter = SILE.length.parse(SU.required(options, "gutter", "setting up columns")):absolute()
  -- Later we'll do variable width columns. Not today.
  local fw = SILE.typesetter.frame:width()
  local gutterSkip = SILE.nodefactory.newGlue({width = gutter })
  local colwidth = (fw - gutter * (numcols-1))/numcols
  local vboxlist
  local splitAt
  SILE.typesetter:pushState()
  local pb = SILE.typesetter.pageBuilder
  SILE.typesetter.pageBuilder = function () return false end
  SILE.settings.temporarily(function()
    SILE.settings.set("typesetter.breakwidth", colwidth)
    SILE.process(content)
    SILE.typesetter:leaveHmode(true)
    vboxlist = SILE.typesetter.state.outputQueue
  end)
  SILE.typesetter.pageBuilder = pb
  SILE.typesetter:popState()

  ::again::
  local splits, last
  if balanced then
    splits, height, last = balanceSplit(vboxlist, numcols)
  else
    splits, height, last = remainingSplit(vboxlist, numcols, heightSoFar)
  end

  SILE.call("noindent")
  for i = 1,#splits do
    local nstart = splits[i][1]
    local nend = splits[i][2]
    local output = SILE.nodefactory.newVbox({nodes = {} })
    local vboxes = {}
    for j = nstart,nend do
      vboxes[j-nstart+1] = vboxlist[j]
      output:append(vboxlist[j])
    end
    output.height = correctGlues(vboxes, height)
    output.depth = (height - output.height).length
    output.width = colwidth
    output.outputYourself = inlineOutputter
    SILE.typesetter:pushHorizontal(output)
    if i <= #splits then
      SILE.typesetter:pushHorizontal(gutterSkip)
    end
  end
  SILE.typesetter:leaveHmode()
  SILE.typesetter:pushVpenalty({ penalty = -10000 })
  SILE.typesetter:pushVglue({ height = height })
  if last < #vboxlist and #vboxlist > 0 then -- More to do.
    local remainder = {}
    for i = last+1,#vboxlist do remainder[#remainder+1] = vboxlist[i] end
    vboxlist = remainder
    goto again
  end
end)
