SILE.registerCommand("thisframeLTR", function(options, content)
  SILE.typesetter.frame.direction = "LTR"
  SILE.typesetter:leaveHmode()
end);

SILE.registerCommand("thisframeRTL", function(options, content)
  SILE.typesetter.frame.direction = "RTL"
  SILE.typesetter:leaveHmode()
end);

local bidi = require("unicode-bidi-algorithm")

local bidiBoxupNodes = function (self)
  local nl = self.state.nodes
  local newNl = {}
  for i=1,#nl do
    if nl[i]:isUnshaped() then
      local chunks = SU.splitUtf8(nl[i].text)
      for j = 1,#chunks do
        newNl[#newNl+1] = SILE.nodefactory.newUnshaped({text = chunks[j], options = nl[i].options })
      end
    else
      newNl[#newNl+1] = nl[i]
    end
  end
  nl = bidi.process(newNl, self.frame)
  -- Reconstitute. This code is a bit dodgy. Currently we have a bunch of nodes
  -- each with one Unicode character in them. Sending that to the shaper one-at-a-time
  -- will cause, e.g. Arabic letters to all come out as isolated forms. But equally,
  -- we can't send the whole lot to the shaper at once because Harfbuzz doesn't itemize
  -- them for us, spaces have already been converted to glue, and so on. So we combine
  -- characters with equivalent options/character sets into a single node.
  newNL = {nl[1]}
  local ncount = 1 -- small optimization, save indexing newNL every time
  for i=2,#nl do
    local this = nl[i]
    local prev = newNL[ncount]
    if not this:isUnshaped() or not prev:isUnshaped() then
      ncount = ncount + 1
      newNL[ncount] = this

    -- now both are unshaped, compare them
    elseif SILE.font._key(this.options) == SILE.font._key(prev.options) then -- same font
      prev.text = prev.text .. this.text
    else
      ncount = ncount + 1
      newNL[ncount] = this
    end
  end
  self.state.nodes = newNL
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
The \code{bidi} package, which is loaded by default, provides SILE with the ability to
correctly typeset right-to-left text and also documents which mix right-to-left and 
left-to-right typesetting. Because it is loaded by default, you can use both
LTR and RTL text within a paragraph and SILE will ensure that the output 
characters appear in the correct order.

The \code{bidi} package provides two commands, \command{\\thisframeLTR} and
\command{\\thisframeRTL}, which set the default text direction for the current frame.
That is, if you tell SILE that a frame is RTL, the text will start in the right margin
and proceed leftward.

\end{document}]] }