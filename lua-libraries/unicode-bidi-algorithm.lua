bidi            = bidi or { }

bidi.module     = {
  name        = "bidi",
  version     = 0.003,
  date        = "2011/09/05",
  description = "Unicode Bidirectional Algorithm implementation for LuaTeX",
  author      = "Khaled Hosny",
  copyright   = "Khaled Hosny",
  license     = "CC0",
}

if not modules then modules = { } end modules ['bidi'] = bidi.module

--[[
  This code started as a line for line translation of Arabeyes' minibidi.c from
  C to lua, excluding parts that of no use to us like shaping.

  The C code is Copyright (c) 2004 Ahmad Khalifa, and is distributed under the
  MIT Licence. The full license text:
  http://svn.arabeyes.org/viewvc/projects/adawat/minibidi/LICENCE
--]]

local MAX_STACK = 60

local format, upper, max = string.format, string.upper, math.max
require("char-def")
local chardata  = characters.data

local function get_bidi_type(c)
  local dir = chardata[c] and chardata[c].direction or "l"
  return dir
end

local function get_mirror(c)
  local mir = chardata[c] and chardata[c].mirror
  return mir
end

local function odd(x)
  return x%2 == 1 and true or false
end

local function least_greater_odd(x)
  return odd(x) and x+2 or x+1
end

local function least_greater_even(x)
  return odd(x) and x+1 or x+2
end

local function type_of_level(x)
  return odd(x) and "r" or "l"
end

local function dir_of_level(x)
  return format("T%sT", upper(type_of_level(x)))
end

local function Set(list)
  local set = {}
  for _,v in ipairs(list) do
    set[v] = true
  end
  return set
end

local function is_whitespace(x)
  if Set{"lre", "rle", "lro", "rlo", "pdf", "bn", "ws"}[x] then
    return true
  end
end

local function find_run_limit(line, run_start, limit, types)
  local run_limit = run_start
  local i = run_start
  while i <= limit and Set(types)[line[i].type] do
    run_limit = i
    i = i + 1
  end
  return run_limit
end

local function get_base_level(line)
  -- P2, P3
  for _,c in next, line do
    if c.type == "r" or c.type == "al" then
      return 1
    elseif c.type == "l" then
      return 0
    end
  end
  return 0
end

local function resolve_explicit(line, base_level)
  --[[
  to be checked:
  X1. Begin by setting the current embedding level to the paragraph
    embedding level. Set the directional override status to neutral.
  X8. All explicit directional embeddings and overrides are completely
  terminated at the end of each paragraph. Paragraph separators are not
  included in the embedding. (Useless here) NOT IMPLEMENTED
  --]]

  local curr_level    = base_level
  local curr_override = "on"
  local stack         = { }

  for _,c in next, line do
    -- X2
    if c.type == "rle" then
      if #stack <= MAX_STACK then
        table.insert  (stack, {curr_level, curr_override})
        curr_level    = least_greater_odd(curr_level)
        curr_override =  "on"
        c.level       = curr_level
        c.type        = "bn"
        c.remove      = true
      end
    -- X3
    elseif c.type == "lre" then
      if #stack < MAX_STACK then
        table.insert  (stack, {curr_level, curr_override})
        curr_level    = least_greater_even(curr_level)
        curr_override =  "on"
        c.level       = curr_level
        c.type        = "bn"
        c.remove      = true
      end
    -- X4
    elseif c.type == "rlo" then
      if #stack <= MAX_STACK then
        table.insert  (stack, {curr_level, curr_override})
        curr_level    = least_greater_odd(curr_level)
        curr_override = "r"
        c.level       = curr_level
        c.type        = "bn"
        c.remove      = true
      end
    -- X5
    elseif c.type == "lro" then
      if #stack < MAX_STACK then
        table.insert  (stack, {curr_level, curr_override})
        curr_level    = least_greater_even(curr_level)
        curr_override = "l"
        c.level       = curr_level
        c.type        = "bn"
        c.remove      = true
      end
    -- X7
    elseif c.type == "pdf" then
      if #stack > 0 then
        curr_level, curr_override = unpack(table.remove(stack))
        c.level  = curr_level
        c.type   = "bn"
        c.remove = true
      end
    -- X6
    else
      c.level = curr_level
      if curr_override ~= "on" then
        c.type  = curr_override
      end
    end
  end
