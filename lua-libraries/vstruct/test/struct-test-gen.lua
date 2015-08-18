-- Config
local CONF = {
  VERBOSE = false,   -- Spew verbosely while testing?

  WIDTH = 32,      -- Total size of numbers in bits.
  PRECISION = 17,    -- Fractional precision in bits.

  MAX_DEPTH = 5,     -- Limit on nesting depth of test formats.
  COMPOUND_LENGTH = 2,   -- # formats in a sequence.
  SEED = false,    -- Seed for generating tests.
  
  NROF_TESTS = 2^10,  -- number of random test cases to run
}

-- Features to use when making format strings to test.
local USE = {
  LEFT_REPETITION = true,  --n*fmt
  GROUPING = true,   --{ fmt }
  NESTING = true,    --( fmt )
  NAMING = true,   --id:fmt
  ENDIAN = true,   --><
  EMPTY = true,    --
  COMPOUND = true    --fmt fmt ... fmt
}


-- Non-config
local PROTECT_STRUCT = true -- If set, wrap calls to struct with pcall.
local TEST_KIND = nil   --"read"|"write"

-- Should every format string explicitly set the endianness at the start?
-- Setting this to true mask(s|ed?) a bug where the endianness controls leak
-- between calls to struct.write().
local PREFIX_ENDIAN = false
local PREFIX_ENDIAN_SEP = " " --"" gives format string parse errors

local TOKEN_SEP = ""    -- Separator between tokens.
local MAX_BITS = 52   -- Maximum bit size we care about.
local MACHINE_ENDIAN = "<"  -- Native endianness.

local COMPOUND_SEP = " "

local loadstring = loadstring or load

-- Parse arguments and sort then out into USE vs. CONF options.
for _,given_arg in ipairs(arg) do
  local k,v = given_arg:match("^([^=]+)=(.+)")
  k = k or given_arg
  k = k:upper():gsub("-", "_")
  v = v or true

  if nil ~= CONF[k] then
    CONF[k] = assert(loadstring("return "..tostring(v)))()
  elseif nil ~= USE[k] then
    USE[k] = v ~= "FALSE" and true or false
  elseif k == "NONE" then
    for feature,_ in pairs(USE) do USE[feature] = false end
  elseif given_arg == "read" or given_arg == "write" then
    TEST_KIND = given_arg
  else
    io.stderr:write(("unknown argument %q\n"):format(given_arg))
    os.exit(1)
  end
end

-- Imports
local io, math, os, string, table =
  io, math, os, string, table

local assert, ipairs, pairs, pcall =
  assert, ipairs, pairs, pcall
local require, setmetatable, tonumber, tostring, type =
  require, setmetatable, tonumber, tostring, type

local struct = require "vstruct"; struct.cache = nil
local test = require "vstruct.test.common"
local record = test.record
local __EOG__ = __EOG__

local ceil,floor,fmod = math.ceil, math.floor, math.fmod
local char_ = string.char

local function char(x) return char_(x % 256) end

-- Structural equality (no cycles please)
local function eq(a,b)
  if a == b then return true end
  local t = type(a)
  if t ~= type(b) then return false end
  if t ~= "table" then return false end

  for k,av in pairs(a) do
    local bv = b[k]
    if not eq(av,bv) then
      return false
    end
  end
  for k,bv in pairs(b) do
    local av = a[k]
    if not eq(av,bv) then
      return false
    end
  end
  return true
end

-- str = dump(value)
local dump = {}
setmetatable(dump,
  {
    __call =
      function (self, value)
        local t = type(value)
        local f = dump[t]
        assert(f, "don't know how to dump "..
                  "values of type "..t)
        return f(value)
      end
  })

dump["nil"] = function() return "nil" end

function dump.string(s) return ("%q"):format(s) end

function dump.boolean(b) return tostring(b) end

function dump.number(x)
  local m, e = math.frexp(x)   --0.5 <= m <= 1, e an int
  for i=1,53 do      --scale m to an integer
    if floor(m) == m then break end
    m = m*2
    e = e - 1
  end

  if e == 0 then return ("%.0f"):format(m) end

  local op = e < 0 and "/" or "*"
  e = math.abs(e)
  local exp = e > 1 and "2^"..e or "2"
  return ("%.0f%s%s"):format(m, op, exp)
