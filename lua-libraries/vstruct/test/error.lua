-- tests for error conditions
-- checks that vstruct properly raises an error (and raises the *correct* error)
-- when things go wrong

local test = require "vstruct.test.common"
local vstruct = require "vstruct"
local E = test.errortest

test.group "error conditions"


-- utility functions gone horribly wrong
E("missing-explode-1", "bad argument #1 to 'vstruct.explode' %(number expected, got nil%)", vstruct.explode)
E("invalid-explode-1", "bad argument #1 to 'vstruct.explode' %(number expected, got boolean%)", vstruct.explode, true, nil)
E("invalid-explode-2", "bad argument #2 to 'vstruct.explode' %(number expected, got boolean%)", vstruct.explode, 0, true)

E("missing-implode-1", "bad argument #1 to 'vstruct.implode' %(table expected, got nil%)", vstruct.implode)
E("invalid-implode-1", "bad argument #1 to 'vstruct.implode' %(table expected, got boolean%)", vstruct.implode, true, nil)
E("invalid-implode-2", "bad argument #2 to 'vstruct.implode' %(number expected, got boolean%)", vstruct.implode, { 0 }, true)

-- attempt to read/seek past bounds of file
-- seeking past the end is totally allowed when writing
-- when reading, you will get a different error when you try to do IO
E("invalid-seek-uf", "attempt to read past end of buffer", vstruct.read, "@8 u4", "1234")
E("invalid-seek-ub", "attempt to seek prior to start of file", vstruct.read, "@0 -4", "1234")
E("invalid-seek-pb", "attempt to seek prior to start of file", vstruct.write, "@0 -4", "1234", {})

-- invalid argument type
E("invalid-arg-u1", "bad argument #1 to 'vstruct.read' %(string expected, got nil%)", vstruct.read)
E("invalid-arg-p1", "bad argument #1 to 'vstruct.write' %(string expected, got nil%)", vstruct.write)
E("invalid-arg-c1", "bad argument #1 to 'vstruct.compile' %(string expected, got nil%)", vstruct.compile)
E("invalid-arg-u1", "bad argument #1 to 'vstruct.read' %(string expected, got number%)", vstruct.read, 0, "1234")
E("invalid-arg-p1", "bad argument #1 to 'vstruct.write' %(string expected, got number%)", vstruct.write, 0, {})
E("invalid-arg-c1", "bad argument #1 to 'vstruct.compile' %(string expected, got number%)", vstruct.compile, 0)

E("invalid-arg-u2", "bad argument #2 to 'vstruct.read' %(file or string expected, got number%)", vstruct.read, "@0", 0)
E("invalid-arg-p2", "bad argument #2 to 'vstruct.write' %(file or string expected, got number%)", vstruct.write, "@0", 0, {})

E("invalid-arg-u3", "bad argument #3 to 'vstruct.read' %(table expected, got string%)", vstruct.read, "@0", "", "1234")
E("invalid-arg-p3", "bad argument #3 to 'vstruct.write' %(table expected, got string%)", vstruct.write, "@0", nil, "1234")
E("invalid-arg-p3", "bad argument #3 to 'vstruct.write' %(table expected, got string%)", vstruct.write, "@0", "1234")

-- format string is ill-formed
-- note that the empty format string is well-formed, does nothing, and returns/accepts the empty table
E("invalid-format-number", "expected.*, got EOF", vstruct.compile, "4")
E("invalid-format-}", "expected.* or io specifier, got }", vstruct.compile, "}")
E("invalid-format-)", "expected.* or io specifier, got %)", vstruct.compile, ")")
E("invalid-format-]", "expected.* or io specifier, got %]", vstruct.compile, "]")
E("invalid-format-{", "expected.*, got EOF", vstruct.compile, "{")
E("invalid-format-(", "expected.*, got EOF", vstruct.compile, "(")
E("invalid-format-[", "expected.*, got EOF", vstruct.compile, "[")
E("invalid-format-*", "expected.*or io specifier, got %*", vstruct.compile, "*4")
E("invalid-format-no-size", "format requires a size", vstruct.compile, "u u4")

-- format string is well-formed but nonsensical
-- note that empty groups and tables and zero-length repeats make it easier to dynamically construct format strings, and are thus allowed
E("bad-format-no-support", "no support for format 'q'", vstruct.compile, "q1")
E("bad-format-small-bitpack", "bitpack contents do not match bitpack size", vstruct.compile, "[1|u4]")
E("bad-format-large-bitpack", "bitpack contents do not match bitpack size", vstruct.compile, "[1|u16]")

-- io format size checking occurs on a format-by-format basis
E("bad-format-size-missing-f", "only supports sizes 4", vstruct.compile, 'f')
E("bad-format-size-wrong-f", "only supports sizes 4", vstruct.compile, 'f1')
E("bad-format-fraction-p", "format requires a fractional%-part size", vstruct.compile, 'p4')
E("bad-format-x-bit", "invalid value to `x` format in bitpack: 0 or 1 required, got 2", vstruct.write, "[1|x8,2]", {})
E("bad-format-x-byte", "bad argument #1 to 'char'", vstruct.write, "x1,300", {})
-- note that s and z can be used either with or without a size specifier
local sized_formats = "abcimpux@+-"
local plain_formats = "<>="
for format in sized_formats:gmatch(".") do
    E("bad-format-size-missing-"..format, "format requires a size", vstruct.compile, format)
end
for format in plain_formats:gmatch(".") do
    E("bad-format-size-present-"..format, "is an endianness control, and does not have size", vstruct.compile, format.."1")
end

-- format string splicing
vstruct.compile("coord", "x:u1 y:u1 z:u1")
E("splice-wrong-syntax", "parsing format string at character 10.*expected value.*got splice", vstruct.read, "position:&coord", "000")
E("splice-wrong-name", "attempt to splice in format 'coords', which is not registered", vstruct.read, "&coords", "000")

-- input table doesn't match format string
E("bad-data-missing", "bad input while writing: no value for key 1", vstruct.write, "u4", {})
E("bad-data-missing-name", "bad input while writing: no value for key t", vstruct.write, "t:{ x:u4 }", {})
E("bad-data-missing-nested", "bad input while writing: no value for key t.x", vstruct.write, "t.x:u4", {})
-- these require a bunch of type-specific checks. I don't have a good way to do this yet and it's an open question whether I want to do it at all.
--E("bad-data-u-string", "placeholder", vstruct.write, "u4", { "string" })
--E("bad-data-u-numeric-string", "placeholder", vstruct.write, "u4", { "0" })
--E("bad-data-s-number", "placeholder", vstruct.write, "s4", { 0 })
--E("bad-data-z-number", "placeholder", vstruct.write, "z4", { 0 })
