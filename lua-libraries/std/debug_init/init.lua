-- Debugging is on by default
local M = {
  _DEBUG = true,
}

if _G._DEBUG ~= nil then
  M._DEBUG = _G._DEBUG
end

return M