end

function dump.table(t)
  local dumped = {}

  local pieces = {}
  local function push(x) table.insert(pieces, x) end

  push("{")

  for i, v in ipairs(t) do
    if #pieces > 1 then push(", ") end
    push(dump(v))
    dumped[i] = true
  end

  for k,v in pairs(t) do
    if not dumped[k] then
      if #pieces > 1 then push(", ") end
      if type(k) == "string" and k:match("^%a[a-zA-Z0-9_]*$") then
        push(k)
      else
        push("[")
        push(dump(k))
        push("]")
      end
      push("=")
      push(dump(v))
    end
  end

  push("}")
  return table.concat(pieces)
end

-- List module
local list
list = {
  reverse = 
    function (t)
      local out = {}
      local n = #t
      for i=1,n do
        local j = n-i+1
        out[j] = t[i]
      end
      return out
    end,

  iter =
    function (t, f)
      for i,v in ipairs(t) do  f(v)  end
      return t
    end,

  map =
    function (t, f)
      local out = {}
      for i,v in ipairs(t) do  out[i] = f(v)  end
      return out
    end,

  foldl =
    function (t, f, accu)
      for i,v in ipairs(t) do  accu = f(v, accu)  end
      return accu
    end,

  merge =
    function (dst, src)
      local merged = {}
      for k,v in ipairs(src) do --append the array part
        table.insert(dst, v)
        merged[k] = true
      end
      for k,v in pairs(src) do --overwrite the hash part
        if not merged[k] then
          dst[k] = v
        end
      end
      return dst
    end,

  zeros =
    function (n)
      local t={}
      for i=1,n do t[i] = 0 end
      return t
    end,

  range =
    function (first, last, step)
      local t = {}
      if nil == last then
        first,last,step = 1,first,step
      end
      step = step or 1
      for i=first,last,step do t[#t+1] = i end
      return t
    end,

  cat =
    function (...)
      local accu = {}
      local function loop(t,...)
        if nil == t then return accu end
        list.merge(accu, t)
        return loop(...)
      end
      return loop(...)
    end,

  rep =
    function (t, count)
      count = count or 0
      local accu = {}
      for i=1,count do list.merge(accu, t) end
      return accu
    end
}

-- MRG32k3a random number generator.
-- Returns numbers which are random for the full range of the IEEE
-- double mantissa.
local function make_rand(seed)

  local s10, s11, s12 = 12345,12345,12345
  local s20, s21, s22 = 12345,12345,12345

  local function rand()
    -- Return the next random number in the range [0,4294967087).
    local p1 = (1403580*s11 - 810728*s10) % 4294967087
    local p2 = (527612*s22 - 1370589*s20) % 4294944443
    s10,s11,s12 = s11,s12,p1
    s20,s21,s22 = s21,s22,p2
    return (p1 - p2) % 4294967087
  end

  if seed then
    seed = tonumber(seed) or 12345
    local m = 4294967087
    local a = seed % 4294967087
    a = a==a and a or 12345
    s10,s11,s12,s20,s21,s22 = a,a+1,a+2,a+3,a+4,a+5 -- not all zero
    rand(); rand(); rand(); -- pump out the seed.
  end

  local frexp = math.frexp

  local function rand52()
    local hi,lo = rand(), rand()
    local m,e = frexp(hi * 4294967087 + lo) -- 0.5 <= m < 1
    local t = m*2^53 - 2^52 -- map mantissa to 0 <= t < 2^52 range
    return t
  end

  return rand52
end

local function byte_rand(rand)
  return function () return rand() % 256 end
end

local function bool_rand(rand)
  return function () return rand() % 2 == 0 end
end

local function char_rand(rand)
  return function () return char(rand()) end
end

local function clamped_rand(rand, lo, hi)
  local wid = hi - lo + 1
  return function () return lo + (rand() % wid) end
end

local function string_rand(rand, minlen, maxlen)
  minlen = minlen or 0
  maxlen = maxlen or 512
  local gen_len = clamped_rand(rand, minlen, maxlen)
  local gen_char = char_rand(clamped_rand(rand, 66, 90))
  return function (len)
    len = len or gen_len()
    return table.concat(list.map(list.range(len), gen_char))
  end
end

-- Return an array of size representing value in two's
-- complement in little-endian format.
local function int_to_bytes_le(value, nbytes)
  local t = {}
  for i=1,nbytes do
    local r = value % 256
    t[i] = r
    value = (value - r) / 256
  end
  return t
end

local function keys(tab)
  local ks = {}
  for k,_ in pairs(tab) do table.insert(ks, k) end
  return ks
end

local function bless(obj, class)  --make obj an instance of class
  return setmetatable(obj, {__index = class})
end

-- Test case interface.
local Test = {
  new =
    function (class, self)
      return bless(self or {}, class)
    end,

  get_naked = nil, --write/read format string w/o endian control
  get_data = nil,      --data byte string
  get_values = nil,      --value list
  get_length = nil,      --# top level entities in the format
  get_endian = nil,      --before/after endian; nil=don't care

  get_format =
    function (self, endian, fmt)
      local fmt = fmt or self:get_naked()
      local before, after = self:get_endian()
      endian = endian or before
      before = before or endian
      after = after or before
      if before ~= endian then
        fmt = before..fmt
      end
      return fmt, after
    end
}

local function as_hex(str)
  if not str then return nil end
  return str:gsub('.', function(c)
    return string.format("%02X ", c:byte())
  end)
end

local function perform_write_test(test, endian)
  endian = endian or MACHINE_ENDIAN

  local format = test:get_format(endian)
  local want_data = test:get_data()
  local values = test:get_values()

  if PREFIX_ENDIAN then
    format = "=" .. PREFIX_ENDIAN_SEP .. format
  end
  
  local pcall = pcall
  if not PROTECT_STRUCT then
    pcall = function (f,...) return true, f(...) end
  end

  local errmsg = nil

  local success, got_data = pcall(struct.write, format, values)
  if not success then
  errmsg = got_data
    got_data = nil
  end

  success = success and eq(got_data, want_data)

  record("random write test", success, dump {
    got_data = got_data and as_hex(got_data) or nil,
    want_data = as_hex(want_data),
    format = format,
    values = values,
    error = errmsg,
    ok = success
  })
end

local function perform_read_test(test, endian)
  endian = endian or MACHINE_ENDIAN

  local format = test:get_format(endian)
  local from_data = test:get_data()
  local want_values = test:get_values()

  if PREFIX_ENDIAN then
    format = "=" .. PREFIX_ENDIAN_SEP .. format
  end
   
  local pcall = pcall
  if not PROTECT_STRUCT then
    pcall = function (f,...) return true, f(...) end
  end

  local errmsg = nil

  local success, got_values = pcall(struct.read, format, from_data)
  if not success then
    errmsg = got_values
    got_values = nil
  end

  success = success and eq(got_values, want_values)

  record("random read test", success, dump {
    got_values = got_values,
    want_values = want_values,
    from_data = as_hex(from_data),
    format = format,
    error = errmsg,
    ok = success
  })
end

local ScalarTest = Test:new{
  new = function (class, self)
    self = Test.new(class, self)
    self.is_scalar = true
    return self
  end,
  get_naked = function (self, endian) return self.format end,
  get_values = function (self) return { self.value } end,
  get_data = function (self) return self.data end,
  get_length = function (self) return self.length or 1 end,
  get_endian = function (self) return self.endian, self.endian end,
}

local EmptyTest = ScalarTest:new{
  format = "",
  value = nil,
  data = "",
  length = 0,
  endian = nil
}

-- A compound test models a sequence of unnested or ungrouped formats.
local CompoundTest = Test:new{
  new =
    function (class, self)
      self = Test.new(class, self)
      self.tests = {}
      return self
    end,

  add_test =
    function (self, t)
      table.insert(self.tests, t)
      return self
    end,

  get_data =
    function (self)
      return table.concat(list.map(self.tests,
        function (t) return t:get_data() end))
    end,

  get_format =
    function (self, endian)
      return table.concat(list.map(self.tests,
        function (t)
          local fmt
          fmt,endian = t:get_format(endian)
          return fmt
        end),
       COMPOUND_SEP), endian
    end,

  get_endian =
    function (self)
      local n = #(self.tests)
      if n == 0 then return nil,nil end
      local before, after
      for i=1,n do
        local b,a = self.tests[i]:get_endian()
        before = before or b
        after = a or after
      end
      return before, after
    end,

  get_values =
    function (self)
       local accu = {}
       list.iter(self.tests,
          function (t)
            list.merge(accu, t:get_values())
          end)
      return accu
    end,

  get_length =
    function (self)
      return #(self.tests)
    end,
}

-- A ProxyTest just resends its messages to a test named in self.body.
local ProxyTest = Test:new{
  new =
    function (class, self, body)
      local self = Test.new(class, self)
      self.body = self.body or body
      return self
    end,

  get_naked =
    function (self)
      return self.body:get_naked()
    end,

  get_data =
    function (self)
      return self.body:get_data()
    end,

  get_values =
    function (self)
      return self.body:get_values()
    end,

  get_length =
    function (self)
      return self.body:get_length()
    end,

  get_endian =
    function (self)
      return self.body:get_endian()
    end
}

-- Gives the self.body test a self.name.
local NamedTest = ProxyTest:new{
  new =
    function (class, self)
      self = ProxyTest.new(class, self)
      assert(self.name, "NamedTest unnamed")
      return self
    end,

  get_naked =
    function (self)
      return self.name ..":" .. self.body:get_naked()
    end,

  get_values =
    function (self)
      local values = self.body:get_values()
      local key, value
      for k,v in ipairs(values) do
        assert(nil == value,
          "NamedTest bound to multiple values")
        value = v
        key = k
      end
      for k,v in pairs(values) do
        assert(nil == value or key == k,
          "NamedTest bound to multiple values")
        value = v
      end
      assert(nil ~= value, "NamedTest unbound to a value")
      return { [self.name] = value }
    end
}

-- Models a test group nested in curlies.
local GroupedTest = ProxyTest:new{
  get_format =
    function (self, endian)
      local fmt,after = self.body:get_format(endian)
      return "{"..fmt.."}", after
    end,

  get_values =
    function (self)
      return { self.body:get_values() }
    end,

  get_length =
    function (self)
      return 1
    end
}

-- Models a test nested within parens.
local NestedTest = ProxyTest:new{
  get_format =
    function (self, endian)
      local fmt,after = self.body:get_format(endian)
      return "("..fmt..")", after
    end,

  get_length =
    function (self)
      return 1
    end
}

local LeftRepetitionTest = ProxyTest:new{
  new =
    function (class, self)
      self = ProxyTest.new(class, self)
      self.count = self.count or 1
      return self
    end,

  get_format =
    function (self, endian)
      local before = self.body:get_endian()
      local fmt, after = self.body:get_format(endian)
      before = before or endian
      after = after or before
      after = self.count > 0 and after or endian

      assert(after == before or self.count == 0,
        ("Non-idempotent left repetition for format '%s'"):format(fmt))
      fmt = "("..fmt..")"
      return self.count..TOKEN_SEP.."*"..TOKEN_SEP..fmt, after
    end,

  get_data =
    function (self)
      return self.body:get_data():rep(self.count)
    end,

  get_values =
    function (self)
      return list.rep(self.body:get_values(), self.count)
    end,

  get_length =
    function (self)
      return 1
    end,

  get_endian =
    function (self)
      if self.count > 0 then
        return self.body:get_endian()
      end
    end,
}

-- Test generation state.
local State = {
  new =
    function (class, seed)
      local self = {
        rand = make_rand(seed), --data source
        endian = nil,   --nil|">"|"<"
        size = 56,
        precision = 16,
        depth = 0,      --recursion depth
        uniq = 0      --unique name seq
      }
      return bless(self, class)
    end,

  is_big_endian =
    function (self)
      return self.endian == ">"  --XXX: should test vs. native also?
    end,

  raw_of_list =      --byte list, endian -> byte string
    function (self, t, reverse)
      if nil == reverse then reverse = self:is_big_endian() end

      local chars = list.map(t, char)
      if reverse then
        chars = list.reverse(chars)
      end
      return table.concat(chars)
    end,

  raw_of_int =        --int, size, endian -> byte string
    function (self, val, W, reverse)
      return self:raw_of_list(int_to_bytes_le(val, W), reverse)
    end
}

local function zero_pad_to_length(s, len)
  local pad_len = len - #s
  if pad_len <= 0 then
    return s
  end
  return s .. ("\0"):rep(pad_len)
end

local function cruft_pad_to_length(s, len)
  local cruft = "cruft"
  while #s < len do
    local ix = 1 + #s % #cruft
    s = s .. cruft:sub(ix,ix)
  end
  return s
end

-- Scalar test generators
-- TODO: fW
-- manually tested: @A +A -A
local ScalarGen
ScalarGen = {

  bitmask =
    function (state, w)
      local W = ceil(w/8)
      w = w < MAX_BITS and w or MAX_BITS
      local value = state.rand()
      local value = fmod(value,2^w)

      local write_bits = {}
      local read_bits = {}
      local n = 0
      local v = value

      while n < 8*W do
        local r = v % 2

        table.insert(read_bits, r == 1)
        if v > 0 then
           table.insert(write_bits, r == 1)
        end

        v = (v - r) / 2
        n = n+1
      end

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = ("m%d"):format(W),
        value = write_bits,
        data = state:raw_of_int(value, W)
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("m%d"):format(W),
        value = read_bits,
        data = state:raw_of_int(value, W)
      }
      return write_test, read_test
    end,

  skip_pad =
    function (state, w)
      local W = ceil(w/8)
      return ScalarTest:new{
        format = "x"..W,
        value = nil,    --?
        data = zero_pad_to_length("", W)
      },
      ScalarTest:new{
        format = "x"..W,
        value = nil,    --?
        data = cruft_pad_to_length("", W)
      }
    end,

  cstring_implicit =
    function (state, w)
      local W = ceil(w/8)
      local len = W-1
      local s = string_rand(state.rand)(len)

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = "z",
        value = s,
        data = s.."\0"
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("z%d"):format(W),
        value = s,
        data = write_test.data
      }
      return write_test, read_test
    end,

  cstring_short =
    function (state, w)
      local W = ceil(w/8)    -->0
      local len = state.rand() % (W) -- must be < W
      local s = string_rand(state.rand)(len)

      local data = s.."\0"
      local write_data = zero_pad_to_length(data, W)
      local read_data = cruft_pad_to_length(data, W)

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = ("z%d"):format(W),
        value = s,
        data = write_data:sub(1,W)
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("z%d"):format(W),
        value = s,
        data = read_data:sub(1,W)
      }
      return write_test, read_test
    end,

  cstring_long =
    function (state, w)
      local W = ceil(w/8)    -->0
      local s = string_rand(state.rand)(W-1)
      local cruft = string_rand(state.rand,1,W)()

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = ("z%d"):format(W),
        value = s .. cruft,
        data = s.."\0"
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("z%d"):format(W),
        value = s,
        data = write_test.data
      }
      return write_test, read_test
    end,

  boolean =
    function (state, w)
      local W = ceil(w/8)
      local value = fmod((state.rand() % 2) * state.rand(), 2^8)
      local flag = value ~= 0 and w > 0
      if not flag then value = 0 end

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = ("b%d"):format(W),
        value = flag,
        data = state:raw_of_int(flag and 1 or 0, W)
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("b%d"):format(W),
        value = flag,
        data = state:raw_of_int(value, W)
      }
      return write_test, read_test
    end,

  unsigned_int =
    function (state, w)
      local W = ceil(w/8)
      w = w < MAX_BITS and w or MAX_BITS
      local value = state.rand()
      local value = fmod(value,2^w)
      return ScalarTest:new{
        endian = state.endian,
        format = ("u%d"):format(W),
        value = value,
        data = state:raw_of_int(value, W)
      }
    end,

  signed_int =
    function (state, w)
      local W = ceil(w/8)
      w = w < MAX_BITS and w or MAX_BITS
      local bias = 2^(w-1)
      local value = (fmod(state.rand(), 2^w) - bias)
      if w == 0 then value = 0 end
      return ScalarTest:new{
        endian = state.endian,
        format = ("i%d"):format(W),
        value = value,
        data = state:raw_of_int(value, W)
      }
    end,

    --[[
  fixed_rational_bit =
    function (state, w, f)
  local W = ceil(w/8)
  local test = ScalarGen.signed_int(state, w)
  test.format = ("P%d.%d"):format(8*W - f, f)
  test.value = test.value / 2^f
  return test
    end,

  fixed_rational_byte =
    function (state, w, f)
  local W = ceil(w/8)
  local F = ceil(f/8)
  local test = ScalarGen.signed_int(state, w)
  test.format = ("p%d.%d"):format(W - F, F)
  test.value = test.value / 2^(8*F)
  return test
    end,

    --]]
  string_implicit =
    function (state, w)
      local W = ceil(w/8)
      local len = W
      local s = string_rand(state.rand)(len)

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = "s",
        value = s,
        data = s
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("s%d"):format(W),
        value = s,
        data = write_test.data
      }
      return write_test, read_test
    end,

  string_short =
    function (state, w)
      local W = ceil(w/8)
      local len = state.rand() % (W+1)
      local s = string_rand(state.rand)(len)
      local pad = ("\0"):rep(W - #s)

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = ("s%d"):format(W),
        value = s,
        data = s .. pad
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("s%d"):format(W),
        value = s .. pad,
        data = write_test.data
      }
      return write_test, read_test
    end,

  string_long =
    function (state, w)
      local W = ceil(w/8)
      local s = string_rand(state.rand)(W)
      local cruft = string_rand(state.rand,0,W)()

      local write_test = ScalarTest:new{
        endian = state.endian,
        format = ("s%d"):format(W),
        value = s .. cruft,
        data = s
      }
      local read_test = ScalarTest:new{
        endian = state.endian,
        format = ("s%d"):format(W),
        value = s,
        data = write_test.data
      }
      return write_test, read_test
    end,

  counted_string =
    function (state, w)
      local W = ceil(w/8)
      w = w > 4 and 4 or w
      local count = fmod(state.rand(), 2^w)
      local count_data = state:raw_of_int(count, W)
      local s = string_rand(state.rand)(count)
      return ScalarTest:new{
        endian = state.endian,
        format = ("c%d"):format(W),
        value = s,
        data = count_data..s
      }
    end,
}

