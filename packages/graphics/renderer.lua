--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022 Didier Willis
--
-- Public API consists in:
-- - a PathRenderer class that provides basic drawing methods, using a default
--   painter.
-- - a RoughPainter class, an instance of which may be passed to the
--   PathRenderer constructor, to replace the default renderer by the rough
--   one.
--

local RoughGenerator = SILE.require("packages/graphics/rough").RoughGenerator

-- HELPERS

local _r = function(number)
  -- Lua 5.3+ formats floats as 1.0 and integers as 1
  -- This is annoying.
  return math.floor(number) == number and math.floor(number) or number
end

-- Builds a PDF graphics color (stroke or fill) from a SILE parsed color.
local makeColorHelper = function(color, stroke)
  local colspec
  local colop
  if color.r then -- RGB
    colspec = table.concat({ _r(color.r), _r(color.g), _r(color.b) }, " ")
    colop = stroke and "RG" or "rg"
  elseif color.c then -- CMYK
    colspec = table.concat({ _r(color.c), _r(color.m), _r(color.y), _r(color.k) }, " ")
    colop = stroke and "K" or "k"
  elseif color.l then -- Grayscale
    colspec = color.l
    colop = stroke and "G" or "g"
  else
    SU.error("Invalid color specification")
  end
  return colspec .. " " .. colop
end

