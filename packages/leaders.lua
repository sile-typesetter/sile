local leader = pl.class({
    _base = SILE.nodefactory.glue,

    outputYourself = function (self, typesetter, line)
      local outputWidth = SU.rationWidth(self.width, self.width, line.ratio)
      local valwidth = self.value.width
      local repetitions = math.floor(outputWidth:tonumber() / valwidth:tonumber())
      if repetitions < 1 then
        typesetter.frame:advanceWritingDirection(outputWidth)
        return
      end
      local remainder = outputWidth - repetitions * valwidth
      if repetitions == 1 then
        typesetter.frame:advanceWritingDirection(remainder)
        self.value:outputYourself(typesetter, line)
      end
      if repetitions > 1 then
        local glue = remainder / (repetitions-1)
        for _ = 1, (repetitions - 1) do
          self.value:outputYourself(typesetter, line)
          typesetter.frame:advanceWritingDirection(glue)
        end
        self.value:outputYourself(typesetter, line)
      end
    end

  })

SILE.registerCommand("leaders", function(options, content)
  local width = SU.required(options, "width", "creating leaders", "length")
  SILE.call("hbox", {}, content)
  local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  local l = leader({ width = width, value = hbox })
  table.insert(SILE.typesetter.state.nodes, l)
end)

SILE.registerCommand("dotfill", function(_, _)
  SILE.call("leaders", { width = "0pt plus 100000pt" }, { " . " })
end)
