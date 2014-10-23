--[[--
 Container object.

 A container is a @{std.object} with no methods.  It's functionality is
 instead defined by its *meta*methods.

 Where an Object uses the `\_\_index` metatable entry to hold object
 methods, a Container stores its contents using `\_\_index`, preventing
 it from having methods in there too.

 Although there are no actual methods, Containers are free to use
 metamethods (`\_\_index`, `\_\_sub`, etc) and, like Objects, can supply
 module functions by listing them in `\_functions`.  Also, since a
 @{std.container} is a @{std.object}, it can be passed to the
 @{std.object} module functions, or anywhere else a @{std.object} is
 expected.

 Container derived objects returned directly from a `require` statement
 may also provide module functions, which can be called only from the
 initial prototype object returned by `require`, but are **not** passed
 on to derived objects during cloning:

      > Container = require "std.container"
      > x = Container {}
      > = Container.prototype (x)
      Object
      > = x.prototype (o)
      stdin:1: attempt to call field 'prototype' (a nil value)
      ...

 To add functions like this to your own prototype objects, pass a table
 of the module functions in the `_functions` private field before
 cloning, and those functions will not be inherited by clones.

      > Container = require "std.container"
      > Graph = Container {
      >>   _type = "Graph",
      >>   _functions = {
      >>     nodes = function (graph)
      >>       local n = 0
      >>       for _ in pairs (graph) do n = n + 1 end
      >>       return n
      >>     end,
      >>   },
      >> }
      > g = Graph { "node1", "node2" }
      > = Graph.nodes (g)
      2
      > = g.nodes
      nil

 When making your own prototypes, start from @{std.container} if you
 want to access the contents of your objects with the `[]` operator, or
 @{std.object} if you want to access the functionality of your objects
 with named object methods.

 @classmod std.container
]]


local base = require "std.base"

local clone, merge = base.clone, base.merge


local ModuleFunction = {
  __tostring = function (self) return tostring (self.call) end,
  __call     = function (self, ...) return self.call (...) end,
}


--- Mark a function not to be copied into clones.
--
-- It responds to `type` with `table`, but otherwise behaves like a
-- regular function.  Marking uncopied module functions in-situ like this
-- (as opposed to doing book keeping in the metatable) means that we
-- don't have to create a new metatable with the book keeping removed for
-- cloned objects, we can just share our existing metatable directly.
-- @func fn a function
-- @treturn functable a callable functable for `fn`
local function modulefunction (fn)
  return setmetatable ({_type = "modulefunction", call = fn}, ModuleFunction)
end


--- Return `obj` with references to the fields of `src` merged in.
-- @static
-- @tparam table obj destination object
-- @tparam table src fields to copy int clone
-- @tparam[opt={}] table map `{old_key=new_key, ...}`
-- @treturn table `obj` with non-private fields from `src` merged, and
--   a metatable with private fields (if any) merged, both sets of keys
--   renamed according to `map`
-- @see std.object.mapfields
local function mapfields (obj, src, map)
  map = map or {}
  local mt = getmetatable (obj) or {}

  -- Map key pairs.
  for k, v in pairs (src) do
    local key, dst = map[k] or k, obj
    if type (key) == "string" and key:sub (1, 1) == "_" then
      dst = mt
    end
    dst[key] = v
  end

  -- Quicker to remove this after copying fields than test for it
  -- it on every iteration above.
  mt._functions = nil

  -- Inject module functions.
  for k, v in pairs (src._functions or {}) do
    obj[k] = modulefunction (v)
  end

  -- Only set non-empty metatable.
  if next (mt) then
    setmetatable (obj, mt)
  end
  return obj
end


-- Type of this container.
-- @static
-- @tparam  std.container o  an container
-- @treturn string        type of the container
-- @see std.object.prototype
local function prototype (o)
  return (getmetatable (o) or {})._type or type (o)
end


--- Container prototype.
-- @table std.container
-- @string[opt="Container"] _type type of Container, returned by
--   @{std.object.prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, used by @{__call}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
local metatable = {
  _type = "Container",
  _init = {},

  --- Return a clone of this container.
  -- @function __call
  -- @param x a table if prototype `_init` is a table, otherwise first
  --   argument for a function type `_init`
  -- @param ... any additional arguments for `_init`
  -- @treturn std.container a clone of the called container.
  -- @see std.object:__call
  __call = function (self, x, ...)
    local mt     = getmetatable (self)
    local obj_mt = mt
    local obj    = {}

    -- This is the slowest part of cloning for any objects that have
    -- a lot of fields to test and copy.  If you need to clone a lot of
    -- objects from a prototype with several module functions, it's much
    -- faster to clone objects from each other than the prototype!
    for k, v in pairs (self) do
      if type (v) ~= "table" or v._type ~= "modulefunction" then
	obj[k] = v
      end
    end

    if type (mt._init) == "table" then
      obj = (self.mapfields or mapfields) (obj, x, mt._init)
    else
      obj = mt._init (obj, x, ...)
    end

    -- If a metatable was set, then merge our fields and use it.
    if next (getmetatable (obj) or {}) then
      obj_mt = merge (clone (mt), getmetatable (obj))

      -- Merge object methods.
      if type (obj_mt.__index) == "table" and
        type ((mt or {}).__index) == "table"
      then
	obj_mt.__index = merge (clone (mt.__index), obj_mt.__index)
      end
    end

    return setmetatable (obj, obj_mt)
  end,


  --- Return a string representation of this container.
  -- @function __tostring
  -- @treturn string        stringified container representation
  -- @see std.object.__tostring
  __tostring = function (self)
    local totable = getmetatable (self).__totable
    local array = clone (totable (self), "nometa")
    local other = clone (array, "nometa")
    local s = ""
    if #other > 0 then
      for i in ipairs (other) do other[i] = nil end
    end
    for k in pairs (other) do array[k] = nil end
    for i, v in ipairs (array) do array[i] = tostring (v) end

    local keys, dict = {}, {}
    for k in pairs (other) do table.insert (keys, k) end
    table.sort (keys, function (a, b) return tostring (a) < tostring (b) end)
    for _, k in ipairs (keys) do
      table.insert (dict, tostring (k) .. "=" .. tostring (other[k]))
    end

    if #array > 0 then
      s = s .. table.concat (array, ", ")
      if next (dict) ~= nil then s = s .. "; " end
    end
    if #dict > 0 then
      s = s .. table.concat (dict, ", ")
    end

    return prototype (self) .. " {" .. s .. "}"
  end,


  --- Return a table representation of this container.
  -- @function __totable
  -- @treturn table a shallow copy of non-private container fields
  -- @see std.object:__totable
  __totable  = function (self)
    local t = {}
    for k, v in pairs (self) do
      if type (k) ~= "string" or k:sub (1, 1) ~= "_" then
	t[k] = v
      end
    end
    return t
  end,
}

return setmetatable ({

  -- Normally, these are set and wrapped automatically during cloning.
  -- But, we have to bootstrap the first object, so in this one instance
  -- it has to be done manually.

  mapfields = modulefunction (mapfields),
  prototype = modulefunction (prototype),
}, metatable)
