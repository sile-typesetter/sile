local breakFrameVertical = function (after)
  local cFrame = SILE.typesetter.frame
  local totalHeight
  if after then
    totalHeight = after
  else
    totalHeight = SILE.length(0)
    SILE.typesetter:leaveHmode(1)
    local queue = SILE.typesetter.state.outputQueue
    for i = 1, #queue do
      totalHeight = totalHeight + queue[i].height + queue[i].depth
    end
    SILE.typesetter:chuck()
  end

  local newFrame = SILE.newFrame({
    bottom = cFrame:bottom(),
    left = cFrame:left(),
    right = cFrame:right(),
    next = cFrame.next,
    previous = cFrame,
    id = cFrame.id .. "_"
  })
  if SILE.scratch.insertions and SILE.scratch.insertions.classes['footnote'] and SILE.scratch.insertions.classes['footnote'].stealFrom then
    SILE.scratch.insertions.classes['footnote'].stealFrom[newFrame.id] = 1
  end

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
  if not offset or not (offset > SILE.length(0)) then
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
  -- if SILE.scratch.insertions and SILE.scratch.insertions.classes['footnote'] and SILE.scratch.insertions.classes['footnote'].stealFrom then
    -- SILE.scratch.insertions.classes['footnote'].stealFrom[newFrame.id] = 1
  -- end
  local oldLeft = cFrame:left()
  cFrame.next = newFrame.id
  cFrame:constrain("left", oldLeft)
  cFrame:constrain("right", oldLeft + offset)
  -- SILE.outputter:debugFrame(cFrame)
  -- SILE.outputter:debugFrame(newFrame)
  SILE.typesetter:initFrame(newFrame)
end

local shiftframeedge = function (frame, options)
  if options.left then
    frame:constrain("left", frame:left() + SILE.length(options.left))
  end
  if options.right then
    frame:constrain("right", frame:right() + SILE.length(options.right))
  end
end

local makecolumns = function (options)
  local cFrame = SILE.typesetter.frame
  local cols = options.columns or 2
  local gutterWidth = options.gutter or "3%pw"
  local right = cFrame:right()
  local origId = cFrame.id
  for i = 1, cols-1 do
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
    newFrame.balanced = true
    cFrame.balanced = true
    gutter:constrain("right", "left("..newFrame.id..")")
    newFrame:constrain("left", "right("..gutter.id..")")
    -- In the future we may way to allow for unequal columns
    -- but for now just assume they will be equal.
    newFrame:constrain("width", "width("..cFrame.id..")")
    cFrame.next = newFrame.id
    cFrame = newFrame
  end
  cFrame:constrain("right", right)
end

local mergeColumns = function ()
  SILE.require("packages/balanced-frames")

  -- 1) Balance all remaining material.

  -- 1.1) Run the pagebuilder once to clear out any full pages
  SILE.typesetter:buildPage()

  -- 1.2) Find out the shape of the columnset. (It will change after we balance it)
  local frame = SILE.typesetter.frame
  -- local left = frame:left()
  -- local bottom = frame:bottom()
  while frame.next and SILE.getFrame(frame.next).balanced do
    frame = SILE.getFrame(frame.next)
  end
  -- local right = frame:right()

  -- 1.3) Now force a balance, which will resize the frames
  SILE.call("balancecolumns")
  SILE.typesetter:buildPage()

  -- 2) Add a new frame, the width of the old frameset and the height of
  -- old frameset - new height, at the end of the current frame
  local newId = SILE.typesetter.frame.id .. "_"
  SILE.typesetter.frame.next = newId
  SILE.typesetter:initNextFrame()
end

SILE.registerCommand("mergecolumns", function (_, _)
  mergeColumns()
end, "Merge multiple columns into one")

SILE.registerCommand("showframe", function (options, _)
  local id = options.id or SILE.typesetter.frame.id
  if id == "all" then
    for _, frame in pairs(SILE.frames) do
      SILE.outputter:debugFrame(frame)
    end
  else
    SILE.outputter:debugFrame(SILE.getFrame(id))
  end
end)

SILE.registerCommand("shiftframeedge", function (options, _)
  local cFrame = SILE.typesetter.frame
  shiftframeedge(cFrame, options)
  SILE.typesetter:initFrame(cFrame)
  --SILE.outputter:debugFrame(cFrame)
end, "Adjusts the edge of the frame horizontally by amounts specified in <left> and <right>")

SILE.registerCommand("breakframevertical", function (options, _)
  breakFrameVertical(options.offset)
end, "Breaks the current frame in two vertically at the current location or at a point <offset> below the current location")

SILE.registerCommand("makecolumns", function (options, _)
  makecolumns(options)
end, "Split the current frame into multiple columns")

SILE.registerCommand("breakframehorizontal", function (options, _)
  breakFrameHorizontalAt(options.offset)
end, "Breaks the current frame in two horizontally either at the current location or at a point <offset> from the left of the current frame")

