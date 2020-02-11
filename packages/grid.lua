-- TODO: Should be registered as a setting not hidden as a package variable
local gridSpacing = SILE.measurement()

local function makeUp (totals)
  local toadd = gridSpacing - totals.gridCursor % gridSpacing
  totals.gridCursor = totals.gridCursor + toadd
  SU.debug("typesetter", "Makeup height = " .. toadd)
  return SILE.nodefactory.vglue(toadd)
end

local function leadingFor (typesetter, vbox, previous)
  SU.debug("typesetter", "   Considering leading between two lines (grid mode):")
  SU.debug("typesetter", "   1) "..previous)
  SU.debug("typesetter", "   2) "..vbox)
  if not previous then return SILE.nodefactory.vglue() end
  SU.debug("typesetter", "   Depth of previous line was " .. previous.depth)
  local totals = typesetter.frame.state.totals
  local oldCursor = totals.gridCursor
  totals.gridCursor = totals.gridCursor + vbox.height:absolute() + previous.depth
  SU.debug("typesetter", "   Cursor change = " .. totals.gridCursor - oldCursor)
  return makeUp(typesetter.frame.state.totals)
end

local function pushVglue (typesetter, spec)
  -- if SU.type(spec) ~= "table" then SU.warn("Please use pushVertical() to pass a premade node instead of a spec") end
  local node = SU.type(spec) == "vglue" and spec or SILE.nodefactory.vglue(spec)
  node.height.stretch = SILE.measurement()
  node.height.shrink = SILE.measurement()
  local totals = typesetter.frame.state.totals
  totals.gridCursor = totals.gridCursor + SILE.measurement(node.height):absolute()
  typesetter:pushVertical(node)
  typesetter:pushVertical(makeUp(typesetter.frame.state.totals))
  return node
end

local function pushExplicitVglue (typesetter, spec)
  -- if SU.type(spec) ~= "table" then SU.warn("Please use pushVertical() to pass a premade node instead of a spec") end
  local node = SU.type(spec) == "vglue" and spec or SILE.nodefactory.vglue(spec)
  node.explicit = true
  node.discardable = false
  node.height.stretch = SILE.measurement()
  node.height.shrink = SILE.measurement()
  local totals = typesetter.frame.state.totals
  totals.gridCursor = totals.gridCursor + SILE.measurement(node.height):absolute()
  typesetter:pushVertical(node)
  typesetter:pushVertical(makeUp(typesetter.frame.state.totals))
  return node
end

local function startGridInFrame (typesetter)
  local queue = typesetter.state.outputQueue
  typesetter.frame.state.totals.gridCursor = SILE.measurement(0)
  if #queue == 0 then
    typesetter.state.previousVbox = typesetter:pushVbox()
    return
  end
  while queue[1] and queue[1].discardable do
    table.remove(queue, 1)
  end
  if queue[1] then
    table.insert(queue, 1, SILE.nodefactory.vbox())
    table.insert(queue, 2, SILE.typesetter:leadingFor(queue[2], queue[1]))
  end
end

local function saveGridCursor (typesetter)
  -- TODO: fix the assumption that top() is the anchor for the page advance direction
  SILE.scratch.savedGridCursor = typesetter.frame:top() + typesetter.frame.state.totals.gridCursor
  SU.debug("que", "save")
end

local function restoreGridCursor (typesetter)
  local currentCursor = typesetter.frame:top() + typesetter.frame.state.totals.gridCursor
  typesetter.frame.state.totals.gridCursor = currentCursor - SILE.scratch.savedGridCursor
  SU.debug("que", "restore", currentCursor, SILE.scratch.savedGridCursor)
end

local function debugGrid ()
  local frame = SILE.typesetter.frame
  local gridCursor = gridSpacing
  while SILE.measurement(gridCursor) < SILE.measurement(frame:height()) do
    SILE.outputter.rule(frame:left(), frame:top() + gridCursor, frame:width(), 0.1)
    gridCursor = gridCursor + gridSpacing
  end
