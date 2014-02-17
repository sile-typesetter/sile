local utilities = { }

function utilities.debugging(category)
  return false
  --return category == "typesetter"
end

function utilities.gtoke(string, pattern)
  string = string and tostring(string) or ''
  pattern = pattern and tostring(pattern) or "%s+"
  return coroutine.wrap(function()
    local index= 1
    repeat
      local first, last = string:find(pattern, index)
      if first and last then
        if index < first then coroutine.yield({ string = string:sub(index, first -1) }) end
        coroutine.yield({ separator = string:sub(first, last) })
        index = last + 1
      else
        if index <= #string then coroutine.yield({ string = string:sub(index) }) end
        break
      end
    until index > #string
  end)
end

function utilities.debug(category, messages)
  if utilities.debugging(category) then print(messages) end
end

function utilities.concat(s,c)
    local t = { }
    for k,v in ipairs(s) do
        t[#t+1] = tostring(v)
    end
    return table.concat(t,c)
end

function utilities.inherit (orig, spec) 
	local new = std.tree.clone(orig)
	if spec then
		for k,v in pairs(spec) do new[k] = v end
	end
	if new.init then new:init() end
	return new
end

function utilities.map(func, array)
  local new_array = {}
  for i,v in ipairs(array) do new_array[i] = func(v) end
  return new_array
end

function utilities.splice(array, start, stop, replacement)
  if replacement then
    local n = stop - start + 1
    while n > 0 do
      table.remove(array, start)
      n = n - 1
    end
    for i,v in ipairs(replacement) do
      table.insert(array, start+i-1, v)
    end
    return array
  else
    local res = {}
    for i = start,stop do
      table.insert(res, array[i])
    end
    return res
  end
end

function utilities.sum(array)
  local t = 0
  for i,v in ipairs(array) do t = t + v end
  return t
end
return utilities