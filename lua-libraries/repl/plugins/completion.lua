-- Copyright (c) 2011-2014 Rob Hoelz <rob@hoelz.ro>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local getmetatable = getmetatable
local pairs        = pairs
local sfind        = string.find
local sgmatch      = string.gmatch
local smatch       = string.match
local ssub         = string.sub
local tconcat      = table.concat
local tsort        = table.sort
local type         = type

local function isindexable(value)
  if type(value) == 'table' then
    return true
  end

  local mt = getmetatable(value)

  return mt and mt.__index
end

local function getcompletions(t)
  local union = {}

  while isindexable(t) do
    if type(t) == 'table' then
      -- XXX what about the pairs metamethod in 5.2?
      --     either we don't care, we implement a __pairs-friendly
      --     pairs for 5.1, or implement a 'rawpairs' for 5.2
      for k, v in pairs(t) do
        if union[k] == nil then
          union[k] = v
        end
      end
    end

    local mt = getmetatable(t)
    t        = mt and mt.__index or nil
  end

  return pairs(union)
end

local function split_ns(expr)
  if expr == '' then
    return { '' }
  end

  local pieces = {}

  -- XXX method calls too (option?)
  for m in sgmatch(expr, '[^.]+') do
    pieces[#pieces + 1] = m
  end

  -- logic for determining whether to pad the matches with the empty
  -- string (ugly)
  if ssub(expr, -1) == '.' then
    pieces[#pieces + 1] = ''
  end

  return pieces
end

local function determine_ns(expr)
  local ns     = _G -- XXX what if the REPL lives in a special context? (option?)
  local pieces = split_ns(expr)

  for index = 1, #pieces - 1 do
    local key = pieces[index]
    -- XXX rawget? or regular access? (option?)
    ns = ns[key]

    if not isindexable(ns) then
      return {}, '', ''
    end
  end

  expr = pieces[#pieces]

  local prefix = ''

  if #pieces > 1 then
    prefix = tconcat(pieces, '.', 1, #pieces - 1) .. '.'
  end

  local last_piece = pieces[#pieces]

  local before, after = smatch(last_piece, '(.*):(.*)')

  if before then
    ns     = ns[before] -- XXX rawget
    prefix = prefix .. before .. ':'
    expr   = after
  end

  return ns, prefix, expr
end

local isidentifierchar

do
  local ident_chars_set = {}
  -- XXX I think this can be done with isalpha in C...
  local ident_chars     = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:_0123456789'

  for i = 1, #ident_chars do
    local char = ssub(ident_chars, i, i)
    ident_chars_set[char] = true
  end

  function isidentifierchar(char)
    return ident_chars_set[char]
  end
end

local function extract_innermost_expr(expr)
  local index = #expr

  while index > 0 do
    local char = ssub(expr, index, index)
    if isidentifierchar(char) then
      index = index - 1
    else
      break
    end
  end

  index = index + 1

  return ssub(expr, 1, index - 1), ssub(expr, index)
end

-- XXX is this logic (namely, returning the entire line) too specific to
--     linenoise?
function repl:complete(expr, callback)
  local ns, prefix, path

  prefix, expr = extract_innermost_expr(expr)

  ns, path, expr = determine_ns(expr)

  prefix = prefix .. path

  local completions = {}

  for k, v in getcompletions(ns) do
    if sfind(k, expr, 1, true) == 1 then
      local suffix = ''
      local type   = type(v)

      -- XXX this should be optional
      if type == 'function' then
        suffix = '('
      elseif type == 'table' then
        suffix = '.'
      end

      completions[#completions + 1] = prefix .. k .. suffix
    end
  end

  tsort(completions)

  for _, completion in ipairs(completions) do
    callback(completion)
  end
end

features = 'completion'
