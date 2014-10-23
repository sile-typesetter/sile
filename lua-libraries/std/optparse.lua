--[=[--
 Parse and process command line options.

     local OptionParser = require "std.optparse"

     local parser = OptionParser [[
     any text VERSION
     Additional lines of text to show when the --version
     option is passed.

     Several lines or paragraphs are permitted.

     Usage: PROGNAME

     Banner text.

     Optional long description text to show when the --help
     option is passed.

     Several lines or paragraphs of long description are permitted.

     Options:

       -b                       a short option with no long option
           --long               a long option with no short option
           --another-long       a long option with internal hypen
       -v, --verbose            a combined short and long option
       -n, --dryrun, --dry-run  several spellings of the same option
       -u, --name=USER          require an argument
       -o, --output=[FILE]      accept an optional argument
           --version            display version information, then exit
           --help               display this help, then exit

    Footer text.  Several lines or paragraphs are permitted.

    Please report bugs at bug-list@yourhost.com
    ]]

    _G.arg, _G.opts = parser:parse (_G.arg)

 Most often, everything else is handled automatically.  After calling
 `parser:parse` as shown above, `_G.arg` will contain unparsed arguments,
 usually filenames or similar, and `_G.opts` will be a table of parsed
 option values. The keys to the table are the long-options with leading
 hyphens stripped, and non-word characters turned to `_`.  For example
 if `--another-long` had been found in `_G.arg` then `_G.opts` would
 have a key named `another_long`.  If there is no long option name, then
 the short option is used, e.g. `_G.opts.b` will be set.  The values
 saved in those keys are controlled by the option handler, usually just
 `true` or the option argument string as appropriate.

 On those occasions where more complex processing is required, handlers
 can be replaced or added using parser:@{on}.  A good option to always
 add, is to make `--` signal the end of processed options, so that any
 options following `--` on the command line, even if they begin with a
 hyphen and look like options otherwise, are not processed but instead
 left in the modified `_G.arg` returned by `parser:parse`:

     parser:on ('--', parser.finished)

 See the documentation for @{std.optparse:on} for more details of how to
 use this powerful method.

 When writing your own handlers for @{std.optparse:on}, you only need
 to deal with normalised arguments, because combined short arguments
 (`-xyz`), equals separators to long options (`--long=ARG`) are fully
 expanded before any handler is called.

 Note that @{std.io.die} and @{std.io.warn} will only prefix messages
 with `parser.program` if the parser options are assigned back to
 `_G.opts` as shown in the example above.

 @classmod std.optparse
]=]


local OptionParser -- forward declaration


------
-- Customized parser for your options.
--
-- This table is returned by @{OptionParser}, and most importantly has
-- the @{parse} method you call to fill the `opts` table according to
-- what command-line options were passed to your program.
-- @table parser
-- @string program the first word following `Usage:` in @{OptionParser}
--   spec string
-- @string version the last white-space delimited word on the first line
--   of text in the spec string
-- @string versiontext everything preceding `Usage:` in the spec string,
--   and which will be displayed by the @{version} @{on_handler}
-- @string helptext everything including and following `Usage:` in the
--   spec string and which will be displayed by the @{help}
--   @{on_handler}
-- @func parse see @{parse}
-- @func on see @{on}


--[[ ----------------- ]]--
--[[ Helper Functions. ]]--
--[[ ----------------- ]]--


local optional, required


