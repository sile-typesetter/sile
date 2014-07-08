local breakFrameVertical = function()
  local cFrame = SILE.typesetter.frame
  SILE.typesetter:leaveHmode(1)
  totalHeight = 0
  local q = SILE.typesetter.state.outputQueue
  for i=1,#q do
    totalHeight = totalHeight + q[i].height + q[i].depth
  end
  SILE.typesetter:chuck()

  if type(totalHeight) == "table" then totalHeight= totalHeight.length end
  local newFrame = SILE.newFrame({ 
    bottom = cFrame:bottom(), 
    left = cFrame:left(), 
    right = cFrame:right(),
    next = cFrame.next,
    id = cFrame.id .. "'"
  })

  cFrame._height = totalHeight
  cFrame.next = newFrame

  newFrame._top = cFrame:top() + totalHeight
  SILE.typesetter:initFrame(newFrame)
  -- SILE.outputter:debugFrame(cFrame)
  -- SILE.outputter:debugFrame(newFrame)
end

SILE.registerCommand("shiftframeedge", function(options, content)
  local cFrame = SILE.typesetter.frame
  if options.left then 
    local oldLeft = cFrame.left
    cFrame.left = function()
      return oldLeft(cFrame) + SILE.length.parse(options.left).length
    end
  end
  if options.right then 
    local oldRight = cFrame.right
    cFrame.right = function()
      return oldRight(cFrame) + SILE.length.parse(options.right).length
    end
  end
  SILE.typesetter:initFrame(cFrame)
  --SILE.outputter:debugFrame(cFrame)
end)

SILE.registerCommand("breakframevertical", function ( options, content )
  breakFrameVertical()
end)

return {
  init = function () end,
  exports = {
    breakFrameVertical = breakFrameVertical
  }
}