local _deprecated = [[
  You appear to be using a document class '%s' programmed for SILE <= v0.12.5.
  This system was refactored in v0.13.0 and the shims trying to make it
  work temporarily withouth refactoring your classes have been removed
  in v0.14.0. Please see v0.13.0 release notes for help.
]]

local base = pl.class()

function base._init (_) end

function base.classInit (_, tree)
  local class = tree.options.class or "plain"
  local constructor = SILE.require(class, "classes", true)
  if constructor.id then
    SU.deprecated("std.object", "pl.class", "0.13.0", "0.14.0", string.format(_deprecated, constructor.id))
  end
  SILE.documentState.documentClass = constructor(tree.options)
end

-- Just a simple one-level find. We're not reimplementing XPath here.
function base.findInTree (_, tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return tree[i]
    end
  end
end

return base
