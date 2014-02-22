
SILE.registerCommand("verbatim", function(options, content)
  local t = SILE.typesetter;
  t:pushVglue({ height = SILE.length.new({ length = 15 }) })
  t:leaveHmode()
  SILE.typesetter = SILE.typesetter {}
  -- Keep lines
  SILE.typesetter.parSepPattern = "\n"

  -- Set ragged right
  local saveState = std.tree.clone(SILE.documentState.documentClass.state)
  SILE.documentState.documentClass.state.rskip = SILE.nodefactory.newGlue({width = SILE.length.new({ length = 0, stretch = 10000 }) })
  SILE.documentState.documentClass.state.parindent = SILE.nodefactory.newGlue({width = SILE.length.new({ length = 0 }) })
  SILE.documentState.documentClass.state.baselineSkip = SILE.nodefactory.newVglue({height = SILE.length.new({ length = 0 }) })
  SILE.documentState.documentClass.state.lineSkip = SILE.nodefactory.newVglue({height = SILE.length.new({ length = 2 }) })
  SILE.documentState.documentClass.state.spaceskip = SILE.length.new({ length = 6 }) -- XXX
  
  local saveState2 = std.tree.clone(SILE.documentState) -- urgh
  SILE.documentState.fontFamily = SILE.documentState.documentClass.state.ttfont or "Monaco"
  SILE.documentState.fontSize = SILE.documentState.fontSize - 3
  SILE.documentState.language = "xx"
  SILE.process(content)

  SILE.typesetter = t
  SILE.documentState = saveState2
  t:pushVglue({ height = SILE.length.new({ length = 15 }) })
  SILE.documentState.documentClass.state = saveState
end)