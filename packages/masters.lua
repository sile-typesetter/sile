if not SILE.scratch.masters then
  SILE.scratch.masters = {}
end

local _currentMaster

local function defineMaster (_, args)
  SU.required(args, "id", "defining master")
  SU.required(args, "frames", "defining master")
  SU.required(args, "firstContentFrame", "defining master")
  SILE.scratch.masters[args.id] = { frames = {}, firstContentFrame = nil }
  for frame, spec in pairs(args.frames) do
    spec.id = frame
    if spec.solve then
      SILE.scratch.masters[args.id].frames[frame] = spec
    else
      SILE.scratch.masters[args.id].frames[frame] = SILE.newFrame(spec)
    end
  end
  SILE.scratch.masters[args.id].firstContentFrame = SILE.scratch.masters[args.id].frames[args.firstContentFrame]
end

local function defineMasters (self, list)
  if list then
    for i = 1, #list do
      defineMaster(self, list[i])
    end
  end
end

local function doswitch (frames)
  SILE.frames = { page = SILE.frames.page }
  for id, frame in pairs(frames) do
    SILE.frames[id] = frame
    frame:invalidate()
  end
end

local function switchMasterOnePage (id)
  if not SILE.scratch.masters[id] then
    SU.error("Can't find master "..id)
  end
  SILE.documentState.thisPageTemplate = SILE.scratch.masters[id]
  doswitch(SILE.scratch.masters[id].frames)
  SILE.typesetter:chuck()
  SILE.typesetter:initFrame(SILE.scratch.masters[id].firstContentFrame)
end

local function switchMaster (id)
  _currentMaster = id
  if not SILE.scratch.masters[id] then
    SU.error("Can't find master "..id)
  end
  SILE.documentState.documentClass.pageTemplate = SILE.scratch.masters[id]
  SILE.documentState.thisPageTemplate = pl.tablex.deepcopy(SILE.documentState.documentClass.pageTemplate)
  doswitch(SILE.scratch.masters[id].frames)
  SILE.typesetter:initFrame(SILE.scratch.masters[id].firstContentFrame)
end

SILE.registerCommand("define-master-template", function(options, content)
  SU.required(options, "id", "defining a master")
  SU.required(options, "first-content-frame", "defining a master")
  -- Subvert the <frame> functionality from baseclass
  local spare = SILE.documentState.thisPageTemplate.frames
  local sp2 = SILE.frames
  SILE.frames = { page = SILE.frames.page }
  SILE.documentState.thisPageTemplate.frames = {}
  SILE.process(content)
  SILE.scratch.masters[options.id] = {}
  SILE.scratch.masters[options.id].frames = SILE.documentState.thisPageTemplate.frames
  if not SILE.scratch.masters[options.id].frames[options["first-content-frame"]] then
    SU.error("first-content-frame "..options["first-content-frame"].." not found")
  end
  SILE.scratch.masters[options.id].firstContentFrame = SILE.scratch.masters[options.id].frames[options["first-content-frame"]]
  SILE.documentState.thisPageTemplate.frames = spare
  SILE.frames = sp2
end)

SILE.registerCommand("switch-master-one-page", function (options, _)
  SU.required(options, "id", "switching master")
  switchMasterOnePage(options.id)
  SILE.typesetter:leaveHmode()
end, "Switches the master for the current page")

SILE.registerCommand("switch-master", function (options, _)
  SU.required(options, "id", "switching master")
  switchMaster(options.id)
end, "Switches the master for the current page")

return {
  init = defineMasters,
  exports = {
    switchMasterOnePage = switchMasterOnePage,
    switchMaster = switchMaster,
    defineMaster = defineMaster,
    defineMasters = defineMasters,
    currentMaster = function () return _currentMaster end
  },
  documentation = [[
\begin{document}

The masters functionality is also itself an add-on package. It allows a class to
define sets of frames and switch between them either temporarily or permanently.
It defines the commands \autodoc:command{\define-master-template} (which is pattern
on the \autodoc:command{\pagetemplate} function we will meet in chapter 8),
\autodoc:command{\switch-master} and \autodoc:command{\switch-master-one-page}.
See \code{tests/masters.sil} for more about this package.

\end{document}
]]
}
