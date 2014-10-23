--[[--
 Additions to the io module.
 @module std.io
]]

local package = require "std.package"
local string  = require "std.string"
local tree    = require "std.tree"


-- Get an input file handle.
-- @param h file handle or name (default: `io.input ()`)
-- @return file handle, or nil on error
local function input_handle (h)
  if h == nil then
    h = io.input ()
  elseif type (h) == "string" then
    h = io.open (h)
  end
  return h
end

--- Slurp a file handle.
-- @param h file handle or name (default: `io.input ()`)
-- @return contents of file or handle, or nil if error
local function slurp (h)
  h = input_handle (h)
  if h then
    local s = h:read ("*a")
    h:close ()
    return s
  end
end

--- Read a file or file handle into a list of lines.
-- @param h file handle or name (default: `io.input ()`);
-- if h is a handle, the file is closed after reading
-- @return list of lines
local function readlines (h)
  h = input_handle (h)
  local l = {}
  for line in h:lines () do
    table.insert (l, line)
  end
  h:close ()
  return l
end

--- Write values adding a newline after each.
-- @param h file handle (default: `io.output ()`
-- @param ... values to write (as for write)
local function writelines (h, ...)
  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for v in tree.ileaves ({...}) do
    h:write (v, "\n")
  end
end

--- Split a directory path into components.
-- Empty components are retained: the root directory becomes `{"", ""}`.
-- @param path path
-- @return list of path components
local function splitdir (path)
  return string.split (path, package.dirsep)
end

--- Concatenate one or more directories and a filename into a path.
-- @param ... path components
-- @return path
local function catfile (...)
  return table.concat ({...}, package.dirsep)
end

--- Concatenate two or more directories into a path, removing the trailing slash.
-- @param ... path components
-- @return path
local function catdir (...)
  return (string.gsub (catfile (...), "^$", package.dirsep))
end

--- Perform a shell command and return its output.
-- @param c command
-- @return output, or nil if error
local function shell (c)
  return slurp (io.popen (c))
end

--- Process files specified on the command-line.
-- If no files given, process `io.stdin`; in list of files,
-- `-` means `io.stdin`.
-- @todo Make the file list an argument to the function.
-- @param f function to process files with, which is passed
-- `(name, arg_no)`
local function process_files (f)
  -- N.B. "arg" below refers to the global array of command-line args
  if #arg == 0 then
    table.insert (arg, "-")
  end
  for i, v in ipairs (arg) do
    if v == "-" then
      io.input (io.stdin)
    else
      io.input (v)
    end
    f (v, i)
  end
end

--- Give warning with the name of program and file (if any).
-- If there is a global `prog` table, prefix the message with
-- `prog.name` or `prog.file`, and `prog.line` if any.  Otherwise
-- if there is a global `opts` table, prefix the message with
-- `opts.program` and `opts.line` if any.  @{std.optparse:parse}
-- returns an `opts` table that provides the required `program`
-- field, as long as you assign it back to `_G.opts`:
--
--     local OptionParser = require "std.optparse"
--     local parser = OptionParser "eg 0\nUsage: eg\n"
--     _G.arg, _G.opts = parser:parse (_G.arg)
--     if not _G.opts.keep_going then
--       require "std.io".warn "oh noes!"
--     end
--
-- @param ... arguments for format
-- @see std.optparse:parse
local function warn (...)
  local prefix = ""
  if (prog or {}).name then
    prefix = prog.name .. ":"
    if prog.line then
      prefix = prefix .. tostring (prog.line) .. ":"
    end
  elseif (prog or {}).file then
    prefix = prog.file .. ":"
    if prog.line then
      prefix = prefix .. tostring (prog.line) .. ":"
    end
  elseif (opts or {}).program then
    prefix = opts.program .. ":"
    if opts.line then
      prefix = prefix .. tostring (opts.line) .. ":"
    end
  end
  if #prefix > 0 then prefix = prefix .. " " end
  writelines (io.stderr, prefix .. string.format (...))
end

--- Die with error.
-- This function uses the same rules to build a message prefix
-- as @{std.io.warn}.
-- @param ... arguments for format
-- @see std.io.warn
local function die (...)
  warn (...)
  error ()
end


--- @export
local M = {
  catdir        = catdir,
  catfile       = catfile,
  die           = die,
  process_files = process_files,
  readlines     = readlines,
  shell         = shell,
  slurp         = slurp,
  splitdir      = splitdir,
  warn          = warn,
  writelines    = writelines,
}

-- camelCase compatibility.
M.processFiles  = process_files

for k, v in pairs (io) do
  M[k] = M[k] or v
end

return M
