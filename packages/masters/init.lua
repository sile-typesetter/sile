local base = require("packages.base")

local package = pl.class(base)
package._name = "masters"

local _currentMaster

local function defineMaster (_, options)
  SU.required(options, "id", "defining master")
  SU.required(options, "frames", "defining master")
  SU.required(options, "firstContentFrame", "defining master")
  SILE.scratch.masters[options.id] = { frames = {}, firstContentFrame = nil }
  for frame, spec in pairs(options.frames) do
    spec.id = frame
    if spec.solve then
      SILE.scratch.masters[options.id].frames[frame] = spec
    else
      SILE.scratch.masters[options.id].frames[frame] = SILE.newFrame(spec)
    end
  end
  SILE.scratch.masters[options.id].firstContentFrame = SILE.scratch.masters[options.id].frames[options.firstContentFrame]
end

local function defineMasters (class, list)
  if list then
    for i = 1, #list do
      defineMaster(class, list[i])
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

local function switchMasterOnePage (_, id)
  if not id then
    SU.deprecated("class.switchMasterOnePage", "class:switchMasterOnePage", "0.13.0", "0.15.0")
  end
  if not SILE.scratch.masters[id] then
    SU.error("Can't find master "..id)
  end
  SILE.documentState.thisPageTemplate = SILE.scratch.masters[id]
  doswitch(SILE.scratch.masters[id].frames)
  SILE.typesetter:chuck()
  SILE.typesetter:initFrame(SILE.scratch.masters[id].firstContentFrame)
end

local function switchMaster (class, id)
  if not id then
    SU.deprecated("class.switchMaster", "class:switchMaster", "0.13.0", "0.15.0")
  end
  _currentMaster = id
  if not SILE.scratch.masters[id] then
    SU.error("Can't find master "..id)
  end
  class.pageTemplate = SILE.scratch.masters[id]
  SILE.documentState.thisPageTemplate = class.pageTemplate
  doswitch(SILE.scratch.masters[id].frames)
  SILE.typesetter:initFrame(SILE.scratch.masters[id].firstContentFrame)
end

local function currentMaster (_)
  return _currentMaster
end

function package:_init (options)
  base._init(self, options)
  if not SILE.scratch.masters then
    SILE.scratch.masters = {}
  end
  self:export("switchMasterOnePage", switchMasterOnePage)
  self:export("switchMaster", switchMaster)
  self:export("defineMaster", defineMaster)
  self:export("defineMasters", defineMasters)
  self:export("currentMaster", currentMaster)
  if options then
    self.class:defineMasters(options)
  end
end

function package:registerCommands ()

  self:registerCommand("define-master-template", function(options, content)
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

  self:registerCommand("switch-master-one-page", function (options, _)
    SU.required(options, "id", "switching master")
    self.class:switchMasterOnePage(options.id)
    SILE.typesetter:leaveHmode()
  end, "Switches the master for the current page")

  self:registerCommand("switch-master", function (options, _)
    SU.required(options, "id", "switching master")
    self.class:switchMaster(options.id)
  end, "Switches the master for the current page")

end

package.documentation = [[
\begin{document}
The masters functionality is also itself an add-on package.
It allows a class to define sets of frames and switch between them either temporarily or permanently.
It defines the commands \autodoc:command{\define-master-template} (which is patterned on the \autodoc:command{\pagetemplate} function we will meet in Chapter 8), \autodoc:command{\switch-master}, and \autodoc:command{\switch-master-one-page}.
See \code{tests/masters.sil} for more about this package.
\end{document}
]]

return package
