-- (c) 2009-2011 John MacFarlane.  Released under MIT license.
-- See the file LICENSE in the source for details.

--- Utility functions for lunamark.

local M = {}
local cosmo = require("cosmo")
local rep  = string.rep
local lpeg = require("lpeg")
local Cs, P, S, lpegmatch = lpeg.Cs, lpeg.P, lpeg.S, lpeg.match
local any = lpeg.P(1)

--- Find a template and return its contents (or `false` if
-- not found). The template is sought first in the
-- working directory, then in `templates`, then in
-- `$HOME/.lunamark/templates`, then in the Windows
-- `APPDATA` directory.
function M.find_template(name)
  local base, ext = name:match("([^%.]*)(.*)")
  local fname = base .. ext
  local file = io.open(fname, "read")
  if not file then
    file = io.open("templates/" .. fname, "read")
  end
  if not file then
    local home = os.getenv("HOME")
    if home then
      file = io.open(home .. "/.lunamark/templates/" .. fname, "read")
    end
  end
  if not file then
    local appdata = os.getenv("APPDATA")
    if appdata then
      file = io.open(appdata .. "/lunamark/templates/" .. fname, "read")
    end
  end
  if file then
    local data = file:read("*all")
    file:close()
    return data
  else
    return false, "Could not find template '" .. fname .. "'"
  end
end

--- Implements a `sepby` directive for cosmo templates.
-- `$sepby{ myarray }[[$it]][[, ]]` will render the elements
-- of `myarray` separated by commas. If `myarray` is a string,
-- it will be treated as an array with one element.  If it is
-- `nil`, it will be treated as an empty array.
function M.sepby(arg)
  local a = arg[1]
  if not a then
    a = {}
  elseif type(a) ~= "table" then
    a = {a}
  end
  for i in ipairs(a) do
     if i > 1 then cosmo.yield{_template=2} end
     cosmo.yield{it = a[i], _template=1}
  end
end

--[[
-- extend(t) returns a table that falls back to t for non-found values
function M.extend(prototype)
  local newt = {}
  local metat = { __index = function(t,key)
                              return prototype[key]
                            end }
  setmetatable(newt, metat)
  return newt
end
--]]

--- Print error message and exit.
function M.err(msg, exit_code)
  io.stderr:write("lunamark: " .. msg .. "\n")
  os.exit(exit_code or 1)
end

--- Shallow table copy including metatables.
function M.table_copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

--- Expand tabs in a line of text.
-- `s` is assumed to be a single line of text.
-- From *Programming Lua*.
function M.expand_tabs_in_line(s, tabstop)
  local tab = tabstop or 4
  local corr = 0
  return (s:gsub("()\t", function(p)
          local sp = tab - (p - 1 + corr)%tab
          corr = corr - 1 + sp
          return rep(" ",sp)
        end))
end

--- Walk a rope `t`, applying a function `f` to each leaf element in order.
-- A rope is an array whose elements may be ropes, strings, numbers,
-- or functions. If a leaf element is a function, call it and get the return value
-- before proceeding.
local function walk(t, f)
    local typ = type(t)
    if typ == "string" then
      f(t)
    elseif typ == "table" then
      local i = 1
      local n
      n = t[i]
      while n do
        walk(n, f)
        i = i + 1
        n = t[i]
      end
    elseif typ == "function" then
      local ok, val = pcall(t)
      if ok then
        walk(val,f)
      end
    else
      f(tostring(t))
    end
end

M.walk = walk

--- Flatten an array `ary`.
local function flatten(ary)
  local new = {}
  for _,v in ipairs(ary) do
    if type(v) == "table" then
      for _,w in ipairs(flatten(v)) do
        new[#new + 1] = w
      end
    else
      new[#new + 1] = v
    end
  end
  return new
end

M.flatten = flatten

--- Convert a rope to a string.
local function rope_to_string(rope)
  local buffer = {}
  walk(rope, function(x) buffer[#buffer + 1] = x end)
  return table.concat(buffer)
end

M.rope_to_string = rope_to_string

-- assert(rope_to_string{"one","two"} == "onetwo")
-- assert(rope_to_string{"one",{"1","2"},"three"} == "one12three")

--- Return the last item in a rope.
local function rope_last(rope)
  if #rope == 0 then
    return nil
  else
    local l = rope[#rope]
    if type(l) == "table" then
      return rope_last(l)
    else
      return l
    end
  end
end

-- assert(rope_last{"one","two"} == "two")
-- assert(rope_last{} == nil)
-- assert(rope_last{"one",{"2",{"3","4"}}} == "4")

M.rope_last = rope_last

--- Given an array `ary`, return a new array with `x`
-- interspersed between elements of `ary`.
function M.intersperse(ary, x)
  local new = {}
  local l = #ary
  for i,v in ipairs(ary) do
    local n = #new
    new[n + 1] = v
    if i ~= l then
      new[n + 2] = x
    end
  end
  return new
end

--- Given an array `ary`, return a new array with each
-- element `x` of `ary` replaced by `f(x)`.
function M.map(ary, f)
  local new = {}
  for i,v in ipairs(ary) do
    new[i] = f(v)
  end
  return new
end

--- Given a table `char_escapes` mapping escapable characters onto
-- their escaped versions and optionally `string_escapes` mapping
-- escapable strings (or multibyte UTF-8 characters) onto their
-- escaped versions, returns a function that escapes a string.
-- This function uses lpeg and is faster than gsub.
function M.escaper(char_escapes, string_escapes)
  local char_escapes_list = ""
  for i,_ in pairs(char_escapes) do
    char_escapes_list = char_escapes_list .. i
  end
  local escapable = S(char_escapes_list) / char_escapes
  if string_escapes then
    for k,v in pairs(string_escapes) do
      escapable = P(k) / v + escapable
    end
  end
  local escape_string = Cs((escapable + any)^0)
  return function(s)
    return lpegmatch(escape_string, s)
  end
end


return M