--- Normalise an argument list.
-- Separate short options, remove `=` separators from
-- `--long-option=optarg` etc.
-- @local
-- @function normalise
-- @tparam table arglist list of arguments to normalise
-- @treturn table normalised argument list
local function normalise (self, arglist)
  -- First pass: Normalise to long option names, without '=' separators.
  local normal = {}
  local i = 0
  while i < #arglist do
    i = i + 1
    local opt = arglist[i]

    -- Split '--long-option=option-argument'.
    if opt:sub (1, 2) == "--" then
      local x = opt:find ("=", 3, true)
      if x then
        table.insert (normal, opt:sub (1, x - 1))
        table.insert (normal, opt:sub (x + 1))
      else
        table.insert (normal, opt)
      end

    elseif opt:sub (1, 1) == "-" and string.len (opt) > 2 then
      local rest
      repeat
        opt, rest = opt:sub (1, 2), opt:sub (3)

        table.insert (normal, opt)

        -- Split '-xyz' into '-x -yz', and reiterate for '-yz'
        if self[opt].handler ~= optional and
           self[opt].handler ~= required then
	  if string.len (rest) > 0 then
            opt = "-" .. rest
	  else
	    opt = nil
	  end

        -- Split '-xshortargument' into '-x shortargument'.
        else
          table.insert (normal, rest)
          opt = nil
        end
      until opt == nil
    else
      table.insert (normal, opt)
    end
  end

  normal[-1], normal[0]  = arglist[-1], arglist[0]
  return normal
end


--- Store `value` with `opt`.
-- @local
-- @function set
-- @string opt option name
-- @param value option argument value
local function set (self, opt, value)
  local key = self[opt].key

  if type (self.opts[key]) == "table" then
    table.insert (self.opts[key], value)
  elseif self.opts[key] ~= nil then
    self.opts[key] = { self.opts[key], value }
  else
    self.opts[key] = value
  end
end



--[[ ============= ]]--
--[[ Option Types. ]]--
--[[ ============= ]]--


--- Option at `arglist[i]` can take an argument.
-- Argument is accepted only if there is a following entry that does not
-- begin with a '-'.
--
-- This is the handler automatically assigned to options that have
-- `--opt=[ARG]` style specifications in the @{OptionParser} spec
-- argument.  You can also pass it as the `handler` argument to @{on} for
-- options you want to add manually without putting them in the
-- @{OptionParser} spec.
--
-- Like @{required}, this handler will store multiple occurrences of a
-- command-line option.
-- @static
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt=true] value either a function to process the option
--   argument, or a default value if encountered without an optarg
-- @treturn int index of next element of `arglist` to process
function optional (self, arglist, i, value)
  if i + 1 <= #arglist and arglist[i + 1]:sub (1, 1) ~= "-" then
    return self:required (arglist, i, value)
  end

  if type (value) == "function" then
    value = value (self, opt, nil)
  elseif value == nil then
    value = true
  end

  set (self, arglist[i], value)
  return i + 1
end


--- Option at `arglist[i}` requires an argument.
--
-- This is the handler automatically assigned to options that have
-- `--opt=ARG` style specifications in the @{OptionParser} spec argument.
-- You can also pass it as the `handler` argument to @{on} for options
-- you want to add manually without putting them in the @{OptionParser}
-- spec.
--
-- Normally the value stored in the `opt` table by this handler will be
-- the string given as the argument to that option on the command line.
-- However, if the option is given on the command-line multiple times,
-- `opt["name"]` will end up with all those arguments stored in the
-- array part of a table:
--
--     $ cat ./prog
--     ...
--     parser:on ({"-e", "-exec"}, required)
--     _G.arg, _G.opt = parser:parse (_G.arg)
--     print std.string.tostring (_G.opt.exec)
--     ...
--     $ ./prog -e '(foo bar)' -e '(foo baz)' -- qux
--     {1=(foo bar),2=(foo baz)}
-- @static
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt] value either a function to process the option argument,
--   or a forced value to replace the user's option argument.
-- @treturn int index of next element of `arglist` to process
function required (self, arglist, i, value)
  local opt = arglist[i]
  if i + 1 > #arglist then
    self:opterr ("option '" .. opt .. "' requires an argument")
    return i + 1
  end

  if type (value) == "function" then
    value = value (self, opt, arglist[i + 1])
  elseif value == nil then
    value = arglist[i + 1]
  end

  set (self, opt, value)
  return i + 2
end


