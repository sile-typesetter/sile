local vstruct = require "vstruct"

vstruct.cache = nil

local char,ord = string.char,string.byte
local unpack = table.unpack or unpack

local test = { results = {} }

function test.x(str)
  return (str:gsub("%X", ""):gsub("%x%x", function(b) return char(tonumber(b, 16)) end))
end

function test.od(str, sep)
  local fmt = "%02X"..(sep or " ")
  return (str:gsub('.', function(c) return fmt:format(c:byte()) end))
end

function test.eq(x, y)
  if type(x) ~= type(y) then return false end
  
  if type(x) == 'table' then
    for k,v in pairs(x) do
      if not test.eq(v, y[k]) then return false end
    end
    for k,v in pairs(y) do
      if not test.eq(v, x[k]) then return false end
    end
    return true
  end

  return x == y
end

function test.group(name)
  local group = { name=name }
  table.insert(test.results, group)
  test.current_group = group
end

-- record the results of the test
-- test is the name
-- result is the boolean pass/fail
-- message is an optional string, and will be displayed to the user as 
-- "note" or "fail" depending on the value of result
function test.record(name, result, data, message)
  table.insert(test.current_group, { name=name, result=result, message=message, data=data })
end

-- automatically test writing and reading. obuf and oval are optional,
-- and default to the same values as ibuf and ival.
-- This tests the following operations:
-- read(ibuf) == oval
-- write(read(ibuf)) == obuf
-- write(ival) == obuf
-- read(write(ival)) == oval
function test.autotest(name, format, ibuf, ival, obuf, oval)
  local eq = test.eq
  local record = test.record
  
  obuf = obuf or ibuf
  oval = oval or ival

  assert(type(obuf) == type(ibuf))
  assert(type(obuf) == "string")

  if type(ival) ~= "table" then ival = {ival} end
  if type(oval) ~= "table" then oval = {oval} end

  local function tester()
    local f = vstruct.compile(format)

    local U = f:read(ibuf)
    record(name.." (U )", eq(U, oval), unpack(U))

    local UP = f:write(U)
    record(name.." (UP)", eq(UP, obuf), test.od(UP))

    local P = f:write(ival)
    record(name.." (P )", eq(P, obuf), test.od(P))

    local PU = f:read(P)
    record(name.." (PU)", eq(PU, oval), unpack(PU))
  end

  xpcall(tester, function(err)
      record(name.." !ERR", false, debug.traceback("Error executing test: "..err))
    end)
end

-- test whether an error is properly reported
-- this will call fn(...), and verify that it raises an error that matches
-- the pattern
function test.errortest(name, pattern, fn, ...)
  local res,err = pcall(fn, ...)
  if res then
    test.record(name, false, "Expected error("..pattern.."), got success")
  else
    if err:match(pattern) then
      test.record(name, true, err)
    else
      test.record(name, false, "Expected error("..pattern.."), got "..err)
    end
  end
end

function test.report()
  local allfailed = 0
  for _,group in ipairs(test.results) do
    local failed = 0
    print("\t=== "..group.name.." ===")

    for _,test in ipairs(group) do
      if not test.result then
        failed = failed + 1
        print("FAIL", test.name)
        if type(test.data) == 'string' and test.data:match("%z") then
          print("", (test.data:gsub("%z", ".")))
        else
          print("",   test.data)
        end
      end
    end
    
    print("\tTotal: ", #group)
    print("\tFailed:", failed)
    print()
    allfailed = allfailed + failed
  end
  
  return allfailed
end

-- determine host endianness
function test.bigendian()
  return require "vstruct.io" ("endianness", "host") == "big"
end

return test
