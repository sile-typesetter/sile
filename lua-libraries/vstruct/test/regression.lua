-- regression tests for vstruct
-- tests for fixed bugs go here to make sure they don't recur
-- tests are named after the bug they trigger, not the intended behaviour

local test = require "vstruct.test.common"

local x = test.x
local T = test.autotest

test.group "regression tests"

-- B#21
-- this was found as an error in writing fixed point values, but is actually an underlying issue
-- with how u and i handle non-integer inputs
-- in short: don't assume string.char() truncates, because it doesn't.
T("i rounds instead of truncating",
  "> i2",
  x"FF FF", -1.5,
  x"FF FF", -1)
T("u rounds instead of truncating",
  "> u2",
  x"00 01", 1.5,
  x"00 01", 1)
T("p passes invalid value to string.char and crashes",
  "> p2,2",
  x"FD 00", -192.098910,
  x"FD 00", -192.00)
