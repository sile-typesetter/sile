-- vstruct 1.x compatibility module

local vstruct = require "vstruct"

vstruct.WARN = true

local function warning(f, level)
  return function(...)
    if vstruct.WARN then
      local info = debug.getinfo(level or 2)
      io.stderr:write(info.short_src..":"..info.currentline..": vstruct: call to legacy API\n")
    end
    return f(...)
  end
end

vstruct.unpack = warning(vstruct.read)
vstruct.unpackvals = warning(vstruct.readvals)
vstruct.pack = warning(vstruct.write)

do
  local _compile = vstruct.compile
  function vstruct.compile(...)
    local obj = _compile(...)
    obj.unpack = warning(function(...) return obj:read(...) end)
    obj.pack = warning(function(...) return obj:write(...) end)
    return obj
  end
end
