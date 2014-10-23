--[[--
 Tables as lists.

 Every list is also an object, and thus inherits all of the `std.object`
 methods, particularly use of object cloning for making new list objects.

 In addition to calling methods on list objects in OO style...

     local List = require "std.list"
     local l = List {1, 2, 3}
     for e in l:relems () do print (e) end
       => 3
       => 2
       => 1

 ... some can also be called as module functions with an explicit list
 argument in the first or last parameter, check the documentation for
 details:

     local List = require "std.list"
     local l = List {1, 2, 3}
     for e in List.relems (l) do print (e) end
       => 3
       => 2
       => 1

 @classmod std.list
]]

local base    = require "std.base"
local func    = require "std.functional"
local Object  = require "std.object"


local List -- forward declaration

------
-- An Object derived List.
-- @table List

--- Append an item to a list.
-- @tparam List l a list
-- @param x item
-- @treturn List new list containing `{l[1], ..., l[#l], x}`
local function append (l, x)
  return List (base.append (l, x))
end


--- Compare two lists element-by-element, from left-to-right.
--
--     if a_list:compare (another_list) == 0 then print "same" end
-- @static
-- @function compare
-- @tparam List l a list
-- @tparam table m another list
-- @return -1 if `l` is less than `m`, 0 if they are the same, and 1
--   if `l` is greater than `m`
local compare = base.compare


--- Concatenate arguments into a list.
-- @tparam List l a list
-- @param ... tuple of lists
-- @treturn List new list containing
--   `{l[1], ..., l[#l], l\_1[1], ..., l\_1[#l\_1], ..., l\_n[1], ..., l\_n[#l\_n]}`
local function concat (l, ...)
  return List (base.concat (l, ...))
end


--- Prepend an item to a list.
-- @tparam List l a list
-- @param x item
-- @treturn List new list containing `{x, unpack (l)}`
local function cons (l, x)
  return List {x, unpack (l)}
end


--- An iterator over the elements of a list.
-- @static
-- @function elems
-- @tparam List l a list
-- @treturn function  iterator function which returns successive elements
--   of `l`
-- @treturn List `l`
-- @return `true`
local elems = base.elems


--- Turn a list of pairs into a table.
-- @todo Find a better name.
-- @tparam  table ls list of lists `{{i1, v1}, ..., {in, vn}}`
-- @treturn table a new list containing table `{i1=v1, ..., in=vn}`
-- @see enpair
local function depair (ls)
  local t = {}
  for v in elems (ls) do
    t[v[1]] = v[2]
  end
  return t
end


--- Turn a table into a list of pairs.
-- @todo Find a better name.
-- @tparam  table t  a table `{i1=v1, ..., in=vn}`
-- @treturn List a new list containing `{{i1, v1}, ..., {in, vn}}`
-- @see depair
local function enpair (t)
  local ls = List {}
  for i, v in pairs (t) do
    table.insert (ls, List {i, v})
  end
  return ls
end


--- Filter a list according to a predicate.
-- @func p predicate function, of one argument returning a boolean
-- @tparam List l a list
-- @treturn List new list containing elements `e` of `l` for which
--   `p (e)` is true
-- @see std.list:filter
local function filter (p, l)
  return List (func.filter (p, elems, l))
end


--- Flatten a list.
-- @tparam List l a list
-- @treturn List flattened list
local function flatten (l)
  local r = List {}
  for v in base.ileaves (l) do
    table.insert (r, v)
  end
  return r
end


--- Fold a binary function through a list left associatively.
-- @func fn binary function
-- @param e element to place in left-most position
-- @tparam List l a list
-- @return result
-- @see std.list:foldl
local function foldl (fn, e, l)
  return func.fold (fn, e, elems, l)
end


--- An iterator over the elements of a list, in reverse.
-- @tparam List l a list
-- @treturn function iterator function which returns precessive elements
--   of the `l`
-- @treturn List `l`
-- @return `true`
local function relems (l)
  local n = #l + 1
  return function (l)
           n = n - 1
           if n > 0 then
             return l[n]
           end
         end,
  l, true
end