-- Builds a PDF graphics path from a starting position (x, y)
-- and a set of relative segments which can be either lines (2 coords)
-- or bezier curves (6 segments).
local makePathHelper = function(x, y, segments)
  local paths = { { x, y, "m" } }
  for i = 1, #segments do
    local s = segments[i]
    if #s == 2 then
      -- line
      x = s[1] + x
      y = s[2] + y
      paths[#paths + 1] = { _r(x), _r(y), "l" }
    else
      -- bezier curve
      paths[#paths + 1] = { _r(s[1] + x), _r(s[2] + y), _r(s[3] + x), _r(s[4] + y), _r(s[5] + x), _r(s[6] + y), "c" }
      x = s[5] + x
      y = s[6] + y
    end
  end
  for i, v in ipairs(paths) do
    paths[i] = table.concat(v, " ")
  end
  return table.concat(paths, " ")
end

local DefaultPainter = pl.class({
  defaultOptions = {
    stroke = { l = 0 }, -- color
    strokeWidth = 1,
    -- fill (color) is not set by default, i.e. no fill.
  },
  -- Line from (x1, y1) to (x2, y2)
  line = function (self, x1, y1, x2, y2, options)
    options = options and pl.tablex.union(self.defaultOptions, options) or self.defaultOptions
    return {
      path = table.concat({ _r(x1), _r(y1), "m", _r(x2 - x1), _r(y2 - y1), "l" }, " "),
      options = options,
    }
  end,
  -- Path for a rectangle with upper left (x, y), with given width and height.
  rectangle = function (self, x, y , w , h, options)
    options = options and pl.tablex.union(self.defaultOptions, options) or self.defaultOptions
    return {
      path = table.concat({ _r(x), _r(y), _r(w), _r(h), "re" }, " "),
      options = options,
    }
  end,
  -- Path for a rounded rectangle with upper left (x, y), with given width,
  -- height and border radius.
  roundedRectangle = function (self, x, y , w , h, rx, ry, options)
    options = options and pl.tablex.union(self.defaultOptions, options) or self.defaultOptions
    local arc = 4 / 3 * (1.4142135623730951 - 1)
    -- starting point
    local x0 = x + rx
    -- table of segments (2 coords) or bezier curves (6 coords)
    local segments = {
      {(w - 2 * rx), 0}, {(rx * arc), 0, rx, ry - (ry * arc), rx, ry}, {0, (h - 2 * ry)},
      {0, (ry * arc), -(rx * arc), ry, -rx, ry}, {(-w + 2 * rx), 0},
      {-(rx * arc), 0, -rx, -(ry * arc), -rx, -ry}, {0, (-h + 2 * ry)},
      {0, -(ry * arc), (rx * arc), -ry, rx, -ry}
    }
    return {
      path = makePathHelper(x0, y, segments),
      options = options,
    }
  end,
  -- Path for a curly brace between (x1,y1) and (x2,y2),
  -- with given width and thickness in points,
  -- and curvyness from 0.5 (normal) to higher values for a more "expressive" bracket.
  -- Algorithm derived from https://gist.github.com/alexhornbake/6005176 (which used
  -- quadratic Bezier curves, but it doesn't really matter much here).
  curlyBrace = function (self, x1, y1 , x2 , y2, width, thickness, curvyness, options)
    options = options and pl.tablex.union(self.defaultOptions, options) or self.defaultOptions
    -- Calculate unit vector
    local dx = x1 - x2
    local dy = y1 - y2
    local len = math.sqrt(dx*dx + dy*dy)
    dx =  dx / len
    dy =  dy / len
    -- Calculate Control Points of path,
    -- Top segment:
    --   Q1    --P1
    --        /
    --       |
    --       Q2 Q2b
    --      /
    --     /
    -- T--
    --
    local qx1 = x1 + curvyness * width * dy
    local qy1 = y1 - curvyness * width * dx
    local qx2 = (x1 - 0.25 * len * dx) + (1 - curvyness) * width * dy
    local qy2 = (y1 - 0.25*len * dy) - (1 - curvyness) * width * dx
    -- 'Middle' point (the pointing terminator of the brace)
    local tx = (x1 -  0.5 * len * dx) + width * dy
    local ty = (y1 -  0.5 * len * dy) - width * dx
    -- Bottom segment (same logic)
    local qx3 = x2 + curvyness * width * dy
    local qy3 = y2 - curvyness * width * dx
    local qx4 = (x1 - 0.75 * len * dx) + (1 - curvyness) * width * dy
    local qy4 = (y1 - 0.75 * len * dy) - (1 - curvyness) * width * dx
    -- Thickness
    local thickoffset = width > 0 and thickness or -thickness
    local qx2b, qy2b = qx2 - thickoffset * dy, qy2 - thickoffset * dx
    local qx4b, qy4b = qx4 - thickoffset * dy, qy4 - thickoffset * dx
    return {
      path = table.concat({
        -- TOP SEGMENT
        -- From (x1, y1)
        _r(x1), _r(y1), "m",
        -- Goto (qx2, qy2) vith control point (qx1, qy1) on current position (x1, y1)
        _r(qx1), _r(qy1), _r(qx2), _r(qy2), "v",
        -- Then go to (tx, ty) with the reflexion of the previous control point
        -- ((2 * point - control) is the reflexion of control relative to point)
        _r(2 * qx2 - qx1), _r(2 * qy2 - qy1), _r(tx), _r(ty), "v",
        -- TOP SEGMENT THICKNESS
        -- Go back to (qx2b, qy2b) with control control point on it.
        _r(2 * qx2b - qx1), _r(2 * qy2b - qy1), _r(qx2b), _r(qy2b), "y",
        -- And back to the original point (x1, y1), with control point on it.
        _r(qx1), _r(qy1), _r(x1), _r(y1), "y",
        -- BOTTOM SEGMENT
        -- Same thing but from (x2, y2) to (tx, ty) and backwards with thickness.
        _r(x2), _r(y2), "m",
        _r(qx3), _r(qy3), _r(qx4), _r(qy4), "v",
        _r(2 * qx4 - qx3), _r(2 * qy4 - qy3), _r(tx), _r(ty), "v",
        _r(2 * qx4b - qx3), _r(2 * qy4b - qy3), _r(qx4b), _r(qy4b), "y",
        _r(qx3), _r(qy3), _r(x2), _r(y2), "y",
        -- Round line caps and line joins
        1, "J", 1, "j",
      }, " "),
      options = options
    }
  end,
  draw = function (_, drawable)
    local o = drawable.options
    if o.stroke == "none" then
      if o.fill then
        -- Fill only
        return table.concat({
          drawable.path,
          makeColorHelper(o.fill, false),
          "f"
        }, " ")
      else
        SU.error("Drawable has neither stroke nor fill")
      end
    elseif o.fill then
      -- Stroke and fill
      return table.concat({
        drawable.path,
        makeColorHelper(o.stroke, true),
        makeColorHelper(o.fill, false),
        _r(o.strokeWidth), "w",
        "B"
      }, " ")
    else
      -- Stroke only
      return table.concat({
        drawable.path,
        makeColorHelper(o.stroke, true),
        _r(o.strokeWidth), "w",
        "S"
      }, " ")
    end
  end
})

local RoughPainter = pl.class({
  _init = function (self, options)
    self.gen = RoughGenerator(options)
  end,
  line = function (self, x1, y1, x2, y2, options)
    return self.gen:line(x1, y1, x2, y2, options)
  end,
  rectangle = function (self, x, y , w , h, options)
    return self.gen:rectangle(x, y , w , h, options)
  end,
  roundedRectangle = function ()
    SU.error("Rounded rectangle not implemented in RoughPainter")
  end,
  curlyBrace = function ()
    SU.error("Rounded rectangle not implemented in RoughPainter")
  end,
  draw = function (self, drawable)
    local sets = drawable.sets or {}
    local o = drawable.options
    local precision = drawable.options.fixedDecimalPlaceDigits
    local g = {}
    for _, drawing in ipairs(sets) do
      local path
      if drawing.type == "path" then
        path = table.concat({
           self:opsToPath(drawing, precision),
           makeColorHelper(o.stroke, true),
           _r(o.strokeWidth), "w",
           "S"
        }, " ")
      elseif drawing.type == "fillPath" then
        SU.error("Path filling not yet implemented.")
      elseif drawing.type == "fillSketch" then
        path = table.concat({
          self:opsToPath(drawing, precision),
          makeColorHelper(o.fill, true),
          _r(o.strokeWidth), "w",
          "S"
       }, " ")
      end
      if path then
        g[#g + 1] = path
      end
    end
    return table.concat(g, " ")
  end,
  opsToPath = function (_, drawing, _)
    local path = {}
    for _, item in ipairs(drawing.ops) do
      local data = item.data
      -- NOTE: we currently ignore the decimal precision option
      if item.op == "move" then
          path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " m"
      elseif item.op == 'bcurveTo' then
          path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " " .. _r(data[5]) .. " " .. _r(data[6]) .. " c"
      elseif item.op == "lineTo" then
          path[#path + 1] = _r(data[1]) .. " " ..  _r(data[2]) .. " l"
      end
    end
    return table.concat(path, " ")
  end
})

local PathRenderer = pl.class({
  _init = function (self, adapter)
    self.adapter = adapter or DefaultPainter()
  end,
  line = function (self, x1, y1, x2, y2, options)
    local drawable = self.adapter:line(x1, y1, x2, y2, options)
    return self.adapter:draw(drawable)
  end,
  rectangle = function (self, x, y , w , h, options)
    local drawable = self.adapter:rectangle(x, y, w, h, options)
    return self.adapter:draw(drawable)
  end,
  roundedRectangle = function (self, x, y , w , h, rx, ry, options)
    local drawable = self.adapter:roundedRectangle(x, y, w, h, rx, ry, options)
    return self.adapter:draw(drawable)
  end,
  curlyBrace = function (self, x1, y1 , x2 , y2, width, thickness, curvyness, options)
    local drawable = self.adapter:curlyBrace( x1, y1 , x2 , y2, width, thickness, curvyness, options)
    return self.adapter:draw(drawable)
  end,
})

-- Exports

return {
  PathRenderer = PathRenderer,
  RoughPainter = RoughPainter,
}

