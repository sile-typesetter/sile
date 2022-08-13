--
-- SILE AST utilites
--
local ast = {}

-- ------------------------------------------------------
-- AST to SIL: reconstruct a SIL-like output from the AST
-- ------------------------------------------------------

local function escapeContentString (s)
  return s:gsub("[%%\\{}]",
    function(x)
      return "\\"..x
    end)
end

local function escapeParamString (value)
  local v = tostring(value)
  return '"' .. v:gsub('"', '\\"') .. '"'
end

local function optionsToString (options)
  local out = ""
  -- options are in an associative table and Lua doesn't guarantee a fixed order.
  -- To ensure we get a consistent and stable output, rely on alphabetical order.
  local sortedOpts = {}
  for k, _ in pairs(options) do table.insert(sortedOpts, k) end
  table.sort(sortedOpts)
  if #sortedOpts > 0 then
    out = out .. "["
    for iOpt, option in ipairs(sortedOpts) do
      out = out .. option .. "=" .. escapeParamString(options[option])
      if iOpt == #sortedOpts then
        out = out .. "]"
      else
        out = out .. ", "
      end
    end
  end
  return out
end

-- Environments and commands are the same thing, just a writing convenience.
local isEnvironment = {
  document = true,
}

ast.astToSil = function (content)
  local out = ""
  if not content then return out end

  for i = 1, #content do
    local node = content[i]
    if type(node) == "string" then
      out = out .. escapeContentString(node)
    elseif node.command then
      if isEnvironment[node.command] then
        out = out .. "\\begin" .. optionsToString(node.options) .. "{" .. node.command .. "}\n"
        if (#node >= 1) then
          out = out .. ast.astToSil(node)
        end
        out = out .. "\n\\end{" .. node.command .. "}\n"
      else
        out = out .. "\\"  .. node.command .. optionsToString(node.options)
        if (#node >= 1) then
          out = out .. "{" .. ast.astToSil(node) .. "}"
        else
          out = out .. "{}"
        end
      end
    elseif node.id then
      -- Due to the way it is implemented, the SILE-inputter may generate such
      -- nodes in the AST. It's poorly documented, so it's not clear why they
      -- are even kept there (esp. the id="texlike_stuff" nodes), but anyhow, as
      -- far concerned for presentation purposes, just recurse into them.
      out = out .. ast.astToSil(node)
    else
      -- Silently recurse into other (nested) tables, i.e. flatten them.
      out = out .. ast.astToSil(node)
    end
  end
  return out
end

return ast
