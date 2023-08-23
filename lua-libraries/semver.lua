-- Loosely inspired from https://github.com/kikito/semver.lua
-- (MIT License (c) 2011 Enrique García Cota)
-- but simplified to our bare needs.

local semver = {}
local mt = {}

function mt:__eq(other)
  return self.major == other.major and
          self.minor == other.minor and
          self.patch == other.patch
end

function mt:__lt(other)
  if self.major ~= other.major then return self.major < other.major end
  if self.minor ~= other.minor then return self.minor < other.minor end
  if self.patch ~= other.patch then return self.patch < other.patch end
  return false
end

function mt:__le(other)
  if self.major ~= other.major then return self.major <= other.major end
  if self.minor ~= other.minor then return self.minor <= other.minor end
  if self.patch ~= other.patch then return self.patch <= other.patch end
  return true
end

function mt:__tostring()
  return ("%d.%d.%d"):format(self.major, self.minor, self.patch)
end

local function new (vstr)
  local major, minor, patch = vstr:match("^v?(%d+)%.(%d+)%.(%d+)")
  local result = { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch) }
  if not result.major and not result.minor and not result.patch then
    error("Invalid version string: "..vstr)
  end
  local o = setmetatable(result, mt)
  return o
end

setmetatable(semver, {
  __call = function(_, ...) return new(...) end
})

return semver
