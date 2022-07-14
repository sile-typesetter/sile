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

-- Localization library, provided as global
fluent = require("fluent")()

-- Includes for _this_ scope
local lfs = require("lfs")

SILE.utilities = require("core.utilities")
SU = SILE.utilities -- regrettable global alias

-- On demand loader, allows modules to be loaded into a specific scope but
-- only when/if accessed.
local core_loader = function (scope)
  return setmetatable({}, {
    __index = function (self, key)
      -- local var = rawget(self, key)
      local m = require(("%s.%s"):format(scope, key))
      self[key] = m
      return m
    end
  })
end

SILE.Commands = {}
SILE.Help = {}
SILE.debugFlags = {}
SILE.nodeMakers = {}
SILE.tokenizers = {}
SILE.status = {}
SILE.scratch = {}
SILE.documentState = {}

-- User input values, currently from CLI options, potentially all the inuts
-- needed for a user to use a SILE-as-a-library verion to produce documents
-- programatically.
SILE.input = {
  evaluates = {},
  evaluateAfters = {},
  includes = {},
  requires = {},
  options = {},
  preambles = {},
  postambles = {},
}

-- Internal libraries that are idempotent and return classes that need instantiation
SILE.inputters = core_loader("inputters")
SILE.shapers = core_loader("shapers")
SILE.outputters = core_loader("outputters")
SILE.classes = core_loader("classes")

-- Internal libraries that don't make assumptions on load, only use
SILE.traceStack = require("core.tracestack")()
SILE.parserBits = require("core.parserbits")
SILE.frameParser = require("core.frameparser")
SILE.units = require("core.units")
SILE.fontManager = require("core.fontmanager")

-- Internal libraries that assume globals, may be picky about load order
SILE.measurement = require("core.measurement")
SILE.length = require("core.length")
SILE.papersize = require("core.papersize")
SILE.nodefactory = require("core.nodefactory")

-- NOTE:
-- See remainaing internal libraries loaded at the end of this file because
-- they run core SILE functions on load istead of waiting to be called (or
-- depend on others that do).

local function runEvals (evals, arg)
  for _, snippet in ipairs(evals) do
    local pId = SILE.traceStack:pushText(snippet)
    local status, func = pcall(load, snippet)
    if status then
      func()
    else
      SU.error(("Error parsing code provided in --%s snippet: %s"):format(arg, func))
    end
    SILE.traceStack:pop(pId)
  end
end

SILE.init = function ()
  -- Set by def
  if not SILE.backend then
    if pcall(require, "justenoughharfbuzz") then
      SILE.backend = "libtexpdf"
    else
      SU.error("Default backend libtexpdf not available!")
    end
  end
  if SILE.backend == "libtexpdf" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.libtexpdf()
  elseif SILE.backend == "cairo" then
    SILE.shaper = SILE.shapers.pango()
    SILE.outputter = SILE.outputters.cairo()
  elseif SILE.backend == "debug" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.debug()
  elseif SILE.backend == "text" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.text()
  elseif SILE.backend == "dummy" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.dummy()
  end
  runEvals(SILE.input.evaluates, "evaluate")
end

SILE.require = function (dependency, pathprefix, deprecation_ack)
  if pathprefix and not deprecation_ack then
    local notice = string.format([[
  Please don't use the path prefix mechanism; it was intended to provide
  alternate paths to override core components but never worked well and is
  causing portability problems. Just use Lua idiomatic module loading:
      SILE.require("%s", "%s") → SILE.require("%s.%s")]],
      dependency, pathprefix, pathprefix, dependency)
    SU.deprecated("SILE.require", "SILE.require", "0.13.0", nil, notice)
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
  init functions. It ill not function fully before the class is instantiated.
  Please just use the Lua require() function directly:
      SILE.require("%s") → require("%s")]], dependency, dependency))
  end
  if lib and class then
    class:initPackage(lib)
  end
  return lib
end

SILE.process = function (input)
  if not input then return end
  if type(input) == "function" then return input() end
  if SU.debugging("ast") then
    SU.debugAST(input, 0)
  end
  for _, content in ipairs(input) do
    if type(content) == "string" then
      SILE.typesetter:typeset(content)
    elseif type(content) == "function" then
      content()
    elseif SILE.Commands[content.command] then
      SILE.call(content.command, content.options, content)
    elseif content.id == "texlike_stuff" or (not content.command and not content.id) then
      local pId = SILE.traceStack:pushContent(content, "texlike_stuff")
      SILE.process(content)
      SILE.traceStack:pop(pId)
    else
      local pId = SILE.traceStack:pushContent(content)
      SU.error("Unknown command "..(content.command or content.id))
      SILE.traceStack:pop(pId)
    end
  end
