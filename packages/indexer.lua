SILE.registerCommand("indexentry", function(o,c)
  if not o.label then
    -- Reconstruct the text.
    SILE.typesetter:pushState()
    SILE.process(c)
    local t = ""
    local nl = SILE.typesetter.state.nodes
    for i = 2,#nl do
      t = t .. nl[i]:toText()
    end
    o.label = t
    SILE.typesetter:popState()
  end
  if not o.index then o.index = "main" end
  SILE.call("info", {category="index", value = { index = o.index, label = o.label }})
end)

SILE.scratch.index = {}

local moveNodes = function(self)
  local n = SILE.scratch.info.thispage.index
  local thisPage = SILE.formatCounter(SILE.scratch.counters.folio)
  if not n then return end
  for i=1,#n do node = n[i]
    if not SILE.scratch.index[node.index] then SILE.scratch.index[node.index] = {} end
    local thisIndex = SILE.scratch.index[node.index]
    if not thisIndex[node.label] then thisIndex[node.label] = {} end
    if not(#(thisIndex[node.label])) or (thisIndex[node.label])[#(thisIndex[node.label])] ~= thisPage then
      table.insert(thisIndex[node.label], thisPage)
    end
  end
end
  -- if c then
  --   for i = 1,#c do
  --     if not SILE.scratch.index.commands[c[i].label] then
  --       SILE.scratch.index.commands[c[i].label] = {}
  --     end
  --     SILE.scratch.index.commands[c[i].label][SILE.formatCounter(SILE.scratch.counters.folio)] = 1
  --   end
  -- end


SILE.registerCommand("printindex", function(o,c)
  moveNodes()
  if not o.index then o.index = "main" end
  local index = SILE.scratch.index[o.index]
  local sortedIndex = {}
  for n in pairs(index) do table.insert(sortedIndex, n) end
  table.sort(sortedIndex)
  SILE.call("bigskip")
  for i,k in ipairs(sortedIndex) do
    local v = table.concat(index[k],", ")
    SILE.call("index:item", {pageno = v}, {k})
  end
end)

SILE.registerCommand("index:item", function (o,c)
  SILE.settings.temporarily(function ()
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
    SILE.call("code", {}, c)
    -- Ideally, leaders
    SILE.call("hss")
    SILE.typesetter:typeset(o.pageno)
    SILE.call("smallskip")
  end)
end)

return {
  init = function () end,
  exports = {
    buildIndex = moveNodes
  }
}
