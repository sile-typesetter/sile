-- Initialize SILE internals
SILE = {}

SILE.version = require("core.version")
SILE.features = require("core.features")

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

-- Developer tooling profiler
local ProFi

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
SILE.rawHandlers = {}

-- User input values, currently from CLI options, potentially all the inuts
-- needed for a user to use a SILE-as-a-library verion to produce documents
-- programatically.
SILE.input = {
  filename = "",
  evaluates = {},
  evaluateAfters = {},
  includes = {},
  uses = {},
  options = {},
  preambles = {},
  postambles = {},
}

-- Internal libraries that are idempotent and return classes that need instantiation
SILE.inputters = core_loader("inputters")
SILE.shapers = core_loader("shapers")
SILE.outputters = core_loader("outputters")
SILE.classes = core_loader("classes")
SILE.packages = core_loader("packages")
SILE.typesetters = core_loader("typesetters")
SILE.pagebuilders = core_loader("pagebuilders")

-- Internal libraries that don't make assumptions on load, only use
SILE.traceStack = require("core.tracestack")()
SILE.parserBits = require("core.parserbits")
SILE.frameParser = require("core.frameparser")
SILE.color = require("core.color")
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
  if not SILE.backend then
    SILE.backend = "libtexpdf"
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
  SILE.pagebuilder = SILE.pagebuilders.base()
  io.stdout:setvbuf("no")
  if SU.debugging("profile") then
    ProFi = require("ProFi")
    ProFi:start()
  end
  if SILE.makeDeps then
    SILE.makeDeps:add(executable)
  end
  runEvals(SILE.input.evaluates, "evaluate")
end

SILE.use = function (module, options)
  local pack
  if type(module) == "string" then
    pack = require(module)
  elseif type(module) == "table" then
    pack = module
  end
  local name = pack._name
  local class = SILE.documentState.documentClass
  if not pack.type then
    SU.error("Modules must declare their type")
  elseif pack.type == "class" then
    SILE.classes[name] = pack
    if class then
      SU.error("Cannot load a class after one is already instantiated")
    end
    SILE.scratch.class_from_uses = pack
  elseif pack.type == "inputter" then
    SILE.inputters[name] = pack
    SILE.inputter = pack(options)
  elseif pack.type == "outputter" then
    SILE.outputters[name] = pack
    SILE.outputter = pack(options)
  elseif pack.type == "shaper" then
    SILE.shapers[name] = pack
    SILE.shaper = pack(options)
  elseif pack.type == "typesetter" then
    SILE.typesetters[name] = pack
    SILE.typesetter = pack(options)
  elseif pack.type == "pagebuilder" then
    SILE.pagebuilders[name] = pack
    SILE.pagebuilder = pack(options)
  elseif pack.type == "package" then
    SILE.packages[name] = pack
    if class then
      pack(options)
    else
      table.insert(SILE.input.preambles, { pack = pack, options = options })
    end
  end
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
  if not status then
    local prefixederror = lib
    status, lib = pcall(require, dependency)
    if not status then
      SU.error(("Unable to find module '%s'%s")
        :format(dependency, SILE.traceback and ((pathprefix and "\n  " .. prefixederror or "") .. "\n  " .. lib) or ""))
    end
  end
  local class = SILE.documentState.documentClass
  if not class and not deprecation_ack then
    SU.warn(string.format([[
  Use of SILE.require() is only supported in documents, packages, or class
  init functions. It will not function fully before the class is instantiated.
  Please just use the Lua require() function directly:
      SILE.require("%s") → require("%s")]], dependency, dependency))
  end
  if type(lib) == "table" and class then
    if lib.type == "package" then
      lib(class)
    else
      class:initPackage(lib)
    end
  end
  return lib
end

SILE.process = function (ast)
  if not ast then return end
  if SU.debugging("ast") then
    SU.debugAST(ast, 0)
  end
  if type(ast) == "function" then return ast() end
  for _, content in ipairs(ast) do
    if type(content) == "string" then
      SILE.typesetter:typeset(content)
    elseif type(content) == "function" then
      content()
    elseif SILE.Commands[content.command] then
      SILE.call(content.command, content.options, content)
    elseif content.id == "texlike_stuff"
      or (not content.command and not content.id) then
      local pId = SILE.traceStack:pushContent(content, "texlike_stuff")
      SILE.process(content)
      SILE.traceStack:pop(pId)
    elseif type(content) ~= "nil" then
      local pId = SILE.traceStack:pushContent(content)
      SU.error("Unknown command "..(tostring(content.command or content.id)))
      SILE.traceStack:pop(pId)
    end
  end
