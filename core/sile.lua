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

-- Internal data tables
SILE.inputters = core_loader("inputters")
SILE.shapers = core_loader("shapers")
SILE.outputters = core_loader("outputters")
SILE.classes = core_loader("classes")

SILE.Commands = {}
SILE.Help = {}
SILE.debugFlags = {}
SILE.nodeMakers = {}
SILE.tokenizers = {}
SILE.status = {}
SILE.scratch = {}
SILE.dolua = {}
SILE.preamble = {}
SILE.documentState = {}

-- Internal functions / classes / factories
SILE.traceStack = require("core.tracestack")()
SILE.parserBits = require("core.parserbits")
SILE.units = require("core.units")
SILE.measurement = require("core.measurement")
SILE.length = require("core.length")
SILE.papersize = require("core.papersize")
SILE.nodefactory = require("core.nodefactory")
SILE.settings = require("core.settings")()
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
SILE.cli = require("core.cli")
SILE.repl = require("core.repl")

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
  for _, func in ipairs(SILE.dolua) do
    local _, err = pcall(func)
    if err then error(err) end
  end
  -- Preload default reader types so content detection has something to work with
  for _, inputter in ipairs({ "sil", "xml" }) do
    local _ = SILE.inputters[inputter]
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

function SILE.readFile (filename)
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
  local contentDetectionOrder = {}
  for _, inputter in pairs(SILE.inputters) do
    if inputter.order then table.insert(contentDetectionOrder, inputter) end
  end
  table.sort(contentDetectionOrder, function (a, b) return a.order < b.order end)
  for _, inputter in ipairs(contentDetectionOrder) do
    if inputter.appropriate(filename, sniff) then
      SILE.inputter = inputter()
      local pId = SILE.traceStack:pushDocument(filename, sniff, doc)
      SILE.inputter:process(doc)
      SILE.traceStack:pop(pId)
      return
    end
  end
  SU.error("No input processor available for "..filename.." (should never happen)", true)
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
    SU.warn("Unable to find file " .. filename .. err)
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

function SILE.registerCommand (name, func, help, pack)
  SILE.Commands[name] = func
  if not pack then
    local where = debug.getinfo(2).source
    pack = where:match("(%w+).lua")
  end
  --if not help and not pack:match(".sil") then SU.error("Could not define command '"..name.."' (in package "..pack..") - no help text" ) end
  SILE.Help[name] = {
    description = help,
    where = pack
  }
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

function SILE.doTexlike (doc)
  -- Setup new "fake" file in which the doc exists
  local cpf = SILE.currentlyProcessingFile
  local caller = debug.getinfo(2, "Sl")
  local temporaryFile = "<"..caller.short_src..":"..caller.currentline..">"
  SILE.currentlyProcessingFile = temporaryFile
  -- NOTE: this messes up column numbers on first line, but most places start with newline, so it isn't a problem
  doc = "\\begin{document}" .. doc .. "\\end{document}"
  local tree = SILE.inputs.TeXlike.docToTree(doc)
  -- Since elements of the tree may be used long after currentlyProcessingFile has changed (e.g. through \define)
  -- supply the file in which the node was found explicitly.
  SU.walkContent(tree, function (c) c.file = temporaryFile end)
  SILE.process(tree)
  -- Revert the processed file
  SILE.currentlyProcessingFile = cpf
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

-- For warnings and shims scheduled for removal that are easier to keep track
-- of when they are not spead across so many locations...
require("core/deprecations")

return SILE
