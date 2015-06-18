local breakFrameVertical = function(after)
  local cFrame = SILE.typesetter.frame
  if after then
    totalHeight = after
  else
    totalHeight = 0
    SILE.typesetter:leaveHmode(1)
    local q = SILE.typesetter.state.outputQueue
    for i=1,#q do
      totalHeight = totalHeight + q[i].height + q[i].depth
    end
    SILE.typesetter:chuck()
  end

  if type(totalHeight) == "table" then totalHeight= totalHeight.length end

  local newFrame = SILE.newFrame({
    bottom = cFrame:bottom(),
    left = cFrame:left(),
    right = cFrame:right(),
    next = cFrame.next,
    previous = cFrame,
    id = cFrame.id .. "_"
  })

  cFrame:relax("bottom")
  cFrame:constrain("height", totalHeight)
  cFrame.next = newFrame.id
  SILE.documentState.thisPageTemplate.frames[newFrame.id] = newFrame
  newFrame:constrain("top", cFrame:top() + totalHeight)
  if (after) then
    SILE.typesetter:initFrame(cFrame)
  else
    SILE.typesetter:initFrame(newFrame)
  end
  -- SILE.outputter:debugFrame(cFrame)
  -- SILE.outputter:debugFrame(newFrame)
end

local breakFrameHorizontalAt = function (offset)
  local cFrame = SILE.typesetter.frame
  if not offset or not (offset > 0) then
    SILE.typesetter:chuck()
    offset = SILE.typesetter.frame.state.cursorX
  end
  local newFrame = SILE.newFrame({
    bottom = cFrame:bottom(),
    top = cFrame:top(),
    left = cFrame:left() + offset,
    right = cFrame:right(),
    next = cFrame.next,
    previous = cFrame,
    id = cFrame.id .. "_"
  })
  local oldLeft = cFrame:left()
  cFrame.next = newFrame.id
  cFrame:constrain("left", oldLeft)
  cFrame:constrain("right", oldLeft + offset)
  -- SILE.outputter:debugFrame(cFrame)
  -- SILE.outputter:debugFrame(newFrame)
  SILE.typesetter:initFrame(newFrame)
end

local shiftframeedge = function(frame, options)
  if options.left then
    frame:constrain("left", frame:left() + SILE.length.parse(options.left).length)
  end
  if options.right then
    frame:constrain("right", frame:right() + SILE.length.parse(options.right).length)
  end
end

local makecolumns = function (options)
  local cFrame = SILE.typesetter.frame
  local cols = options.columns or 2
  local gutterWidth = options.gutter or "3%"
  local right = cFrame:right()
  local origId = cFrame.id
  for i = 1,cols-1 do
    local gutter = SILE.newFrame({
      width = gutterWidth,
      left = "right("..cFrame.id..")",
      id = origId .. "_gutter" ..i
    })
    cFrame:relax("right")
    cFrame:constrain("right", "left("..gutter.id..")")
    local newFrame = SILE.newFrame({
      top = cFrame:top(),
      bottom = cFrame:bottom(),
      id = origId .. "_col"..i
    })
    gutter:constrain("right", "left("..newFrame.id..")")
    newFrame:constrain("left", "right("..gutter.id..")")
    newFrame:constrain("width", "width("..cFrame.id..")") -- XXX
    cFrame.next = newFrame.id
    cFrame = newFrame
  end
  cFrame:constrain("right", right)
end

SILE.registerCommand("showframe", function(options, content)
  local id = options.id or SILE.typesetter.frame.id
  if id == "all" then
    for _,f in pairs(SILE.frames) do
      SILE.outputter:debugFrame(f)
    end
  else
    SILE.outputter:debugFrame(SILE.getFrame(id))
  end
end)

SILE.registerCommand("shiftframeedge", function(options, content)
  local cFrame = SILE.typesetter.frame
  shiftframeedge(cFrame, options)
  SILE.typesetter:initFrame(cFrame)
  --SILE.outputter:debugFrame(cFrame)
end, "Adjusts the edge of the frame horizontally by amounts specified in <left> and <right>")

SILE.registerCommand("breakframevertical", function ( options, content )
  breakFrameVertical(options.offset and SILE.length.parse(options.offset).length)
end, "Breaks the current frame in two vertically at the current location or at a point <offset> below the current location")

SILE.registerCommand("makecolumns", function ( options, content )
  makecolumns(options)
end, "Split the current frame into multiple columns")

SILE.registerCommand("breakframehorizontal", function ( options, content )
  breakFrameHorizontalAt(options.offset and SILE.length.parse(options.offset).length)
end, "Breaks the current frame in two horizontally either at the current location or at a point <offset> from the left of the current frame")

SILE.registerCommand("float", function(options, content)
  breakFrameVertical()
  SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
  local hbox = SILE.Commands["hbox"]({}, content)
  table.remove(SILE.typesetter.state.nodes) -- steal it back
  local boundary = hbox.width.length + SILE.length.parse(options.rightboundary).length
  breakFrameHorizontalAt(boundary)
  SILE.typesetNaturally(SILE.typesetter.frame.previous, function()
    table.insert(SILE.typesetter.state.nodes,hbox)
  end)
  local undoSkip = SILE.length.new({}) - SILE.settings.get("document.baselineskip").height.length + SILE.length.parse("1ex")
  undoSkip.stretch = hbox.height
  SILE.typesetter:pushHbox({value = {}})
  -- SILE.typesetter:pushVglue({height = undoSkip })
  breakFrameVertical(hbox.height + SILE.length.parse(options.bottomboundary).length)
  shiftframeedge(SILE.getFrame(SILE.typesetter.frame.next), {left = ""..tostring(SILE.length.new() - boundary)})
  --SILE.outputter:debugFrame(SILE.typesetter.frame)
  SILE.settings.set("current.parindent", SILE.settings.get("document.parindent"))
end, "Sets the given content in its own frame, flowing the remaining content around it")

SILE.registerCommand("typeset-into", function(options,content)
  SU.required(options, "frame", "calling \\typeset-into")
  if not SILE.frames[options.frame] then
    SU.error("Can't find frame "..options.frame.." to typeset into")
  end
  SILE.typesetter:chuck()
  SILE.typesetNaturally(SILE.frames[options.frame], function() SILE.process(content) end)
end)

return {
  init = function () end,
  exports = {
    breakFrameVertical = breakFrameVertical
  }
}
