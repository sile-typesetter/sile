local framePrototype = {
  next= nil,
  id= nil,
  previous= nil,
  balanced= 0
};

function framePrototype:top() if (type(self._top) == "function" ) then return self:_top() else return self._top end end
function framePrototype:left () if (type(self._left) == "function" ) then return self:_left() else return self._left end end
function framePrototype:right ()
    if (type(self._right) == "function") then return self:_right() end
    if (not self._right and self._width) then return self:left() + self:width() end
    return self._right
  end
function framePrototype:bottom ()
    if (type(self._bottom) == "function" ) then return self:_bottom() end
    if (not self._bottom and self._height) then return self:top() + self:height() end
    return self._bottom
  end
function framePrototype:width ()
    if (type(self._width) == "function" ) then return self:_width() end
    if (not self._width) then return self:right() - self:left() end
    return self._width
  end
function framePrototype:height()
    if (type(self._height) == "function" ) then return self:_height() end
    if (self._height) then return self._height end
    if (self._bottom and self._top) then return self:bottom() - self:top() end
    return Infinity
  end

SILE.newFrame = function(spec)
  local frame = SU.deepCopy(framePrototype)
  local dims = { top="h", bottom="h", height="h", left="w", right="w", width="w"}
  for method, dimension in pairs(dims) do 
    if spec[method] then
    if not(type(spec[method]) == "function") then
      local old = spec[method] -- Closure me harder
      if type(old) == "string" and string.find(old, "%%") then
        -- Defer relative calculations until page size is known
        spec[method] = function() return SILE.toPoints(old, "%", dimension) end
      else
        spec[method] = SILE.toPoints(spec[method])
      end
    end
    frame["_"..method] = spec[method]
  end end
  return frame
end

SILE.getFrame = function(id) return SILE.documentState.thisPageTemplate.frames[id] end

SILE._frameParser = require("core/frameparser")

SILE.parseComplexFrameDimension = function(d, width_or_height)
    SILE.documentState._dimension = width_or_height; -- ugly hack since you can't pass state to the parser
    return SILE._frameParser:match(d);
end