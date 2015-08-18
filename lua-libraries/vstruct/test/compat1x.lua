-- "basic" test module for vstruct
-- does not test floating point operations - see test/fp-*endian.lua for those
-- Copyright (c) 2011 Ben "ToxicFrog" Kelly; see COPYING

local vstruct = require "vstruct"
local test = require "vstruct.test.common"

local x = test.x

test.group "compat1x"

require "vstruct.compat1x"
vstruct.WARN = false

local fmt = "< i3"
local data = x"FE FF FF"

test.record(vstruct.unpack(fmt, data)[1] == vstruct.read(fmt, data)[1], "unpack/read")
test.record(vstruct.unpackvals(fmt, data) == vstruct.readvals(fmt, data), "unpack/read")
test.record(vstruct.pack(fmt, data, {-2}) == vstruct.write(fmt, data, {-2}), "pack/write")

local t = vstruct.compile(fmt)
test.record(t.unpack(data)[1] == t:read(data)[1], ":unpack/read")
test.record(t.pack(data, {-2}) == t:write(data, {-2}), ":pack/write")

vstruct.WARN = true
-- test that the top-level API works as well
