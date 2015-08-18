-- default implementations for some of the IO sub-operations - if a format
-- doesn't provide its own, these will be used

local defaults = {}

-- verifies the size given, returns the number of bytes that will actually
-- be read or written. Default assumes that size is mandatory and exactly
-- equals the amount that will be RWd.
-- If the format doesn't do any, should return 0. If the amount cannot be
-- determined ahead of time (for example, format c) should return nil.
function defaults.size(n)
  assert(tonumber(n), "format requires a size")
  return tonumber(n)
end

function defaults.validate()
  return true
end

function defaults.hasvalue()
  return true
end

return defaults
