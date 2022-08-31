local base = require("packages.base")

local package = pl.class(base)
package._name = "twoside"

local _odd = true

local mirrorMaster = function (_, existing, new)
  -- Frames in one master can't "see" frames in another, so we have to get creative
  -- XXX This knows altogether too much about the implementation of masters
  if not SILE.scratch.masters[new] then SILE.scratch.masters[new] = {frames={}} end
  if not SILE.scratch.masters[existing] then
    SU.error("Can't find master "..existing)
  end
  for name, frame in pairs(SILE.scratch.masters[existing].frames) do
    local newframe = pl.tablex.deepcopy(frame)
    if frame:isAbsoluteConstraint("right") then
      newframe.constraints.left = "100%pw-("..frame.constraints.right..")"
    end
    if frame:isAbsoluteConstraint("left") then
      newframe.constraints.right = "100%pw-("..frame.constraints.left..")"
    end
    SILE.scratch.masters[new].frames[name] = newframe
    if frame == SILE.scratch.masters[existing].firstContentFrame then
      SILE.scratch.masters[new].firstContentFrame = newframe
    end
  end
end

function package.oddPage (_)
  return _odd
end

local function switchPage (class)
  _odd = not class:oddPage()
  local nextmaster = _odd and class.oddPageMaster or class.evenPageMaster
  class:switchMaster(nextmaster)
end

local _deprecate  = [[
  Directly calling master switch handling functions is no longer necessary. All
  the SILE core classes and anything inheriting from them will take care of this
  automatically using hooks. Custom classes that override the class:newPage()
  function may need to handle this in other ways. By calling this hook directly
  you are likely causing it to run twice and duplicate entries.
]]

local spread_counter = 0
local spreadHook = function ()
  spread_counter = spread_counter + 1
end

function package:_init (options)
  base._init(self)
  if not SILE.scratch.masters then
    SU.error("Cannot load twoside package before masters.")
  end
  self:export("oddPage", self.oddPage)
  self:export("mirrorMaster", mirrorMaster)
  self:export("switchPage", function (class)
    SU.deprecated("class:switchPage", nil, "0.13.0", "0.15.0", _deprecate)
    return class:switchPage()
  end)
  self.class.oddPageMaster = options.oddPageMaster
  self.class.evenPageMaster = options.evenPageMaster
  self.class:registerPostinit(function (class)
    class:mirrorMaster(options.oddPageMaster, options.evenPageMaster)
  end)
  self.class:registerHook("newpage", spreadHook)
  self.class:registerHook("newpage", switchPage)
end

function package:registerCommands ()

  self:registerCommand("open-double-page", function()
    spread_counter = 0
    SILE.typesetter:leaveHmode()
    -- Output a box, then nuke it otherwise we can't prove what page new content will land on
    SILE.call("hbox"); SILE.typesetter:leaveHmode(); table.remove(SILE.typesetter.state.nodes)
    if spread_counter == 1 and self.class:oddPage() then
      SILE.typesetter.state.outputQueue = {}
      return
    end
    local startedattop = #SILE.typesetter.state.outputQueue == 2 and #SILE.typesetter.state.nodes == 0
    local spread_counter_at_start = spread_counter
    repeat
      if spread_counter > 0 then
        SILE.call("hbox")
        SILE.typesetter:leaveHmode()
      end
      SILE.call("supereject")
      SILE.typesetter:leaveHmode()
    until self.class:oddPage()
  end)

end

package.documentation = [[
\begin{document}
The \code{book} class described in chapter 4 sets up left and right mirrored page masters; the \autodoc:package{twoside} package is responsible for swapping between the two left and right frames, running headers and so on.
It has no user-serviceable parts.
\end{document}
]]

return package
