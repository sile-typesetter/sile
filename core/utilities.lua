local utilities = {}

function utilities.required(t, name, context)
  if not t[name] then utilities.error(context.." needs a "..name.." parameter") end
  return t[name]
end

function utilities.error(message)
  print("\n! "..message)
  os.exit(1)
end

function utilities.warn(message)
  print("\n! "..message)
  print(debug.traceback())
  --os.exit(1)
end

function utilities.debugging(category)
  return SILE.debugFlags[category]
end

function utilities.gtoke(string, pattern)
  string = string and tostring(string) or ''
  pattern = pattern and tostring(pattern) or "%s+"
  local length = #string
  return coroutine.wrap(function()
    local index = 1
    repeat
      local first, last = string:find(pattern, index)
      if last then
        if index < first then coroutine.yield({ string = string:sub(index, first - 1) }) end
        coroutine.yield({ separator = string:sub(first, last) })
        index = last + 1
      else
        if index <= length then
          coroutine.yield({ string = string:sub(index) })
        end
        break
      end
    until index > length
  end)
end

function utilities.debug(category, messages)
  if utilities.debugging(category) then
    print("["..category.."]", messages)
  end
end

function utilities.concat(array, c)
  return table.concat(utilities.map(tostring, array), c)
end

function utilities.inherit(orig, spec)
  local new = std.tree.clone(orig)
  if spec then
    for k,v in pairs(spec) do new[k] = v end
  end
  if new.init then new:init() end
  return new
end

function utilities.map(func, array)
  local new_array = {}
  local last = #array
  for i = 1, last do
    new_array[i] = func(array[i])
  end
  return new_array
end

function utilities.splice(array, start, stop, replacement)
  local ptr = start
  local room = stop - start + 1
  local last = replacement and #replacement or 0
  for i = 1, last do
    if room > 0 then
      room = room - 1
      array[ptr] = replacement[i]
    else
      table.insert(array, ptr, replacement[i])
    end
    ptr = ptr + 1
  end

  for i = 1, room do
      table.remove(array, ptr)
  end
  return array
end

function utilities.sum(array)
  local t = 0
  local last = #array
  for i = 1, last do
    t = t + array[i]
  end
  return t
end

return utilities
