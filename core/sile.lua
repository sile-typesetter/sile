-- Initialize SILE internals
SILE = {}

SILE.version = require("core.version")

-- Initialize Lua environment and global utilities
SILE.lua_version = _VERSION:sub(-3)
SILE.lua_isjit = type(jit) == "table"
SILE.full_version = string.format("SILE %s (%s)", SILE.version, SILE.lua_isjit and jit.version or _VERSION)

-- Backport of lots of Lua 5.3 features to Lua 5.[12]
if not SILE.lua_isjit and SILE.lua_version < "5.3" then require("compat53") end

-- Penlight on-demand module loader, provided for SILE and document usage
pl = require("pl.import_into")()

-- For developer testing only, usually in CI
if os.getenv("SILE_COVERAGE") then require("luacov") end

-- Lua 5.3+ has a UTF-8 safe string function module but it is somewhat
-- underwhelming. This module includes more functions and supports older Lua
-- versions. Docs: https://github.com/starwing/luautf8
luautf8 = require("lua-utf8")

-- Includes for _this_ scope
local lfs = require("lfs")

-- Internal data tables
SILE.inputs = {}
SILE.Commands = {}
SILE.debugFlags = {}
SILE.nodeMakers = {}
SILE.tokenizers = {}
SILE.status = {}
SILE.scratch = {}
SILE.dolua = {}
SILE.preamble = {}
SILE.documentState = {}

-- Internal functions / classes / factories
SILE.fluent = require("fluent")()
SILE.utilities = require("core.utilities")
SU = SILE.utilities -- alias
SILE.traceStack = require("core.tracestack")()
SILE.parserBits = require("core.parserbits")
SILE.units = require("core.units")
SILE.measurement = require("core.measurement")
SILE.length = require("core.length")
SILE.papersize = require("core.papersize")
SILE.classes = require("core.classes")
SILE.nodefactory = require("core.nodefactory")
SILE.settings = require("core.settings")()
require("core.inputs-texlike")
require("core.inputs-xml")
require("core.inputs-common")
SILE.colorparser = require("core.colorparser")
SILE.pagebuilder = require("core.pagebuilder")()
require("core.typesetter")
require("core.hyphenator-liang")
require("core.languages")
SILE.font = require("core.font")
require("core.packagemanager")
SILE.fontManager = require("core.fontmanager")
SILE.frameParser = require("core.frameparser")
SILE.linebreak = require("core.break")
require("core.frame")

-- Class system deprecation shims
SILE.baseClass = {}
local _classdeprecation = function ()
  SU.warn([[
  The inheritance system for SILE classes has been refactored using a
    different object model, please update your code as use of the old
    model will cause unexpected errors and will eventually be removed.
  ]])
  SU.deprecated("SILE.baseclass", "SILE.classes.base", "0.13.0", "0.14.0")
end
setmetatable(SILE.baseClass, {
    __index = function(_, key)
      -- Likely at attempt to iterate (or dump) the table, sort of safe to ignore
      if type(key) ~= "number" then
        _classdeprecation()
      end
      return SILE.classes.base[key]
    end,
    __call = function (_, ...)
      _classdeprecation()
      return SILE.classes.base(...)
    end
  })

SILE.init = function ()
  -- Set by def
  if not SILE.backend then
    if pcall(require, "justenoughharfbuzz") then
      SILE.backend = "libtexpdf"
    else
      SU.error("libtexpdf backend not available!")
    end
  end
  if SILE.backend == "libtexpdf" then
    require("core.harfbuzz-shaper")
    require("core.libtexpdf-output")
  elseif SILE.backend == "cairo" then
    require("core.pango-shaper")
    require("core.cairo-output")
  elseif SILE.backend == "debug" then
    require("core.harfbuzz-shaper")
    require("core.debug-output")
  elseif SILE.backend == "text" then
    require("core.harfbuzz-shaper")
    require("core.text-output")
  elseif SILE.backend == "dummy" then
    require("core.harfbuzz-shaper")
    require("core.dummy-output")
  end
  for _, func in ipairs(SILE.dolua) do
    local _, err = pcall(func)
    if err then error(err) end
  end
end

