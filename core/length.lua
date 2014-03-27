local _length = { length = 0, stretch = 0, shrink = 0 }
_length.mt = {}
function _length.mt.__add (x,y)
	local n = SU.inherit(_length)

	if type(x) == "table" then
		n.length = x.length
		n.stretch = x.stretch
		n.shrink = x.shrink
	else
		n.length = x
	end

	if type(y) == "table" then
		n.length = n.length + y.length
		n.stretch = n.stretch + y.stretch
		n.shrink = n.shrink + y.shrink
	else
		n.length = n.length + y
	end

	return n
end
function _length.mt.__sub (x,y) 
	local n = SU.inherit(_length)	
	if type(x) == "table" then
		n.length = x.length
		n.stretch = x.stretch
		n.shrink = x.shrink
	else
		n.length = x
	end

	if type(y) == "table" then
		n.length = n.length - y.length
		n.stretch = n.stretch - y.stretch
		n.shrink = n.shrink - y.shrink
	else
		n.length = n.length - y
	end
	return n
end

function _length.mt.__lt (x,y) 
	return (x-y).length < 0
end
function _length.mt.__tostring (x)
	local s = tostring(x.length)
	if not (x.stretch == 0) then s = s .. " plus "..x.stretch end
	if not (x.shrink == 0) then s = s .. " minus "..x.shrink end
	return s
end

function _length.mt.__tonumber (x)
	return x.length
end


setmetatable(_length, _length.mt)


length = { new = function (spec) return SU.inherit(_length, spec) end }
return length