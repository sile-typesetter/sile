local leader = SILE.nodefactory.newGlue({})
leader.outputYourself = function (self,typesetter, line)
  local scaledWidth = self.width.length
  if line.ratio and line.ratio < 0 and self.width.shrink > 0 then
    scaledWidth = scaledWidth + self.width.shrink * line.ratio
  elseif line.ratio and line.ratio > 0 and self.width.stretch > 0 then
    scaledWidth = scaledWidth + self.width.stretch * line.ratio
  end
  local valwidth = self.value.width.length
  local repetitions = math.floor(scaledWidth / valwidth)
  if repetitions < 1 then
    typesetter.frame:advanceWritingDirection(scaledWidth)
    return
  end

  local remainder = scaledWidth - repetitions * valwidth
  if repetitions == 1 then
    typesetter.frame:advanceWritingDirection(remainder)
    self.value:outputYourself(typesetter, line)
  end

  if repetitions > 1 then
    local glue = remainder / (repetitions-1)
    for i=1,(repetitions-1) do
      self.value:outputYourself(typesetter, line)
      typesetter.frame:advanceWritingDirection(glue)
    end
    self.value:outputYourself(typesetter, line)
  end
end

SILE.registerCommand("leaders", function(o,c)
  local gluespec = SU.required(o, "width", "creating leaders")
  local width = SILE.length.parse(gluespec)
  SILE.call("hbox", {}, c)
  local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  local l = leader({ width = width, value = hbox })
  table.insert(SILE.typesetter.state.nodes, l)
end)

SILE.registerCommand("dotfill", function(o,c)
  SILE.call("leaders", {width = "0pt plus 100000pt"}, {" . "})
end)
