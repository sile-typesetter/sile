local base = require("packages.base")

local package = pl.class(base)
package._name = "twoside"

local tp = "odd"

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

local function oddPage ()
  return tp == "odd"
end

local function switchPage (class)
  if class:oddPage() then
    tp = "even"
    class:switchMaster(class.evenPageMaster)
  else
    tp = "odd"
    class:switchMaster(class.oddPageMaster)
  end
end

local _deprecate  = [[
  Directly calling master switch handling functions is no longer necessary. All
  the SILE core classes and anything inheriting from them will take care of this
  automatically using hooks. Custom classes that override the class:newPage()
  function may need to handle this in other ways. By calling this hook directly
  you are likely causing it to run twice and duplicate entries.
]]

function package:_init (options)
  base._init(self)
  if not SILE.scratch.masters then
    SU.error("Cannot load twoside package before masters.")
  end
  self:export("oddPage", oddPage)
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
  self.class:registerHook("newpage", switchPage)
end

function package:registerCommands ()

  self.class:registerCommand("open-double-page", function()
    SILE.typesetter:leaveHmode()
    SILE.call("supereject")
    if self.class:oddPage() then
      SILE.typesetter:typeset("")
      SILE.typesetter:leaveHmode()
      SILE.call("supereject")
    end
    SILE.typesetter:leaveHmode()
  end)

end

package.documentation = [[
\begin{document}
The \code{book} class described in chapter 4 sets up left and right mirrored page masters; the \autodoc:package{twoside} package is responsible for swapping between the two left and right frames, running headers and so on.
It has no user-serviceable parts.
\end{document}
]]

return package
