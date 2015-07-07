local gridSpacing -- Should be a setting

local makeUp = function ()
  if not SILE.typesetter.frame.state.totals.gridCursor then SILE.typesetter.frame.state.totals.gridCursor = 0 end
  local toadd = gridSpacing - (SILE.typesetter.frame.state.totals.gridCursor % gridSpacing) 
  SILE.typesetter.frame.state.totals.gridCursor = SILE.typesetter.frame.state.totals.gridCursor + toadd
  return SILE.nodefactory.newVglue({ height = SILE.length.new({ length = toadd }) })
end

local leadingFor = function(this, vbox, previous)
print("Leading ", previous, vbox)
  if not this.frame.state.totals.gridCursor then this.frame.state.totals.gridCursor = 0 end
  if type(vbox.height) == "table" then
    this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + vbox.height.length + previous.depth
  else
    this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + vbox.height + previous.depth
  end
  g = makeUp()
  print(g)
  return g
end

local pushVglue = function(this, spec)
  if not this.frame.state.totals.gridCursor then 
    print("Setting")
    this.frame.state.totals.gridCursor = 0 
  end
  this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + spec.height.length
  print("Adding")
  SILE.defaultTypesetter.pushVglue(this, spec)
  SILE.defaultTypesetter.pushVglue(this, makeUp())
end

local debugGrid = function()
  local t = SILE.typesetter
  if not t.frame.state.totals.gridCursor then t.frame.state.totals.gridCursor = 0 end
  local g = t.frame.state.totals.gridCursor
  while g < t.frame:bottom() do
    SILE.outputter.rule(t.frame:left(), t.frame:top() + g, t.frame:width(), 0.1)
    g = g + gridSpacing
  end
end

SILE.registerCommand("grid:debug", debugGrid)

SILE.registerCommand("grid", function(options, content)
  SU.required(options, "spacing", "grid package")
  gridSpacing = SILE.parseComplexFrameDimension(options.spacing,"h");
  -- SILE.typesetter:leaveHmode()

  SILE.typesetter.leadingFor = leadingFor
  SILE.typesetter.pushVglue = pushVglue
  SILE.typesetter.setVerticalGlue = function () end
  SILE.typesetter.frame.state.totals.gridCursor = 0
  SILE.typesetter.state.previousVbox = SILE.defaultTypesetter.pushVbox(SILE.typesetter,{})
  SILE.typesetter:registerNewPageHook(function(this)
    SILE.typesetter.frame.state.totals.gridCursor = 0
    SILE.typesetter.state.previousVbox = SILE.defaultTypesetter.pushVbox(SILE.typesetter,{})
  end)

end, "Begins typesetting on a grid spaced at <spacing> intervals.")

SILE.registerCommand("no-grid", function (options, content)
  SILE.typesetter.leadingFor = SILE.defaultTypesetter.leadingFor
  SILE.typesetter.pushVglue = SILE.defaultTypesetter.pushVglue
  SILE.typesetter.setVerticalGlue = SILE.defaultTypesetter.setVerticalGlue
  -- SILE.typesetter.state = t.state
end, "Stops grid typesetting.")
