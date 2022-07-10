local _deprecated = [[
  You appear to be using a document class '%s' programmed for SILE <= v0.12.5.
  This system was refactored in v0.13.0 and the shims trying to make it
  work temporarily withouth refactoring your classes have been removed
  in v0.14.0. Please see v0.13.0 release notes for help.
]]

local base = pl.class()

function base._init (_) end

function base.classInit (_, tree)
  local options = pl.tablex.merge(tree.options, SILE.input.options, true)
  local constructor, class
  if SILE.scratch.required_class then
    constructor = SILE.scratch.required_class
    class = constructor._name
  end
  class = SILE.input.class or class or options.class or "plain"
  constructor = constructor or SILE.require(class, "classes", true)
  if constructor.id then
    SU.deprecated("std.object", "pl.class", "0.13.0", "0.14.0", string.format(_deprecated, constructor.id))
  end
  SILE.documentState.documentClass = constructor(options)
end

-- Just a simple one-level find. We're not reimplementing XPath here.
function base.findInTree (_, tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return tree[i]
    end
  end
end

function base.preamble (_)
  for _, path in ipairs(SILE.input.preamble) do
    SILE.processFile(path)
  end
end

function base.postamble (_)
  for _, path in ipairs(SILE.input.postambles) do
    SILE.processFile(path)
  end
end

return base
