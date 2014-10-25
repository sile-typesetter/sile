SILE.registerCommand("thisframeLTR", function(options, content)
  SILE.typesetter.frame.direction = "LTR"
  SILE.typesetter:leaveHmode()
end);

SILE.registerCommand("thisframeRTL", function(options, content)
  SILE.typesetter.frame.direction = "RTL"
  SILE.typesetter:leaveHmode()
end);

local bidi = require("unicode-bidi-algorithm")

SILE.typesetter.boxUpNodes = function (self)
    local listToString = function(l)
      local rv = ""
      for i = 1,#l do rv = rv ..l[i] end return rv
    end
  print("Before",listToString(self.state.nodes))
  self.state.nodes = bidi.process(self.state.nodes, self.frame)
  print("After", listToString(self.state.nodes))
  return SILE.defaultTypesetter.boxUpNodes(self)
end