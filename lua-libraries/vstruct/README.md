## Contents ##

1.  Overview
2.  Warnings
    1. Numeric Precision
    2. Known Incompatibilities
3.  Setup
    1. Installation
    2. Testing
    3. Loading
    4. Backwards Compatibility
4.  API
    1. Variables
    2. Functions
5. Format string syntax
    1. Repeat markers
    2. Tables
    3. Names
    4. Bitpacks
6. Data items
    1. Controlling endianness
    2. Seeking
    3. Reading and writing
7. Adding new formats
8. Credits



## 1. Overview ##

VStruct is a library for Lua 5.1 and 5.2 and LuaJIT 2. It provides functions for manipulating binary data, in particular for reading binary files or byte buffers into Lua values and for writing Lua values back into files or buffers. Supported data types include:

  * signed and unsigned integers of arbitrary size
  * fixed and floating point numbers
  * fixed-size, length-prefixed, and null-terminated strings
  * booleans and bitmasks
  * bit-packed integers, booleans and bitmasks

In addition, the library supports seeking, alignment, and byte order controls, repetition, grouping of data into tables, and named fields.



## 2. Warnings ##

### 2.1 Numeric Precision ###

When reading and writing numeric formats, vstruct is inherently limited by lua's number format, which is by default the IEEE 754 double. What this means in practice is that formats `i`, `u`, `c`, and `p` (see section 6) may be subject to data loss, if they contain more than 52 significant bits. (The same is true of numeric constants declared in Lua itself, of course, and other libraries which store values in lua numbers). In other words - be careful when manipulating data, especially 64-bit ints, that may not fit in Lua's native types.

Formats not listed above are not subject to this limitation, as they either do not use Lua numbers at all, or do so only in ways that are guaranteed to be lossless.


### 2.2 Known Incompatibilities ###

Lua 5.0 is not supported, as vstruct makes heavy use of features introduced in 5.1.

Lua 5.3 has not been tested but is expected to break at least some features due to changes in number handling and in the math library.

LuaJIT 2.0b7 has a bug in the code generator that affects vstruct. This is fixed in 2.0b9. If you need to run vstruct in 2.0b7, you will need to disable JIT compilation for the `m.read` function:

    jit.off(require("vstruct.io.m").read, true)

The `strict` module raises an error when using vstruct outside of LuaJIT, as it checks for the presence of LuaJIT by checking if the global variable `jit` is defined (resulting in a "variable not declared" error). This can be worked around by setting `jit = false` before loading vstruct.


## 3. Setup ##

### 3.1 Installation ###

vstruct is a pure-lua module, and as such requires no seperate build step; it can be installed as-is. It supports Lua 5.1 and 5.2 and luaJIT, automatically detecting which one you are using as needed; the only difference in installation procedures between these is where you install it to.

The initializer is `vstruct/init.lua`, so it should be installed in a way that means `require "vstruct"` will load that file, and that `require "vstruct.foo"` will load `vstruct/foo.lua`. In a default install of Lua 5.1 on Linux, you can do this simply by copying the `vstruct/` directory from the vstruct distribution into any of these directories:

  * `/usr/local/share/lua/5.1/`
  * `/usr/share/lib/5.1/`
  * `/usr/local/lib/lua/5.1/`
  * `/usr/lib/lua/5.1/`

This also works for Lua 5.2, replacing the `5.1` in each path with `5.2`.

If you install it elsewhere, you can accomplish this by modifying `package.path` to include the following entries (assuming that `$LIBDIR` is the directory *containing* `vstruct/`):

  * `$LIBDIR/?.lua`
  * `$LIBDIR/?/init.lua`

Note that installing it to `./` will *not* work unless you also add an entry for `./?/init.lua` to `package.path`; by default, lua will look for `./?.lua` but not `./?/init.lua`.


### 3.2 Testing ###

vstruct comes with a number of builtin tests. To run them, simply invoke vstruct/test.lua:

    lua vstruct/test.lua

If any of the tests fail, it will report them on standard output and then raise an error; if all of the tests pass, it will exit cleanly.

If vstruct is properly installed, you can also load the tests as a library:

    lua -lvstruct.test
    require "vstruct.test"

With the same behaviour - it will load cleanly if the tests succeeded and raise an error if any of them failed.


### 3.3 Loading ###

vstruct makes itself available under the name `vstruct`. Note that, in accordance with current module conventions, it does *not* assign the module to a global; you must assign the return value of `require` yourself:

    local vstruct = require "vstruct"
    print(vstruct._VERSION)