end

local preloadedinputters = { "xml", "lua", "sil" }

local function detectFormat (doc, filename)
  -- Preload default reader types so content detection has something to work with
  if #SILE.inputters == 0 then
    for _, format in ipairs(preloadedinputters) do
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
      SU.debug("inputter", "Running content type detection round", round, "with", inputter._name)
      if inputter.appropriate(round, filename, doc) then
        return inputter._name
      end
    end
  end
  SU.error(("Unable to pick inputter to process input from '%s'"):format(filename))
end

function SILE.processString (doc, format, filename, options)
  local cpf
  if not filename then
    cpf = SILE.currentlyProcessingFile
    local caller = debug.getinfo(2, "Sl")
    SILE.currentlyProcessingFile = caller.short_src..":"..caller.currentline
  end
  -- In the event we're processing the master file *and* the user gave us
  -- a specific inputter to use, use it at the exclusion of all content type
  -- detection
  local inputter
  if filename and filename:gsub("STDIN", "-") == SILE.input.filename and SILE.inputter then
    inputter = SILE.inputter
  else
    format = format or detectFormat(doc, filename)
    if not SILE.quiet then
      io.stderr:write(("<%s> as %s\n"):format(SILE.currentlyProcessingFile, format))
    end
    inputter = SILE.inputters[format](options)
    -- If we did content detection *and* this is the master file, save the
    -- inputter for posterity and postambles
    if filename and filename:gsub("STDIN", "-") == SILE.input.filename then
      SILE.inputter = inputter
    end
  end
  local pId = SILE.traceStack:pushDocument(SILE.currentlyProcessingFile, doc)
  inputter:process(doc)
  SILE.traceStack:pop(pId)
  if cpf then SILE.currentlyProcessingFile = cpf end
end

function SILE.processFile (filename, format, options)
  local doc
  if filename == "-" then
    filename = "STDIN"
    doc = io.stdin:read("*a")
  else
    -- Turn slashes around in the event we get passed a path from a Windows shell
    filename = filename:gsub("\\", "/")
    if not SILE.masterFilename then
      -- Strip extension
      SILE.masterFilename = string.match(filename, "(.+)%..-$") or filename
    end
    if SILE.masterFilename and not SILE.masterDir then
      SILE.masterDir = SILE.masterFilename:match("(.-)[^%/]+$")
    end
    if SILE.masterDir and SILE.masterDir:len() >= 1 then
      extendSilePath(SILE.masterDir)
    end
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
  local cpf = SILE.currentlyProcessingFile
  SILE.currentlyProcessingFile = filename
  local pId = SILE.traceStack:pushDocument(filename, doc)
  local ret = SILE.processString(doc, format, filename, options)
  SILE.traceStack:pop(pId)
  SILE.currentlyProcessingFile = cpf
  return ret
end

-- TODO: this probably needs deprecating, moved here just to get out of the way so
-- typesetters classing works as expected
SILE.typesetNaturally = function (frame, func)
  local saveTypesetter = SILE.typesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:leave(SILE.typesetter) end
  SILE.typesetter = SILE.typesetters.base(frame)
  SILE.settings:temporarily(func)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:chuck()
  SILE.typesetter.frame:leave(SILE.typesetter)
  SILE.typesetter = saveTypesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:enter(SILE.typesetter) end
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
  if SILE.masterDir then
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
  local class = SILE.documentState.documentClass
  if not cheat then
    SU.deprecated("SILE.registerCommand", "class:registerCommand", "0.14.0", "0.16.0",
    [[Commands are being scoped to the document classes they are loaded into rather than being globals.]])
  end
  -- Shimming until we have all scope cheating removed from core
  if not cheat or not class or class.type ~= "class" then
    return SILE.classes.base.registerCommand(nil, name, func, help, pack)
  end
  return class:registerCommand(name, func, help, pack)
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
  -- If a unit exists already, clear it first so we get fresh meta table entries, see #1607
  if SILE.units[unit] then
    SILE.units[unit] = nil
  end
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
  SILE.font.finish()
  runEvals(SILE.input.evaluateAfters, "evaluate-after")
  if not SILE.quiet then
    io.stderr:write("\n")
  end
  if SU.debugging("profile") then
    ProFi:stop()
    ProFi:writeReport(SILE.masterFilename..'.profile.txt')
  end
  if SU.debugging("versions") then
    SILE.shaper:debugVersions()
  end
end

-- Internal libraries that run core SILE functions on load
SILE.settings = require("core.settings")()
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