end

local function resolve_weak(line, start, limit, sor, eor)
  -- W1
  for i = start, limit do
    local c = line[i]
    if c.type == "nsm" then
      if i == start then
        c.type = sor
      else
        c.type = line[i-1].type
      end
    end
  end

  -- W2
  for i = start, limit do
    local c = line[i]
    if c.type == "en" then
      for j = i - 1, start, -1 do
        local bc = line[j]
        if bc.type == "al" then
          c.type = "an"
          break
        elseif bc.type == "r" or bc.type == "l" then
          break
        end
      end
    end
  end

  -- W3
  for i = start, limit do
    local c = line[i]
    if c.type == "al" then
      c.type = "r"
    end
  end

  -- W4
  for i = start+1, limit-1 do
    local c, pc, nc = line[i], line[i-1], line[i+1]
    if c.type == "es" or c.type == "cs"  then
      if pc.type == "en" and nc.type == "en" then
        c.type = "en"
      elseif c.type == "cs" and pc.type == "an" and nc.type == "an" then
        c.type = "an"
      end
    end
  end

  -- W5
  local i = start
  while i <= limit do
    if line[i].type == "et" then
      local et_start, et_limit, t
      et_start = i
      et_limit = find_run_limit(line, et_start, limit, {"et"})

      t = (et_start == start and sor) or line[et_start-1].type

      if t ~= "en" then
        t = (et_limit == limit and eor) or line[et_limit+1].type
      end

      if t == "en" then
        for j = et_start, et_limit do
          line[j].type = "en"
        end
      end
      i = et_limit
    end
    i = i + 1
  end

  -- W6
  for i = start, limit do
    local c = line[i]
    if c.type == "es" or c.type == "et" or c.type == "cs" then
      c.type = "on"
    end
  end

  -- W7
  for i = start, limit do
    local c = line[i]
    if c.type == "en" then
      local prev_strong = sor
      for j = i - 1, start, -1 do
        if line[j].type == "l" or line[j].type == "r" then
          prev_strong = line[j].type
          break
        end
      end
      if prev_strong == "l" then
        c.type = "l"
      end
    end
  end
end

local function resolve_neutral(line, start, limit, sor, eor)
  -- N1, N2
  for i = start, limit do
    local c = line[i]
    if c.type == "b" or c.type == "s" or c.type == "ws" or c.type == "on" then
      local n_start, n_limit, leading_type, trailing_type, resolved_type
      n_start = i
      n_limit = find_run_limit(line, n_start, limit, {"b", "s", "ws", "on"})

      if n_start == start then
        leading_type = sor
      else
        leading_type = line[n_start-1].type
        if leading_type == "en" or leading_type == "an" then
          leading_type = "r"
        end
      end

      if n_limit == limit then
        trailing_type = eor
      else
        trailing_type = line[n_limit+1].type
        if trailing_type == "en" or trailing_type == "an" then
          trailing_type = "r"
        end
      end

      if leading_type == trailing_type then
        -- N1
        resolved_type = leading_type
      else
        -- N2
        resolved_type = type_of_level(line[i].level)
      end
      for j = n_start, n_limit do
        line[j].type = resolved_type
      end
      i = n_limit
    end
    i = i + 1
  end
end

local function resolve_implicit(line, start, limit, sor, eor)
  -- I1
  for i = start, limit do
    local c = line[i]
    if not odd(c.level) then
      if c.type == "r" then
        c.level = c.level + 1
      elseif c.type == "an" or c.type == "en" then
        c.level = c.level + 2
      end
    end
  end

  -- I2
  for i = start, limit do
    local c = line[i]
    if odd(c.level) then
      if c.type == "l" or c.type == "en" or c.type == "an" then
        c.level = c.level + 1
      end
    end
  end
end

