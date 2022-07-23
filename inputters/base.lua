local _deprecated = [[
  You appear to be using a document class '%s' programmed for SILE <= v0.12.5.
  This system was refactored in v0.13.0 and the shims trying to make it
  work temporarily without refactoring your classes have been removed
  in v0.14.0. Please see v0.13.0 release notes for help.
]]

local base = pl.class()
base.type = "inputter"
base._name = "base"

base._docclass = nil

function base._init (_) end

function base:classInit (options)
  options = pl.tablex.merge(options, SILE.input.options, true)
  local constructor, class
  if SILE.scratch.class_from_uses then
    constructor = SILE.scratch.class_from_uses
    class = constructor._name
  end
  class = SILE.input.class or class or options.class or "plain"
  constructor = self._docclass or constructor or SILE.require(class, "classes", true)
  if constructor.id then
    SU.deprecated("std.object", "pl.class", "0.13.0", "0.14.0", string.format(_deprecated, constructor.id))
  end
  SILE.documentState.documentClass = constructor(options)
end

function base:requireClass (tree)
  local root = SILE.documentState.documentClass == nil
  if root then
    if #tree ~= 1
      or (tree[1].command ~= "sile" and tree[1].command ~= "document") then
      SU.error("This isn't a SILE document!")
    end
    self:classInit(tree[1].options or {})
    self:preamble()
  end
end

function base.packageInit (_, pack)
  local class = SILE.documentState.documentClass
  if not class then
    SU.error("Cannot load a package before instantiating a document class")
  else
    class:initPackage(pack)
  end
end

function base:process (doc)
  local tree = self:parse(doc)
  self:requireClass(tree)
  return SILE.process(tree)
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
  for _, preamble in ipairs(SILE.input.preambles) do
    if type(preamble) == "string" then
      SILE.processFile(preamble)
    elseif type(preamble) == "table" then
      if preamble.type == "package" then
        SILE.documentState.documentClass:initPackage(preamble)
      end
    end
  end
end

function base.postamble (_)
  for _, path in ipairs(SILE.input.postambles) do
    SILE.processFile(path)
  end
end

return base
