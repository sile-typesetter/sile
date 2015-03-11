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
  self.state.nodes = bidi.process(SILE.hyphenate(self.state.nodes), self.frame)
  return SILE.defaultTypesetter.boxUpNodes(self)
end

return { documentation = [[\begin{document}

Scripts like the Latin alphabet you are currently reading are normally written left to
right; however, some scripts, such as Arabic and Hebrew, are written right to left.
The \code{bidi} package provides some tools to help you correctly typeset right-to-left
text and also documents which mix right-to-left and left-to-right typesetting.

Loading the \code{bidi} package provides two commands, \command{\\thisframeLTR} and
\command{\\thisframeRTL}, which set the default text direction for the current frame.
That is, if you tell SILE that a frame is RTL, the text will start in the right margin
and proceed leftward. Additionally, loading \code{bidi} will cause SILE to check for and
correctly order left-to-right text within right-to-left paragraphs, RTL within LTR
within LTR and so on. If you are working with Hebrew, Arabic or other RTL languages,
you will want to load the \code{bidi} package.

\end{document}]] }