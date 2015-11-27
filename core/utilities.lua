local utilities = {}

local bit32 = require("bit32-compat")

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

function table.append(t1, t2)
  if type(t1) == "nil" or type(t2) == "nil" then
    t1[#t1+1] = nil
    return
  end
  for i=1,#t2 do
      t1[#t1+1] = t2[i]
  end
end

function utilities.allCombinations(options)
  local count = 1
  for i=1,#options do count = count * options[i] end
  return coroutine.wrap(function()
    for i=0,count-1 do
      local this = i
      local rv = {}
      for j = 1,#options do
        local base = options[j]
        rv[#rv+1] = this % base + 1
        this = (this - this % base )/ base
      end
      coroutine.yield(rv)
    end
  end)
end

-- Unicode-related utilities
utilities.utf8char = function (c)
    if     c < 128 then
        return string.char(c)
    elseif c < 2048 then
        return string.char(math.floor(192 + c/64), 128 + c%64)
    elseif c < 55296 or 57343 < c and c < 65536 then
        return  string.char(math.floor(224 + c/4096), math.floor(128 + c/64%64), 128 + c%64)
    elseif c < 1114112 then
        return string.char(math.floor(240 + c/262144), math.floor(128 + c/4096%64), math.floor(128 + c/64%64), 128 + c%64)
    end
end

utilities.codepoint = function (uchar)
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

utilities.utf8codes = function (ustr)
  local pos = 1
  return function()
    if pos > #ustr then
      return nil
    else
      local c, ucv = 0, 0
      local nbytes = 0
      c = string.byte(ustr, pos)
      pos = pos + 1
      if c < 0x80 then
        ucv    = c
        nbytes = 0
      elseif c >= 0xc0 and c < 0xe0 then -- 110x xxxx
        ucv    = c - 0xc0
        nbytes = 1
      elseif c >= 0xe0 and c < 0xf0 then -- 1110 xxxx
        ucv    = c - 0xe0
        nbytes = 2
      elseif c >= 0xf0 and c < 0xf8 then -- 1111 0xxx
        ucv    = c - 0xf0
        nbytes = 3
      elseif c >= 0xf8 and c < 0xfc then -- 1111 10xx
        ucv    = c - 0xf8
        nbytes = 4
      elseif c >= 0xfc and c < 0xfe then -- 1111 110x
        ucv    = c - 0xfc
        nbytes = 5
      else -- Invalid
        return nil
      end
      if pos + nbytes > #ustr + 1 then -- Invalid
        return nil
      end
      while nbytes > 0 do
        nbytes = nbytes - 1
        c = string.byte(ustr, pos)
        pos = pos + 1
        if c < 0x80 or c >= 0xc0 then -- Invalid
          return nil
        else
          ucv = ucv * 64 + (c - 0x80);
        end
      end
      return ucv
    end
  end
end

function utilities.splitUtf8(s) -- Return an array of UTF8 strings each representing a Unicode char
  local seq = 0
  local rv = {}
  local val = -1
  local this = ""
  for i = 1, #s do
    local c = string.byte(s, i)
    if seq == 0 then
      if val > -1 then
        rv[1+#rv] = this
        this = ""
      end
      seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
            c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
          error("invalid UTF-8 character sequence")
      val = bit32.band(c, 2^(8-seq) - 1)
      this = this .. s[i]
    else
      val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
      this = this .. s[i]
    end
    seq = seq - 1
  end
  rv[1+#rv] = this
  return rv
end

function utilities.utf8charat(str, index)
  return str:sub(index):match("([%z\1-\127\194-\244][\128-\191]*)")
end

function utilities.utf8_to_utf16be(str)
  local ustr = string.format("%04x", 0xfeff) -- BOM
  for uchr in utilities.utf8codes(str) do
    if (uchr < 0x10000) then
      ustr = ustr..string.format("%04x", uchr)
    else -- Surrogate pair
      local sur_hi = (uchr - 0x10000) / 0x400 + 0xd800
      local sur_lo = (uchr - 0x10000) % 0x400 + 0xdc00
      ustr = ustr..string.format("%04x%04x", sur_hi, sur_lo)
    end
  end
  return ustr
end

return utilities