vstruct does make one global modification when loaded: if the function `math.trunc` is not already defined, it will install its own definition.


### 3.4 Backwards Compatibility ###

vstruct 2.x is not backwards compatible with 1.x versions, and code using 1.x APIs will not work with it. Converting 1.x code to use 2.x is very easy - just replace calls to `unpack`, `unpackvals`, and `pack` with `read`, `readvals`, and `write`, and if you are using custom formats, rename their `width`, `pack*`, and `unpack*` functions to `size`, `write`, and `read`.

If you do need to run legacy code and can't, for whatever reason, update it to use the 2.x API or install an older version of vstruct, there is a compatibility module available. `require "vstruct.compat1x"` and it will be loaded, making the 1.x API available through a translation layer. By default, it will emit a warning on stderr every time a legacy function is called; to disable this, set `vstruct.WARN = false` after loading it.


## 4. API ##

vstruct, once loaded, exports a number of variables and functions, all of them available in the table returned by `require "vstruct"`.

In this section, a *format string* means the string used to describe a binary format, controlling how data is read or written. The syntax for format strings is described in section 5; the semantics in section 6. They are not be confused with the format strings used by `string.format`.


### 4.1 Error Handling ###

In vstruct, all errors are *hard errors*: they are raised with `error` and must be caught with `pcall`. The vstruct API functions will always either return a valid result or raise an error. Barring bugs in vstruct itself, the only errors one is likely to encounter involve invalid arguments to the API - wrong types, a syntactically invalid format string, or a data table that doesn't match up with the format string. The one potential surprise is seeking past the start of a file; in the standard `io` library, this is a soft error (returning `nil,error`), while in vstruct this will immediately raise.

There are also some conditions which are *not* currently treated as errors:

  * Seeking past the end of the file. This will extend the file when writing; it is an error when reading only if you subsequently attempt to read data without seeking back into the bounds of the file.
  * Lossy numeric conversion. In particular, passing a float where an int is expected will truncate the float, and trying to read a number with more bits of precision than Lua supports will give you as many bits as it can manage.
  * Passing numbers where strings are expected, or numeric strings where numbers are expected, is permitted *in some cases* due to Lua's automatic coercion between strings and numbers. This may not always be the case, so I recommend not relying on this.
  * One can often substitute any boolean true value when `true` is expected, or nil when `false` is expected. As above, this is not guaranteed to work and is not to be relied on.


### 4.2 Variables ###

These variables are used to control various settings of the library at runtime. At present there is only one public setting, but others may be added in the future.

--------

    vstruct.cache = (true|false|nil)

Enables or disables caching of compiled format strings. This can improve performance in the common case where you are re-using the same format strings many times; if, on the other hand, you are generating lots of different format strings, this will increase memory usage - perhaps significantly - for no performance benefit.

If true, enables caching. If false, existing cache entries will be used, but new ones will not be created. If nil, the cache is entirely disabled.

The default is nil.


### 4.3 Functions ###

    vstruct.cursor(string)

Wraps a string so that it can be used as a file. The returned object ('cur') supports cur:seek, cur:read(num_bytes) and cur:write(string), with the same behaviours as the file methods of the same names. In general, vstruct will attempt to automatically wrap strings if they are passed to it where a file is expected (and unwrap them before returning them); this function is primarily useful when more control over the process is required.

To access the wrapped string, use cur.str; to determine where the read/write pointer is, use cur.pos.

--------

    vstruct.read(fmt, <fd or string>, [data])

`read` takes a format string and a buffer or file to read from, and returns a table of unpacked data items. The items will appear in the table with the same order and/or names that they had in the format string.

The `data` argument is an optional table. If present, `read` will not create a new table, but will store any values read into this table in-place, and return the table. Existing entries in the table will not be cleared (but might be overwritten by named entries). Numbered entries will always be appended, not overwritten:

    t = { 0, 0, 0 }
    vstruct.read("3*u1 x:u1", buf, t)      -- t == { 0, 0, 0, 1, 2, 3; x = 4 }

--------

    vstruct.readvals(fmt, <fd or string>, [data])

Equivalent to `vstruct.read` in every way, except it calls `unpack` (or `table.unpack` in 5.2) before returning. This is a convenience function allowing you to write this:

    count = vstruct.readvals(fmt, fd)
    x,y,z = vstruct.readvals(fmt, fd)

Instead of this:

    count = vstruct.read(fmt, fd)[1]
    x,y,z = table.unpack(vstruct.read(fmt, fd))

