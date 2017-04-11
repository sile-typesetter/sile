local typesetterPool = {}
local calculations = {}
local folioOrder = {}

local allTypesetters = function (f)
  local o = SILE.typesetter
for k,v in pairs(typesetterPool) do
  SILE.typesetter = v
  f(k,v)
end
  SILE.typesetter = o
end

local nulTypesetter = SILE.typesetter {} -- we ignore this
nulTypesetter.outputLinesToPage = function() end

local parallelPagebreak = function ()
  for i = 1,#folioOrder do
    local thisPageFrames = folioOrder[i]
    for j = 1,#thisPageFrames do
      local n = thisPageFrames[j]
      local t = typesetterPool[n]
      local thispage = {}
      SU.debug("parallel", "Dumping lines for page on typesetter "..t.id)
      if #t.state.outputQueue > 0 and calculations[n].mark == 0 then
        -- More than one page worth of stuff here.
        -- Just ship out one page and hope for the best.
        SILE.defaultTypesetter.pageBuilder(t)
      else
        for i = 1, calculations[n].mark do
          thispage[i] = table.remove(t.state.outputQueue, 1)
          SU.debug("parallel", thispage[i])
        end
        t:outputLinesToPage(thispage)
      end
    end
    SILE.documentState.documentClass:endPage()
    for j = 1,#thisPageFrames do
      local n = thisPageFrames[j]
      local t = typesetterPool[n]
      t:initFrame(t.frame)
    end
    SILE.documentState.documentClass:newPage()
  end
end

local setupParallel = function (klass, options)
  nulTypesetter:init(SILE.getFrame("page"))
  for k,v in pairs(options.frames) do
    typesetterPool[k] = SILE.typesetter {}
    typesetterPool[k].id = v
    typesetterPool[k]:init(SILE.getFrame(v))
    typesetterPool[k].pageBuilder = function()
      -- No thank you, I will do that.
    end
    -- Fixed leading here is obviously a bug, but n-way leading calculations
    -- get very complicated...
    -- typesetterPool[k].leadingFor = function() return SILE.nodefactory.newVglue(SILE.settings.get("document.lineskip")) end
    SILE.registerCommand(k, function (o,c) -- \left ...
      SILE.typesetter = typesetterPool[k]
      SILE.call(k..":font")
    end)
    SILE.registerCommand(k..":font", function (o,c) end) -- to be overridden
  end
  if not options.folios then
    folioOrder = { {} }
    for k,v in pairs(options.frames) do table.insert(folioOrder[1],k) end
  else
    folioOrder = options.folios -- As usual we trust the user knows what they're doing
  end
  local o = klass.newPage
  klass.newPage = function(self)
    allTypesetters(function (n,t)
      calculations[n] = { mark = 0 }
    end)
    SILE.baseClass:newPage()
    SILE.call("sync")
  end
  allTypesetters(function (n,t) calculations[n] = { mark = 0 } end)
  o = klass.finish
  klass.finish = function(self)
    parallelPagebreak()
    o(self)
  end
end

local addBalancingGlue = function (h)
  allTypesetters(function (n,t)
    local g = h - calculations[n].heightOfNewMaterial
    if g.length > 0 then
      SU.debug("parallel", "Adding "..g.." to "..n)
      t:pushVglue({ height = g })
    end
    calculations[n].mark = #t.state.outputQueue
  end)
end

SILE.registerCommand("sync", function (o,c)
  local anybreak = false
  local maxheight = SILE.length.new()
  SU.debug("parallel", "Trying a sync")
  allTypesetters(function (n,t)
    SU.debug("parallel", "Leaving hmode on "..t.id)
    t:leaveHmode(true)
    -- Now we have each typesetter's content boxed up onto the output stream
    -- but page breaking has not been run. See if page breaking would cause a
    -- break
    local lines = std.table.clone(t.state.outputQueue)
    if SILE.pagebuilder.findBestBreak({vboxlist = lines, target = t:pageTarget() }) then
      anybreak = true
    end
  end)
  
  if anybreak then
    parallelPagebreak()
    return
  end

  allTypesetters(function (n,t)
    calculations[n].heightOfNewMaterial = SILE.length.new()
    local lastdepth = 0
    for i = calculations[n].mark + 1, #t.state.outputQueue do
      local thisHeight = t.state.outputQueue[i].height + t.state.outputQueue[i].depth
      calculations[n].heightOfNewMaterial = calculations[n].heightOfNewMaterial + thisHeight
    end
    if maxheight < calculations[n].heightOfNewMaterial then maxheight = calculations[n].heightOfNewMaterial end
    SU.debug("parallel", n..": pre-sync content="..calculations[n].mark..", now "..#t.state.outputQueue..", height of material: "..calculations[n].heightOfNewMaterial)
  end)
  addBalancingGlue(maxheight)
  SILE.typesetter = nulTypesetter
end)

return {
  init = setupParallel
}