--- Finish option processing
--
-- This is the handler automatically assigned to the option written as
-- `--` in the @{OptionParser} spec argument.  You can also pass it as
-- the `handler` argument to @{on} if you want to manually add an end
-- of options marker without writing it in the @{OptionParser} spec.
--
-- This handler tells the parser to stop processing arguments, so that
-- anything after it will be an argument even if it otherwise looks
-- like an option.
-- @static
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @treturn int index of next element of `arglist` to process
local function finished (self, arglist, i)
  for opt = i + 1, #arglist do
    table.insert (self.unrecognised, arglist[opt])
  end
  return 1 + #arglist
end


--- Option at `arglist[i]` is a boolean switch.
--
-- This is the handler automatically assigned to options that have
-- `--long-opt` or `-x` style specifications in the @{OptionParser} spec
-- argument. You can also pass it as the `handler` argument to @{on} for
-- options you want to add manually without putting them in the
-- @{OptionParser} spec.
--
-- Beware that, _unlike_ @{required}, this handler will store multiple
-- occurrences of a command-line option as a table **only** when given a
-- `value` function.  Automatically assigned handlers do not do this, so
-- the option will simply be `true` if the option was given one or more
-- times on the command-line.
-- @static
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt] value either a function to process the option argument,
--   or a value to store when this flag is encountered
-- @treturn int index of next element of `arglist` to process
local function flag (self, arglist, i, value)
  local opt = arglist[i]
  if type (value) == "function" then
    set (self, opt, value (self, opt, true))
  elseif value == nil then
    local key = self[opt].key
    self.opts[key] = true
  end

  return i + 1
end


--- Option should display help text, then exit.
--
-- This is the handler automatically assigned tooptions that have
-- `--help` in the specification, e.g. `-h, -?, --help`.
-- @static
-- @function help
local function help (self)
  print (self.helptext)
  os.exit (0)
end


--- Option should display version text, then exit.
--
-- This is the handler automatically assigned tooptions that have
-- `--version` in the specification, e.g. `-V, --version`.
-- @static
-- @function version
local function version (self)
  print (self.versiontext)
  os.exit (0)
end



--[[ =============== ]]--
--[[ Argument Types. ]]--
--[[ =============== ]]--


--- Map various option strings to equivalent Lua boolean values.
-- @table boolvals
-- @field false false
-- @field 0 false
-- @field no false
-- @field n false
-- @field true true
-- @field 1 true
-- @field yes true
-- @field y true
local boolvals = {
  ["false"] = false, ["true"]  = true,
  ["0"]     = false, ["1"]     = true,
  no        = false, yes       = true,
  n         = false, y         = true,
}


--- Return a Lua boolean equivalent of various `optarg` strings.
-- Report an option parse error if `optarg` is not recognised.
--
-- Pass this as the `value` function to @{on} when you want various
-- *truthy* or *falsey* option arguments to be coerced to a Lua `true`
-- or `false` respectively in the options table.
-- @static
-- @string opt option name
-- @string[opt="1"] optarg option argument, must be a key in @{boolvals}
-- @treturn bool `true` or `false`
local function boolean (self, opt, optarg)
  if optarg == nil then optarg = "1" end -- default to truthy
  local b = boolvals[tostring (optarg):lower ()]
  if b == nil then
    return self:opterr (optarg .. ": Not a valid argument to " ..opt[1] .. ".")
  end
  return b
end


--- Report an option parse error unless `optarg` names an
-- existing file.
--
-- Pass this as the `value` function to @{on} when you want to accept
-- only option arguments that name an existing file.
-- @fixme this only checks whether the file has read permissions
-- @static
-- @string opt option name
-- @string optarg option argument, must be an existing file
-- @treturn `optarg`
local function file (self, opt, optarg)
  local h, errmsg = io.open (optarg, "r")
  if h == nil then
    return self:opterr (optarg .. ": " .. errmsg)
  end
  h:close ()
  return optarg
end



--[[ =============== ]]--
--[[ Option Parsing. ]]--
--[[ =============== ]]--


