--[[--
 Tree container.

 Derived from @{std.container}, and inherits Container's metamethods.

 Note that Functions listed below are only available from the Tree
 prototype return by requiring this module, because Container objects
 cannot have object methods.

 @classmod std.tree
 @see std.container
]]

local base      = require "std.base"
local Container = require "std.container"
local List      = require "std.list"
local func      = require "std.functional"

local prototype = (require "std.object").prototype

local Tree -- forward declaration


--- Tree iterator which returns just numbered leaves, in order.
-- @function ileaves
-- @static
-- @tparam  tree|table tr tree or tree-like table
-- @treturn function iterator function
-- @treturn tree|table the tree `tr`
local ileaves = base.ileaves


--- Tree iterator which returns just leaves.
-- @function leaves
-- @static
-- @tparam  tree|table tr tree or tree-like table
-- @treturn function iterator function
-- @treturn tree|table the tree, `tr`
local leaves = base.leaves


--- Make a deep copy of a tree, including any metatables.
--
-- To make fast shallow copies, use @{std.table.clone}.
-- @tparam  table|tree t table or tree to be cloned
-- @tparam  boolean nometa if non-nil don't copy metatables
-- @treturn table|tree a deep copy of `t`
local function clone (t, nometa)
  assert (type (t) == "table",
          "bad argument #1 to 'clone' (table expected, got " .. type (t) .. ")")
  local r = {}
  if not nometa then
    setmetatable (r, getmetatable (t))
  end
  local d = {[t] = r}
  local function copy (o, x)
    for i, v in pairs (x) do
      if type (v) == "table" then
        if not d[v] then
          d[v] = {}
          if not nometa then
            setmetatable (d[v], getmetatable (v))
          end
          o[i] = copy (d[v], v)
        else
          o[i] = d[v]
        end
      else
        o[i] = v
      end
    end
    return o
  end
  return copy (r, t)
end


--- Tree iterator.
-- @tparam  function it iterator function
-- @tparam  tree|table tr tree or tree-like table
-- @treturn string   type ("leaf", "branch" (pre-order) or "join" (post-order))
-- @treturn table    path to node ({i\_1...i\_k})
-- @return           node
local function _nodes (it, tr)
  local p = {}
  local function visit (n)
    if type (n) == "table" then
      coroutine.yield ("branch", p, n)
      for i, v in it (n) do
        table.insert (p, i)
        visit (v)
        table.remove (p)
      end
      coroutine.yield ("join", p, n)
    else
      coroutine.yield ("leaf", p, n)
    end
  end
  return coroutine.wrap (visit), tr
end


--- Tree iterator over all nodes.
--
-- The returned iterator function performs a depth-first traversal of
-- `tr`, and at each node it returns `{node-type, tree-path, tree-node}`
-- where `node-type` is `branch`, `join` or `leaf`; `tree-path` is a
-- list of keys used to reach this node, and `tree-node` is the current
-- node.
--
-- Given a `tree` to represent:
--
--     + root
--        +-- node1
--        |    +-- leaf1
--        |    '-- leaf2
--        '-- leaf 3
--
--     tree = std.tree { std.tree { "leaf1", "leaf2"}, "leaf3" }
--
-- A series of calls to `tree.nodes` will return:
--
--     "branch", {},    {{"leaf1", "leaf2"}, "leaf3"}
--     "branch", {1},   {"leaf1", "leaf"2")
--     "leaf",   {1,1}, "leaf1"
--     "leaf",   {1,2}, "leaf2"
--     "join",   {1},   {"leaf1", "leaf2"}
--     "leaf",   {2},   "leaf3"
--     "join",   {},    {{"leaf1", "leaf2"}, "leaf3"}
--
-- Note that the `tree-path` reuses the same table on each iteration, so
-- you must `table.clone` a copy if you want to take a snap-shot of the
-- current state of the `tree-path` list before the next iteration
-- changes it.
-- @tparam  tree|table tr tree or tree-like table to iterate over
-- @treturn function iterator function
-- @treturn tree|table the tree, `tr`
-- @see inodes
local function nodes (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'nodes' (table expected, got " .. type (tr) .. ")")
  return _nodes (pairs, tr)
end


--- Tree iterator over numbered nodes, in order.
--
-- The iterator function behaves like @{nodes}, but only traverses the
-- array part of the nodes of `tr`, ignoring any others.
-- @tparam  tree|table tr tree to iterate over
-- @treturn function iterator function
-- @treturn tree|table the tree, `tr`
-- @see nodes
local function inodes (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'inodes' (table expected, got " .. type (tr) .. ")")
  return _nodes (ipairs, tr)
end


--- Destructively deep-merge one tree into another.
-- @tparam  tree|table t destination tree or table
-- @tparam  tree|table u tree or table with nodes to merge
-- @treturn tree|table `t` with nodes from `u` merged in
-- @see std.table.merge
local function merge (t, u)
  assert (type (t) == "table",
          "bad argument #1 to 'merge' (table expected, got " .. type (t) .. ")")
  assert (type (u) == "table",
          "bad argument #2 to 'merge' (table expected, got " .. type (u) .. ")")
  for ty, p, n in nodes (u) do
    if ty == "leaf" then
      t[p] = n
    end
  end
  return t
end


--- @export
local _functions = {
  clone   = clone,
  ileaves = ileaves,
  inodes  = inodes,
  leaves  = leaves,
  merge   = merge,
  nodes   = nodes,
}


--- Tree prototype object.
-- @table std.tree
-- @string[opt="Tree"] _type type of Tree, returned by
--   @{std.object.prototype}
-- @tfield[opt={}] table|function _init a table of field names, or
--   initialisation function, see @{std.object.__call}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
Tree = Container {
  -- Derived object type.
  _type = "Tree",

  --- Tree `__index` metamethod.
  -- @function __index
  -- @param i non-table, or list of keys `{i\_1 ... i\_n}`
  -- @return `self[i]...[i\_n]` if i is a table, or `self[i]` otherwise
  -- @todo the following doesn't treat list keys correctly
  --       e.g. self[{{1, 2}, {3, 4}}], maybe flatten first?
  __index = function (self, i)
    if type (i) == "table" and #i > 0 then
      return List.foldl (func.op["[]"], self, i)
    else
      return rawget (self, i)
    end
  end,

  --- Tree `__newindex` metamethod.
  --
  -- Sets `self[i\_1]...[i\_n] = v` if i is a table, or `self[i] = v` otherwise
  -- @function __newindex
  -- @param i non-table, or list of keys `{i\_1 ... i\_n}`
  -- @param v value
  __newindex = function (self, i, v)
    if type (i) == "table" then
      for n = 1, #i - 1 do
        if prototype (self[i[n]]) ~= "Tree" then
          rawset (self, i[n], Tree {})
        end
        self = self[i[n]]
      end
      rawset (self, i[#i], v)
    else
      rawset (self, i, v)
    end
  end,

  _functions = base.merge (_functions, {
    -- backwards compatibility.
    new = function (t) return Tree (t or {}) end,
  }),
}

return Tree
