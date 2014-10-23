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

-- Pretty prints expression results (console only)

local format   = string.format
local tconcat  = table.concat
local tsort    = table.sort
local tostring = tostring
local type     = type
local floor    = math.floor
local pairs    = pairs
local ipairs   = ipairs
local error    = error
local stderr   = io.stderr

pcall(require, 'luarocks.require')
local ok, term = pcall(require, 'term')
if not ok then
  term = nil
end

local keywords = {
  ['and']      = true,
  ['break']    = true,
  ['do']       = true,
  ['else']     = true,
  ['elseif']   = true,
  ['end']      = true,
  ['false']    = true,
  ['for']      = true,
  ['function'] = true,
  ['if']       = true,
  ['in']       = true,
  ['local']    = true,
  ['nil']      = true,
  ['not']      = true,
  ['or']       = true,
  ['repeat']   = true,
  ['return']   = true,
  ['then']     = true,
  ['true']     = true,
  ['until']    = true,
  ['while']    = true,
}

local function compose(f, g)
  return function(...)
    return f(g(...))
  end
end

local emptycolormap = setmetatable({}, { __index = function()
  return function(s)
    return s
  end
end})

local colormap = emptycolormap

if term then
  colormap = {
    ['nil']     = term.colors.blue,
    string      = term.colors.yellow,
    punctuation = compose(term.colors.green, term.colors.bright),
    ident       = term.colors.red,
    boolean     = term.colors.green,
    number      = term.colors.cyan,
    path        = term.colors.white,
    misc        = term.colors.magenta,
  }
end

local function isinteger(n)
  return type(n) == 'number' and floor(n) == n
end

local function isident(s)
  return type(s) == 'string' and not keywords[s] and s:match('^[a-zA-Z_][a-zA-Z0-9_]*$')
end

-- most of these are arbitrary, I *do* want numbers first, though
local type_order = {
  number       = 0,
  string       = 1,
  userdata     = 2,
  table        = 3,
  thread       = 4,
  boolean      = 5,
  ['function'] = 6,
}

local function cross_type_order(a, b)
  local pos_a = type_order[ type(a) ]
  local pos_b = type_order[ type(b) ]

  if pos_a == pos_b then
    return a < b
  else
    return pos_a < pos_b
  end
end

local function sortedpairs(t)
  local keys = {}

  local seen_non_string

  for k in pairs(t) do
    keys[#keys + 1] = k

    if not seen_non_string and type(k) ~= 'string' then
      seen_non_string = true
    end
  end

  local sort_func = seen_non_string and cross_type_order or nil
  tsort(keys, sort_func)

  local index = 1
  return function()
    if keys[index] == nil then
      return nil
    else
      local key   = keys[index]
      local value = t[key]
      index       = index + 1

      return key, value
    end
  end, keys
end

local function find_longstring_nest_level(s)
  local level = 0

  while s:find(']' .. string.rep('=', level) .. ']', 1, true) do
    level = level + 1
  end

  return level
end

local function dump(params)
  local pieces = params.pieces
  local seen   = params.seen
  local path   = params.path
  local v      = params.value
  local indent = params.indent

  local t = type(v)

  if t == 'nil' or t == 'boolean' or t == 'number' then
    pieces[#pieces + 1] = colormap[t](tostring(v))
  elseif t == 'string' then
    if v:match '\n' then
      local level = find_longstring_nest_level(v)
      pieces[#pieces + 1] = colormap.string('[' .. string.rep('=', level) .. '[' .. v .. ']' .. string.rep('=', level) .. ']')
    else
      pieces[#pieces + 1] = colormap.string(format('%q', v))
    end
  elseif t == 'table' then
    if seen[v] then
      pieces[#pieces + 1] = colormap.path(seen[v])
      return
    end

    seen[v] = path

    local lastintkey = 0

    pieces[#pieces + 1] = colormap.punctuation '{\n'
    for i, v in ipairs(v) do
      for j = 1, indent do
        pieces[#pieces + 1] = '  '
      end
      dump {
        pieces = pieces,
        seen   = seen,
        path   = path .. '[' .. tostring(i) .. ']',
        value  = v,
        indent = indent + 1,
      }
      pieces[#pieces + 1] = colormap.punctuation ',\n'
      lastintkey = i
    end

    for k, v in sortedpairs(v) do
      if not (isinteger(k) and k <= lastintkey and k > 0) then
        for j = 1, indent do
          pieces[#pieces + 1] = '  '
        end

        if isident(k) then
          pieces[#pieces + 1] = colormap.ident(k)
        else
          pieces[#pieces + 1] = colormap.punctuation '['
          dump {
            pieces = pieces,
            seen   = seen,
            path   = path .. '.' .. tostring(k),
            value  = k,
            indent = indent + 1,
          }
          pieces[#pieces + 1] = colormap.punctuation ']'
        end
        pieces[#pieces + 1] = colormap.punctuation ' = '
        dump {
          pieces = pieces,
          seen   = seen,
          path   = path .. '.' .. tostring(k),
          value  = v,
          indent = indent + 1,
        }
        pieces[#pieces + 1] = colormap.punctuation ',\n'
      end
    end

    for j = 1, indent - 1 do
      pieces[#pieces + 1] = '  '
    end

    pieces[#pieces + 1] = colormap.punctuation '}'
  else
    pieces[#pieces + 1] = colormap.misc(tostring(v))
  end
end

repl:requirefeature 'console'

function override:displayresults(results)
  local pieces = {}

  for i = 1, results.n do
    dump {
      pieces = pieces,
      seen   = {},
      path   = '<topvalue>',
      value  = results[i],
      indent = 1,
    }
    pieces[#pieces + 1] = '\n'
  end

  stderr:write(tconcat(pieces, ''))
end