SILE.registerCommand("float", function (options, content)
  SILE.typesetter:leaveHmode()
  local hbox = SILE.call("hbox", {}, content)
  table.remove(SILE.typesetter.state.nodes) -- steal it back
  local heightOfPageSoFar = SILE.pagebuilder:collateVboxes(SILE.typesetter.state.outputQueue).height
  local overshoot = SILE.length(heightOfPageSoFar + hbox.height - SILE.typesetter:getTargetLength())
  if overshoot > SILE.length(0) then
    SILE.call("eject")
    SILE.typesetter:leaveHmode()
  end
  breakFrameVertical()
  local boundary = hbox.width + SILE.length(options.rightboundary):absolute()
  breakFrameHorizontalAt(boundary)
  SILE.typesetNaturally(SILE.typesetter.frame.previous, function ()
    table.insert(SILE.typesetter.state.nodes, hbox)
  end)
  -- SILE.settings.set("document.baselineskip", SILE.length("1ex") - SILE.settings.get("document.baselineskip").height)
  -- undoSkip.stretch = hbox.height
  -- SILE.typesetter:pushHbox({ value = {} })
  -- SILE.typesetter:pushVglue({ height = undoSkip })
  breakFrameVertical(hbox.height + SILE.length(options.bottomboundary):absolute())
  shiftframeedge(SILE.getFrame(SILE.typesetter.frame.next), { left = -boundary })
  --SILE.outputter:debugFrame(SILE.typesetter.frame)
end, "Sets the given content in its own frame, flowing the remaining content around it")

SILE.registerCommand("typeset-into", function (options, content)
  SU.required(options, "frame", "calling \\typeset-into")
  if not SILE.frames[options.frame] then
    SU.error("Can't find frame "..options.frame.." to typeset into")
  end
  SILE.typesetNaturally(SILE.frames[options.frame], function () SILE.process(content) end)
end)

SILE.registerCommand("fit-frame", function (options, _)
  SU.required(options, "frame", "calling \\fit-frame")
  if not SILE.frames[options.frame] then
    SU.error("Can't find frame "..options.frame.." to fit")
  end
  local frame = SILE.frames[options.frame]
  local height = SILE.length()
  SILE.typesetNaturally(frame, function ()
    SILE.typesetter:leaveHmode()
    for i = 1, #SILE.typesetter.state.outputQueue do
      height = height + SILE.typesetter.state.outputQueue[i].height
    end
  end)
  frame:constrain("height", frame:height() + height)
end)

return {
  init = function () end,
  exports = {
    breakFrameVertical = breakFrameVertical
  }, documentation = [[
\begin{document}
As we mentioned in the first chapter, SILE uses frames as an indication
of where to put text onto the page. The \autodoc:package{frametricks} package assists
package authors by providing a number of commands to manipulate frames.

The most immediately useful is \autodoc:command{\showframe}. This asks the output
engine to draw a box and label around a particular frame. It takes an optional
parameter \autodoc:parameter{id=<frame id>}; if this is not supplied, the current
frame is used. If the ID is \code{all}, then all frames declared by the
current class are displayed.

It’s possible to define frames such as sidebars which are not connected
to the main text flow of a page. We’ll see how to do that in a later chapter, but
this raises the obvious question: if they’re not part of the text flow, how do we
get stuff into them? \autodoc:package{frametricks} provides the \autodoc:command{\typeset-into}
command, which allows you to write text into a specified frame:

\begin{verbatim}
\line
\\typeset-into[frame=sidebar]\{ ... frame content here ... \}
\line
\end{verbatim}

\autodoc:package{frametricks} also provides a number of commands which, to be perfectly
honest, we \em{thought} were going to be useful, but haven’t quite ended up
being as useful as all that.

\breakframevertical\par
The command \autodoc:command{\breakframevertical} breaks the current frame in two
at the specified location into an upper and lower frame. If the frame initially had the ID
\code{main}, then \code{main} becomes the upper frame (before the command)
and the lower frame (after the command) is called \code{main_}. We just
issued a \autodoc:command{\breakframevertical} command at the start of this paragraph,
and now we will issue the command \autodoc:command{\showframe}. \showframe As you can
see, the current frame is called
\code{\script{SILE.typesetter:typeset(SILE.typesetter.frame.id)}}
and now begins at the start of the paragraph.

Similarly, the \autodoc:command{\breakframehorizontal} command breaks the frame in two
into a left and a right frame.
The command takes an optional argument \autodoc:parameter{offset=<dimension>}, specifying
where on the line the frame should be split. If it is not supplied, the
frame is split at the current position in the line.

The command \autodoc:command{\shiftframeedge} allows you to reposition the current
frame left or right. It takes \autodoc:parameter{left} and/or \autodoc:parameter{right} parameters,
which can be positive or negative dimensions. It should only be used at the
top of a frame, as it reinitializes the typesetter object.

Combining all of these commands, the \autodoc:command{\float} command breaks the current
frame, creates a small frame to hold a floating object, flows text into
the surrounding frame, and then, once text has descended past the floating object,
moves the frame back into place again. It takes two optional parameters,
\autodoc:parameter{bottomboundary=<dimension>} and/or \autodoc:parameter{rightboundary=<dimension>},
which open up additional space around the frame. At the start of this paragraph, I issued
the command

\medskip
\begin{verbatim}
\\float[bottomboundary=5pt]\{\\font[size=60pt]\{C\}\}.
\end{verbatim}

To reiterate: we started playing around with frames like this in the early
days of SILE and they have not really proved a good solution to the things
we wanted to do with them. They’re great for arranging where content should
live on the page, but messing about with them dynamically seems to create
more problems than it solves. There’s probably a reason why InDesign and
similar applications handle floats, drop caps, tables and so on inside the
context of a content frame rather than by messing with the frames themselves.
If you feel tempted to play with \autodoc:package{frametricks}, there’s almost always
a better way to achieve what you want without it.
\end{document}
]]
}