local EmptyGen = {}

if USE.EMPTY then
  function EmptyGen.empty(state) return EmptyTest:new() end
  function EmptyGen.space(state) return EmptyTest:new{ format = " " } end
  function EmptyGen.tab(state) return EmptyTest:new{ format = "\t" } end
  function EmptyGen.nl(state) return EmptyTest:new{ format = "\n" } end
   --function EmptyGen.cr(state) return EmptyTest:new{ format = "\r" } end
end

if USE.ENDIAN then
  function EmptyGen.big_endian(state)
    state.endian = ">"
    local self = EmptyTest:new()
    self.endian = state.endian
    return self
  end

  function EmptyGen.little_endian(state)
    state.endian = "<"
    local self = EmptyTest:new()
    self.endian = state.endian
    return self
  end
end

-- Leaf tests don't recurse.
local LeafGen = {}
for _,f in pairs(EmptyGen) do table.insert(LeafGen, f) end
for _,f in pairs(ScalarGen) do table.insert(LeafGen, f) end

local gen_random_leaf

local function gen_random_leaf_for_write(state, w, f)
  local i = 1 + state.rand() % #LeafGen
  local gen = LeafGen[i]
  return gen(state, w or state.size, f or state.precision)
end

local function gen_random_leaf_for_read(state, w, f)
  local write,read = gen_random_leaf_for_write(state, w, f)
  read = read or write
  return read
