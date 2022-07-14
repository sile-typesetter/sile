local base = require("inputters.base")

local lua = pl.class(base)
lua._name = "lua"

lua.order = 99

function lua.appropriate (round, filename, doc)
  if round == 1 then
    return filename:match(".lua$")
  elseif round == 2 then
    local sniff = doc:sub(1, 100)
    local promising = sniff:match("^%-%-") or sniff:match("^local") or sniff:match("^return")
    return promising and lua.appropriate(3, filename, doc)
  elseif round == 3 then
    local status, _ = pcall(load, doc)
    return status
  end
end

function lua.parse (_, doc)
  local result, err = load(doc)
  if not result then SU.error(err) end
  return { result }
end

function lua:process (doc)
  local tree = self:parse(doc)()
  if type(tree) == "string" then
    return SILE.processString(tree)
  elseif type(tree) == "function" then
    SILE.process(tree)
  elseif type(tree) == "table" then
    if not tree.type then
      tree = { tree }
      -- hoping tree is an AST
      self:requireClass(tree)
      return SILE.process(tree)
    else
      load_sile_module(tree)
      if tree.type == "class" then
        if SILE.documentState.documentClass then
          SU.error("Cannot load a class after one is already instantiated")
        end
        self._docclass = tree
      elseif tree.type == "package" then
        return self:packageInit(tree)
      end
      -- other module types like inputters, outputters, shappers, etc. don't
      -- need instantiation on load, only when they are used
    end
  end
end

return lua
