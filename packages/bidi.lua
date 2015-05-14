SILE.registerCommand("thisframeLTR", function(options, content)
  SILE.typesetter.frame.direction = "LTR"
  SILE.typesetter:leaveHmode()
end);

SILE.registerCommand("thisframeRTL", function(options, content)
  SILE.typesetter.frame.direction = "RTL"
  SILE.typesetter:leaveHmode()
end);

local bidi = require("unicode-bidi-algorithm")

-- Split text into chunks of equal bidi type
local bidiTokenize = function(text)
  local unichars = SU.splitUtf8(text)
  local chunks = { unichars[1] }
  local lastType = bidi.get_bidi_type(SU.codepoint(unichars[1]))
  for j = 2,#unichars do
    local thisType = bidi.get_bidi_type(SU.codepoint(unichars[j]))
    if thisType ~= lastType then
      chunks[#chunks+1] = (chunks[#chunks+1]or"")..unichars[j]
      lastType = thisType
    else
      chunks[#chunks] = chunks[#chunks]..unichars[j]
    end
  end
  return chunks
end

local bidiBoxupNodes = function (self)
  local nl = self.state.nodes
  local newNl = {}
  -- This is crazy-inefficient but processors get faster 
  -- over time while code doesn't get easier to understand.
  for i=1,#nl do
    if nl[i]:isUnshaped() then
      local chunks = bidiTokenize(nl[i].text)
      for j = 1,#chunks do
        newNl[#newNl+1] = SILE.nodefactory.newUnshaped({text = chunks[j], options = nl[i].options })
      end
    else
      newNl[#newNl+1] = nl[i]
    end
  end
  self.state.nodes = bidi.process(newNl, self.frame)
  return SILE.defaultTypesetter.boxUpNodes(self)
end

SILE.typesetter.boxUpNodes = bidiBoxupNodes

SILE.registerCommand("bidi-on", function(options, content)
  SILE.typesetter.boxUpNodes = bidiBoxupNodes
end)

SILE.registerCommand("bidi-off", function(options, content)
  SILE.typesetter.boxUpNodes = SILE.defaultTypesetter.boxUpNodes
end)

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