end

-- List of all test generators (populated below)
local TestGen = {}

local function gen_random_test(state, w, f)
  if state.depth >= CONF.MAX_DEPTH then
    return gen_random_leaf(state, w, f)
  end
  state.depth = state.depth + 1
  local i = 1 + state.rand() % #TestGen
  local gen = TestGen[i]
  local t = gen(state, w, f)
  state.depth = state.depth - 1
  return t
end

-- Populate the test generators.
table.insert(TestGen,
  function (...)
    return gen_random_leaf(...)
  end)

if USE.COMPOUND then
  table.insert(TestGen,
    function (state,w,f)
      local n = CONF.COMPOUND_LENGTH
      local t = CompoundTest:new()
      for i=1,n do
        t:add_test(gen_random_test(state, w, f))
      end
      return t
    end)
end

if USE.NESTING then
  table.insert(TestGen,
    function (state,w,f)
      local t = gen_random_test(state, w, f)
      return NestedTest:new{body = t}
    end)
end

if USE.GROUPING then
  table.insert(TestGen,
    function (state,w,f)
      local t = gen_random_test(state, w, f)
      return GroupedTest:new{body = t}
    end)
end

if USE.NAMING then
  table.insert(TestGen,
    function (state,w,f)
      local t = gen_random_test(state, w, f)
      local vs = t:get_values()
      if #vs == 1 and t.is_scalar then
        state.uniq = state.uniq + 1
        t = NamedTest:new{body = t, name="u"..state.uniq}
      end
      return t
    end)
