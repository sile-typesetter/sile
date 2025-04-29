SILE.frames = {}

local cassowary = require("cassowary")
local solver = cassowary.SimplexSolver()

SILE.newFrame = function (spec, prototype)
   -- SU.deprecated("SILE.newFrame", "SILE.types.frame", "0.16.0", "0.17.0")
   SU.required(spec, "id", "frame declaration")
   prototype = prototype or SILE.framePrototype
   local frame = prototype(spec)
   SILE.frames[spec.id] = frame
   return frame
end

SILE.getFrame = function (id)
   -- SU.deprecated("SILE.getFrame", "class.frames:get", "0.16.0", "0.17.0")
   if type(id) == "table" then
      SU.error("Passed a table, expected a string", true)
   end
   local frame, last_attempt
   while not frame do
      frame = SILE.frames[id]
      id = id:gsub("_$", "")
      if id == last_attempt then
         break
      end
      last_attempt = id
   end
   return frame or SU.warn("Couldn't find frame ID " .. id, true)
end

SILE.parseComplexFrameDimension = function (dimension)
   -- SU.deprecated("SILE.parseComplexFrameDimension", "", "0.16.0", "0.17.0")
   local length = SILE.frameParser:match(SU.cast("string", dimension))
   if type(length) == "table" then
      local g = cassowary.Variable({ name = "t" })
      local eq = cassowary.Equation(g, length)
      SILE.frames.page:invalidate()
      solver:addConstraint(eq)
      SILE.frames.page:solve()
      SILE.frames.page:invalidate()
      return g.value
   end
   return length
end

SU.deprecated("core.frame", "types.frame", "0.16.0", "0.17.0")
return require("types.frame")
