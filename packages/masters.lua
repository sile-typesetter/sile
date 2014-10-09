SILE.scratch.masters = {}

local function defineMaster (id, frameset, firstContentFrame)
  SILE.scratch.masters[id] = {frames = {}, first = nil}
  for k,spec in pairs(frameset) do
    SILE.scratch.masters[id].frames[k] = SILE.newFrame(spec)
  end
  SILE.scratch.masters[id].firstContentFrame = SILE.scratch.masters[id].frames[firstContentFrame]
end

local function doswitch(frames)
  local page = SILE.frames.page
  SILE.frames = {}
  SILE.frames.page = page
  for id,f in pairs(frames) do
    SILE.frames[id] =f 
    f:invalidate()
  end
end
 
local function switchMasterOnePage (id)
  if not SILE.scratch.masters[id] then
    SU.error("Can't find master "..id)
  end
  print("(Going to master "..id..")")
  SILE.documentState.thisPageTemplate = SILE.scratch.masters[id]
  doswitch(SILE.scratch.masters[id].frames)
  SILE.typesetter:chuck()
  SILE.typesetter:initFrame(SILE.scratch.masters[id].firstContentFrame)
end

local function switchMaster (id)
  if not SILE.scratch.masters[id] then
    SU.error("Can't find master "..id)
  end
  SILE.documentState.documentClass.pageTemplate = SILE.scratch.masters[id]
  SILE.documentState.thisPageTemplate = std.tree.clone(SILE.documentState.documentClass.pageTemplate)
  doswitch(SILE.scratch.masters[id].frames)
  SILE.typesetter:init(SILE.scratch.masters[id].firstContentFrame)
end

SILE.registerCommand("define-master-template", function(options, content)
  SU.required(options, "id", "defining a master")
  SU.required(options, "first-content-frame", "defining a master")
  -- Subvert the <frame> functionality from baseclass
  local spare = SILE.documentState.thisPageTemplate.frames
  local sp2 = SILE.frames
  SILE.frames = {page = SILE.frames.page}
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

SILE.registerCommand("switch-master-one-page", function ( options, content )
  SU.required(options, "id", "switching master")
  switchMasterOnePage(options.id)
  SILE.typesetter:leaveHmode()
end, "Switches the master for the current page")
SILE.registerCommand("switch-master", function ( options, content )
  SU.required(options, "id", "switching master")
  switchMaster(options.id)
end, "Switches the master for the current page")


return {
  init = defineMasters,
  exports = {
    switchMasterOnePage = switchMasterOnePage,
    switchMaster = switchMaster
  }
}