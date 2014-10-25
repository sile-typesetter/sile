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
  self.state.nodes = bidi.process(self.state.nodes, self.frame)
  return SILE.defaultTypesetter.boxUpNodes(self)
end