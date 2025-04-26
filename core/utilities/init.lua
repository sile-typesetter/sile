--- SILE.utilities (aliased as SU)
-- @module SU
-- @alias utilities

local bitshim = require("bitshim")
local luautf8 = require("lua-utf8")
local semver = require("rusile").semver

local utilities = {}

local epsilon = 1E-12

--- Generic
-- @section generic

--- Concatenate values from a table using a given separator.
-- Differs from `table.concat` in that all values are explicitly cast to strings, allowing debugging of tables that
-- include functions, other tables, data types, etc.
-- @tparam table array Input.
-- @tparam[opt=" "] string separator Separator.
function utilities.concat (array, separator)
   return table.concat(utilities.map(tostring, array), separator)
end

--- Execute a callback function on each value in a table.
-- @tparam function func Function to run on each value.
-- @tparam table array Input list-like table.
function utilities.map (func, array)
   local new_array = {}
   local last = #array
   for i = 1, last do
      new_array[i] = func(array[i])
   end
   return new_array
end

--- Require that an option table contains a specific value, otherwise raise an error.
-- @param options Input table of options.
-- @param name Name of the required option.
-- @param context User friendly name of the function or calling context.
-- @param required_type The name of a data type that the option must successfully cast to.
function utilities.required (options, name, context, required_type)
   if not options[name] then
      utilities.error(context .. " needs a " .. name .. " parameter")
   end
   if required_type then
      return utilities.cast(required_type, options[name])
   end
   return options[name]
end