end

local defaultinputters = { "xml", "lua", "sil" }

local function detectFormat (doc, filename)
  -- Preload default reader types so content detection has something to work with
  if #SILE.inputters == 0 then
    for _, format in ipairs(defaultinputters) do
      local _ = SILE.inputters[format]
    end
  end
  local contentDetectionOrder = {}
  for _, inputter in pairs(SILE.inputters) do
    if inputter.order then table.insert(contentDetectionOrder, inputter) end
  end
  table.sort(contentDetectionOrder, function (a, b) return a.order < b.order end)
  local initialround = filename and 1 or 2
  for round = initialround, 3 do
    for _, inputter in ipairs(contentDetectionOrder) do
      SU.debug("inputter", ("Running content type detection round %s with %s"):format(round, inputter._name))
      if inputter.appropriate(round, filename, doc) then
        return inputter._name
      end
    end
  end
  SU.error(("Unable to pick inputter to process input from '%s'"):format(filename))
end

function SILE.processString (doc, format, filename)
  local cpf
  if not filename then
    cpf = SILE.currentlyProcessingFile
    local caller = debug.getinfo(2, "Sl")
    SILE.currentlyProcessingFile = caller.short_src..":"..caller.currentline
  end
  format = format or detectFormat(doc, filename)
  io.stderr:write(("<%s> as %s\n"):format(SILE.currentlyProcessingFile, format))
  SILE.inputter = SILE.inputters[format]()
  local pId = SILE.traceStack:pushDocument(SILE.currentlyProcessingFile, doc)
  SILE.inputter:process(doc)
  SILE.traceStack:pop(pId)
  if cpf then SILE.currentlyProcessingFile = cpf end
end

function SILE.processFile (filename, format)
  local doc
  if filename == "-" then
    filename = "STDIN"
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
    doc = file:read("*a")
  end
  SILE.currentlyProcessingFile = filename
  local pId = SILE.traceStack:pushDocument(filename, doc)
  local ret = SILE.processString(doc, format, filename)
  SILE.traceStack:pop(pId)
  return ret
end

-- Sort through possible places files could be
function SILE.resolveFile (filename, pathprefix)
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
    SU.warn(("Unable to find file '%s': %s"):format(filename, err))
  end
  return resolved
end

function SILE.call (command, options, content)
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

function SILE.registerCommand (name, func, help, pack, cheat)
  if not cheat then
    SU.deprecated("SILE.registerCommand", "class:registerCommand", "0.14.0", "0.16.0",
    [[Commands are being scoped to the document classes they are loaded into rather than being globals.]])
    local class = SILE.documentState.documentClass
    if not class then SU.error("Can't register command "..name.." before a document class is loaded") end
    class:registerCommand(name, func, help, pack)
  else
    -- Shimming until we have all scope cheating removed from core
    SILE.classes.base.registerCommand(nil, name, func, help, pack)
  end
end

function SILE.setCommandDefaults (command, defaults)
  local oldCommand = SILE.Commands[command]
  SILE.Commands[command] = function (options, content)
    for k, v in pairs(defaults) do
      options[k] = options[k] or v
    end
    return oldCommand(options, content)
  end
end

function SILE.registerUnit (unit, spec)
  -- SU.deprecated("SILE.registerUnit", "SILE.units", "0.10.0", nil, [[
  -- Add new units via metamethod SILE.units["unit"] = (spec)]])
  SILE.units[unit] = spec
end

function SILE.paperSizeParser (size)
  -- SU.deprecated("SILE.paperSizeParser", "SILE.papersize", "0.10.0", nil)
  return SILE.papersize(size)
end

function SILE.finish ()
  if SILE.makeDeps then
    SILE.makeDeps:write()
  end
  SILE.documentState.documentClass:finish()
  runEvals(SILE.input.evaluateAfters, "evaluate-after")
  io.stderr:write("\n")
end

-- Internal libraries that run core SILE functions on load
SILE.settings = require("core.settings")()
SILE.colorparser = require("core.colorparser")
SILE.pagebuilder = require("core.pagebuilder")()
require("core.typesetter")
require("core.hyphenator-liang")
require("core.languages")
require("core.packagemanager")
SILE.linebreak = require("core.break")
require("core.frame")
SILE.cli = require("core.cli")
SILE.repl = require("core.repl")
SILE.font = require("core.font")

-- For warnings and shims scheduled for removal that are easier to keep track
-- of when they are not spead across so many locations...
require("core/deprecations")

return SILE
