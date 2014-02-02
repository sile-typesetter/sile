local pushVbox = function(this, spec)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + spec.height.length + spec.depth.length;
  this.super.pushVbox(this, spec);
end

local pushVglue = function(this, spec)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + spec.height.length;
  this.super.pushVglue(this, spec);
end

local gridLeading = function (this, v)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  local lead = this.state.gridSpacing - (this.state.frameTotals.gridCursor % this.state.gridSpacing);
  if this.state.frameTotals.gridCursor then
    this:pushVglue({height = SILE.length.new({ length = lead, stretch = 0, shrink = 0})})
  end
end

SILE.registerCommand("grid", function(options, content)
  local t = SILE.typesetter;
  SILE.typesetter = SU.deepCopy(SILE.typesetter);
  SILE.typesetter.super = t;
  SILE.typesetter.state.gridSpacing = SILE.parseComplexFrameDimension(options.spacing,"h");
  SILE.typesetter.insertLeading = gridLeading;
  SILE.typesetter.pushVglue = pushVglue;
  SILE.typesetter.pushVbox = pushVbox;
end)

SILE.registerCommand("no-grid", function (options, content)
  SILE.typesetter = SILE.typesetter.super;
end)