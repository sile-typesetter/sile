SILE.registerCommand("indexentry", function (options, content)
  if not options.label then
    -- Reconstruct the text.
    SILE.typesetter:pushState()
    SILE.process(content)
    local text = ""
    local nl = SILE.typesetter.state.nodes
    for i = 2, #nl do
      text = text .. nl[i]:toText()
    end
    options.label = text
    SILE.typesetter:popState()
  end
  if not options.index then options.index = "main" end
  SILE.call("info", {category="index", value = { index = options.index, label = options.label }})
end)

SILE.scratch.index = {}

local moveNodes = function (_)
  local nodes = SILE.scratch.info.thispage.index
  local thisPage = SILE.formatCounter(SILE.scratch.counters.folio)
  if not nodes then return end
  for _, node in ipairs(nodes) do
    if not SILE.scratch.index[node.index] then SILE.scratch.index[node.index] = {} end
    local thisIndex = SILE.scratch.index[node.index]
    if not thisIndex[node.label] then thisIndex[node.label] = {} end
    if not(#(thisIndex[node.label])) or (thisIndex[node.label])[#(thisIndex[node.label])] ~= thisPage then
      table.insert(thisIndex[node.label], thisPage)
    end
  end
end
  -- if content then
  --   for i = 1, #content do
  --     if not SILE.scratch.index.commands[content[i].label] then
  --       SILE.scratch.index.commands[content[i].label] = {}
  --     end
  --     SILE.scratch.index.commands[content[i].label][SILE.formatCounter(SILE.scratch.counters.folio)] = 1
  --   end
  -- end


SILE.registerCommand("printindex", function (options, _)
  moveNodes()
  if not options.index then options.index = "main" end
  local index = SILE.scratch.index[options.index]
  local sortedIndex = {}
  for n in pairs(index) do table.insert(sortedIndex, n) end
  table.sort(sortedIndex)
  SILE.call("bigskip")
  for _, k in ipairs(sortedIndex) do
    local pageno = table.concat(index[k], ", ")
    SILE.call("index:item", { pageno = pageno }, { k })
  end
end)

SILE.registerCommand("index:item", function (options, content)
  SILE.settings.temporarily(function ()
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
    SILE.settings.set("current.parindent", SILE.nodefactory.glue())
    SILE.call("code", {}, content)
    -- Ideally, leaders
    SILE.call("hss")
    SILE.typesetter:typeset(options.pageno)
    SILE.call("smallskip")
  end)
end)

return {
  init = function () end,
  exports = {
    buildIndex = moveNodes
  }
}
