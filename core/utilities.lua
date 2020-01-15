local utilities = {}

local epsilon = 1E-12

utilities.required = function (options, name, context, _type)
  if not options[name] then utilities.error(context.." needs a "..name.." parameter") end
  if _type then
    return utilities.cast(_type, options[name])
  end
  return options[name]
end

local function preferbool ()
  utilities.warn("Please use boolean values or strings such as 'true' and 'false' instead of 'yes' and 'no'.")
end

utilities.boolean = function (value, default)
  if value == false then return false end
  if value == true then return true end
  if value == "false" then return false end
  if value == "true" then return true end
  if value == "no" then preferbool(); return false end
  if value == "yes" then preferbool(); return true end
  return default
end

utilities.error = function(message, bug)
  utilities.warn(message, bug)
  io.stderr:flush()
  SILE.outputter:finish()
  os.exit(1)
end

utilities.warn = function(message, bug)
  io.stderr:write("\n! " .. message)
  if SILE.traceback or bug then
    io.stderr:write(" at:\n" .. SILE.traceStack:locationTrace())
    io.stderr:write(debug.traceback(nil, 2))
  else
    io.stderr:write(" at " .. SILE.traceStack:locationHead())
  end
  io.stderr:write("\n")
end

utilities.debugging = function (category)
  return SILE.debugFlags.all or SILE.debugFlags[category]
end

utilities.feq = function (lhs, rhs) -- Float point equal
  lhs = SU.cast("number", lhs)
  rhs = SU.cast("number", rhs)
  local abs = math.abs
  return abs(lhs - rhs) <= epsilon * (abs(lhs) + abs(rhs))
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
  if utilities.debugging(category) then
    local inputs = table.pack(...)
    for i, input in ipairs(inputs) do
      if type(input) == "function" then
        inputs[i] = input()
      end
    end
    io.stderr:write("\n["..category.."] ", utilities.concat(inputs, " "))
  end
end

