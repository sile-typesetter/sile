SILE = {}
SILE.version = "0.9.5.1"
SILE.utilities = require("core/utilities")
SU = SILE.utilities
SILE.inputs = {}
SILE.Commands = {}
SILE.debugFlags = {}
SILE.nodeMakers = {}
SILE.tokenizers = {}

loadstring = loadstring or load -- 5.3 compatibility
if not unpack then unpack = table.unpack end -- 5.3 compatibility
std = require("std")
lfs = require("lfs")
if (os.getenv("SILE_COVERAGE")) then require("luacov") end

SILE.documentState = std.object {}
SILE.scratch = {}
SILE.length = require("core/length")
require("core/parserbits")
require("core/measurements")
require("core/baseclass")
SILE.nodefactory = require("core/nodefactory")
require("core/settings")
require("core/inputs-texlike")
require("core/inputs-xml")
require("core/inputs-common")
require("core/papersizes")
require("core/colorparser")
require("core/pagebuilder")
require("core/typesetter")
require("core/hyphenator-liang")
require("core/languages")
require("core/font")
require("core/packagemanager")

SILE.frameParser = require("core/frameparser")
SILE.linebreak = require("core/break")

require("core/frame")

SILE.init = function ()
  if not SILE.backend then
    if pcall(function () require("justenoughharfbuzz") end) then
      SILE.backend = "libtexpdf"
    else
      SU.error("libtexpdf backend not available!")
    end
  end
  if SILE.backend == "libtexpdf" then
    require("core/harfbuzz-shaper")
    require("core/libtexpdf-output")
  elseif SILE.backend == "cairo" then
    require("core/cairo-output")
  elseif SILE.backend == "debug" then
    require("core/harfbuzz-shaper")
    require("core/debug-output")
  elseif SILE.backend == "text" then
    require("core/harfbuzz-shaper")
    require("core/text-output")
  end
  if SILE.dolua then
    for _, func in pairs(SILE.dolua) do
      _, err = pcall(func)
      if err then error(err) end
    end
  end
end

SILE.require = function (dependency, pathprefix)
  local file = SILE.resolveFile(dependency..".lua", pathprefix)
  if file then return require(file:gsub(".lua$","")) end
  if pathprefix then
    local status, lib = pcall(require, std.io.catfile(pathprefix, dependency))
    return status and lib or require(dependency)
  end
  return require(dependency)
end