--- Report an option parse error, then exit with status 2.
--
-- Use this in your custom option handlers for consistency with the
-- error output from built-in `optparse` error messages.
-- @static
-- @string msg error message
local function opterr (self, msg)
  local prog = self.program
  -- Ensure final period.
  if msg:match ("%.$") == nil then msg = msg .. "." end
  io.stderr:write (prog .. ": error: " .. msg .. "\n")
  io.stderr:write (prog .. ": Try '" .. prog .. " --help' for help.\n")
  os.exit (2)
end


------
-- Function signature of an option handler for @{on}.
-- @function on_handler
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt=nil] value additional `value` registered with @{on}
-- @treturn int index of next element of `arglist` to process


--- Add an option handler.
--
-- When the automatically assigned option handlers don't do everything
-- you require, or when you don't want to put an option into the
-- @{OptionParser} `spec` argument, use this function to specify custom
-- behaviour.  If you write the option into the `spec` argument anyway,
-- calling this function will replace the automatically assigned handler
-- with your own.
--
--     parser:on ("--", parser.finished)
--     parser:on ("-V", parser.version)
--     parser:on ("--config-file", parser.required, parser.file)
--     parser:on ("--enable-nls", parser.optional, parser.boolean)
-- @function on
-- @tparam[string|table] opts name of the option, or list of option names
-- @tparam on_handler handler function to call when any of `opts` is
--   encountered
-- @param value additional value passed to @{on_handler}
local function on (self, opts, handler, value)
  if type (opts) == "string" then opts = { opts } end
  handler = handler or flag -- unspecified options behave as flags

  normal = {}
  for _, optspec in ipairs (opts) do
    optspec:gsub ("(%S+)",
                  function (opt)
                    -- 'x' => '-x'
                    if string.len (opt) == 1 then
                      opt = "-" .. opt

                    -- 'option-name' => '--option-name'
                    elseif opt:match ("^[^%-]") ~= nil then
                      opt = "--" .. opt
                    end

                    if opt:match ("^%-[^%-]+") ~= nil then
                      -- '-xyz' => '-x -y -z'
                      for i = 2, string.len (opt) do
                        table.insert (normal, "-" .. opt:sub (i, i))
                      end
                    else
                      table.insert (normal, opt)
                    end
                  end)
  end

  -- strip leading '-', and convert non-alphanums to '_'
  key = normal[#normal]:match ("^%-*(.*)$"):gsub ("%W", "_")

  for _, opt in ipairs (normal) do
    self[opt] = { key = key, handler = handler, value = value }
  end
end


------
-- Parsed options table, with a key for each encountered option, each
-- with value set by that option's @{on_handler}.  Where an option
-- has one or more long-options specified, the key will be the first
-- one of those with leading hyphens stripped and non-alphanumeric
-- characters replaced with underscores.  For options that can only be
-- specified by a short option, the key will be the letter of the first
-- of the specified short options:
--
--     {"-e", "--eval-file"} => opts.eval_file
--     {"-n", "--dryrun", "--dry-run"} => opts.dryrun
--     {"-t", "-T"} => opts.t
--
-- Generally there will be one key for each previously specified
-- option (either automatically assigned by @{OptionParser} or
-- added manually with @{on}) containing the value(s) assigned by the
-- associated @{on_handler}.  For automatically assigned handlers,
-- that means `true` for straight-forward flags and
-- optional-argument options for which no argument was given; or else
-- the string value of the argument passed with an option given only
-- once; or a table of string values of the same for arguments given
-- multiple times.
--
--     ./prog -x -n -x => opts = { x = true, dryrun = true }
--     ./prog -e '(foo bar)' -e '(foo baz)'
--         => opts = {eval_file = {"(foo bar)", "(foo baz)"} }
--
-- If you write your own handlers, or otherwise specify custom
-- handling of options with @{on}, then whatever value those handlers
-- return will be assigned to the respective keys in `opts`.
-- @table opts


--- Parse `arglist`.
-- @tparam table arglist list of arguments
-- @treturn table a list of unrecognised `arglist` elements
-- @treturn opts parsing results
local function parse (self, arglist)
  self.unrecognised = {}

  arglist = normalise (self, arglist)

  local i = 1
  while i > 0 and i <= #arglist do
    local opt = arglist[i]

    if self[opt] == nil then
      table.insert (self.unrecognised, opt)
      i = i + 1

      -- Following non-'-' prefixed argument is an optarg.
      if i <= #arglist and arglist[i]:match "^[^%-]" then
        table.insert (self.unrecognised, arglist[i])
        i = i + 1
      end

    -- Run option handler functions.
    else
      assert (type (self[opt].handler) == "function")

      i = self[opt].handler (self, arglist, i, self[opt].value)
    end
  end

  -- metatable allows `io.warn` to find `parser.program` when assigned
  -- back to _G.opts.
  return self.unrecognised, setmetatable (self.opts, {__index = self})
end


--- @export
local methods = {
  boolean  = boolean,
  file     = file,
  finished = finished,
  flag     = flag,
  help     = help,
  optional = optional,
  required = required,
  version  = version,

  on     = on,
  opterr = opterr,
  parse  = parse,
}



--- Take care not to register duplicate handlers.
-- @param current current handler value
-- @param new new handler value
-- @return `new` if `current` is nil
local function set_handler (current, new)
  assert (current == nil, "only one handler per option")
  return new
end


--- Instantiate a new parser.
-- Read the documented options from `spec` and return a new parser that
-- can be passed to @{parse} for parsing those options from an argument
-- list.  Options are recognised as lines that begin with at least two
-- spaces, followed by a hyphen.
-- @static
-- @string spec option parsing specification
-- @treturn parser a parser for options described by `spec`
function OptionParser (spec)
  local parser = setmetatable ({ opts = {} }, { __index = methods })

  parser.versiontext, parser.version, parser.helptext, parser.program =
    spec:match ("^([^\n]-(%S+)\n.-)%s*([Uu]sage: (%S+).-)%s*$")

  if parser.versiontext == nil then
    error ("OptionParser spec argument must match '<version>\\n" ..
           "...Usage: <program>...'")
  end

  -- Collect helptext lines that begin with two or more spaces followed
  -- by a '-'.
  local specs = {}
  parser.helptext:gsub ("\n  %s*(%-[^\n]+)",
                        function (spec) table.insert (specs, spec) end)

  -- Register option handlers according to the help text.
  for _, spec in ipairs (specs) do
    local options, handler = {}

    -- Loop around each '-' prefixed option on this line.
    while spec:sub (1, 1) == "-" do

      -- Capture end of options processing marker.
      if spec:match "^%-%-,?%s" then
        handler = set_handler (handler, finished)

      -- Capture optional argument in the option string.
      elseif spec:match "^%-[%-%w]+=%[.+%],?%s" then
        handler = set_handler (handler, optional)

      -- Capture required argument in the option string.
      elseif spec:match "^%-[%-%w]+=%S+,?%s" then
        handler = set_handler (handler, required)

      -- Capture any specially handled arguments.
      elseif spec:match "^%-%-help,?%s" then
        handler = set_handler (handler, help)

      elseif spec:match "^%-%-version,?%s" then
        handler = set_handler (handler, version)
      end

      -- Consume argument spec, now that it was processed above.
      spec = spec:gsub ("^(%-[%-%w]+)=%S+%s", "%1 ")

      -- Consume short option.
      local _, c = spec:gsub ("^%-([-%w]),?%s+(.*)$",
                              function (opt, rest)
                                if opt == "-" then opt = "--" end
                                table.insert (options, opt)
                                spec = rest
                              end)

      -- Be careful not to consume more than one option per iteration,
      -- otherwise we might miss a handler test at the next loop.
      if c == 0 then
        -- Consume long option.
        spec:gsub ("^%-%-([%-%w]+),?%s+(.*)$",
                   function (opt, rest)
                     table.insert (options, opt)
                     spec = rest
                   end)
      end
    end

    -- Unless specified otherwise, treat each option as a flag.
    parser:on (options, handler or flag)
  end

  return parser
end


-- Support calling the returned table:
return setmetatable (methods, {
  __call = function (_, ...)
             return OptionParser (...)
           end,
})