--- Iterate over key/value pairs in sequence of the sorted keys.
-- Table iteration order with `pairs` is non-deterministic. This function returns an iterator that can be used in plais
-- of `pairs` that will iterate through the values in the order of their *sorted* keys.
-- @tparam table input Input table.
-- @usage for val in SU.sortedpairs({ b: "runs second", a: "runs first" ) do print(val) end
function utilities.sortedpairs (input)
   local keys = {}
   for k, _ in pairs(input) do
      keys[#keys + 1] = k
   end
   table.sort(keys, function (a, b)
      if type(a) == type(b) then
         return a < b
      elseif type(a) == "number" then
         return true
      else
         return false
      end
   end)
   return coroutine.wrap(function ()
      for i = 1, #keys do
         coroutine.yield(keys[i], input[keys[i]])
      end
   end)
end

--- Substitute a range of value(s) in one table with values from another.
-- @tparam table array Table to modify.
-- @tparam integer start First key to replace.
-- @tparam integer stop Last key to replace.
-- @tparam table replacement Table from which to pull key/values plairs to inject in array.
-- @treturn table array First input array modified with values from replacement.
function utilities.splice (array, start, stop, replacement)
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

-- TODO: Unused, now deprecated?
function utilities.inherit (orig, spec)
   local new = pl.tablex.deepcopy(orig)
   if spec then
      for k, v in pairs(spec) do
         new[k] = v
      end
   end
   if new.init then
      new:init()
   end
   return new
end

--- Type handling
-- @section types

local function preferbool ()
   utilities.warn("Please use boolean values or strings such as 'true' and 'false' instead of 'yes' and 'no'.")
end

--- Cast user input into a boolean type.
-- User input content such as options typed into documents will return string values such as "true" or "false rather
-- than true or false types. This evaluates those strings or other inputs ane returns a consistent boolean type in
-- return.
-- @tparam nil|bool|string value Input value such as a string to evaluate for thruthyness.
-- @tparam[opt=false] boolean default Whether to assume inputs that don't specifically evaluate to something should be true or false.
-- @treturn boolean
function utilities.boolean (value, default)
   if value == false then
      return false
   end
   if value == true then
      return true
   end
   if value == "false" then
      return false
   end
   if value == "true" then
      return true
   end
   if value == "no" then
      preferbool()
      return false
   end
   if value == "yes" then
      preferbool()
      return true
   end
   if value == nil then
      return default == true
   end
   if value == "" then
      return default == true
   end
   SU.error("Expecting a boolean value but got '" .. value .. "'")
   return default == true
end

--- Cast user input to an expected type.
-- If possible, converts input from one type to another. Not all types can be cast. For example "four" can't be cast to
-- a number, but "4" or 4 can. Likewise "6pt" or 6 can be cast to a SILE.types.measurement, SILE.types.length, or even
-- a SILE.types.node.glue, but not a SILE.types.color.
-- @tparam string wantedType Expected type.
-- @return A value of the type wantedType.
function utilities.cast (wantedType, value)
   local actualType = SU.type(value)
   wantedType = string.lower(wantedType)
   if wantedType:match(actualType) then
      return value
   elseif actualType == "nil" and wantedType:match("nil") then
      return nil
   elseif wantedType:match("length") then
      return SILE.types.length(value)
   elseif wantedType:match("measurement") then
      return SILE.types.measurement(value)
   elseif wantedType:match("vglue") then
      return SILE.types.node.vglue(value)
   elseif wantedType:match("glue") then
      return SILE.types.node.glue(value)
   elseif wantedType:match("kern") then
      return SILE.types.node.kern(value)
   elseif actualType == "nil" then
      SU.error("Cannot cast nil to " .. wantedType)
   elseif wantedType:match("boolean") then
      return SU.boolean(value)
   elseif wantedType:match("string") then
      return tostring(value)
   elseif wantedType:match("number") then
      if type(value) == "table" and type(value.tonumber) == "function" then
         return value:tonumber()
      end
      local num = tonumber(value)
      if not num then
         SU.error("Cannot cast '" .. value .. "'' to " .. wantedType)
      end
      return num
   elseif wantedType:match("integer") then
      local num
      if type(value) == "table" and type(value.tonumber) == "function" then
         num = value:tonumber()
      else
         num = tonumber(value)
      end
      if not num then
         SU.error("Cannot cast '" .. value .. "'' to " .. wantedType)
      end
      if not wantedType:match("number") and num % 1 ~= 0 then
         -- Could be an error but since it wasn't checked before, let's just warn:
         -- Some packages might have wrongly typed settings, for instance.
         SU.warn("Casting an integer but got a float number " .. num)
      end
      return num
   else
      SU.error("Cannot cast to unrecognized type " .. wantedType)
   end
end

--- Return the type of an object
-- Like Lua's `type`, but also handles various SILE user data types.
-- @tparam any value Any input value. If a table is one of SILE's classes or types, report on it's internal type.
-- Otherwise use the output of `type`.
-- @treturn string
function utilities.type (value)
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

--- Errors and debugging
-- @section errors

--- Output a debug message only if debugging for a specific category is enabled.
-- Importantly passing siries of strings, functions, or tables is more efficient than trying to formulate a full message
-- using concatenation and tostring() methods in the original code because it doesn't have to even run if the relevant
-- debug flag is not enabled.
-- @tparam text category Category flag for which this message should be output.
-- @tparam string|function|table ... Each argument will be returned separated by spaces, strings directly, functions by
-- evaluating them and assuming the return value is a string, and tables by using their internal :__tostring() methods.
-- @usage
--    > glue = SILE.types.node.glue("6em")
--    > SU.debug("foo", "A glue node", glue)
--    [foo] A glue node G<6em>
function utilities.debug (category, ...)
   if SILE.quiet then
      return
   end
   if utilities.debugging(category) then
      local inputs = pl.utils.pack(...)
      for i, input in ipairs(inputs) do
         if type(input) == "function" then
            local status, output = pcall(input)
            inputs[i] = status and output
               or SU.warn(("Output of %s debug function was an error: %s"):format(category, output))
         elseif type(input) ~= "string" then
            inputs[i] = tostring(input)
         end
      end
      local message = utilities.concat(inputs, " ")
      if message then
         io.stderr:write(("\n[%s] %s"):format(category, message))
      end
   end
end

--- Determine if a specific debug flag is set.
-- @tparam string category Name of the flag status to check, e.g. "frames".
-- @treturn boolean
function utilities.debugging (category)
   return SILE.debugFlags.all and category ~= "profile" or SILE.debugFlags[category]
end

--- Warn about use of a deprecated feature.
-- Checks the current version and decides whether to warn or error, then oatputs a message with as much useful
-- information as possible to make it easy for end users to update their usage.
-- @tparam string old The name of the deprecated interface.
-- @tparam string new A name of a suggested replacement interface.
-- @tparam string warnat The first release where the interface is considered deprecated, at which point their might be
-- a shim.
-- @tparam string errorat The first release where the interface is no longer functional even with a shim.
-- @tparam string extra Longer-form help to include in output separate from the expected one-liner of warning messages.
function utilities.deprecated (old, new, warnat, errorat, extra)
   warnat, errorat = semver(warnat or 0), semver(errorat or 0)
   local current = SILE.version and semver(SILE.version:match("v([0-9]*.[0-9]*.[0-9]*)")) or warnat
   -- SILE.version is defined *after* most of SILE loads. It’s available at
   -- runtime but not useful if we encounter deprecated code in core code. Users
   -- will never encounter this failure, but as a developer it’s hard to test a
   -- deprecation when core code refactoring is an all-or-nothing proposition.
   -- Hence we fake it ‘till we make it, all deprecations internally are warnings.
   local brackets = old:sub(1, 1) == "\\" and "" or "()"
   local _new = new and "Please use " .. (new .. brackets) .. " instead." or "Please don't use it."
   local msg = (old .. brackets)
      .. " was deprecated in SILE v"
      .. tostring(warnat)
      .. "\n\n  "
      .. _new
      .. "\n\n"
      .. (extra and (pl.stringx.indent(pl.stringx.dedent(extra), 2)) or "")
   if errorat and current >= errorat then
      SU.error(msg)
   elseif warnat and current >= warnat then
      SU.warn(msg)
   end
end

--- Dump the contents of a any Lua type.
-- For quick debugging, can be used on any number of any type of Lua value. Pretty-prints tables.
-- @tparam any ... Any number of values
function utilities.dump (...)
   local arg = { ... } -- Avoid things that Lua stuffs in arg like args to self()
   pl.pretty.dump(#arg == 1 and arg[1] or arg, "/dev/stderr")
end

local _skip_traceback_levels = 2

--- Raise an error and exit.
-- Outputs a warning message via `warn`, then finishes up anything it can without processing more content, then exits.
-- @tparam string message The error message to give.
-- @tparam boolean isbug Whether or not hitting this error is expected to be a code bug (as opposed to mistakes in user input).
function utilities.error (message, isbug)
   SILE.quiet = false
   _skip_traceback_levels = 3
   utilities.warn(message, isbug)
   _skip_traceback_levels = 2
   io.stderr:flush()
   SILE.outputter:abort()
   SILE.scratch.caughterror = true
   error("", 2)
end

--- Output an information message.
-- Basically like `warn`, except to source tracing information is added.
-- @tparam string message
function utilities.msg (message)
   if SILE.quiet then
      return
   end
   message = pl.stringx.rstrip(message)
   message = "                        " .. message
   message = pl.stringx.dedent(message)
   message = pl.stringx.lstrip(message)
   message = pl.stringx.indent(message, 2)
   message = message:gsub("^.", "!")
   io.stderr:write("\n" .. message .. "\n")
end

--- Output a warning.
-- Outputs a warning message including identifying where in the processing SILE is at when the warning is given.
-- @tparam string message The error message to give.
-- @tparam boolean isbug Whether or not hitting this warning is expected to be a code bug (as opposed to mistakes in user input).
function utilities.warn (message, isbug)
   if SILE.quiet then
      return
   end
   utilities.msg(message)
   if SILE.traceback or isbug then
      io.stderr:write("at:\n" .. SILE.traceStack:locationTrace())
      if _skip_traceback_levels == 2 then
         io.stderr:write(
            debug.traceback("", _skip_traceback_levels) or "\t! debug.traceback() did not identify code location"
         )
      end
   else
      io.stderr:write("  at " .. SILE.traceStack:locationHead())
   end
   io.stderr:write("\n")
end

--- Math
-- @section math

--- Check equality of floating point values.
-- Comparing floating point numbers using math functions in Lua may give different and unexpected answers depending on
-- the Lua VM and other environmental factors. This normalizes them using our standard internal epsilon value and
-- compares the absolute intereger value to avoid floating point number weirdness.
-- @tparam float lhs
-- @tparam float rhs
-- @treturn boolean
function utilities.feq (lhs, rhs)
   lhs = SU.cast("number", lhs)
   rhs = SU.cast("number", rhs)
   local abs = math.abs
   return abs(lhs - rhs) <= epsilon * (abs(lhs) + abs(rhs))
end

--- Add up all the values in a table.
-- @tparam table array Input list-like table.
-- @treturn number Sum of all values.
function utilities.sum (array)
   local total = 0
   local last = #array
   for i = 1, last do
      total = total + array[i]
   end
   return total
end

--- Return maximum value of inputs.
-- `math.max`, but works on SILE types such as SILE.types.measurement.
-- Lua <= 5.2 can't handle math operators on objects.
function utilities.max (...)
   local input = pl.utils.pack(...)
   local max = table.remove(input, 1)
   for _, val in ipairs(input) do
      if val > max then
         max = val
      end
   end
   return max
end

--- Return minimum value of inputs.
-- `math.min`, but works on SILE types such as SILE.types.measurement.
-- Lua <= 5.2 can't handle math operators on objects.
function utilities.min (...)
   local input = pl.utils.pack(...)
   local min = input[1]
   for _, val in ipairs(input) do
      if val < min then
         min = val
      end
   end
   return min
end

--- Round and normalize a number for debugging.
-- LuaJIT 2.1 betas (and inheritors such as OpenResty and Moonjit) are biased
-- towards rounding 0.5 up to 1, all other Lua interpreters are biased
-- towards rounding such floating point numbers down.  This hack shaves off
-- just enough to fix the bias so our test suite works across interpreters.
-- Note that even a true rounding function here will fail because the bias is
-- inherent to the floating point type. Also note we are erroring in favor of
-- the *less* common option because the LuaJIT VMS are hopelessly broken
-- whereas normal LUA VMs can be cooerced.
-- @tparam number input Input value.
-- @treturn string Four-digit precision foating point.
function utilities.debug_round (input)
   if input > 0 then
      input = input + 0.00000000000001
   end
   if input < 0 then
      input = input - 0.00000000000001
   end
   return string.format("%.4f", input)
end

--- Remove empty spaces from list-like tables
-- Iterating list-like tables is hard if some values have been removed. This converts { 1 = "a", 3 = "b" } into
-- { 1 = "a", 2 = "b" } which can be iterated using `ipairs` without stopping after 1.
-- @tparam table items List-like table potentially with holes.
-- @treturn table List like table without holes.
function utilities.compress (items)
   local rv = {}
   local max = math.max(pl.utils.unpack(pl.tablex.keys(items)))
   for i = 1, max do
      if items[i] then
         rv[#rv + 1] = items[i]
      end
   end
   return rv
end

--- Reverse the order of a list-like table.
-- @tparam table tbl Input list-like table.
function utilities.flip_in_place (tbl)
   local tmp, j
   for i = 1, math.floor(#tbl / 2) do
      tmp = tbl[i]
      j = #tbl - i + 1
      tbl[i] = tbl[j]
      tbl[j] = tmp
   end
end

-- TODO: Before documenting, consider whether this should be private to the one existing usage.
function utilities.allCombinations (options)
   local count = 1
   for i = 1, #options do
      count = count * options[i]
   end
   return coroutine.wrap(function ()
      for i = 0, count - 1 do
         local this = i
         local rv = {}
         for j = 1, #options do
            local base = options[j]
            rv[#rv + 1] = this % base + 1
            this = (this - this % base) / base
         end
         coroutine.yield(rv)
      end
   end)
end

function utilities.rateBadness (inf_bad, shortfall, spring)
   if spring == 0 then
      return inf_bad
   end
   local bad = math.floor(100 * math.abs(shortfall / spring) ^ 3)
   return math.min(inf_bad, bad)
end

function utilities.rationWidth (target, width, ratio)
   if ratio < 0 and width.shrink:tonumber() > 0 then
      target:___add(width.shrink:tonumber() * ratio)
   elseif ratio > 0 and width.stretch:tonumber() > 0 then
      target:___add(width.stretch:tonumber() * ratio)
   end
   return target
end

--- Text handling
-- @section text

--- Iterate over a string split into tokens via a pattern.
-- @tparam string string Input string.
-- @tparam string pattern Pattern on which to split the input.
-- @treturn function An iterator function
-- @usage for str in SU.gtoke("foo-bar-baz", "-") do print(str) end
function utilities.gtoke (string, pattern)
   string = string and tostring(string) or ""
   pattern = pattern and tostring(pattern) or "%s+"
   local length = #string
   return coroutine.wrap(function ()
      local index = 1
      repeat
         local first, last = string:find(pattern, index)
         if last then
            if index < first then
               coroutine.yield({ string = string:sub(index, first - 1) })
            end
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

--- Convert a Unicode character to its corresponding codepoint.
-- @tparam string uchar A single inicode character.
-- @return number The Unicode code point where uchar is encoded.
function utilities.codepoint (uchar)
   local seq = 0
   local val = -1
   for i = 1, #uchar do
      local c = string.byte(uchar, i)
      if seq == 0 then
         if val > -1 then
            return val
         end
         seq = c < 0x80 and 1
            or c < 0xE0 and 2
            or c < 0xF0 and 3
            or c < 0xF8 and 4 --c < 0xFC and 5 or c < 0xFE and 6 or
            or error("invalid UTF-8 character sequence")
         val = bitshim.band(c, 2 ^ (8 - seq) - 1)
      else
         val = bitshim.bor(bitshim.lshift(val, 6), bitshim.band(c, 0x3F))
      end
      seq = seq - 1
   end
   return val
end

--- Covert a code point to a Unicode character.
-- @tparam number|string codepoint Input code point value, either as a number or a string representing the decimal value "U+NNNN" or hex value "0xFFFF".
-- @treturn string The character replestened by a codepoint descriptions.
function utilities.utf8charfromcodepoint (codepoint)
   local val = codepoint
   local cp = val
   local hex = (cp:match("[Uu]%+(%x+)") or cp:match("0[xX](%x+)"))
   if hex then
      cp = tonumber("0x" .. hex)
   elseif tonumber(cp) then
      cp = tonumber(cp)
   end

   if type(cp) == "number" then
      val = luautf8.char(cp)
   end
   return val
end

--- Convert a UTF-16 encoded string to a series of code points.
-- Like `luautf8.codes`, but for UTF-16 strings.
-- @tparam string ustr Input string.
-- @tparam string endian Either "le" or "be" depending on the encoding endedness.
-- @treturn string Serious of hex encoded code points.
function utilities.utf16codes (ustr, endian)
   local pos = 1
   return function ()
      if pos > #ustr then
         return nil
      else
         local c1, c2, c3, c4, wchar, lowchar
         c1 = string.byte(ustr, pos, pos + 1)
         pos = pos + 1
         c2 = string.byte(ustr, pos, pos + 1)
         pos = pos + 1
         if endian == "be" then
            wchar = c1 * 256 + c2
         else
            wchar = c2 * 256 + c1
         end
         if not (wchar >= 0xD800 and wchar <= 0xDBFF) then
            return wchar
         end
         c3 = string.byte(ustr, pos, pos + 1)
         pos = pos + 1
         c4 = string.byte(ustr, pos, pos + 1)
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

--- Split a UTF-8 string into characters.
-- Lua's `string.split` will only explode a string by bytes. For text processing purposes it is usually more desirable
-- to split it into 1, 2, 3, or 4 byte groups matching the UTF-8 encoding.
-- @tparam string str Input UTF-8 encoded string.
-- @treturn table A list-like table of UTF8 strings each representing a Unicode char from the input string.
function utilities.splitUtf8 (str)
   local rv = {}
   for _, cp in luautf8.next, str do
      table.insert(rv, luautf8.char(cp))
   end
   return rv
end

--- The last Unicode character in a UTF-8 encoded string.
-- Uses `SU.splitUtf8` to break an string into segments represtenting encoded characters, returns the last one. May be
-- more than one byte.
-- @tparam string str Input string.
-- @treturn string A single Unicode character.
function utilities.lastChar (str)
   local chars = utilities.splitUtf8(str)
   return chars[#chars]
end

--- The first Unicode character in a UTF-8 encoded string.
-- Uses `SU.splitUtf8` to break an string into segments represtenting encoded characters, returns the first one. May be
-- more than one byte.
-- @tparam string str Input string.
-- @treturn string A single Unicode character.
function utilities.firstChar (str)
   local chars = utilities.splitUtf8(str)
   return chars[1]
end

local byte, floor, reverse = string.byte, math.floor, string.reverse

--- The Unicode character in a UTF-8 encoded string at a specific position
-- Uses `SU.splitUtf8` to break an string into segments represtenting encoded characters, returns the Nth one. May be
-- more than one byte.
-- @tparam string str Input string.
-- @tparam number index Index of character to return.
-- @treturn string A single Unicode character.
function utilities.utf8charat (str, index)
   return str:sub(index):match("([%z\1-\127\194-\244][\128-\191]*)")
end

local utf16bom = function (endianness)
   return endianness == "be" and "\254\255" or endianness == "le" and "\255\254" or SU.error("Unrecognized endianness")
end

--- Encode a string to a hexadecimal replesentation.
-- @tparam string str Input UTF-8 string
-- @treturn string Hexadecimal replesentation of str.
function utilities.hexencoded (str)
   local ustr = ""
   for i = 1, #str do
      ustr = ustr .. string.format("%02x", byte(str, i, i + 1))
   end
   return ustr
end

--- Decode a hexadecimal replesentation into a string.
-- @tparam string str Input hexadecimal encoded string.
-- @treturn string UTF-8 string.
function utilities.hexdecoded (str)
   if #str % 2 == 1 then
      SU.error("Cannot decode hex string with odd len")
   end
   local ustr = ""
   for i = 1, #str, 2 do
      ustr = ustr .. string.char(tonumber(string.sub(str, i, i + 1), 16))
   end
   return ustr
end

local uchr_to_surrogate_pair = function (uchr, endianness)
   local hi, lo = floor((uchr - 0x10000) / 0x400) + 0xd800, (uchr - 0x10000) % 0x400 + 0xdc00
   local s_hi, s_lo =
      string.char(floor(hi / 256)) .. string.char(hi % 256), string.char(floor(lo / 256)) .. string.char(lo % 256)
   return endianness == "le" and (reverse(s_hi) .. reverse(s_lo)) or s_hi .. s_lo
end

local uchr_to_utf16_double_byte = function (uchr, endianness)
   local ustr = string.char(floor(uchr / 256)) .. string.char(uchr % 256)
   return endianness == "le" and reverse(ustr) or ustr
end

local utf8_to_utf16 = function (str, endianness)
   local ustr = utf16bom(endianness)
   for _, uchr in luautf8.codes(str) do
      ustr = ustr
         .. (uchr < 0x10000 and uchr_to_utf16_double_byte(uchr, endianness) or uchr_to_surrogate_pair(uchr, endianness))
   end
   return ustr
end

--- Convert a UTF-8 string to big-endian UTF-16.
-- @tparam string str UTF-8 encoded string.
-- @treturn string Big-endian UTF-16 encoded string.
function utilities.utf8_to_utf16be (str)
   return utf8_to_utf16(str, "be")
end

--- Convert a UTF-8 string to little-endian UTF-16.
-- @tparam string str UTF-8 encoded string.
-- @treturn string Little-endian UTF-16 encoded string.
function utilities.utf8_to_utf16le (str)
   return utf8_to_utf16(str, "le")
end

--- Convert a UTF-8 string to big-endian UTF-16, then encode in hex.
-- @tparam string str UTF-8 encoded string.
-- @treturn string Hexadecimal representation of a big-endian UTF-16 encoded string.
function utilities.utf8_to_utf16be_hexencoded (str)
   return utilities.hexencoded(utilities.utf8_to_utf16be(str))
end

--- Convert a UTF-8 string to little-endian UTF-16, then encode in hex.
-- @tparam string str UTF-8 encoded string.
-- @treturn string Hexadecimal representation of a little-endian UTF-16 encoded string.
function utilities.utf8_to_utf16le_hexencoded (str)
   return utilities.hexencoded(utilities.utf8_to_utf16le(str))
end

local utf16_to_utf8 = function (str, endianness)
   local bom = utf16bom(endianness)

   if str:find(bom) == 1 then
      str = string.sub(str, 3, #str)
   end
   local ustr = ""
   for uchr in utilities.utf16codes(str, endianness) do
      ustr = ustr .. luautf8.char(uchr)
   end
   return ustr
end

--- Convert a big-endian UTF-16 string to UTF-8.
-- @tparam string str Big-endian UTF-16 encoded string.
-- @treturn string UTF-8 encoded string.
function utilities.utf16be_to_utf8 (str)
   return utf16_to_utf8(str, "be")
end

--- Convert a little-endian UTF-16 string to UTF-8.
-- @tparam string str Little-endian UTF-16 encoded string.
-- @treturn string UTF-8 encoded string.
function utilities.utf16le_to_utf8 (str)
   return utf16_to_utf8(str, "le")
end

function utilities.breadcrumbs ()
   local breadcrumbs = {}

   setmetatable(breadcrumbs, {
      __index = function (_, key)
         local frame = SILE.traceStack[key]
         return frame and frame.command or nil
      end,
      __len = function (_)
         return #SILE.traceStack
      end,
      __tostring = function (self)
         return "B»" .. table.concat(self, "»")
      end,
   })

   function breadcrumbs:dump ()
      SU.dump(self)
   end

   function breadcrumbs:parent (count)
      -- Note LuaJIT does not support __len, so this has to work even when that metamethod doesn't fire...
      return self[#SILE.traceStack - (count or 1)]
   end

   function breadcrumbs:contains (needle, startdepth)
      startdepth = startdepth or 0
      for i = startdepth, #SILE.traceStack - 1 do
         local frame = SILE.traceStack[#SILE.traceStack - i]
         if frame.command == needle then
            return true, #self - i
         end
      end
      return false, -1
   end

   return breadcrumbs
end

utilities.formatNumber = require("core.utilities.numbers")

utilities.collatedSort = require("core.utilities.sorting")

utilities.ast = require("core.utilities.ast")
utilities.debugAST = utilities.ast.debug

function utilities.subContent (content)
   SU.deprecated(
      "SU.subContent",
      "SU.ast.subContent",
      "0.15.0",
      "0.17.0",
      [[Note that the new implementation no longer introduces an id="stuff" key.]]
   )
   return utilities.ast.subContent(content)
end

function utilities.hasContent (content)
   SU.deprecated("SU.hasContent", "SU.ast.hasContent", "0.15.0", "0.17.0")
   return SU.ast.hasContent(content)
end

function utilities.contentToString (content)
   SU.deprecated("SU.contentToString", "SU.ast.contentToString", "0.15.0", "0.17.0")
   return SU.ast.contentToString(content)
end

function utilities.walkContent (content, action)
   SU.deprecated("SU.walkContent", "SU.ast.walkContent", "0.15.0", "0.17.0")
   SU.ast.walkContent(content, action)
end

function utilities.stripContentPos (content)
   SU.deprecated("SU.stripContentPos", "SU.ast.stripContentPos", "0.15.0", "0.17.0")
   return SU.ast.stripContentPos(content)
end

-- On demand loader, allows modules to be loaded into a specific scope only if/when accessed
function utilities._module_loader (scope)
   return setmetatable({}, {
      __index = function (self, key)
         local spec = ("%s.%s"):format(scope, key)
         local status, module = pcall(require, spec)
         if not status then
            if scope == "languages" then
               SU.warn(("Unable to load support for language '%s' (not found or unparsable), handling with generic unicode module."):format(key))
               local unicode = require("languages.unicode")
               local language = pl.class(unicode)
               language._name = key
               self[key] = language
               return language
            else
               SU.error(("Unable to load core module %s:\n%s"):format(spec, module))
            end
         end
         self[key] = module
         return module
      end,
   })
end

return utilities