utilities.dump = function (...)
  local arg = { ... } -- Avoid things that Lua stuffs in arg like args to self()
  pl.pretty.dump(#arg == 1 and arg[1] or arg, "/dev/stderr")
end

utilities.concat = function (array, separator)
  return table.concat(utilities.map(tostring, array), separator)
end

utilities.inherit = function (orig, spec)
  local new = pl.tablex.deepcopy(orig)
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

  for _ = 1, room do
      table.remove(array, ptr)
  end
  return array
end

utilities.sum = function (array)
  local total = 0
  local last = #array
  for i = 1, last do
    total = total + array[i]
  end
  return total
end

-- Lua <= 5.2 can't handle objects in math functions
utilities.max = function (...)
  local input = pl.utils.pack(...)
  local max = table.remove(input, 1)
  for _, val in ipairs(input) do
    if val > max then max = val end
  end
  return max
end

utilities.min = function (...)
  local input = pl.utils.pack(...)
  local min = input[1]
  for _, val in ipairs(input) do
    if val < min then min = val end
  end
  return min
end

utilities.compress = function (items)
  local rv = {}
  local max = math.max(table.unpack(pl.tablex.keys(items)))
  for i = 1, max do if items[i] then rv[#rv+1] = items[i] end end
  return rv
end

utilities.flip_in_place = function (tbl)
  local tmp, j
  for i = 1, math.floor(#tbl / 2) do
    tmp = tbl[i]
    j = #tbl - i + 1
    tbl[i] = tbl[j]
    tbl[j] = tmp
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

utilities.type = function(value)
  if type(value) == "number" then
    return math.floor(value) == value and "integer" or "number"
  elseif type(value) == "table" and value.prototype then
    return value:prototype()
  elseif type(value) == "table" and value.is_a then
    return value.type
  else
    return type(value)
  end
end

utilities.cast = function (wantedType, value)
  local actualType = SU.type(value)
  wantedType = string.lower(wantedType)
  if string.match(wantedType, actualType)     then return value
  elseif actualType == "nil"
     and string.match(wantedType, "nil")      then return nil
  elseif string.match(wantedType, "integer") or string.match(wantedType, "number") then
    if type(value) == "table" and type(value.tonumber) == "function" then
      return value:tonumber()
    end
    return tonumber(value)
  elseif string.match(wantedType, "boolean")  then return SU.boolean(value)
  elseif string.match(wantedType, "string")   then return tostring(value)
  elseif string.match(wantedType, "length")   then return SILE.length(value)
  elseif string.match(wantedType, "measurement") then return SILE.measurement(value)
  elseif string.match(wantedType, "vglue")    then return SILE.nodefactory.vglue(value)
  elseif string.match(wantedType, "glue")     then return SILE.nodefactory.glue(value)
  elseif string.match(wantedType, "kern")     then return SILE.nodefactory.kern(value)
  else SU.warn("Unrecognized type: "..wantedType); return value
  end
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
  local out = { id="stuff" }
  for key, val in pairs(content) do
    if type(key) == "number" then
      out[#out+1] = val
    end
  end
  return out
end

-- Call `action` on each content AST node, recursively, including `content` itself.
-- Not called on leaves, i.e. strings.
utilities.walkContent = function (content, action)
  if type(content) ~= "table" then
    return
  end
  action(content)
  for i = 1, #content do
    utilities.walkContent(content[i], action)
  end
end

utilities.rateBadness = function(inf_bad, shortfall, spring)
  if spring == 0 then return inf_bad end
  local bad = math.floor(100 * math.abs(shortfall / spring) ^ 3)
  return math.min(inf_bad, bad)
end

utilities.rationWidth = function (target, width, ratio)
  if ratio < 0 and width.shrink:tonumber() > 0 then
    target:___add(width.shrink:tonumber() * ratio)
  elseif ratio > 0 and width.stretch:tonumber() > 0 then
    target:___add(width.stretch:tonumber() * ratio)
  end
  return target
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
      local c, ucv
      local nbytes
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

utilities.splitUtf8 = function (str) -- Return an array of UTF8 strings each representing a Unicode char
  local seq = 0
  local rv = {}
  local val = -1
  local this = ""
  for i = 1, #str do
    local c = string.byte(str, i)
    if seq == 0 then
      if val > -1 then
        rv[1+#rv] = this
        this = ""
      end
      seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
            c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
          error("invalid UTF-8 character sequence")
      val = bit32.band(c, 2^(8-seq) - 1)
      this = this .. str[i]
    else
      val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
      this = this .. str[i]
    end
    seq = seq - 1
  end
  rv[1+#rv] = this
  return rv
end

utilities.lastChar = function (str)
  local chars = utilities.splitUtf8(str)
  return chars[#chars]
end

utilities.firstChar = function (str)
  local chars = utilities.splitUtf8(str)
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

local icu = require("justenoughicu")

local icuFormat = function (num, format)
  local ok, result  = pcall(function() return icu.format_number(num, format) end)
  return tostring(ok and result or num)
end

-- Language specific number formatters add functions to this table,
-- see e.g. languages/tr.lua
utilities.formatNumber = {
  und = {

    alpha = function (num)
      local out = ""
      local a = string.byte("a")
      repeat
        num = num - 1
        out = string.char(num % 26 + a) .. out
        num = (num - num % 26) / 26
      until num < 1
      return out
    end

  }
}

setmetatable (utilities.formatNumber, {
    __call = function (self, num, format, case)
      if math.abs(num) > 9223372036854775807 then
        SU.warn("Integers larger than 64 bits do not reproduce properly in all formats")
      end
      if not case then
        if format:match("^%l") then
          case = "lower"
        elseif format:match("^.%l") then
          case = "title"
        else
          case = "upper"
        end
      end
      local lang = SILE.settings.get("document.language")
      format = format:lower()
      local result
      if self[lang] and type(self[lang][format]) == "function" then
        result = self[lang][format](num)
      elseif type(self["und"][format]) == "function" then
        result = self.und[format](num)
      else
        result = icuFormat(num, format)
      end
      return icu.case(result, lang, case)
    end
})

utilities.breadcrumbs = function ()
  local breadcrumbs = {}

  setmetatable (breadcrumbs, {
      __index = function(_, key)
        local frame = SILE.traceStack[key]
        return frame and frame.command or nil
      end,
      __len = function(_)
        return #SILE.traceStack
      end,
      __tostring = function (self)
        return "B»" .. table.concat(self, "»")
      end
    })

  function breadcrumbs:dump ()
    SU.dump(self)
  end

  function breadcrumbs:parent (count)
    return self[#self-(count or 1)]
  end

  function breadcrumbs:contains (command)
    for i, name in ipairs(self) do if name == command then return #self-i end end
    return -1
  end

  return breadcrumbs
end

return utilities
