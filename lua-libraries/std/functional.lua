--[[--
 Functional programming.
 @module std.functional
]]

local list = require "std.base"

local functional -- forward declaration


--- Return given metamethod, if any, or nil.
-- @param x object to get metamethod of
-- @param n name of metamethod to get
-- @return metamethod function or nil if no metamethod or not a
-- function
local function metamethod (x, n)
  local _, m = pcall (function (x)
                        return getmetatable (x)[n]
                      end,
                      x)
  if type (m) ~= "function" then
    m = nil
  end
  return m
end


--- Identity function.
-- @param ...
-- @return the arguments passed to the function
local function id (...)
  return ...
end


--- Partially apply a function.
-- @param f function to apply partially
-- @param ... arguments to bind
-- @return function with ai already bound
local function bind (f, ...)
  local fix = {...}
  return function (...)
           return f (unpack (list.concat (fix, {...})))
         end
end


--- Curry a function.
-- @param f function to curry
-- @param n number of arguments
-- @return curried version of f
local function curry (f, n)
  if n <= 1 then
    return f
  else
    return function (x)
             return curry (bind (f, x), n - 1)
           end
  end
end


--- Compose functions.
-- @param f1...fn functions to compose
-- @return composition of f1 ... fn
local function compose (...)
  local arg = {...}
  local fns, n = arg, #arg
  return function (...)
           local arg = {...}
           for i = n, 1, -1 do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end


--- Memoize a function, by wrapping it in a functable.
-- @param fn function that returns a single result
-- @return memoized function
local function memoize (fn)
  return setmetatable ({}, {
    __call = function (self, ...)
               local k = tostring ({...})
               local v = self[k]
               if v == nil then
                 v = fn (...)
                 self[k] = v
               end
               return v
             end
  })
end


--- Evaluate a string.
-- @param s string
-- @return value of string
local function eval (s)
  return loadstring ("return " .. s)()
end


--- Collect the results of an iterator.
-- @param i iterator
-- @return results of running the iterator on its arguments
local function collect (i, ...)
  local t = {}
  for e in i (...) do
    table.insert (t, e)
  end
  return t
end


--- Map a function over an iterator.
-- @param f function
-- @param i iterator
-- @return result table
local function map (f, i, ...)
  local t = {}
  for e in i (...) do
    local r = f (e)
    if r then
      table.insert (t, r)
    end
  end
  return t
end


--- Filter an iterator with a predicate.
-- @param p predicate
-- @param i iterator
-- @return result table containing elements e for which p (e)
local function filter (p, i, ...)
  local t = {}
  for e in i (...) do
    if p (e) then
      table.insert (t, e)
    end
  end
  return t
end


--- Fold a binary function into an iterator.
-- @param f function
-- @param d initial first argument
-- @param i iterator
-- @return result
local function fold (f, d, i, ...)
  local r = d
  for e in i (...) do
    r = f (r, e)
  end
  return r
end

--- @export
functional = {
  bind       = bind,
  collect    = collect,
  compose    = compose,
  curry      = curry,
  eval       = eval,
  filter     = filter,
  fold       = fold,
  id         = id,
  map        = map,
  memoize    = memoize,
  metamethod = metamethod,
}

--- Functional forms of infix operators.
-- Defined here so that other modules can write to it.
-- @table op
-- @field [] dereference table index
-- @field + addition
-- @field - subtraction
-- @field * multiplication
-- @field / division
-- @field and logical and
-- @field or logical or
-- @field not logical not
-- @field == equality
-- @field ~= inequality
functional.op = {
  ["[]"]  = function (t, s) return t[s]    end,
  ["+"]   = function (a, b) return a + b   end,
  ["-"]   = function (a, b) return a - b   end,
  ["*"]   = function (a, b) return a * b   end,
  ["/"]   = function (a, b) return a / b   end,
  ["and"] = function (a, b) return a and b end,
  ["or"]  = function (a, b) return a or b  end,
  ["not"] = function (a)    return not a   end,
  ["=="]  = function (a, b) return a == b  end,
  ["~="]  = function (a, b) return a ~= b  end,
}

return functional