SILE.require = function (dependency, pathprefix, deprecation_ack)
  if pathprefix and not deprecation_ack then
    SU.warn(string.format([[
    Please don't use the path prefix mechanism; it was intended to provide
      alternate paths to override core components but never worked well and is
      causing portability problems. Just use Lua idiomatic module loading:

      SILE.require("%s", "%s") → SILE.require("%s.%s")

    ]], dependency, pathprefix, pathprefix, dependency))
    SU.deprecated("SILE.require", "SILE.require", "0.13.0", "0.14.0")
  end
  dependency = dependency:gsub(".lua$", "")
  local status, lib
  if pathprefix then
    status, lib = pcall(require, pl.path.join(pathprefix, dependency))
  end
  if not status then lib = require(dependency) end
  local class = SILE.documentState.documentClass
  if not class and not deprecation_ack then
    SU.warn(string.format([[
    Use of SILE.require() is only supported in documents, packages, or class
      init functions. It cannot be used before the class is instantiated.
      Please just use the Lua require() function directly.

      SILE.require("%s") → require("%s")

    ]], dependency, dependency))
  end
  if lib and class then
    class:initPackage(lib)
  end
  return lib
end

SILE.parseArguments = function ()
  local cli = require("cliargs")
  local print_version = function()
    print(SILE.full_version)
    os.exit(0)
  end
  cli:set_colsz(0, 120)
  cli:set_name("sile")
  cli:set_description([[
      The SILE typesetter reads a single input file in either SIL or XML format to
      generate an output in PDF format. The output will be written to the same name
      as the input file with the extension changed to .pdf.
    ]])
  cli:splat("INPUT", "input file, SIL or XML format")
  cli:option("-b, --backend=VALUE", "choose an alternative output backend")
  cli:option("-d, --debug=VALUE", "show debug information for tagged aspects of SILE’s operation", {})
  cli:option("-e, --evaluate=VALUE", "evaluate some Lua code before processing file", {})
  cli:option("-f, --fontmanager=VALUE", "choose an alternative font manager")
  cli:option("-m, --makedeps=FILE", "generate a list of dependencies in Makefile format")
  cli:option("-o, --output=FILE", "explicitly set output file name")
  cli:option("-I, --include=FILE", "include a class or SILE file before processing input", {})
  cli:flag("-t, --traceback", "display detailed location trace on errors and warnings")
  cli:flag("-h, --help", "display this help, then exit")
  cli:flag("-v, --version", "display version information, then exit", print_version)
  -- Work around cliargs not processing - as an alias for STDIO streams:
  -- https://github.com/amireh/lua_cliargs/issues/67
  local _arg = pl.tablex.imap(luautf8.gsub, _G.arg, "^-$", "STDIO")
  local opts, parse_err = cli:parse(_arg)
  if not opts and parse_err then
    print(parse_err)
    os.exit(1)
  end
  if opts.INPUT then
    if opts.INPUT == "STDIO" then
      opts.INPUT = "/dev/stdin"
    end
    -- Turn slashes around in the event we get passed a path from a Windows shell
    SILE.inputFile = opts.INPUT:gsub("\\", "/")
    -- Strip extension
    SILE.masterFilename = string.match(SILE.inputFile, "(.+)%..-$") or SILE.inputFile
    SILE.masterDir = SILE.masterFilename:match("(.-)[^%/]+$")
  end
  if opts.backend then
    SILE.backend = opts.backend
  end
  for _, flags in ipairs(opts.debug) do
    for _, flag in ipairs(pl.stringx.split(flags, ",")) do
      SILE.debugFlags[flag] = true
    end
  end
  if opts.evaluate then
    for _, statement in ipairs(opts.evaluate) do
      local func, err = load(statement)
      if err then SU.error(err) end
      SILE.dolua[#SILE.dolua+1] = func
    end
  end
  if opts.fontmanager then
    SILE.forceFontManager = opts.fontmanager
  end
  if opts.makedeps then
    SILE.makeDeps = require("core.makedeps")
    SILE.makeDeps.filename = opts.makedeps
  end
  if opts.output then
    if opts.output == "STDIO" then
      opts.output = "/dev/stdout"
    end
    SILE.outputFilename = opts.output
  end
  for _, include in ipairs(opts.include) do
    SILE.preamble[#SILE.preamble+1] = include
  end
  -- http://lua-users.org/wiki/VarargTheSecondClassCitizen
  local identity = function (...) return table.unpack({...}, 1, select('#', ...)) end
  SILE.errorHandler = opts.traceback and debug.traceback or identity
  SILE.traceback = opts.traceback
end

function SILE.initRepl ()
  SILE._repl          = require 'repl.console'
  local has_linenoise, linenoise = pcall(require, 'linenoise')

  if has_linenoise then
    SILE._repl:loadplugin('linenoise')
    linenoise.enableutf8()
  else
    -- XXX check that we're not receiving input from a non-tty
    local has_rlwrap = os.execute('which rlwrap >/dev/null 2>/dev/null') == 0

    if has_rlwrap and not os.getenv 'LUA_REPL_RLWRAP' then
      local command = 'LUA_REPL_RLWRAP=1 rlwrap'
      local index = 0
      while arg[index - 1] do
        index = index - 1
      end
      while arg[index] do
        command = string.format('%s %q', command, arg[index])
        index = index + 1
      end
      os.execute(command)
      return
    end
  end

  SILE._repl:loadplugin('history')
  SILE._repl:loadplugin('completion')
  SILE._repl:loadplugin('autoreturn')
  SILE._repl:loadplugin('rcfile')
end

function SILE.repl()
  if not SILE._repl then SILE.initRepl() end
  SILE._repl:run()
end

function SILE.readFile(filename)
  SILE.currentlyProcessingFile = filename
  local doc
  if filename == "-" then
    io.stderr:write("<STDIN>\n")
    doc = io.stdin:read("*a")
  else
    filename = SILE.resolveFile(filename)
    if not filename then
      SU.error("Could not find file")
    end
    local mode = lfs.attributes(filename).mode
    if mode ~= "file" and mode ~= "named pipe" then
      SU.error(filename.." isn't a file or named pipe, it's a ".. mode .."!")
    end
    if SILE.makeDeps then
      SILE.makeDeps:add(filename)
    end
    local file, err = io.open(filename)
    if not file then
      print("Could not open "..filename..": "..err)
      return
    end
    io.stderr:write("<"..filename..">\n")
    doc = file:read("*a")
  end
  local sniff = doc:sub(1, 100):gsub("begin.*", "") or ""
  local inputsOrder = {}
  for input in pairs(SILE.inputs) do
    if SILE.inputs[input].order then table.insert(inputsOrder, input) end
  end
  table.sort(inputsOrder,function(a,b) return SILE.inputs[a].order < SILE.inputs[b].order end)
  for i = 1, #inputsOrder do local input = SILE.inputs[inputsOrder[i]]
    if input.appropriate(filename, sniff) then
      local pId = SILE.traceStack:pushDocument(filename, sniff, doc)
      input.process(doc)
      SILE.traceStack:pop(pId)
      return
    end
  end
  SU.error("No input processor available for "..filename.." (should never happen)", true)
end

-- Sort through possible places files could be
function SILE.resolveFile(filename, pathprefix)
  local candidates = {}
  -- Start with the raw file name as given prefixed with a path if requested
  if pathprefix then candidates[#candidates+1] = pl.path.join(pathprefix, "?") end
  -- Also check the raw file name without a path
  candidates[#candidates+1] = "?"
  -- Iterate through the directory of the master file, the SILE_PATH variable, and the current directory
  -- Check for prefixed paths first, then the plain path in that fails
  if SILE.masterFilename then
    for path in SU.gtoke(SILE.masterDir..";"..tostring(os.getenv("SILE_PATH")), ";") do
      if path.string and path.string ~= "nil" then
        if pathprefix then candidates[#candidates+1] = pl.path.join(path.string, pathprefix, "?") end
        candidates[#candidates+1] = pl.path.join(path.string, "?")
      end
    end
  end
  -- Return the first candidate that exists, also checking the .sil suffix
  local path = table.concat(candidates, ";")
  local resolved, err = package.searchpath(filename, path, "/")
  if resolved then
    if SILE.makeDeps then SILE.makeDeps:add(resolved) end
  else
    SU.warn("Unable to find file " .. filename .. err)
  end
  return resolved
end

function SILE.call(command, options, content)
  options = options or {}
  content = content or {}
  if SILE.traceback and type(content) == "table" and not content.lno then
    -- This call is from code (no content.lno) and we want to spend the time
    -- to determine everything we need about the caller
    local caller = debug.getinfo(2, "Sl")
    content.file, content.lno = caller.short_src, caller.currentline
  end
  local pId = SILE.traceStack:pushCommand(command, content, options)
  if not SILE.Commands[command] then SU.error("Unknown command " .. command) end
  local result = SILE.Commands[command](options, content)
  SILE.traceStack:pop(pId)
  return result
end

function SILE.finish ()
  if SILE.makeDeps then
    SILE.makeDeps:write()
  end
  if SILE.preamble then
    SILE.documentState.documentClass:finish()
  end
  io.stderr:write("\n")
end

return SILE
