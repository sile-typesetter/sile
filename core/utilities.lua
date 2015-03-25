local utilities = {}

require("bit32-compat")

function utilities.required(t, name, context)
  if not t[name] then utilities.error(context.." needs a "..name.." parameter") end
  return t[name]
end

function utilities.error(message,bug)
  if(SILE.currentCommand and type(SILE.currentCommand) == "table") then
    print("\n! "..message.. " at "..SILE.currentlyProcessingFile.." l."..(SILE.currentCommand.line)..", col."..(SILE.currentCommand.col))
  else
    print("\n! "..message.. " at "..SILE.currentlyProcessingFile)
  end
  if bug then print(debug.traceback()) end
  SILE.outputter:finish()
  os.exit(1)
end

function utilities.warn(message)
  print("\n! "..message)
  --print(debug.traceback())
  --os.exit(1)
end

function utilities.debugging(category)
  return SILE.debugFlags.all or SILE.debugFlags[category]
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

function utilities.codepoint(uchar)
  local seq = 0
  local val = -1
  for i = 1, #uchar do
    local c = string.byte(uchar, i)
    if seq == 0 then
      if val > -1 then return val end
      seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
            c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
          error("invalid UTF-8 character sequence")
      val = bit32.band(c, 2^(8-seq) - 1)
    else
      val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
    end
    seq = seq - 1
  end  
  return val
end

return utilities
