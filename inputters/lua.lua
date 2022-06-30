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
  local root = SILE.documentState.documentClass == nil
  local result = load(doc)()
  if type(result) == "table" then
    if not result.options then
      result.options = {}
    end
    if root then
      self:classInit(result)
    end
    SILE.process(result.content)
  elseif type(result) == "function" then
    if root then
      self:classInit({ options = {} })
    end
    result()
  elseif type(result) == "string" then
    if root then
      self:classInit({ options = {} })
    end
    SILE.readString(result)
  end
end

return lua
