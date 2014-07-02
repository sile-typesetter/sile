_length = std.object { 
	length = 0, 
	stretch = 0, 
	shrink = 0, 
	_type = "Length",
	fromLengthOrNumber = function (self, x)
		if type(x) == "table" then
			self.length = x.length
			self.stretch = x.stretch
			self.shrink = x.shrink
		else
			self.length = x
		end
		return self
	end,
	__tonumber = function(self)
		if not(self.stretch ==0) or not(self.shrink == 0) then
			SU.warn("tonumber called on a glue length. Bug?")
		end
		return self.length
	end,
	__tostring = function (x)	
		local s = tostring(x.length).."pt"
		if not (x.stretch == 0) then s = s .. " plus "..x.stretch.."pt" end
		if not (x.shrink == 0) then s = s .. " minus "..x.shrink.."pt" end
		return s
	end,
	__add = function (self, other)
		local n = _length {}
		n:fromLengthOrNumber(self)
		if type(other) == "table" then
			n.length = n.length + other.length
			n.stretch = n.stretch + other.stretch
			n.shrink = n.shrink + other.shrink
		else
			n.length = n.length + other
		end
		return n
	end,
	__sub = function (self, other)
		local n = _length {}
		n:fromLengthOrNumber(self)
		if type(other) == "table" then
			n.length = n.length - other.length
			n.stretch = n.stretch - other.stretch
			n.shrink = n.shrink - other.shrink
		else
			n.length = n.length - other
		end
		return n
	end,
	__lt = function (self, other) return (self-other).length < 0 end,
}

local zero = _length({})
length = { 
	new = function (spec) return _length(spec or {}) end,
	parse =  function(spec)
		local t = lpeg.match(SILE.parserBits.length, spec)
    if not t then SU.error("Bad length definition "..spec) end
    if not t.shrink then t.shrink = 0 end
    if not t.stretch then t.stretch = 0 end
    return SILE.length.new(t)
  end,
	zero = zero 
}
return length