end

local gridPagebuilder = pl.class({
    _base = require("core/pagebuilder"),

    findBestBreak = function (_, options)
      local vboxlist = SU.required(options, "vboxlist", "in findBestBreak")
      local target   = SU.required(options, "target", "in findBestBreak")
      local i = 0
      local totalHeight = SILE.length()
      local bestBreak = 0
      SU.debug("pagebuilder", "Page builder for frame "..SILE.typesetter.frame.id.." called with "..#vboxlist.." nodes, "..target)
      if SU.debugging("vboxes") then
        for j, box in ipairs(vboxlist) do
          SU.debug("vboxes", (j == i and " >" or "  ") .. j .. ": " .. box)
        end
      end
      while i < #vboxlist do
        i = i + 1
        if not vboxlist[i].is_vglue then
          i = i - 1
          break
        end
      end
      while i < #vboxlist do
        i = i + 1
        local node = vboxlist[i]
        SU.debug("pagebuilder", "Dealing with VBox " .. node)
        if node.is_vbox then
          totalHeight = totalHeight + node.height:absolute() + node.depth:absolute()
        elseif node.is_vglue then
          totalHeight = totalHeight + node.height:absolute()
        elseif node.is_insertion then
          -- TODO: refactor as hook and without side effects!
          target = SILE.insertions.processInsertion(vboxlist, i, totalHeight, target)
          node = vboxlist[i]
        end
        local left = target - totalHeight
        local _left = left:tonumber()
        SU.debug("pagebuilder", "I have " .. left .. "left")
        SU.debug("pagebuilder", "totalHeight " .. totalHeight .. " with target " .. target)
        local badness = 0
        if _left < 0 then badness = 1000000 end
        if node.is_penalty then
          if node.penalty < -3000 then badness = 100000
          else badness = -_left * _left - node.penalty
          end
        end
      if badness > 0 then
        local onepage = {}
        for j = 1, bestBreak do
          onepage[j] = table.remove(vboxlist, 1)
        end
        while #onepage > 1 and onepage[#onepage].discardable do
          onepage[#onepage] = nil
        end
        return onepage, 1000
      end
      bestBreak = i
    end
    return false, false
  end
})

local oldPageBuilder, oldLeadingFor, oldPushVglue, oldPushExplicitVglue

SILE.registerCommand("grid:debug", function (_, _)
  debugGrid()
  SILE.typesetter:registerHook("afternextframe", debugGrid)
end)

SILE.registerCommand("grid", function (options, _)
  SILE.typesetter.state.grid = true
  SU.required(options, "spacing", "grid package")
  gridSpacing = SILE.parseComplexFrameDimension(options.spacing)
  oldPageBuilder = SILE.pagebuilder
  SILE.pagebuilder = gridPagebuilder()
  oldLeadingFor = SILE.typesetter.leadingFor
  SILE.typesetter.leadingFor = leadingFor
  oldPushVglue = SILE.typesetter.pushVglue
  SILE.typesetter.pushVglue = pushVglue
  oldPushExplicitVglue = SILE.typesetter.pushExplicitVglue
  SILE.typesetter.pushExplicitVglue = pushExplicitVglue
  if SILE.typesetter.frame then
    startGridInFrame(SILE.typesetter)
  end
  SILE.typesetter:registerHook("beforesplitframe", saveGridCursor)
  SILE.typesetter:registerHook("afternextframe", startGridInFrame)
  SILE.typesetter:registerHook("aftersplitframe", restoreGridCursor)
end, "Begins typesetting on a grid spaced at <spacing> intervals.")

SILE.registerCommand("no-grid", function (_, _)
  SILE.typesetter.state.grid = false
  SILE.typesetter.leadingFor = oldLeadingFor
  SILE.typesetter.pushVglue = oldPushVglue
  SILE.typesetter.pushExplicitVglue = oldPushExplicitVglue
  SILE.pagebuilder = oldPageBuilder
end, "Stops grid typesetting.")
