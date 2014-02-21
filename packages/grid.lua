
local gridLeading = function (this, v)
  if (this.state.frameTotals.gridCursor % this.state.gridSpacing) == 0 then return end
  local lead = this.state.gridSpacing - (this.state.frameTotals.gridCursor % this.state.gridSpacing);
  if this.state.frameTotals.gridCursor then
    this.super.pushVglue(this, {height = SILE.length.new({ length = lead, stretch = 0, shrink = 0})})
    this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + lead
  end
end

local pushVbox = function(this, spec)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  local vbox = SILE.nodefactory.newVbox(spec)
  this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + vbox.height.length  + vbox.depth.length
  local remainder = (this.state.frameTotals.gridCursor % this.state.gridSpacing);
  if not (remainder == 0) then
    local lead = this.state.gridSpacing - remainder
    vbox.depth = vbox.depth + lead
    this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + lead
  end
  table.insert(this.state.outputQueue,vbox)
end

local pushVglue = function(this, spec)
  if not this.state.frameTotals.gridCursor then this.state.frameTotals.gridCursor = 0 end
  this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + spec.height.length;
  local remainder = (this.state.frameTotals.gridCursor % this.state.gridSpacing);
  if not (remainder == 0) then
    local lead = this.state.gridSpacing - remainder
    spec.height = spec.height + lead
    this.state.frameTotals.gridCursor = this.state.frameTotals.gridCursor + lead
  end  
  this.super.pushVglue(this, spec);  gridLeading(this)
end

SILE.registerCommand("grid", function(options, content)
  local t = SILE.typesetter;
  SILE.typesetter = SILE.typesetter {};
  SILE.typesetter.super = t;
  SILE.typesetter.state.gridSpacing = SILE.parseComplexFrameDimension(options.spacing,"h");
  SILE.typesetter.insertLeading = function() end ; -- gridLeading;
  SILE.typesetter.pushVglue = pushVglue;
  SILE.typesetter.pushVbox = pushVbox;
end)

SILE.registerCommand("no-grid", function (options, content)
  SILE.typesetter = SILE.typesetter.super;
end)