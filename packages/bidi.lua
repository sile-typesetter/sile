SILE.registerCommand("thisframeLTR", function(options, content)
  SILE.typesetter.frame.direction = "LTR"
  SILE.typesetter:leaveHmode()
  SILE.typesetter.frame:newLine()
end);

SILE.registerCommand("thisframedirection", function(options, content)
  SILE.typesetter.frame.direction = SU.required(options, "direction", "frame direction")
  SILE.typesetter:leaveHmode()
  SILE.typesetter.frame:init()
end);


SILE.registerCommand("thisframeRTL", function(options, content)
  SILE.typesetter.frame.direction = "RTL"
  SILE.typesetter:leaveHmode()
  SILE.typesetter.frame:newLine()
end);

local bidi = require("unicode-bidi-algorithm")
require("char-def")
local chardata  = characters.data

local reorder = function(n, self)
  local nl = n.nodes
  local newNl = {}
  for i=1,#nl do
    newNl[#newNl+1] = nl[i]
    -- XXX Nothing happens?
  end
  n.nodes = newNl
end

local nodeListToText = function (nl)
  local owners, text = {}, {}
  local p = 1
  for i = 1,#nl do local n = nl[i]
    if n.text then
      local utfchars = SU.splitUtf8(n.text)
      for j = 1,#utfchars do
        owners[p] = { node = n, pos = j }
        text[p] = utfchars[j]
        p = p + 1
      end
    else
      owners[p] = { node = n }
      text[p] = SU.utf8char(0xFFFC)
    end
  end
  return owners, text
end

local splitNodeAtPos = function (n,splitstart, p)
  if n:isUnshaped() then
    local utf8chars = SU.splitUtf8(n.text)
    local n2 = SILE.nodefactory.newUnshaped({ text = "", options = table.clone(n.options) })
    local n1 = SILE.nodefactory.newUnshaped({ text = "", options = table.clone(n.options) })
    for i = splitstart,#utf8chars do
      if i < p then n1.text = n1.text .. utf8chars[i]
      else n2.text = n2.text .. utf8chars[i]
      end
    end
    return n1,n2
  else
    SU.error("Unsure how to split node "..n.." at position p",1)
  end
end

local splitNodelistIntoBidiRuns = function (self)
  local nl = self.state.nodes
  if #nl == 0 then return nl end
  local owners, text = nodeListToText(nl)
  local levels = bidi.process(text, {},true)
  local base_direction = "LTR"
  local flipped_direction = "RTL"
  local base_level = self.frame:writingDirection() == "RTL" and 1 or 0
  local lastlevel = base_level
  local nl = {}
  local lastowner
  local splitstart = 1
  for i = 1,#levels do
    if levels[i] % 2 ~= lastlevel % 2 and owners[i].node == lastowner then
      owners[i].bidilevel = levels[i]
      local before,after = splitNodeAtPos(owners[i].node,splitstart,owners[i].pos)
      nl[#nl] = before
      nl[#nl+1] = after
      lastowner = owners[i].node
      splitstart = owners[i].pos
      before.options.bidilevel = lastlevel
      after.options.direction = (levels[i] %2) == 0 and base_direction or flipped_direction
      after.options.bidilevel = levels[i]
      before.options.direction = (levels[i-1] %2) == 0 and base_direction or flipped_direction
      -- assign direction for both nodes
    else
      if owners[i].node ~= lastowner then
        nl[#nl+1] = owners[i].node
        splitstart = 1
        if nl[#nl].options then
          nl[#nl].options.direction = (levels[i] %2) == 0 and base_direction or flipped_direction
        end
      end
      lastowner = owners[i].node
      if nl[#nl].options then nl[#nl].options.bidilevel = (levels[i]) end
    end
    lastlevel = levels[i]
  end
  return nl
end

local bidiBoxupNodes = function (self)
  local newNodeList = splitNodelistIntoBidiRuns(self)
  self.state.nodes = newNodeList
  -- SU.error(1,true)
  local vboxlist = SILE.defaultTypesetter.boxUpNodes(self)
  -- Scan for out-of-direction material
  for i=1,#vboxlist do local v = vboxlist[i]
    if v:isVbox() then reorder(v, self) end
  end
  return vboxlist
end

SILE.typesetter.boxUpNodes = bidiBoxupNodes

SILE.registerCommand("bidi-on", function(options, content)
  SILE.typesetter.boxUpNodes = bidiBoxupNodes
end)

SILE.registerCommand("bidi-off", function(options, content)
  SILE.typesetter.boxUpNodes = SILE.defaultTypesetter.boxUpNodes
end)

return {
reorder = reorder,
documentation = [[\begin{document}

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
and proceed leftward. It also provides the commands \command{\\bidi-off} and
\command{\\bidi-on}, which allow you to trade off bidirectional support for a dubious
increase in speed.

\end{document}]] }
