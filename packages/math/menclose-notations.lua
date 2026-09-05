-- SVG rendering instructions for various menclose notations.
--   box = needed for \boxed
--   updiagonalstrike = needed for \cancel and \xcancel
--   downdiagonalstrike = needed for \bcancel and \xcancel
--   northeastarrow = needed for \cancelto
-- NOTE: MathML3 defines other notations:
--   actuarial, phasorangle, roundedbox, circle, left, right, top, bottom, verticalstrike, horizontalstrike, madruwb.
-- Feel free to implement them as needed.

local function box (w, h, thickness, _, _)
   return {
      thickness,
      "w", -- line width
      1,
      "j", -- round line joins
      0,
      0,
      w,
      h,
      "re",
      "S", -- stroke only
   }
end

local function updiagonalstrike (w, h, thickness, offset, _)
   return {
      thickness,
      "w", -- line width
      1,
      "J", -- round line caps
      offset,
      h - offset,
      "m",
      w - offset,
      offset,
      "l",
      "S", -- stroke only
   }
end

local function downdiagonalstrike (w, h, thickness, offset, _)
   return {
      thickness,
      "w", -- line width
      1,
      "J", -- round line caps
      offset,
      offset,
      "m",
      w - offset,
      h - offset,
      "l",
      "S", -- stroke only
   }
end

local function northeastarrow (w, h, thickness, offset, sw)
   -- LuaJIT and Lua < 5.3 have atan2.
   -- Lua 5.3+ deprecated atan2 and supported atan with two args.
   -- Frankly we live in a world of pain.
   local atan = SILE.lua_version < "5.3" and math.atan2 or math.atan -- luacheck: ignore

   local angle = atan(h - 2 * offset, w - 2 * offset)
   local arrowLength = sw
   local arrowAngle = math.pi / 7 -- about 25 degrees
   local arrowX1 = arrowLength * math.cos(angle - arrowAngle)
   local arrowY1 = arrowLength * math.sin(angle - arrowAngle)
   local arrowX2 = arrowLength * math.cos(angle + arrowAngle)
   local arrowY2 = arrowLength * math.sin(angle + arrowAngle)
   return {
      -- line width
      thickness,
      "w", -- line width
      1,
      "j", -- round line joinss
      1,
      "J", -- round line caps
      -- Main line
      offset,
      h - offset,
      "m",
      w - offset,
      offset,
      "l",
      "S", -- stroke only
      -- Arrow head
      w - offset - arrowX1,
      offset + arrowY1,
      "m",
      w - offset,
      offset,
      "l",
      "S", -- stroke only
      -- Other side of arrow head
      w - offset - arrowX2,
      offset + arrowY2,
      "m",
      w - offset,
      offset,
      "l",
      "S", -- stroke only
   }
end

return {
   box = box,
   updiagonalstrike = updiagonalstrike,
   downdiagonalstrike = downdiagonalstrike,
   northeastarrow = northeastarrow,
}