end

if USE.LEFT_REPETITION then
  table.insert(TestGen,
    function (state,w,f)
      local t = gen_random_test(state, w, f)
      local before, after = t:get_endian()
      if before == after then
        t = LeftRepetitionTest:new{
          body = t,
          count = state.rand() % 5
        }
      end
      return t
    end)
end

local function main_write()
  test.group "randomly generated write tests"
  local state = State:new(CONF.SEED or os.time())
  state.size = CONF.WIDTH
  state.precision = CONF.PRECISION

  gen_random_leaf = gen_random_leaf_for_write

  for k,gen in pairs(EmptyGen) do
    for _,e in ipairs{"<",">"} do
      state.endian = e
      local t = gen(state, state.size, state.precision)
      perform_write_test(t, "=")
    end
  end

  for k,gen in pairs(ScalarGen) do
    for _,e in ipairs{"<",">"} do
      state.endian = e
      local t = gen(state, state.size, state.precision)
      perform_write_test(t, "=")
    end
  end

  for i=1,CONF.NROF_TESTS do
    for _,e in ipairs{"<",">"} do
      state.endian = e
      local t = gen_random_test(state, state.size, state.precision)
      perform_write_test(t)
    end
  end
end

local function main_read()
  test.group "randomly generated read tests"
  local state = State:new(CONF.SEED or os.time())
  state.size = CONF.WIDTH
  state.precision = CONF.PRECISION

  gen_random_leaf = gen_random_leaf_for_read

  for k,gen in pairs(EmptyGen) do
    for _,e in ipairs{"<",">"} do
      state.endian = e
      local w,r = gen(state, state.size, state.precision)
      local t = r or w
      perform_read_test(t, "=")
    end
  end

  for k,gen in pairs(ScalarGen) do
    for _,e in ipairs{"<",">"} do
      state.endian = e
      local w,r = gen(state, state.size, state.precision)
      local t = r or w
      perform_read_test(t, "=")
    end
  end

  for i=1,CONF.NROF_TESTS do
    for _,e in ipairs{"<",">"} do
      state.endian = e
      local t = gen_random_test(state, state.size, state.precision)
      perform_read_test(t)
    end
  end
end

if TEST_KIND == "read" then
  main_read()
elseif TEST_KIND == "write" then
  main_write()
else
  local function opt_of_keyword(k)
    local o = k:lower():gsub("_", "-")
    return o
  end

  io.write"usage: <features...> <opts..> read|write\n\n"

  io.write"Features:\n"
  io.write("\tnone")
  for i,k in ipairs(keys(USE)) do
    io.write", "
    if i % 5 == 0 then io.write"\n\t" end
    io.write(opt_of_keyword(k))
  end
  io.write"\n"

  io.write"Options:\n"
  for k, v in pairs(CONF) do
    io.write("\t",opt_of_keyword(k),"=",tostring(v),"\n")
  end
end