--------

    vstruct.write(fmt, [fd], data)

`write` takes a format string and a table of data and writes the contents of the table. If the `fd` argument is present, it will write the data directly to it using standard file io methods; if `fd` is a string, it will wrap it with `vstruct.cursor` first.

`write` returns the written data in string format, if `fd` was omitted or was a string to wrap; otherwise it returns `fd` as originally passed to the function.

The structure of the `data` table is expected to be the same as the structure that would be created by a call to `read` with the same format string; in effect, you should be able to take the result of `read` and pass it to `write` unaltered (and get the same data back), and vice versa.

--------

    vstruct.explode(int)
    vstruct.implode(table)

`explode` converts a bitmask (in integer format) into a list of booleans, and implode does the converse. In such lists, list[1] is the least significant bit, and list[n] the most significant.

    vstruct.explode(0xF0)                     -- { 0, 0, 0, 0, 1, 1, 1, 1 }
    vstruct.impode { 0, 0, 0, 0, 1, 1, 1, 1 } -- 0xF0

--------

    vstruct.compile([name,] format)

`compile` takes a format string and runs it through the compiler and code generator, but does not actually pack or unpack anything. Instead, it returns a *format object* with the following fields:

  * `format.source` - the original format string
  * `format:read(fd, [data]) - equivalent to `vstruct.read(format.source, fd, data)`
  * `format:write(fd, data)` - equivalent to `vstruct.write(format.source, fd, data)`

In effect, the following code:

    obj = vstruct.compile(fmt)
    d = obj:read(fd)
    obj:write(fd, d)

Is equivalent to:

    d = vstruct.read(fmt, fd)
    vstruct.write(fmt, fd, d)

If `name` is specified, it additionally registers the format string it just compiled under `name`, allowing it to referenced in future format strings as `&name`; see section 5.5 "Splices" for details.

--------

    vstruct.records(format, <fd or string>, [unpack])

Given a format string, and a data source to read records of that format from, `records` returns an iterator over all of those records. It terminates when there is no more data to be read (i.e. fd:read(0) returns nil rather than ""). If there is an incomplete record at the end of the data source, it will error.

It is roughly analogous to:

    for _,record in ipairs(vstruct.read(NUM_RECORDS .. "*" .. format, fd)) do
      ...
    end

Except that it doesn't require you to know the number of records in advance, and doesn't read all of the records into memory at once.

If `unpack` is true, it will additionally call `unpack()` (`table.unpack()` in 5.2) on each record and return the results of the unpacking, so that you can (for example) easily read a list of coordinates with:

    for x,y,z in vstruct.records("f8 f8 f8", fd, true) do ...

If `unpack` is false or unspecified, it behaves the same as `vstruct.read`.


## 5. Format string syntax ##

A format string consists of a series of *format items*. A format item is:

  * a data item, seek control, or endianness control (see section 6)
  * a repeat marker 'N*' followed by a format item, or a sequence of format items enclosed in '(' and ')'
  * a table '{ ... }' enclosing any number of format items
  * a name 'foo:' followed by a data item or table
  * a bitpack '[S| ... ]' enclosing any number of *bitpack-capable* format items
  * a splice '&name'
  * a comment, starting with '--' and ending at the next newline

These are explained in detail in the rest of this section, apart from data items, seek controls, and endianness controls, which are a sufficiently lengthy topic that they have a section of their own (section 6).

In general, whitespace may be omitted where the result is unambiguous, and when present, the amount and type of whitespace is irrelevant. Comments are considered to be whitespace.


### 5.1 Repeat markers ###

A repeat marker consists of a decimal number *N*, followed by a *, followed by a format item (or a group of such items enclosed in parentheses). The following item is repeated N times. For example, these three format strings:

    "u4 u4 u4 u4"
    "{ u2 b1 } { u2 b1 }"
    "u2 u2 u4 u2 u2 u4 u2 u2 u4 m2"

Can be expressed more concisely as these:

    "4*u4"
    "2*{ u2 b1 }"
    "3*(u2 u2 u4) m2"


### 5.2 Tables ###

A table consists of any number of format items enclosed in curlybraces. When reading, the items contained in the table will be packed into their own subtable in the output; when writing, items contained in the table will be searched for in a subtable. For example, this format string:

    "{ u4 u4 u4 } { { b1 b1 } s8 }"

Describes the following table (or something similarly structured):

    {
      { 1, 2, 3 };
      {
        { true, false };
        "test";
      };
    };

Note the outer table; `read` returns all read values in a table by default, and `write` expects the values it writes to be contained in one.

Within a format string, tables may be nested arbitrarily.


### 5.3 Names ###

A name consists of a valid Lua identifier, or sequence of such identifiers separated with '.', followed by a ':'. It must be followed by a data item or a table. The following item will be stored in/retrieved from a field with the given name, rather than being read/written sequentially as is the default.

For example, this table:

    {
      coords = { x=1, y=2, z=3 };
    }

Could be expressed by either of these format strings:

    "coords:{ x:u4 y:u4 z:u4 }"
    "coords:{} coords.x:u4 coords.y:u4 coords.z:u4"


### 5.4 Bitpacks ###

A bitpack consists of multiple data items packed into a single item (typically an int) with no regard for byte-alignment - for example, something that stores three five-bit ints and a one-bit boolean in a single 16-bit int.

These are expressed in vstruct as `'[' size '|' items ']'`, where `size` is the size of the entire bitpack in *bytes* and `items` is a sequence of data items with their sizes in *bits*. The above example would be expressed thus:

    "[2| u5 u5 u5 b1 ]"

Bitpacks read their contents MSB to LSB; in the above example, the boolean is the least significant bit of the enclosing 2-byte int.

The declared total size of the bitpack, and the sizes of the individual items inside it, *must* match; if they do not, the format string will not compile. If there are bits inside the pack you are not interested in, use the `x` (skip/pad) format to ignore them.

Despite being conceptually packed into ints, bitpacks are not subject to numeric precision limitations (although the data items inside them might be, if they are large enough); a 100-byte bitpack will be handled just as accurately as a 1-byte one.

Reading and writing of bitpacks respects *byte* endianness; in little-endian mode, the least significant *byte* is expected to come first. Bits are always MSB first, LSB last. That is to say, given the following bytes on disk:

    01 02

It will be read in the following manners in big- and little-endian modes

    "> [2| 4*u4 ]"      -- { 0, 1, 0, 2 }
    "< [2| 4*u4 ]"      -- { 0, 2, 0, 1 }

At present, only formats `b`, `u`, `i`, `x` and `m` are supported inside bitpacks.


### 5.5 Splices ###

Splices let you concisely refer to other format strings, provided that those others have been registered ahead of time using the optional `name` argument to `vstruct.compile`. A splice `&foo` is equivalent to including the contents of the format string registered as `foo` at the point where the splice appears; thus, the following two calls are equivalent:

    vstruct.compile("coord", "x:u4 y:u4 z:u4")
    vstruct.read("name:z128 position:{ x:u4 y:u4 z:u4 }")
    vstruct.read("name:z128 position:{ &coord }")


## 6. Data Items ##

This section describes the individual field types that make up the bulk of a format string, as well as the seek and endianness controls available. All data items consist of a single letter or punctuation character, optionally followed by one or more comma-separated numbers indicating the size of the corresponding field (or other parameters specific to the type).

By convention, in this section, upper-case single letters represent decimal numbers to be filled in when the format string is written. In particular, *S* is consistently used to mean the size, in bytes, of a field, and *A* an address or offset in the packed data.


### 6.1 Controlling Endianness ###

At any given moment, when reading or writing, vstruct is in either *big-endian* or *little-endian* mode. These affect the order in which it expects bytes to appear for formats `f`, `u`, `i`, and `m`, for the initial string length in `c`, and for the bytes making up a bitpack. In big-endian mode it expects the most significant byte to occur first; in little-endian mode, the least sigificant byte. (There is at present no support for more esoteric modes like middle-endian.)

Each operation starts in *host-endian* mode - the endianness is set to match that of the host system. It can subsequently be controlled with the following characters in the format string:

--------

    <

Sets the endianness to little-endian (eg, Intel processors)

--------

    >

Sets the endianness to big-endian (eg, PPC processors)

--------

    =

Resets the endianness to match that of the host system

The means by which host-endianness is detected is, at present, implementation specific. Under luaJIT, it uses the ffi library (specifically, the ffi.abi function). Under standard lua, it uses string.dump on an empty function and checks the bytecode header. If neither of these is available, it emits a warning and assumes little-endian.

If you have a lua implementation for which this approach fails (either crashing, or getting the wrong answer), please file a bug report.


### 6.2 Seeking ###

vstruct supports seeking in the underlying buffer or file; these operations will translate into a call to the :seek() method. Note that attempting to use these when reading from or writing to a non-seekable stream (such as stdout) will generate a runtime error. In that case, use `x` (the skip/pad format) instead.

--------

    @A

Seek to absolute address `A`.

--------

    +A

Seek forwards `A` bytes.

--------

    -A

Seek backwards `A` bytes.

--------

    aS

Align to word size `S` (seek to the next address which is a multiple of `S`). If the current address is `S`-aligned already, this is a no-op.


### 6.3 Reading and Writing ###

The following items perform actual reading and writing of data.

--------

    bS    -- Boolean.

Read: as `uS`, but returns true if the result is non-zero and false otherwise.
Write: as `uS` with input 1 if true and 0 otherwise.

Note that when writing, the output for true is integer 1, not all bits 1.

--------

    cS    -- Length-prefixed ("counted") string.

Read: `uS` to determine the length of the string `S'`, followed by `sS'`.
Write: the length of the string as `uS`, followed by the string itself.

The counted string is a common idiom where a string is immediately prefixed with its length, as in:

    size_t len;
    char[] str;

The counted string format can be used to easily read and write these. The size provided is the size of the `len` field, which is treated as an unsigned int. Only the string itself is returned (when reading) or required (when writing). Internally, this is implemented as `u` followed by `s`; consequently, it is affected by endianness.

--------

    fS    -- IEEE 754 floating point.

Read: a float, double, or quad.
Write: a float, double, or quad.

Valid sizes are 4 (float) 8 (double) and 16 (quad). Note that quads have more precision than the default lua number format (double), and thus may not read exactly unless you're using a custom lua build.

Affected by endianness.

--------

    iS    -- Signed integer.

Read: a signed integer with `S` bytes of precision.
Write: a signed integer with `S` bytes of precision.

When writing, floating point values will be truncated, not rounded.

Affected by endianness.

--------

    mS    -- Bitmask.

Read: as `uS`, but explodes the result into a list of booleans, one per bit.
Write: implodes the input value, then writes it as `uS`.

In effect, a `u` that automatically calls `vstruct.implode/explode`; unlike `u`, however, it can operate on fields of arbitrarily large size without loss of precision, regardless of what numeric type lua is using.

Affected by endianness.

--------

    pS,F  -- Signed fixed point.

`S` is, as usual, the size of the entire field in *bytes*. `F` is the number of *bits* of fractional precision. Thus, a 24.8 fixed point number (24 bits integer, 8 bits fraction, 32 bits total) would have format `"p4,8"`.

Read: a `S`-byte fixed point number with `F` bits of fractional precision.
Write: a `S`-byte fixed point number long with `F` bits of fractional precision.

When writing, values which cannot be precisely expressed in the given precision will be truncated, not rounded.

Affected by endianness.

--------

    sS    -- Fixed-length string.

`S` is optional.

Read: reads exactly `S` bytes and returns them as a string. If `S` is omitted, reads until EOF.
Write: writes exactly `S` bytes; if the given string is too long, it will be truncated, and if too short, it will be nul-padded. If `S` is omitted, it is considered equal to the length of the string (i.e. it will write the contents of the string without truncation or padding).

--------

    uS    -- Unsigned integer.

Read: an unsigned integer with `S` bytes of precision.
Write: an unsigned integer with `S` bytes of precision.

On write, non-integer values will be truncated. Negative values will be written in absolute form.

Affected by endianness.

--------

    xS,V  -- Skip/pad.

`,V` is optional, and defaults to 0 if omitted.

Read: read and discard the next `S` bytes.
Write: write `S` bytes with value `V`. Within a bitpack, the only valid values for `V` are 0 or 1.

This format does not consume input data (when writing) or produce output values (when reading). However, unlike the seek controls (`@+-a`), it can be used even when the input or output does not support seeking (e.g. when reading from a pipe or socket).

--------

    zS,C  -- Nul terminated/nul padded string.

`S` and `C` are both optional. The `,` is mandatory if `C` is present.

`S`, if present, is the length of the string (in *bytes*, not characters).

`C`, if present, is the size in *bytes* of individual characters in the string. The default is 1.  It is important when operating on wide-character strings to specify `C` correctly, so that sequences like "00 66 00 67" are not incorrectly interpreted as ending the string.

Read: reads exactly `S` bytes, and returns everything up to the first nul *character*. If `S` is omitted, reads until it encounters a nul. The nul is read, but not included in the returned string.

Write: writes exactly `S` bytes. If the input is shorter than `S`, nul pads the output; if longer, truncates it to `S - C` bytes and nul terminates it. If `S` is omitted entirely, the string is written out in full and nul terminated.

When nul terminating, or looking for a nul character to detect the end of the string, `C` zero bytes, `C`-aligned relative to the start of the string, are used. In particular, this means that the following 6-byte string:

    6600 0066 0000

Will be one byte long (plus one byte termination) under `"z6,1"`, but four bytes long (plus two bytes termination) under `"z6,2"` - the second and third bytes make up 0000, nul, but since they are not character-aligned, they are instead read as parts of the two characters `6600` and `0066`.



## 7. Adding new IO operations ##

If you want to add support for a new data type, or modify or replace an existing one, this is how you do it. To see how the current ones are implemented, look at the files in vstruct/io/; any new formats added will use the same API.


### 7.1 How IO operations are loaded ###

When vstruct first sees an operation - say `"p2,8"` - it first breaks it down into two parts - the `op` ("p") and the `args` (2,8). It then attempts to load a handler for this operation using:

    require("vstruct.io."..op)

Typically, this will load the file `vstruct/io/<op>.lua` - in our above example, `vstruct/io/p.lua`. The easiest way to install new operations, then, is just to put them in the `vstruct/io/` directory.

`package.preload` can also be used; for example, `package.preload["vstruct.io.p"]` can be used to override the version of `p` that comes with vstruct.


### 7.2 How they are used ###

When loaded, the handler for an IO operation returns a table containing some or all of the following functions. Note that '...' here means the arguments as given in the format string - '2,8' in the above example.

--------

    hasdata()

Returns true if, when writing, this format consumes a value from the table of input. Formats that actually read and write data will typically return true; formats that merely adjust the output stream or internal vstruct state (eg, seek and endianness controls) or those that generate the data on the fly (skip/pad) will return false.

--------

    size(...)

Returns the exact amount of data, in bytes, that this format will consume from the input if `read` is called, or the exact amount it will append to the output if `write` is called. If this cannot yet be determined (for example, 'z' with no arguments or any usage of 'c'), if it changes the position of the read/write pointer (for example, seek commands), or if does anything else that might interfere with vstruct's own use of the file handle, such as seeking, it should return nil.

Formats that neither interfere with the file handle nor read or write data should return 0; this is the case, for example, for the endianness controls.

The default implementation asserts that a size was specified and returns nil.

--------

    write(fd, data, ...)

If `size()` returned a value earlier, this *must* ignore `fd`, pack `data` into a string, and return the string - the caller will handle writing the string to the fd in an efficient manner. If it did not, this function may freely choose either to return a packed string, or to manipulate `fd` directly (in which case it should return nil).

Some operators, of course, must manipulate `fd` directly by their very nature (such as seek controls); when possible, however, one should endeavour to pre-calculate sizes and return packed strings.

--------

    read(fd, buffer, ...)

If `size()` returned a value earlier, `buffer` will be a string of exactly that many bytes; `read` *must* ignore `fd` and return the value represented by the buffer. If `size()` returned nil, `read` must manipulate `fd` directly to get the data it needs.

--------

    writebits(bit, data, ...)

This is called when the operation is performed inside a bitpack. Data should be written bit-by-bit, MSB first; to write a bit `B` (which must be 0 or 1), call `bit(B)`. `bit()` does not presently accept multiple arguments to write multiple bits at once.

--------

    readbits(bit, ...)

The converse of `writebits`. Each call to `bit()` returns the next bit, MSB first.



## 8. Credits ##

While most of the library code was written by me (Ben Kelly), the existence of this library owes itself to many others.

  * The original inspiration came from Roberto Ierusalimschy's "struct" library and Luiz Henrique de Figueiredo's "lpack" library, as well as the "struct" available in Python.
  * The floating point code was contributed by Peter Cawley ("corsix") on lua-l, as was support for Lua 5.2.
  * sanooj, from #lua on freenode, has done so much testing and bug reporting that at this point he's practically a co-author; the 'struct-test-gen' module in test/ is his work, and has aided in detected many bugs.
  * The overall library design and interface are the result of much discussion with rici, sanooj, Keffo, snogglethorpe, Spark, kozure, Vornicus, McMartin, and probably several others I've forgotten about on IRC (#lua on freenode and #code on nightstar).
  * Finally, without Looking Glass Studios to make System Shock, and Team TSSHP (in particular Jim "hairyjim" Cameron) to reverse engineer it, I wouldn't have had a reason to write this library in the first place.