--- Fold a binary function through a list right associatively.
-- @func fn binary function
-- @param e element to place in right-most position
-- @tparam List l a list
-- @return result
-- @see std.list:foldr
local function foldr (fn, e, l)
  return List (func.fold (function (x, y) return fn (y, x) end,
                          e, relems, l))
end


--- Make an index of a list of tables on a given field
-- @param f field
-- @tparam List l list of tables `{t1, ..., tn}`
-- @treturn List index `{t1[f]=1, ..., tn[f]=n}`
local function index_key (f, l)
  local r = List {}
  for i, v in ipairs (l) do
    local k = v[f]
    if k then
      r[k] = i
    end
  end
  return r
end


--- Copy a list of tables, indexed on a given field
-- @param f field whose value should be used as index
-- @tparam List l list of tables `{i1=t1, ..., in=tn}`
-- @treturn List index `{t1[f]=t1, ..., tn[f]=tn}`
local function index_value (f, l)
  local r = List {}
  for i, v in ipairs (l) do
    local k = v[f]
    if k then
      r[k] = v
    end
  end
  return r
end


--- Map a function over a list.
-- @func fn map function
-- @tparam List l a list
-- @treturn List new list containing `{fn (l[1]), ..., fn (l[#l])}`
-- @see std.list:map
local function map (fn, l)
  return List (func.map (fn, elems, l))
end


--- Map a function over a list of lists.
-- @func fn map function
-- @tparam List ls a list of lists
-- @treturn List new list `{fn (unpack (ls[1]))), ..., fn (unpack (ls[#ls]))}`
local function map_with (fn, ls)
  return List (func.map (func.compose (fn, unpack), elems, ls))
end


--- Project a list of fields from a list of tables.
-- @param f field to project
-- @tparam List l a list
-- @treturn List list of `f` fields
-- @see std.list:project
local function project (f, l)
  return map (function (t) return t[f] end, l)
end


--- Repeat a list.
-- @tparam List l a list
-- @int n number of times to repeat
-- @treturn List `n` copies of `l` appended together
local function rep (l, n)
  local r = List {}
  for i = 1, n do
    r = concat (r, l)
  end
  return r
end


--- Reverse a list.
-- @tparam List l a list
-- @treturn List new list containing `{l[#l], ..., l[1]}`
local function reverse (l)
  local r = List {}
  for i = #l, 1, -1 do
    table.insert (r, l[i])
  end
  return r
end


