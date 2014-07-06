local gridSpacing -- Should be a setting

local leadingFor = function(this, vbox, previous)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  if not previous then 
    return SILE.nodefactory.newVglue({height = SILE.length.new()});
  end
  this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + previous.height.length
  if previous:isVbox() then 
    this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + previous.depth.length
  end
  local lead = gridSpacing - (this.state.frameTotals.gridCursor % gridSpacing);
  this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor  + lead
  return SILE.nodefactory.newVglue({height = SILE.length.new({ length = lead })});
end

local pushVglue = function(this, spec)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  this.super.pushVglue(this, spec);
  this.super.pushVglue(this, leadingFor(this, nil, SILE.nodefactory.newVglue(spec)));
end

SILE.registerCommand("grid", function(options, content)
  local t = SILE.typesetter;
  SILE.typesetter = SILE.typesetter {};
  SILE.typesetter.super = t;
  gridSpacing = SILE.parseComplexFrameDimension(options.spacing,"h");
  SILE.typesetter.leadingFor = leadingFor
  SILE.typesetter.pushVglue = pushVglue;
end, "Begins typesetting on a grid spaced at <spacing> intervals.")

SILE.registerCommand("no-grid", function (options, content)
  SILE.typesetter = SILE.typesetter.super;
end, "Stops grid typesetting.")