local bitshim = require("bitshim")
local luautf8 = require("lua-utf8")
local semver = require("semver")

local utilities = {}

local epsilon = 1E-12

utilities.required = function (options, name, context, required_type)
  if not options[name] then utilities.error(context.." needs a "..name.." parameter") end
  if required_type then
    return utilities.cast(required_type, options[name])
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
  if value == nil then return default end
  SU.error("Expecting a boolean value but got '" .. value .. "'")
  return default
end

local _skip_traceback_levels = 2

utilities.error = function (message, isbug)
  _skip_traceback_levels = 3
  utilities.warn(message, isbug)
  _skip_traceback_levels = 2
  io.stderr:flush()
  SILE.outputter:finish() -- Only really useful from the REPL but no harm in trying
  SILE.scratch.caughterror = true
  error(message, 2)
end

utilities.warn = function (message, isbug)
  if SILE.quiet then return end
  io.stderr:write("\n! " .. message)
  if SILE.traceback or isbug then
    io.stderr:write(" at:\n" .. SILE.traceStack:locationTrace())
    if _skip_traceback_levels == 2 then
      io.stderr:write(debug.traceback("", _skip_traceback_levels) or "\t! debug.traceback() did not identify code location")
    end
  else
    io.stderr:write(" at " .. SILE.traceStack:locationHead())
  end
  io.stderr:write("\n")
end

utilities.msg = function (message)
  if SILE.quiet then return end
  io.stderr:write("\n! " .. message .. "\n")
end

utilities.debugging = function (category)
  return SILE.debugFlags.all and category ~= "profile" or SILE.debugFlags[category]
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

utilities.deprecated = function (old, new, warnat, errorat, extra)
  warnat, errorat = semver(warnat or 0), semver(errorat or 0)
  local current = SILE.version and semver(SILE.version:match("v([0-9]*.[0-9]*.[0-9]*)")) or warnat
  -- SILE.version is defined *after* most of SILE loads. It’s available at
  -- runtime but not useful if we encounter deprecated code in core code. Users
  -- will never encounter this failure, but as a developer it’s hard to test a
  -- deprecation when core code refactoring is an all-or-nothing proposition.
  -- Hence we fake it ‘till we make it, all deprecations internally are warnings.
  local brackets = old:sub(1,1) == '\\' and "" or "()"
  local _new = new and "Please use " .. (new .. brackets) .. " instead." or "Plase don't use it."
  local msg = (old .. brackets) .. " was deprecated in SILE v" .. tostring(warnat) .. ". " .. _new ..  (extra and ("\n\n" .. extra .. "\n") or "")
  if errorat and current >= errorat then
    SU.error(msg)
  elseif warnat and current >= warnat then
    SU.warn(msg)
  end
end

utilities.debug = function (category, ...)
  if SILE.quiet then return end
  if utilities.debugging(category) then
    local inputs = table.pack(...)
    for i, input in ipairs(inputs) do
      if type(input) == "function" then
        local status, output = pcall(input)
        inputs[i] = status and output or SU.warn(("Output of %s debug function was an error: %s"):format(category, output))
      end
    end
    local message = utilities.concat(inputs, " ")
    if message then io.stderr:write(("\n[%s] %s"):format(category, message)) end
  end
end

