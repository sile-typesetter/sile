--[[--
 Global namespace scribbler.

 For backwards compatibility with older releases, `require "std"`
 will inject the same functions into the global namespace as it
 has done previously, even though it is now deprecated.

 For new code, much better than scribbling all over the global
 namespace, it's more hygienic to explicitly assign the results of
 requiring just the submodules you actually use to a local variable,
 and access its functions via that table.

 @todo Write a style guide (indenting/wrapping, capitalisation,
   function and variable names); library functions should call
   error, not die; OO vs non-OO (a thorny problem).
 @todo Add tests for each function immediately after the function;
   this also helps to check module dependencies.
 @todo pre-compile.
 @module std
]]


--- Module table.
-- Lazy load submodules into `std` on first reference.  On initial
-- load, `std` has the usual single `version` entry, but the `__index`
-- metatable will automatically require submodules on first reference:
--
--     local std = require "std"
--     local prototype = std.container.prototype
-- @table std
-- @field version release version string
local version = "General Lua libraries / 38"

local modules = require "std.modules"

for m, globally in pairs (modules) do
  if globally == true then
    -- Inject stdlib extensions directly into global package namespaces.
    for k, v in pairs (require ("std." .. m)) do
      _G[m][k] = v
    end
  else
    _G[m] = require ("std." .. m)
  end
end

-- Add io functions to the file handle metatable.
local file_metatable = getmetatable (io.stdin)
file_metatable.readlines  = io.readlines
file_metatable.writelines = io.writelines

-- Maintain old global interface access points.
for _, api in ipairs {
  --- Partially apply a function.
  -- @function _G.bind
  -- @see std.functional.bind
  "functional.bind",

  --- Collect the results of an iterator.
  -- @function _G.collect
  -- @see std.functional.collect
  "functional.collect",

  --- Compose functions.
  -- @function _G.compose
  -- @see std.functional.compose
  "functional.compose",

  --- Curry a function.
  -- @function _G.curry
  -- @see std.functional.curry
  "functional.curry",

  --- Evaluate a string.
  -- @function _G.eval
  -- @see std.functional.eval
  "functional.eval",

  --- Filter an iterator with a predicate.
  -- @function _G.filter
  -- @see std.functional.filter
  "functional.filter",

  --- Fold a binary function into an iterator.
  -- @function _G.fold
  -- @see std.functional.fold
  "functional.fold",

  --- Identity function.
  -- @function _G.id
  -- @see std.functional.id
  "functional.id",

  --- Map a function over an iterator.
  -- @function _G.map
  -- @see std.functional.map
  "functional.map",

  --- Memoize a function, by wrapping it in a functable.
  -- @function _G.memoize
  -- @see std.functional.memoize
  "functional.memoize",

  --- Return given metamethod, if any, else nil.
  -- @function _G.metamethod
  -- @see std.functional.metamethod
  "functional.metamethod",

  --- Functional forms of infix operators.
  -- @table _G.op
  -- @see std.functional.op
  "functional.op",



  --- Die with an error.
  -- @function _G.die
  -- @see std.io.die
  "io.die",

  --- Give a warning with the name of program and file (if any).
  --  @function _G.warn
  --  @see std.io.warn
  "io.warn",



  --- Extend to allow formatted arguments.
  -- @function _G.assert
  -- @see std.string.assert
  "string.assert",

  --- Convert a value to a string.
  -- @function _G.pickle
  -- @see std.string.pickle
  "string.pickle",

  --- Pretty-print a table.
  -- @function _G.prettytostring
  -- @see std.string.prettytostring
  "string.prettytostring",

  --- Turn tables into strings with recursion detection.
  -- @function _G.render
  -- @see std.string.render
  "string.render",

  --- Require a module with a particular version.
  -- @function _G.require_version
  -- @see std.string.require_version
  "string.require_version",

  --- Extend `tostring` to work better on tables.
  -- @function _G.tostring
  -- @see std.string.tostring
  "string.tostring",



  --- Turn a tuple into a list.
  -- @function _G.pack
  -- @see std.table.pack
  "table.pack",

  --- An iterator like ipairs, but in reverse.
  -- @function _G.ripairs
  -- @see std.table.ripairs
  "table.ripairs",

  --- Turn an object into a table, according to `__totable` metamethod.
  -- @function _G.totable
  -- @see std.table.totable
  "table.totable",



  --- Tree iterator which returns just numbered leaves, in order.
  -- @function _G.ileaves
  -- @see std.tree.ileaves
  "tree.ileaves",

  --- Tree iterator over numbered nodes, in order.
  -- @function _G.inodes
  -- @see std.tree.inodes
  "tree.inodes",

  --- Tree iterator which returns just leaves.
  -- @function _G.leaves
  -- @see std.tree.leaves
  "tree.leaves",

  --- Tree iterator.
  -- @function _G.nodes
  -- @see std.tree.nodes
  "tree.nodes",
} do
  local module, method = api:match "^(.*)%.(.-)$"
  _G[method] = _G[module][method]
end

local M = {
  version = version,
}


--- Metamethods
-- @section Metamethods

return setmetatable (M, {
  --- Lazy loading of stdlib modules.
  -- Don't load everything on initial startup, wait until first attempt
  -- to access a submodule, and then load it on demand.
  -- @function __index
  -- @string name submodule name
  -- @return the submodule that was loaded to satisfy the missing `name`
  __index = function (self, name)
              local ok, t = pcall (require, "std." .. name)
              if ok then
		rawset (self, name, t)
		return t
	      end
	    end,
})
