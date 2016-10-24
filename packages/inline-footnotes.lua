
SILE.registerCommand("inlinefootnote", function(options, content)
  SILE.call("footnotemark")
  local opts = SILE.scratch.insertions.classes.footnote
  local f = SILE.getFrame(opts["insertInto"].frame)
  local oldT = SILE.typesetter
  SILE.typesetter = SILE.typesetter {}
  SILE.typesetter:init(f)
  local box = thisPageInsertionBoxForClass("footnote")
  local oldmaterial = box.nodes[#box.nodes]
  SILE.typesetter:pushVertical(oldmaterial)
  SILE.typesetter:pushBack() -- Our old friend
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  SILE.typesetter:typeset(" ")
  SILE.typesetter.pageTarget = function () return 0xFFFFFF end
  SILE.settings.pushState()
  SILE.settings.reset()
  SILE.Commands["footnote:font"]({}, function()
    SILE.call("footnote:atstart")
    SILE.call("footnote:counter")
    SILE.process(content)
  end)
  SILE.call("par")
  box.nodes[#box.nodes] = nil
  for j=2,#SILE.typesetter.state.outputQueue do
    box.nodes[#box.nodes+1] = SILE.typesetter.state.outputQueue[j]
  end
  print(box.nodes)
  SILE.settings.popState()
  SILE.typesetter = oldT
  SILE.scratch.counters.footnote.value = SILE.scratch.counters.footnote.value + 1
end)