--- Shape a list according to a list of dimensions.
--
-- Dimensions are given outermost first and items from the original
-- list are distributed breadth first; there may be one 0 indicating
-- an indefinite number. Hence, `{0}` is a flat list,
-- `{1}` is a singleton, `{2, 0}` is a list of
-- two lists, and `{0, 2}` is a list of pairs.
--
-- Algorithm: turn shape into all positive numbers, calculating
-- the zero if necessary and making sure there is at most one;
-- recursively walk the shape, adding empty tables until the bottom
-- level is reached at which point add table items instead, using a
-- counter to walk the flattened original list.
--
-- @todo Use ileaves instead of flatten (needs a while instead of a
-- for in fill function)
-- @tparam table s `{d1, ..., dn}`
-- @tparam List l a list
-- @return reshaped list
-- @see std.list:shape
local function shape (s, l)
  l = flatten (l)
  -- Check the shape and calculate the size of the zero, if any
  local size = 1
  local zero
  for i, v in ipairs (s) do
    if v == 0 then
      if zero then -- bad shape: two zeros
        return nil
      else
        zero = i
      end
    else
      size = size * v
    end
  end
  if zero then
    s[zero] = math.ceil (#l / size)
  end
  local function fill (i, d)
    if d > #s then
      return l[i], i + 1
    else
      local r = List {}
      for j = 1, s[d] do
        local e
        e, i = fill (i, d + 1)
        table.insert (r, e)
      end
      return r, i
    end
  end
  return (fill (1, 1))
end


--- Return a sub-range of a list.
-- (The equivalent of `string.sub` on strings; negative list indices
-- count from the end of the list.)
-- @tparam List l a list
-- @int from start of range (default: 1)
-- @int to end of range (default: `#l`)
-- @treturn List new list containing `{l[from], ..., l[to]}`
local function sub (l, from, to)
  local r = List {}
  local len = #l
  from = from or 1
  to = to or len
  if from < 0 then
    from = from + len + 1
  end
  if to < 0 then
    to = to + len + 1
  end
  for i = from, to do
    table.insert (r, l[i])
  end
  return r
end


--- Return a list with its first element removed.
-- @tparam List l a list
-- @treturn List new list containing `{l[2], ..., l[#l]}`
local function tail (l)
  return sub (l, 2)
end


--- Transpose a list of lists.
-- This function in Lua is equivalent to zip and unzip in more strongly
-- typed languages.
-- @tparam table ls
-- `{{ls<1,1>, ..., ls<1,c>}, ..., {ls&lt;r,1>, ..., ls&lt;r,c>}}`
-- @treturn List new list containing
-- `{{ls<1,1>, ..., ls&lt;r,1>}, ..., {ls<1,c>, ..., ls&lt;r,c>}}`
local function transpose (ls)
  local rs, len = List {}, #ls
  for i = 1, math.max (unpack (map (ls, function (l) return #l end))) do
    rs[i] = List {}
    for j = 1, len do
      rs[i][j] = ls[j][i]
    end
  end
  return rs
end


--- Zip a list of lists together with a function.
-- @tparam  table    ls list of lists
-- @tparam  function f  function
-- @treturn List    a new list containing
--   `{f (ls[1][1], ..., ls[#ls][1]), ..., f (ls[1][N], ..., ls[#ls][N])`
-- where `N = max {map (function (l) return #l end, ls)}`
local function zip_with (ls, f)
  return map_with (transpose (ls), f)
end


--- @export
local _functions = {
  append      = append,
  compare     = compare,
  concat      = concat,
  cons        = cons,
  depair      = depair,
  elems       = elems,
  enpair      = enpair,
  filter      = filter,
  flatten     = flatten,
  foldl       = foldl,
  foldr       = foldr,
  index_key   = index_key,
  index_value = index_value,
  map         = map,
  map_with    = map_with,
  project     = project,
  relems      = relems,
  rep         = rep,
  reverse     = reverse,
  shape       = shape,
  sub         = sub,
  tail        = tail,
  transpose   = transpose,
  zip_with    = zip_with,
}


List = Object {
  -- Derived object type.
  _type = "List",

  ------
  -- Concatenate lists.
  --     new = list .. table
  -- @function __concat
  -- @tparam List list a list
  -- @tparam table    table another list, hash part is ignored
  -- @see concat
  __concat = concat,

  ------
  -- Append element to list.
  --     list = list + element
  -- @function __add
  -- @tparam List list a list
  -- @param           element element to append
  -- @see append
  __add    = append,

  ------
  -- List order operator.
  --     max = list1 > list2 and list1 or list2
  -- @tparam List list1 a list
  -- @tparam List list2 another list
  -- @see std.list:compare
  __lt = function (list1, list2) return compare (list1, list2) < 0 end,

  ------
  -- List equality or order operator.
  --     min = list1 <= list2 and list1 or list2
  -- @tparam List list1 a list
  -- @tparam List list2 another list
  -- @see std.list:compare
  __le = function (list1, list2) return compare (list1, list2) <= 0 end,

  __index = {
    ------
    -- Append an item to a list.
    -- @function append
    -- @param x item
    -- @treturn List new list containing `{self[1], ..., self[#self], x}`
    append = append,

    ------
    -- Compare two lists element-by-element, from left-to-right.
    --
    --     if a_list:compare (another_list) == 0 then print "same" end
    -- @function compare
    -- @tparam table l a list
    -- @return -1 if `self` is less than `l`, 0 if they are the same, and 1
    --   if `self` is greater than `l`
    compare = compare,

    ------
    -- Concatenate arguments into a list.
    -- @function concat
    -- @param ... tuple of lists
    -- @treturn List new list containing
    --   `{self[1], ..., self[#self], l\_1[1], ..., l\_1[#l\_1], ..., l\_n[1], ..., l\_n[#l\_n]}`
    concat = concat,

    ------
    -- Prepend an item to a list.
    -- @function cons
    -- @param x item
    -- @treturn List new list containing `{x, unpack (self)}`
    cons = cons,

    ------
    -- An iterator over the elements of a list.
    -- @function elems
    -- @treturn function  iterator function which returns successive
    --   elements of `self`
    -- @treturn List `self`
    -- @return `true`
    elems = elems,

    ------
    -- Filter a list according to a predicate.
    -- @function filter
    -- @func p predicate function, of one argument returning a boolean
    -- @treturn List new list containing elements `e` of `self` for which
    --   `p (e)` is true
    -- @see std.list.filter
    filter = function (self, p) return filter (p, self) end,

    ------
    -- Flatten a list.
    -- @function flatten
    -- @treturn List flattened list
    flatten = flatten,

    ------
    -- Fold a binary function through a list left associatively.
    -- @function foldl
    -- @func fn binary function
    -- @param e element to place in left-most position
    -- @return result
    -- @see std.list.foldl
    foldl = function (self, fn, e) return foldl (fn, e, self) end,

    ------
    -- Fold a binary function through a list right associatively.
    -- @function foldr
    -- @func f binary function
    -- @param e  element to place in right-most position
    -- @return result
    -- @see std.list.foldr
    foldr = function (self, fn, e) return foldr (fn, e, self) end,

    ------
    -- Map a function over a list.
    -- @function map
    -- @func fn map function
    -- @treturn List new list containing
    --   `{fn (self[1]), ..., fn (self[#self])}`
    -- @see std.list.map
    map = function (self, fn) return map (fn, self) end,

    ------
    -- Project a list of fields from a list of tables.
    -- @function project
    -- @param f field to project
    -- @treturn List list of `f` fields
    -- @see std.list.project
    project = function (self, f) return project (f, self) end,

    ------
    -- An iterator over the elements of a list, in reverse.
    -- @function relems
    -- @treturn function iterator function which returns precessive elements
    --   of the `self`
    -- @treturn List `self`
    -- @return `true`
    relems = relems,

    ------
    -- Repeat a list.
    -- @function rep
    -- @int n number of times to repeat
    -- @treturn List `n` copies of `self` appended together
    rep = rep,

    ------
    -- Reverse a list.
    -- @function reverse
    -- @treturn List new list containing `{self[#self], ..., self[1]}`
    reverse = reverse,

    -----
    -- Shape a list according to a list of dimensions.
    -- @function shape
    -- @tparam table s `{d1, ..., dn}`
    -- @return reshaped list
    -- @see std.list.shape
    shape = function (self, s) return shape (s, self) end,

    ------
    -- Return a sub-range of a list.
    -- (The equivalent of `string.sub` on strings; negative list indices
    -- count from the end of the list.)
    -- @function sub
    -- @int from start of range (default: 1)
    -- @int to end of range (default: `#self`)
    -- @treturn List new list containing `{self[from], ..., self[to]}`
    sub = sub,

    ------
    -- Return a list with its first element removed.
    -- @function tail
    -- @treturn List new list containing `{self[2], ..., self[#self]}`
    tail = tail,

    -- For backwards compatibility with pre-Object era lists, but
    -- undocumented so that new code doesn't get tangled up in it.
    depair      = depair,
    index_key   = function (self, f) return index_key (f, self)   end,
    index_value = function (self, f) return index_value (f, self) end,
    indexKey    = function (self, f) return indexKey (f, self)    end,
    indexValue  = function (self, f) return indexValue (f, self)  end,
    map_with    = function (self, f) return map_with (f, self)    end,
    transpose   = transpose,
    zip_with    = function (self, f) return zip_with (f, self)    end,
  },

  _functions = (base.merge (_functions, {
    -- backwards compatibility
    new         = function (t) return List (t or {}) end,
    slice       = sub,

    -- camelCase compatibility
    indexKey    = index_key,
    indexValue  = index_value,
    mapWith     = map_with,
    zipWith     = zip_with,
  })),
}


-- Function forms of operators
func.op[".."] = concat


return List
