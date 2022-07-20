local base = require("packages.base")

local package = pl.class(base)
package._name = "parallel"

local typesetterPool = {}
local calculations = {}
local folioOrder = {}

local allTypesetters = function (callback)
  local oldtypesetter = SILE.typesetter
  for frame, typesetter in pairs(typesetterPool) do
    SILE.typesetter = typesetter
    callback(frame, typesetter)
  end
  SILE.typesetter = oldtypesetter
end

local nulTypesetter = pl.class(SILE.defaultTypesetter) -- we ignore this
nulTypesetter.outputLinesToPage = function () end

local parallelPagebreak = function ()
  for i = 1, #folioOrder do
    local thisPageFrames = folioOrder[i]
    for j = 1, #thisPageFrames do
      local frame = thisPageFrames[j]
      local typesetter = typesetterPool[frame]
      local thispage = {}
      SU.debug("parallel", "Dumping lines for page on typesetter "..typesetter.id)
      if #typesetter.state.outputQueue > 0 and calculations[frame].mark == 0 then
        -- More than one page worth of stuff here.
        -- Just ship out one page and hope for the best.
        SILE.defaultTypesetter.buildPage(typesetter)
      else
        for l = 1, calculations[frame].mark do
          thispage[l] = table.remove(typesetter.state.outputQueue, 1)
          SU.debug("parallel", thispage[l])
        end
        typesetter:outputLinesToPage(thispage)
      end
    end
    SILE.documentState.documentClass:endPage()
    for l = 1, #thisPageFrames do
      local frame = thisPageFrames[l]
      local typesetter = typesetterPool[frame]
      typesetter:initFrame(typesetter.frame)
    end
    SILE.documentState.documentClass:newPage()
  end
end

local addBalancingGlue = function (height)
  allTypesetters(function (frame, typesetter)
    local glue = height - calculations[frame].heightOfNewMaterial
    if glue.length:tonumber() > 0 then
      SU.debug("parallel", "Adding " .. tostring(glue) .. " to " .. tostring(frame))
      typesetter:pushVglue({ height = glue })
    end
    calculations[frame].mark = #typesetter.state.outputQueue
  end)
end

function package:_init (class, options)

  base._init(self, class)

  SILE.typesetter = nulTypesetter(SILE.getFrame("page"))
  for frame, typesetter in pairs(options.frames) do
    typesetterPool[frame] = SILE.defaultTypesetter(SILE.getFrame(typesetter))
    typesetterPool[frame].id = typesetter
    typesetterPool[frame].buildPage = function ()
      -- No thank you, I will do that.
    end
    -- Fixed leading here is obviously a bug, but n-way leading calculations
    -- get very complicated...
    -- typesetterPool[frame].leadingFor = function() return SILE.nodefactory.vglue(SILE.settings:get("document.lineskip")) end
    class:registerCommand(frame, function (_, _) -- \left ...
      SILE.typesetter = typesetterPool[frame]
      SILE.call(frame..":font")
    end)
    class:registerCommand(frame..":font", function (_, _) end) -- to be overridden
  end
  if not options.folios then
    folioOrder = { {} }
    -- Note output order doesn't matter for PDF, but for our test suite it is
    -- essential that the output order is deterministic, hence this sort()
    for frame, _ in pl.tablex.sort(options.frames) do table.insert(folioOrder[1], frame) end
  else
    folioOrder = options.folios -- As usual we trust the user knows what they're doing
  end
  class.newPage = function(self_)
    allTypesetters(function (frame, _)
      calculations[frame] = { mark = 0 }
    end)
    class._base.newPage(self_)
    SILE.call("sync")
  end
  allTypesetters(function (frame, _) calculations[frame] = { mark = 0 } end)
  local oldfinish = class.finish
  class.finish = function (self_)
    parallelPagebreak()
    oldfinish(self_)
  end

end

function package:registerCommands ()

  self.class:registerCommand("sync", function (_, _)
    local anybreak = false
    local maxheight = SILE.length()
    SU.debug("parallel", "Trying a sync")
    allTypesetters(function (_, typesetter)
      SU.debug("parallel", "Leaving hmode on "..typesetter.id)
      typesetter:leaveHmode(true)
      -- Now we have each typesetter's content boxed up onto the output stream
      -- but page breaking has not been run. See if page breaking would cause a
      -- break
      local lines = pl.tablex.copy(typesetter.state.outputQueue)
      if SILE.pagebuilder:findBestBreak({ vboxlist = lines, target = typesetter:getTargetLength() }) then
        anybreak = true
      end
    end)

    if anybreak then
      parallelPagebreak()
      return
    end

    allTypesetters(function (frame, typesetter)
      calculations[frame].heightOfNewMaterial = SILE.length()
      for i = calculations[frame].mark + 1, #typesetter.state.outputQueue do
        local thisHeight = typesetter.state.outputQueue[i].height + typesetter.state.outputQueue[i].depth
        calculations[frame].heightOfNewMaterial = calculations[frame].heightOfNewMaterial + thisHeight
      end
      if maxheight < calculations[frame].heightOfNewMaterial then maxheight = calculations[frame].heightOfNewMaterial end
      SU.debug("parallel", frame .. ": pre-sync content=" .. calculations[frame].mark .. ", now " .. #typesetter.state.outputQueue .. ", height of material: " .. tostring(calculations[frame].heightOfNewMaterial))
    end)
    addBalancingGlue(maxheight)
  end)

end

package.documentation = [[
\begin{document}
The \autodoc:package{parallel} package provides the mechanism for typesetting diglot or other parallel documents.
When used by a class such as \code{classes/diglot.lua}, it registers a command for each parallel frame, to allow you to select which frame you’re typesetting into.
It also defines the \autodoc:command{\sync} command, which adds vertical spacing to each frame such that the \em{next} set of text is vertically aligned.
See \url{https://sile-typesetter.org/examples/parallel.sil} and the source of \code{classes/diglot.lua} for examples which makes the operation clear.
\end{document}
]]

return package
