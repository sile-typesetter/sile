local typesetterPool = {}
local calculations = {}

local allTypesetters = function (f) 
  local o = SILE.typesetter
for k,v in pairs(typesetterPool) do
  SILE.typesetter = v
  f(k,v) 
end 
  SILE.typesetter = o
end

local setupParallel = function (klass, names)
  for k,v in pairs(names) do
    typesetterPool[k] = SILE.typesetter {}
    typesetterPool[k].id = v
    typesetterPool[k]:init(SILE.getFrame(v))
    typesetterPool[k].pageBuilder = function()
      -- No thank you, I will do that.
    end
    -- Fixed leading here is obviously a bug, but n-way leading calculations
    -- get very complicated...
    typesetterPool[k].leadingFor = function() return SILE.nodefactory.newVglue(SILE.settings.get("document.lineskip")) end
    SILE.registerCommand(k, function (o,c) -- \left ...
      SILE.typesetter = typesetterPool[k]
      SILE.call(k..":font")
    end)
    SILE.registerCommand(k..":font", function (o,c) end) -- to be overridden
  end
  local o = klass.newPage
  klass.newPage = function(self)
    allTypesetters(function (n,t)
      calculations[n] = { mark = 0 }
    end)
    SILE.baseClass:newPage()
  end
  allTypesetters(function (n,t) calculations[n] = { mark = 0 } end)
  o = klass.endPage
  klass.endPage = function(self)
    allTypesetters(function (n,t) t:chuck() end)
    o(self)
  end
end

local parallelPagebreak = function ()
  allTypesetters(function (n,t)
    if not calculations[n].pageBreak then
      local thispage = {}
      for i = 1, calculations[n].mark do
        thispage[i] = table.remove(t.state.outputQueue, 1)
      end
      t:outputLinesToPage(thispage)
    else
      t:outputLinesToPage(calculations[n].pageBreak)        
    end
  end)
  SILE.documentState.documentClass:endPage()
  SILE.documentState.documentClass:newPage()
  allTypesetters(function (n,t) t:initFrame(t.frame) end)
end

local addBalancingGlue = function (h)
  allTypesetters(function (n,t)
    local g = h - calculations[n].heightOfNewMaterial
    if g > 0 then 
      SU.debug("parallel", "Adding "..g.." to "..n)
      t:pushVglue({ height = g })
    end
    calculations[n].mark = #t.state.outputQueue
  end)
end

SILE.registerCommand("sync", function (o,c)
  local anybreak = false
  local maxheight = SILE.length.new()
  allTypesetters(function (n,t)
    t:leaveHmode(true)
    -- Now we have each typesetter's content boxed up onto the output stream
    -- but page breaking has not been run. See if page breaking would cause a
    -- break
    calculations[n].pageBreak = SILE.pagebuilder.findBestBreak(t.state.outputQueue, t:pageTarget())
    if calculations[n].pageBreak then 
      anybreak = true 
    else
      calculations[n].heightOfNewMaterial = SILE.length.new()
      local lastdepth = 0
      for i = calculations[n].mark + 1, #t.state.outputQueue do
        local thisHeight = t.state.outputQueue[i].height + t.state.outputQueue[i].depth
        if t.state.outputQueue[i]:isBox() then
          lastdepth = t.state.outputQueue[i].depth
        end
        calculations[n].heightOfNewMaterial = calculations[n].heightOfNewMaterial + thisHeight
      end
      -- calculations[n].heightOfNewMaterial = calculations[n].heightOfNewMaterial - lastdepth
      if maxheight < calculations[n].heightOfNewMaterial then maxheight = calculations[n].heightOfNewMaterial end
    end
    SU.debug("parallel", n..": pre-sync content="..calculations[n].mark..", now "..#t.state.outputQueue..", height of material: "..calculations[n].heightOfNewMaterial)
  end)

  if anybreak then -- Calling sync has causes a page break. Insert it for everyone
    parallelPagebreak()
  else
    addBalancingGlue(maxheight)
  end
end)

return {
  init = setupParallel
}
