--[[--
 Set container.

 Derived from @{std.container}, and inherits Container's metamethods.

 Note that Functions listed below are available only available from the
 Set prototype returned by requiring this module, because Container
 objects cannot have object methods.

 @classmod std.set
 @see std.container
 ]]

local base      = require "std.base"
local Container = require "std.container"
local prototype = (require "std.object").prototype


local Set -- forward declaration

-- Primitive methods (know about representation)
-- The representation is a table whose tags are the elements, and
-- whose values are true.


--- Say whether an element is in a set.
-- @tparam set set a set
-- @param e element
-- @return `true` if `e` is in `set`, otherwise `false`
-- otherwise
local function member (set, e)
  return rawget (set, e) == true
end


--- Insert an element into a set.
-- @tparam set set a set
-- @param e element
-- @return the modified set
local function insert (set, e)
  rawset (set, e, true)
  return set
end


--- Delete an element from a set.
-- @tparam set set a set
-- @param e element
-- @return the modified set
local function delete (set, e)
  rawset (set, e, nil)
  return set
end


--- Iterator for sets.
-- @tparam set set a set
-- @todo Make the iterator return only the key
local function elems (set)
  return pairs (set)
end


-- High level methods (representation-independent)

local difference, symmetric_difference, intersection, union, subset,
      proper_subset, equal


--- Find the difference of two sets.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return `set1` with elements of s removed
function difference (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  local t = Set {}
  for e in elems (set1) do
    if not member (set2, e) then
      insert (t, e)
    end
  end
  return t
end


--- Find the symmetric difference of two sets.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return elements of `set1` and `set2` that are in `set1` or `set2` but not both
function symmetric_difference (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  return difference (union (set1, set2), intersection (set2, set1))
end


--- Find the intersection of two sets.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return set intersection of `set1` and `set2`
function intersection (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  local t = Set {}
  for e in elems (set1) do
    if member (set2, e) then
      insert (t, e)
    end
  end
  return t
end


--- Find the union of two sets.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return set union of `set1` and `set2`
function union (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  local t = Set {}
  for e in elems (set1) do
    insert (t, e)
  end
  for e in elems (set2) do
    insert (t, e)
  end
  return t
end


--- Find whether one set is a subset of another.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return `true` if `set1` is a subset of `set2`, `false` otherwise
function subset (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  for e in elems (set1) do
    if not member (set2, e) then
      return false
    end
  end
  return true
end


--- Find whether one set is a proper subset of another.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return `true` if `set1` is a proper subset of `set2`, `false` otherwise
function proper_subset (set1, set2)
  if prototype (set2) == "table" then
    t = Set (set2)
  end
  return subset (set1, set2) and not subset (set2, set1)
end


--- Find whether two sets are equal.
-- @tparam set set1 a set
-- @tparam table|set set2 another set, or table
-- @return `true` if `set1` and `set2` are equal, `false` otherwise
function equal (set1, set2)
  return subset (set1, set2) and subset (set2, set1)
end


--- @export
local _functions = {
  delete               = delete,
  difference           = difference,
  elems                = elems,
  equal                = equal,
  insert               = insert,
  intersection         = intersection,
  member               = member,
  proper_subset        = proper_subset,
  subset               = subset,
  symmetric_difference = symmetric_difference,
  union                = union,
}


--- Set prototype object.
-- @table std.set
-- @string[opt="Set"] _type type of Set, returned by
--   @{std.object.prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, see @{std.object.__call}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
Set = Container {
  _type      = "Set",

  _init      = function (self, t)
                 for e in base.elems (t) do
                   insert (self, e)
                 end
                 return self
               end,


  --- Union operator.
  --     union = set + table
  -- @function __add
  -- @static
  -- @tparam set set set
  -- @tparam table|set table another set or table
  -- @treturn set union
  -- @see union
  __add = union,


  --- Difference operator.
  --     difference = set - table
  -- @function __sub
  -- @static
  -- @tparam set set set
  -- @tparam table|set table another set or table
  -- @treturn set difference
  -- @see difference
  __sub = difference,


  --- Intersection operator.
  --     intersection = set * table
  -- @function __mul
  -- @static
  -- @tparam set set set
  -- @tparam table|set table another set or table
  -- @treturn set intersection
  -- @see intersection
  __mul = intersection,


  --- Symmetric difference operator.
  --     symmetric_difference = set / table
  -- @function __div
  -- @static
  -- @tparam set set set
  -- @tparam table|set table another set or table
  -- @treturn set symmetric_difference
  -- @see symmetric_difference
  __div = symmetric_difference,


  --- Subset operator.
  --     set = set <= table
  -- @function __le
  -- @static
  -- @tparam set set set
  -- @tparam table|set table another set or table
  -- @treturn set subset
  -- @see subset
  __le  = subset,


  --- Proper subset operator.
  --     proper_subset = set < table
  -- @function __lt
  -- @static
  -- @tparam set set set
  -- @tparam table|set table another set or table
  -- @treturn set proper_subset
  -- @see proper_subset
  __lt  = proper_subset,


  -- Set to table conversion.
  -- @treturn table table representation of a set.
  -- @see std.table.totable
  __totable  = function (self)
                 local t = {}
                 for e in elems (self) do
                   table.insert (t, e)
                 end
                 table.sort (t)
                 return t
               end,


  _functions = base.merge (_functions, {
    -- backwards compatibility.
    new = function (t) return Set (t or {}) end,
  }),
}

return Set
