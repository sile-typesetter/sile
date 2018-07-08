local utilities = {}

local bit32 = require("bit32-compat")

math.epsilon = 1E-12

utilities.required = function (t, name, context)
  if not t[name] then utilities.error(context.." needs a "..name.." parameter") end
  return t[name]
end

utilities.boolean = function (value, default)
  if value == "false" then return false end
  if value == false then return false end
  if value == "true" then return true end
  if value == true then return true end
  return default
end

if not table.maxn then
  table.maxn = function(t)
    local max = 0
    for i,_ in pairs(t) do if i > max then max = i end end
    return max
  end
end

utilities.error = function (message, bug)
  if(SILE.currentCommand and type(SILE.currentCommand) == "table") then
    io.stderr:write("\n! "..message.. " at "..SILE.currentlyProcessingFile.." l."..(SILE.currentCommand.line)..", col."..(SILE.currentCommand.col))
  else
    io.stderr:write("\n! "..message.. " at "..SILE.currentlyProcessingFile)
  end
  if bug then io.stderr:write(debug.traceback()) end
  io.stderr:write("\n")
  SILE.outputter:finish()
  os.exit(1)
end

utilities.warn = function (message)
  io.stderr:write("\n! "..message.."\n")
  --print(debug.traceback())
  --os.exit(1)
end

utilities.debugging = function (category)
  return SILE.debugFlags.all or SILE.debugFlags[category]
end

utilities.feq = function (lhs, rhs) -- Float point equal
  local abs = math.abs
  return abs(lhs - rhs) <= math.epsilon * (abs(lhs) + abs(rhs))
end

utilities.gtoke = function (string, pattern)
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

utilities.debug = function (category, ...)
  local arg = { ... } -- Avoid things that Lua stuffs in arg like args to self()
  if utilities.debugging(category) then
    print("["..category.."]", #arg == 1 and arg[1] or arg)
  end
end

utilities.dump = function (...)
  local arg = { ... } -- Avoid things that Lua stuffs in arg like args to self()
  require("pl.pretty").dump(#arg == 1 and arg[1] or arg, "/dev/stderr")
end

utilities.concat = function (array, c)
  return table.concat(utilities.map(tostring, array), c)
end

utilities.inherit = function (orig, spec)
  local new = std.tree.clone(orig)
  if spec then
    for k,v in pairs(spec) do new[k] = v end
  end
  if new.init then new:init() end
  return new
end

utilities.map = function (func, array)
  local new_array = {}
  local last = #array
  for i = 1, last do
    new_array[i] = func(array[i])
  end
  return new_array
end

utilities.splice = function (array, start, stop, replacement)
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

utilities.sum = function (array)
  local t = 0
  local last = #array
  for i = 1, last do
    t = t + array[i]
  end
  return t
end

utilities.compress = function (items)
  local rv = {}
  for i=1,table.maxn(items) do if items[i] then rv[#rv+1] = items[i] end end
  return rv
end

table.nitems = function (t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

table.append = function (t1, t2)
  if not t1 or not t2 then SU.error("table.append called with nil table!: "..t1..", "..t2,true) end
  for i=1,#t2 do
      t1[#t1+1] = t2[i]
  end
end

table.flip = function(tbl)
  for i=1, math.floor(#tbl / 2) do
    local tmp = tbl[i]
    tbl[i] = tbl[#tbl - i + 1]
    tbl[#tbl - i + 1] = tmp
  end
end

utilities.allCombinations = function (options)
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

-- Flatten content trees into just the string components (allows passing
-- objects with complex structures to functions that need plain strings)
utilities.contentToString = function (content)
  local string = ""
  for i = 1, #content do
    if type(content[i]) == "string" then
      string = string .. content[i]
    end
  end
  return string
end

-- Strip the top level command off a content object and keep only the child
-- items — assuming that the current command is taking care of itself
utilities.subContent = function (content)
  out = { id="stuff" }
  for key, val in pairs(content) do
    if type(key) == "number" then
      out[#out+1] = val
    end
  end
  return out
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

utilities.utf8charfromcodepoint = function (codepoint)
  local val = codepoint
  local cp = val
  local hex = (cp:match("[Uu]%+(%x+)") or cp:match("0[xX](%x+)"))
  if hex then
    cp = tonumber("0x"..hex)
  elseif tonumber(cp) then
    cp = tonumber(cp)
  end

  if type(cp) == "number" then
    val = SU.utf8char(cp)
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
          ucv = ucv * 64 + (c - 0x80)
        end
      end
      return ucv
    end
  end
end

utilities.splitUtf8 = function (s) -- Return an array of UTF8 strings each representing a Unicode char
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

utilities.lastChar = function (s)
  local chars = utilities.splitUtf8(s)
  return chars[#chars]
end

utilities.firstChar = function (s)
  local chars = utilities.splitUtf8(s)
  return chars[1]
end

utilities.utf8charat = function (str, index)
  return str:sub(index):match("([%z\1-\127\194-\244][\128-\191]*)")
end

utilities.utf8_to_utf16be_hexencoded = function (str)
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

utilities.utf8_to_utf16be = function (str)
  local ustr = ""
  for uchr in utilities.utf8codes(str) do
    if (uchr < 0x10000) then
      ustr = ustr..string.format("%c%c", uchr / 256, uchr % 256 )
    else -- Surrogate pair
      local sur_hi = (uchr - 0x10000) / 0x400 + 0xd800
      local sur_lo = (uchr - 0x10000) % 0x400 + 0xdc00
      ustr = ustr..string.format("%c%c%c%c", sur_hi / 256, sur_hi % 256 , sur_lo / 256, sur_lo % 256)
    end
  end
  return ustr
end

utilities.utf8_to_utf16le = function (str)
  local ustr = ""
  for uchr in utilities.utf8codes(str) do
    if (uchr < 0x10000) then
      ustr = ustr..string.format("%c%c", uchr % 256, uchr / 256 )
    else -- Surrogate pair
      local sur_hi = (uchr - 0x10000) / 0x400 + 0xd800
      local sur_lo = (uchr - 0x10000) % 0x400 + 0xdc00
      ustr = ustr..string.format("%c%c%c%c", sur_hi % 256, sur_hi / 256 , sur_lo % 256, sur_lo / 256)
    end
  end
  return ustr
end

return utilities