SILE.parseArguments = function()
local parser = std.optparse ("SILE "..SILE.version..[[

Usage: sile [options] file.sil|file.xml

The SILE typesetter reads a single input file in either SIL or XML format to
generate an output in PDF format. The output will be writted to the same name
as the input file with the extention changed to .pdf.

Options:

  -b, --backend=VALUE      choose an alternative output backend
  -d, --debug=VALUE        debug SILE's operation
  -e, --evaluate=VALUE     evaluate some Lua code before processing file
  -o, --output=[FILE]      explicitly set output file name
  -I, --include=[FILE]     include a class or SILE file before processing input
  -t, --traceback          display traceback and more detailed location information on errors and warnings
  -h, --help               display this help, then exit
  -v, --version            display version information, then exit
]])

  parser:on ('--', parser.finished)
  _G.unparsed, _G.opts = parser:parse(_G.arg)
  -- Turn slashes around in the event we get passed a path from a Windows shell
  if _G.unparsed[1] then
    SILE.masterFilename = _G.unparsed[1]:gsub("\\", "/")
    -- Strip extension
    SILE.masterFilename = string.match(SILE.masterFilename,"(.+)%..-$") or SILE.masterFilename
  end
  SILE.debugFlags = {}
  if opts.backend then
    SILE.backend = opts.backend
  end
  if opts.debug then
    for _,v in ipairs(std.string.split(opts.debug, ",")) do SILE.debugFlags[v] = 1 end
  end
  if opts.evaluate then
    local statements = type(opts.evaluate) == "table" and opts.evaluate or { opts.evaluate }
    SILE.dolua = {}
    for _, statement in ipairs(statements) do
      local func, err = loadstring(statement)
      if err then SU.error(err) end
      SILE.dolua[#SILE.dolua+1] = func
    end
  end
  if opts.output then
    SILE.outputFilename = opts.output
  end
  if opts.include then
    SILE.preamble = type(opts.include) == "table" and opts.include or { opts.include }
  end

  -- http://lua-users.org/wiki/VarargTheSecondClassCitizen
  local identity = function (...) return unpack({...}, 1, select('#', ...)) end
  SILE.errorHandler = opts.traceback and debug.traceback or identity
  SILE.traceback = opts.traceback
end

function SILE.initRepl ()
  SILE._repl          = require 'repl.console'
  local has_linenoise = pcall(require, 'linenoise')

  if has_linenoise then
    SILE._repl:loadplugin 'linenoise'
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

  SILE._repl:loadplugin 'history'
  SILE._repl:loadplugin 'completion'
  SILE._repl:loadplugin 'autoreturn'
  SILE._repl:loadplugin 'rcfile'
end

function SILE.repl()
  if not SILE._repl then SILE.initRepl() end
  SILE._repl:run()
end

function SILE.readFile(filename)
  SILE.currentlyProcessingFile = filename
  local doc = nil
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
      input.process(doc)
      return
    end
  end
  SU.error("No input processor available for "..filename.." (should never happen)",1)
end

local function file_exists (filename)
   local file = io.open(filename, "r")
   if file ~= nil then return io.close(file) else return false end
end

-- Sort through possible places files could be
function SILE.resolveFile(filename, pathprefix)
  local candidates = {}
  -- Start with the raw file name as given prefixed with a path if requested
  if pathprefix then candidates[#candidates+1] = std.io.catfile(pathprefix, filename) end
  -- Also check the raw file name without a path
  candidates[#candidates+1] = filename
  -- Iterate through the directory of the master file, the SILE_PATH variable, and the current directory
  -- Check for prefixed paths first, then the plain path in that fails
  if SILE.masterFilename then
    local dirname = SILE.masterFilename:match("(.-)[^%/]+$")
    for path in SU.gtoke(dirname..";"..tostring(os.getenv("SILE_PATH")), ";") do
      if path.string and path.string ~= "nil" then
        if pathprefix then candidates[#candidates+1] = std.io.catfile(path.string, pathprefix, filename) end
        candidates[#candidates+1] = std.io.catfile(path.string, filename)
      end
    end
  end
  -- Return the first candidate that exists, also checking the .sil suffix
  for _, v in pairs(candidates) do
    if file_exists(v) then return v end
    if file_exists(v..".sil") then return v .. ".sil" end
  end
  -- If we got here then no files existed even resembling the requested one
  return nil
end

-- Represents a stack of frame objects, which describe the call-stack stack of processing of the currently processed document.
-- To manipulate the stack, use
SILE.traceStack = {

  -- Internal: Push-pop balance checking ID
  _lastPushId = 0,

  -- Stores the frame which was last popped. Reset after a push.
  -- Helps to further specify current location in the processed document.
  afterFrame = nil,

  -- Internal: Function assigned to stack frames to convert them to human readable location
  _frameToLocationString = function(self, skipFile, withAttrs)
    local str
    if skipFile or not self.file then
      str = ""
    else
      str = self.file .. " "
    end
    if self.line then
      str = str .. "l." .. self.line .. " "
      if self.column then
        str = str .. "col." .. self.column .. " "
      end
    end
    if self.tag then
      -- Command
      str = str .. "\\" .. self.tag
      if withAttrs then
        str = str .. "["
        local first = true
        for key, value in pairs(self.options) do
          if first then first = false else str = str .. ", " end
          str = str .. key .. "=" .. value
        end
        str = str .. "]"
      end
    elseif self.text then
      -- Literal string
      local text = self.text
      if text:len() > 20 then
        text = text:sub(1, 18) .. "…"
      end
      text = text:gsub("\n", "␤"):gsub("\t", "␉"):gsub("\v", "␋")

      str = str .. "\"" .. text .. "\""
    else
      -- Unknown
      str = str .. type(self.content) .. "(" .. self.content .. ")"
    end
    return str
  end,

  -- Internal: Given an collection of frames and an afterFrame, construct and return a human readable info string
  -- about the location in processed document. Similar to _frameToLocationString, but takes into account
  -- the afterFrame and the fact, that not all frames may carry a location information.
  _formatTraceHead = function (traceStack, afterFrame)
    local top = traceStack[#traceStack]
    if not top then
      -- Stack is empty, there is not much we can do
      return afterFrame and "after " .. afterFrame:toLocationString() or nil
    end
    local info = top:toLocationString()
    -- Not all stack traces have to carry location information.
    -- If the top stack trace does not carry it, find a frame which does.
    -- Then append it, because its information may be useful.
    if not top.line then
      for i = #traceStack - 1, 1, -1 do
        if traceStack[i].line then
          -- Found a frame which does carry some relevant information.
          info = info .. " near " .. traceStack[i]:toLocationString(--[[skipFile=]] traceStack[i].file == top.file)
          break
        end
      end
    end
    -- Print after, if it is in a relevant file
    if afterFrame and (not base or afterFrame.file == base.file) then
      info = info .. " after " .. afterFrame:toLocationString(--[[skipFile=]] true)
    end
    return info
  end

}

-- Push a command frame on to the stack to record the execution trace for debugging.
-- Carries information about the command call, not the command itself.
-- Must be popped with `pop(returnOfPush)`.
function SILE.traceStack:pushCommand(tag, line, column, options, file)
  if not tag then
    SU.warn("Tag should be specified for SILE.traceStack:pushCommand", true)
  end
  return self:_pushFrame({
    tag = tag or "???",
    file = file or SILE.currentlyProcessingFile,
    line = line,
    column = column,
    options = options or {}
  })
end

-- Push a command frame on to the stack to record the execution trace for debugging.
-- Command arguments are inferred from AST content, any item may be overridden.
-- Must be popped with `pop(returnOfPush)`.
function SILE.traceStack:pushContent(content, tag, line, column, options, file)
  if type(content) ~= "table" then
    SU.warn("Content parameter of SILE.traceStack:pushContent must be a table", true)
    content = {}
  end
  tag = tag or content.tag
  if not tag then
    SU.warn("Tag should be specified or inferable for SILE.traceStack:pushContent", true)
  end
  return self:_pushFrame({
    tag = tag or "???",
    file = file or content.file or SILE.currentlyProcessingFile,
    line = line or content.line,
    column = column or content.col,
    options = options or content.attr or {}
  })
end

-- Push a text that is going to get typeset on to the stack to record the execution trace for debugging.
-- Must be popped with `pop(returnOfPush)`.
function SILE.traceStack:pushText(text, line, column, file)
  return self:_pushFrame({
    text = text,
    file = file,
    line = line,
    column = column
  })
end

-- Internal: Push complete frame
function SILE.traceStack:_pushFrame(frame)
  frame.toLocationString = self._frameToLocationString
  frame.typesetter = SILE.typesetter
  -- Push the frame
  if SU.debugging("commandStack") then
    print(string.rep(" ", #self) .. "PUSH(" .. frame:toLocationString(false, true) .. ")")
  end
  self[#self + 1] = frame
  self.afterFrame = nil
  self._lastPushId = self._lastPushId + 1
  frame.pushId = self._lastPushId
  return self._lastPushId
end

-- Pop previously pushed command from the stack.
-- Return value of `push` function must be provided as argument to check for balanced usage.
function SILE.traceStack:pop(pushId)
  if type(pushId) ~= "number" then
    SU.error("SILE.traceStack:pop's argument must be the result value of the corresponding push", true)
  end
  -- First verify that push/pop is balanced
  local popped = self[#self]
  if popped.pushId ~= pushId then
    local message = "Unbalanced content push/pop"
    local debug = SILE.traceback or SU.debugging("commandStack")
    if debug then
      message = message .. ". Expected " .. popped.pushId .. " - (" .. popped:toLocationString() .. "), got " .. pushId
    end
    SU.warn(message, debug)
  else
    -- Correctly balanced: pop the frame
    self.afterFrame = popped
    self[#self] = nil
    if SU.debugging("commandStack") then
      print(string.rep(" ", #self) .. "POP(" .. popped:toLocationString(false, true) .. ")")
    end
  end
end

-- Returns frame stack represented by SILE.traceStack and self.afterFrame, but without frames whose typesetter
-- is different than what is given as a first parameter (nil = use current typesetter for filtering).
-- Most relevant object is in the last index.
function SILE.traceStack:filteredByTypesetter(typesetter)
  typesetter = typesetter or SILE.typesetter
  local result = {}
  for i = 1, #self do
    if self[i].typesetter == typesetter then
      result[#result + 1] = self[i]
    end
  end
  local afterFrame
  if self.afterFrame and self.afterFrame.typesetter == typesetter then
    afterFrame = self.afterFrame
  end
  return result, afterFrame
end

-- Returns short string with most relevant location information for user messages.
function SILE.traceStack:locationInfo()
  return self:_formatTraceHead(self.afterFrame) or SILE.currentlyProcessingFile or "<nowhere>"
end

-- Returns multiline trace string, with full document location information for user messages.
function SILE.traceStack:locationTrace()
  local prefix = "  at "
  local trace = self._formatTraceHead({ self[#self] } --[[we handle rest of the stack ourselves]], self.afterFrame)
  if not trace then
    -- There is nothing else then
    return prefix .. (SILE.currentlyProcessingFile or "<nowhere>") .. "\n"
  end
  trace = prefix .. trace .. "\n"
  -- Iterate backwards, skipping the last element
  for i = #self - 1, 1, -1 do
    local s = self[i]
    trace = trace .. prefix .. s:toLocationString() .. "\n"
  end
  return trace
end

function SILE.call(cmd, options, content)
  -- Prepare trace information for command stack
  local file, line, column
  if SILE.traceback and not (type(content) == "table" and content.line) then
    -- This call is from code (no content.line) and we want to spend the time
    -- to determine everything we need about the caller
    local caller = debug.getinfo(2, "Sl")
    file = caller.short_src
    line = caller.currentline
  elseif type(content) == "table" then
    file = content.file
    line = content.line
    column = content.col
  end
  local pId = SILE.traceStack:pushCommand(cmd, line, column, options, file)
  if not SILE.Commands[cmd] then SU.error("Unknown command "..cmd) end
  local result = SILE.Commands[cmd](options or {}, content or {})
  SILE.traceStack:pop(pId)
  return result
end

return SILE
