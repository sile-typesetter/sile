local base = require("packages.base")

local package = pl.class(base)
package._name = "bidi"

local icu = require("justenoughicu")

local function reverse_portion (tbl, s, e)
  local rv = {}
  for i = 1, s-1 do rv[#rv+1] = tbl[i] end
  for i = e, s, -1 do rv[#rv+1] = tbl[i] end
  for i = e+1, #tbl do rv[#rv+1] = tbl[i] end
  return rv
end

local function create_matrix (line, base_level)
  -- L2; create a transformation matrix of elements
  -- such that output[matrix[i]] = input[i]
  -- e.g. No reversions required: [1, 2, 3, 4, 5]
  -- Levels [0, 0, 0, 1, 1] -> [1, 2, 3, 5, 4]

  local max_level = 0
  local matrix = {}
  for i, c in next, line do
    if c.level > max_level then max_level = c.level end
    matrix[i] = i
  end

  for level = base_level+1, max_level do
    local level_start
    for i, _ in next, line do
      if line[i].level >= level then
        if not level_start then
          level_start = i
        elseif i == #line then
          local level_end = i
          matrix = reverse_portion(matrix, level_start, level_end)
          level_start = nil
        end
      else
        if level_start then
          local level_end = i-1
          matrix = reverse_portion(matrix, level_start, level_end)
          level_start = nil
        end
      end
    end
  end

  return matrix
end

local function reverse_each_node (nodelist)
  for j = 1, #nodelist do
    if nodelist[j].type =="hbox" then
      if nodelist[j].value.items then SU.flip_in_place(nodelist[j].value.items) end
      SU.flip_in_place(nodelist[j].value.glyphString)
    end
  end
end

local nodeListToText = function (nl)
  local owners, text = {}, {}
  local p = 1
  for i = 1, #nl do local n = nl[i]
    if n.text then
      local utfchars = SU.splitUtf8(n.text)
      for j = 1, #utfchars do
        owners[p] = { node = n, pos = j }
        text[p] = utfchars[j]
        p = p + 1
      end
    else
      owners[p] = { node = n }
      text[p] = luautf8.char(0xFFFC)
      p = p + 1
    end
  end
  return owners, text
end

local splitNodeAtPos = function (n, splitstart, p)
  if n.is_unshaped then
    local utf8chars = SU.splitUtf8(n.text)
    local n2 = SILE.types.node.unshaped({ text = "", options = pl.tablex.copy(n.options) })
    local n1 = SILE.types.node.unshaped({ text = "", options = pl.tablex.copy(n.options) })
    for i = splitstart, #utf8chars do
      if i <= p then n1.text = n1.text .. utf8chars[i]
      else n2.text = n2.text .. utf8chars[i]
      end
    end
    return n1, n2
  else
    SU.error("Unsure how to split node " .. tostring(n) .. " at position " .. p, true)
  end
end

local splitNodelistIntoBidiRuns = function (typesetter)
  local nl = typesetter.state.nodes
  if #nl == 0 then return nl end
  local owners, text = nodeListToText(nl)
  local base_level = typesetter.frame:writingDirection() == "RTL" and 1 or 0
  local runs = { icu.bidi_runs(table.concat(text), typesetter.frame:writingDirection()) }
  table.sort(runs, function (a, b) return a.start < b.start end)
  -- local newNl = {}
  -- Split nodes on run boundaries
  for i = 1, #runs do
    local run = runs[i]
    local thisOwner = owners[run.start+run.length]
    local nextOwner = owners[run.start+1+run.length]
    -- print(thisOwner, nextOwner)
    if nextOwner and thisOwner.node == nextOwner.node then
      local before, after = splitNodeAtPos(nextOwner.node, 1, nextOwner.pos-1)
      -- print(before, after)
      local start = nil
      for j = run.start+1, run.start+run.length do
        if owners[j].node==nextOwner.node then
          if not start then start = j end
          owners[j]={ node=before ,pos=j-start+1 }
        end
      end
      for j = run.start + 1 + run.length, #owners do
        if owners[j].node==nextOwner.node then
          owners[j] = { node = after, pos = j - (run.start + run.length) }
        end
      end
    end
  end
  -- Assign direction/level to nodes
  for i = 1, #runs do
    local runstart = runs[i].start+1
    local runend   = runstart + runs[i].length-1
    for j= runstart, runend do
      if owners[j].node and owners[j].node.options then
        owners[j].node.options.direction = runs[i].dir
        owners[j].node.options.bidilevel = runs[i].level - base_level
      end
    end
  end
  -- String together nodelist
  nl={}
  for i = 1, #owners do
    if #nl and nl[#nl] ~= owners[i].node then
      nl[#nl+1] = owners[i].node
      -- print(nl[#nl], nl[#nl].options)
    end
  end
  -- for i = 1, #nl do print(i, nl[i]) end
  return nl
end

local bidiBoxupNodes = function (typesetter)
  local allDone = true
  for i = 1, #typesetter.state.nodes do
    if not typesetter.state.nodes[i].bidiDone then allDone = false end
  end
  if allDone then return typesetter:nobidi_boxUpNodes() end
  local newNodeList = splitNodelistIntoBidiRuns(typesetter)
  typesetter:shapeAllNodes(newNodeList)
  typesetter.state.nodes = newNodeList
  local vboxlist = typesetter:nobidi_boxUpNodes()
  -- Scan for out-of-direction material
  for i = 1, #vboxlist do
    local v = vboxlist[i]
    if v.is_vbox then package.reorder(nil, v, typesetter) end
  end
  return vboxlist
end

function package.reorder (_, n, typesetter)
  local nl = n.nodes
  -- local newNl = {}
  -- local matrix = {}
  local levels = {}
  local base_level = typesetter.frame:writingDirection() == "RTL" and 1 or 0
  for i = 1, #nl do
    if nl[i].options and nl[i].options.bidilevel then
      levels[i] = { level = nl[i].options.bidilevel }
    end
  end
  for i = 1, #nl do
    if not levels[i] then
      -- resolve neutrals
      local left_level, right_level
      for left = i - 1, 1, -1 do
        if nl[left].options and nl[left].options.bidilevel then
          left_level = nl[left].options.bidilevel
          break
        end
      end
      for right = i + 1, #nl do
        if nl[right].options and nl[right].options.bidilevel then
          right_level = nl[right].options.bidilevel
          break
        end
      end
      levels[i] = { level = (left_level == right_level and left_level or 0) }
    end
  end
  local matrix = create_matrix(levels, 0)
  local rv = {}
  -- for i = 1, #nl do print(i, nl[i], levels[i]) end
  for i = 1, #nl do
    if nl[i].is_nnode and levels[i].level %2 ~= base_level then
      SU.flip_in_place(nl[i].nodes)
      reverse_each_node(nl[i].nodes)
    elseif nl[i].is_discretionary and levels[i].level %2 ~= base_level and not nl[i].bidiDone then
      for j = 1, #(nl[i].replacement) do
        if nl[i].replacement[j].is_nnode then
          SU.flip_in_place(nl[i].replacement[j].nodes)
          reverse_each_node(nl[i].replacement[j].nodes)
        end
      end
      for j = 1, #(nl[i].prebreak) do
        if nl[i].prebreak[j].is_nnode then
          SU.flip_in_place(nl[i].prebreak[j].nodes)
          reverse_each_node(nl[i].prebreak[j].nodes)
        end
      end
      for j = 1, #(nl[i].postbreak) do
        if nl[i].postbreak[j].is_nnode then
          SU.flip_in_place(nl[i].postbreak[j].nodes)
          reverse_each_node(nl[i].postbreak[j].nodes)
        end
      end

    end
    rv[matrix[i]] = nl[i]
    nl[i].bidiDone = true
    -- rv[i] = nl[i]
  end
  n.nodes = SU.compress(rv)
end

function package:bidiEnableTypesetter (typesetter)
  if typesetter.nobidi_boxUpNodes and self.class._initialized then
    return SU.warn("BiDi already enabled, nothing to turn on")
  end
  typesetter.nobidi_boxUpNodes = typesetter.boxUpNodes
  typesetter.boxUpNodes = bidiBoxupNodes
end

function package:bidiDisableTypesetter (typesetter)
  if not typesetter.nobidi_boxUpNodes and self.class._initialized then
    return SU.warn("BiDi not enabled, nothing to turn off")
  end
  typesetter.boxUpNodes = typesetter.nobidi_boxUpNodes
  typesetter.nobidi_boxUpNodes = nil
end

function package:_init ()
  base._init(self)
  self:deprecatedExport("reorder", self.reorder)
  self:deprecatedExport("bidiEnableTypesetter", self.bidiEnableTypesetter)
  self:deprecatedExport("bidiDisableTypesetter", self.bidiDisableTypesetter)
  if SILE.typesetter then
    self:bidiEnableTypesetter(SILE.typesetter)
  end
  self:bidiEnableTypesetter(SILE.typesetters.base)
end

function package:registerCommands ()

  self:registerCommand("thisframeLTR", function (_, _)
    local direction = "LTR"
    SILE.typesetter.frame.direction = direction
    SILE.settings:set("font.direction", direction)
    SILE.typesetter:leaveHmode()
    SILE.typesetter.frame:newLine()
  end)

  self:registerCommand("thisframedirection", function (options, _)
    local direction = SU.required(options, "direction", "frame direction")
    SILE.typesetter.frame.direction = direction
    SILE.settings:set("font.direction", direction)
    SILE.typesetter:leaveHmode()
    SILE.typesetter.frame:init()
  end)

  self:registerCommand("thisframeRTL", function (_, _)
    local direction = "RTL"
    SILE.typesetter.frame.direction = direction
    SILE.settings:set("font.direction", direction)
    SILE.typesetter:leaveHmode()
    SILE.typesetter.frame:newLine()
  end)

  self:registerCommand("bidi-on", function (_, _)
    self:bidiEnableTypesetter(SILE.typesetter)
  end)

  self:registerCommand("bidi-off", function (_, _)
    self:bidiDisableTypesetter(SILE.typesetter)
  end)

end

package.documentation = [[
\begin{document}
Scripts like the Latin alphabet you are currently reading are normally written left to right (LTR); however, some scripts, such as Arabic and Hebrew, are written right to left (RTL).
The \autodoc:package{bidi} package, which is loaded by default, provides SILE with the ability to correctly typeset right-to-left text and also documents which mix right-to-left and left-to-right typesetting.
Because it is loaded by default, you can use both LTR and RTL text within a paragraph and SILE will ensure that the output characters appear in the correct order.

The \autodoc:package{bidi} package provides two commands, \autodoc:command{\thisframeLTR} and \autodoc:command{\thisframeRTL}, which set the default text direction for the current frame.
If you tell SILE that a frame is RTL, the text will start in the right margin and proceed leftward.
It also provides the commands \autodoc:command{\bidi-off} and \autodoc:command{\bidi-on}, which allow you to trade off bidirectional support for a dubious increase in speed.
\end{document}
]]

return package