utilities.debugAST = function (ast, level)
  if not ast then
    SU.error("debugAST called with nil", true)
  end
  local out = string.rep("  ", 1+level)
  if level == 0 then
    SU.debug("ast", function ()
      return "[" .. SILE.currentlyProcessingFile
    end)
  end
  if type(ast) == "function" then
    SU.debug("ast", function ()
      return out .. tostring(ast)
    end)
  elseif type(ast) == "table" then
    for _, content in ipairs(ast) do
      if type(content) == "string" then
        SU.debug("ast", function ()
          return out .. "[" .. content .. "]"
        end)
      elseif type(content) == "table" then
        if SILE.Commands[content.command] then
          SU.debug("ast", function ()
            return out .. "\\" .. content.command .. " " .. pl.pretty.write(content.options, "")
          end)
          if (#content>=1) then utilities.debugAST(content, level+1) end
        elseif content.id == "texlike_stuff" or (not content.command and not content.id) then
          utilities.debugAST(content, level+1)
        else
          SU.debug("ast", function ()
            return out .. "?\\" .. (content.command or content.id)
          end)
        end
      end
    end
  end
  if level == 0 then SU.debug("ast", "]") end
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

utilities.sortedpairs = function (input)
  local keys = {}
  for k, _ in pairs(input) do
    keys[#keys+1] = k
  end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b
    elseif type(a) == "number" then return true
    else return false
    end
  end)
  return coroutine.wrap(function()
    for i = 1, #keys do
      coroutine.yield(keys[i], input[keys[i]])
    end
  end)
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
  if wantedType:match(actualType)     then return value
  elseif actualType == "nil" and wantedType:match("nil") then return nil
  elseif wantedType:match("length")      then return SILE.length(value)
  elseif wantedType:match("measurement") then return SILE.measurement(value)
  elseif wantedType:match("vglue")       then return SILE.nodefactory.vglue(value)
  elseif wantedType:match("glue")        then return SILE.nodefactory.glue(value)
  elseif wantedType:match("kern")        then return SILE.nodefactory.kern(value)
  elseif actualType == "nil" then SU.error("Cannot cast nil to " .. wantedType)
  elseif wantedType:match("boolean")     then return SU.boolean(value)
  elseif wantedType:match("string")      then return tostring(value)
  elseif wantedType:match("number") then
    if type(value) == "table" and type(value.tonumber) == "function" then
      return value:tonumber()
    end
    local num = tonumber(value)
    if not num then SU.error("Cannot cast '" .. value .. "'' to " .. wantedType) end
    return num
  elseif wantedType:match("integer") then
    local num
    if type(value) == "table" and type(value.tonumber) == "function" then
      num = value:tonumber()
    else
      num = tonumber(value)
    end
    if not num then SU.error("Cannot cast '" .. value .. "'' to " .. wantedType) end
    if not wantedType:match("number") and num % 1 ~= 0 then
      -- Could be an error but since it wasn't checked before, let's just warn:
      -- Some packages might have wrongly typed settings, for instance.
      SU.warn("Casting an integer but got a float number " .. num)
    end
    return num
  else SU.error("Cannot cast to unrecognized type " .. wantedType)
  end
end

utilities.hasContent = function(content)
  return type(content) == "function" or type(content) == "table" and #content > 0
end

-- Flatten content trees into just the string components (allows passing
-- objects with complex structures to functions that need plain strings)
utilities.contentToString = function (content)
  local string = ""
  for i = 1, #content do
    if type(content[i]) == "table" and type(content[i][1]) == "string" then
      string = string .. content[i][1]
    elseif type(content[i]) == "string" then
      -- Work around PEG parser returning env tags as content
      -- TODO: refactor capture groups in PEG parser
      if content.command == content[i] and content[i] == content[i+1] then
        break
      end
      string = string .. content[i]
    end
  end
  return string
end

-- Strip the top level command off a content object and keep only the child
-- items — assuming that the current command is taking care of itself
utilities.subContent = function (content)
  local out = { id="stuff" }
  for key, val in utilities.sortedpairs(content) do
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

--- Strip position, line and column recursively from a content tree.
-- This can be used to remove position details where we do not want them,
-- e.g. in table of contents entries (referring to the original content,
-- regardless where it was exactly, for the purpose of checking whether
-- the table of contents changed.)
--
utilities.stripContentPos = function (content)
  if type(content) ~= "table" then
    return content
  end
  local stripped = {}
  for k, v in pairs(content) do
    if type(v) == "table" then
      v = SU.stripContentPos(v)
    end
    stripped[k] = v
  end
  if content.id or content.command then
    stripped.pos, stripped.col, stripped.lno = nil, nil, nil
  end
  return stripped
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
  utilities.deprecated("SU.utf8char", "luautf8.char", "0.11.0", "0.12.0")
  return luautf8.char(c)
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
      val = bitshim.band(c, 2^(8-seq) - 1)
    else
      val = bitshim.bor(bitshim.lshift(val, 6), bitshim.band(c, 0x3F))
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
    val = luautf8.char(cp)
  end
  return val
end

utilities.utf8codes = function (ustr)
  utilities.deprecated("SU.utf8codes", "luautf8.codes", "0.11.0", "0.12.0")
  return luautf8.codes(ustr)
end

utilities.utf16codes = function (ustr, endian)
  local pos = 1
  return function()
    if pos > #ustr then
      return nil
    else
      local c1, c2, c3, c4, wchar, lowchar
      c1 = string.byte(ustr, pos, pos+1)
      pos = pos + 1
      c2 = string.byte(ustr, pos, pos+1)
      pos = pos + 1
      if endian == "be" then
        wchar = c1 * 256 + c2
      else
        wchar = c2 * 256 + c1
      end
      if not (wchar >= 0xD800 and wchar <= 0xDBFF) then
        return wchar
      end
      c3 = string.byte(ustr, pos, pos+1)
      pos = pos + 1
      c4 = string.byte(ustr, pos, pos+1)
      pos = pos + 1
      if endian == "be" then
        lowchar = c3 * 256 + c4
      else
        lowchar = c4 * 256 + c3
      end
      return 0x10000 + bitshim.lshift(bitshim.band(wchar, 0x03FF), 10) + bitshim.band(lowchar, 0x03FF)
    end
  end
end

utilities.splitUtf8 = function (str) -- Return an array of UTF8 strings each representing a Unicode char
  local rv = {}
  for _, cp in luautf8.next, str do
    table.insert(rv, luautf8.char(cp))
  end
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

local byte, floor, reverse = string.byte, math.floor, string.reverse

utilities.utf8charat = function (str, index)
  return str:sub(index):match("([%z\1-\127\194-\244][\128-\191]*)")
end

local utf16bom = function(endianness)
  return endianness == "be" and "\254\255" or endianness == "le" and "\255\254" or SU.error("Unrecognized endianness")
end

utilities.hexencoded = function (str)
  local ustr = ""
  for i = 1, #str do
    ustr = ustr..string.format("%02x", byte(str, i, i+1))
  end
  return ustr
end

utilities.hexdecoded = function (str)
  if #str % 2 == 1 then SU.error("Cannot decode hex string with odd len") end
  local ustr = ""
  for i = 1, #str, 2 do
    ustr = ustr..string.char(tonumber(string.sub(str, i, i+1), 16))
  end
  return ustr
end

local uchr_to_surrogate_pair = function(uchr, endianness)
  local hi, lo = floor((uchr - 0x10000) / 0x400) + 0xd800, (uchr - 0x10000) % 0x400 + 0xdc00
  local s_hi, s_lo = string.char(floor(hi / 256)) .. string.char(hi % 256), string.char(floor(lo / 256)) .. string.char(lo % 256)
  return endianness == "le" and (reverse(s_hi) .. reverse(s_lo)) or s_hi .. s_lo
end

local uchr_to_utf16_double_byte = function(uchr, endianness)
  local ustr = string.char(floor(uchr / 256)) .. string.char(uchr % 256)
  return endianness == "le" and reverse(ustr) or ustr
end

local utf8_to_utf16 = function(str, endianness)
  local ustr = utf16bom(endianness)
  for _, uchr in luautf8.codes(str) do
    ustr = ustr..(uchr < 0x10000 and uchr_to_utf16_double_byte(uchr, endianness)
                  or uchr_to_surrogate_pair(uchr, endianness))
  end
  return ustr
end

utilities.utf8_to_utf16be = function (str) return utf8_to_utf16(str, "be") end
utilities.utf8_to_utf16le = function (str) return utf8_to_utf16(str, "le") end
utilities.utf8_to_utf16be_hexencoded = function (str) return utilities.hexencoded(utilities.utf8_to_utf16be(str)) end
utilities.utf8_to_utf16le_hexencoded = function (str) return utilities.hexencoded(utilities.utf8_to_utf16le(str)) end

local utf16_to_utf8 = function (str, endianness)
  local bom = utf16bom(endianness)

  if str:find(bom) == 1 then str = string.sub(str, 3, #str) end
  local ustr = ""
  for uchr in utilities.utf16codes(str, endianness) do
    ustr = ustr..luautf8.char(uchr)
  end
  return ustr
end

utilities.utf16be_to_utf8 = function (str) return utf16_to_utf8(str, "be") end
utilities.utf16le_to_utf8 = function (str) return utf16_to_utf8(str, "le") end

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
    -- Note LuaJIT does not support __len, so this has to work even when that metamethod doesn't fire...
    return self[#SILE.traceStack-(count or 1)]
  end

  function breadcrumbs:contains (needle)
    for i, command in ipairs(self) do
      if command == needle then return true, #self - i end
    end
    return false, -1
  end

  return breadcrumbs
end

utilities.formatNumber = require("core.utilities-numbers")

utilities.collatedSort = require("core.utilities-sorting")

return utilities