local function resolve_levels(line, base_level)
  -- Rules X1 to X9
  resolve_explicit(line, base_level)

  -- X10
  local start = 1
  while start < #line do
    local level = line[start].level

    local limit = start + 1
    while limit < #line and line[limit].level == level do
      limit = limit + 1
    end

    local prev_level = (start == 1 and base_level) or line[start-1].level
    local next_level = (limit == #line and base_level) or line[limit+1].level
    local sor = type_of_level(max(level, prev_level))
    local eor = type_of_level(max(level, next_level))

    -- Rules W1 to W7
    resolve_weak(line, start, limit, sor, eor)

    -- Rules N1 and N2
    resolve_neutral(line, start, limit, sor, eor)

    -- Rules I1 and I2
    resolve_implicit(line, start, limit, sor, eor)

    start = limit
  end

  -- L1
  for i,c in next, line do
    -- (1)
    if c.orig_type == "s" or c.orig_type == "b" then
      c.level = base_level
      -- (2)
      for j = i - 1, 1, -1 do
        local bc = line[j]
        if is_whitespace(bc.orig_type) then
          bc.level = base_level
        else
          break
        end
      end
    end
  end
  -- (3)
  for i = #line, 1, -1 do
    local bc = line[i]
    if is_whitespace(bc.orig_type) then
      bc.level = base_level
    else
      break
    end
  end

  -- L4
  for _,c in next, line do
    if odd(c.level) then
      c.mirror = get_mirror(c.char)
    end
  end

  return line
end

local obj_code = 0xFFFC -- A who-cares character

local function node_to_table(nodelist)
  -- Takes a node list and returns its textual representation
  local line = {}
  for i = 1,#nodelist do
    local n = nodelist[i]
    if not(type(n) == "table") then
      c = SU.codepoint(n)
    elseif n.type == "hbox" and n.value and n.value.text then
      c = SU.codepoint(n.value.text)
    elseif n.text then
      c = SU.codepoint(n.text)
    elseif n:isGlue() then
      c = 0x0020 -- space
    else
      c = obj_code
    end
    line[#line+1] = { char = c, type = get_bidi_type(c), orig_type = get_bidi_type(c), level = 0 }
  end

  return line
end

-- Dumb stupid version
local function reverse_portion(tbl, s,e)
  rv = {}
  for i = 1,s-1 do rv[#rv+1] = tbl[i] end
  for i = e,s,-1 do rv[#rv+1] = tbl[i] end
  for i = e+1, #tbl do rv[#rv+1] = tbl[i] end
  return rv
end
local function backwards(t)
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

local function create_matrix(line, base_level)
  -- L2; create a transformation matrix of elements
  -- such that output[matrix[i]] = input[i]
  -- e.g. No reversions required: [1,2,3,4,5]
  -- Levels [0,0,0,1,1] -> [1,2,3,5,4]

  local max_level = 0
  local matrix = {}
  for i,c in next, line do
    if c.level > max_level then max_level = c.level end
    matrix[i] = i
  end

  for level = base_level+1, max_level do
    local level_start, level_limit
    for i,_ in next, line do
      if line[i].level >= level then
        if not level_start then
          level_start = i
        elseif i == #line then
          level_end = i
          matrix = reverse_portion(matrix, level_start, level_end)
          level_start = nil
        end
      else
        if level_start then
          level_end = i-1
          matrix = reverse_portion(matrix, level_start, level_end)
          level_start = nil
        end
      end
    end
  end

  return matrix
end

local function process(nodelist, frame, justlevels)
  -- main node list processing
  -- return early if there is nothing to process
  if not nodelist then
    return nodelist
  end

  local line, base_level, par_dir

  -- convert node list into our internal structure, this way the bidi
  -- implementation is kept separate from actual node list processing
  line = node_to_table(nodelist)

  -- set paragraph direction according to main direction set by the user,
  -- else based on first strong bidi character according to the algorithm
    if frame.direction then
      base_level = frame:writingDirection() == "RTL" and 1 or 0
    else
      base_level = get_base_level(line)
    end

  -- will be used later to set direction of sublists
  par_dir = dir_of_level(base_level)

  -- run the bidi algorithm
  line = resolve_levels(line, base_level)
  if justlevels then
    local levels = {}
    for i=1,#line do levels[i]=line[i].level end
    return levels
  end
  matrix = create_matrix(line, base_level)
  assert(#line == #nodelist)
  local rv = {}
  for i = 1, #nodelist do
    rv[matrix[i]] = nodelist[i]
    local thisNode = rv[matrix[i]]
  end
  return rv
end

return { process = process, get_bidi_type = get_bidi_type, create_matrix = create_matrix }