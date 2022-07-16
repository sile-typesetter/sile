-- A few SILE AST utilities.

local function createCommand (command, options, content)
  -- content = a simple content
  -- So that's basically the same logic as the "inputfilter" package's
  -- createComment, with col, line, pos dropped as we don't get them
  -- from lunamark's AST.
  local result = { content }
  result.col = 0
  result.line = 0
  result.pos = 0
  result.options = options or {}
  result.command = command
  result.id = "command"
  return result
end

local function createStructuredCommand (command, options, contents)
  -- contents = normally a table of an already prepared content list.
  local result = type(contents) == "table" and contents or { contents }
  result.col = 0
  result.line = 0
  result.pos = 0
  result.options = options or {}
  result.command = command
  result.id = "command"
  return result
end

-- Some other utility functions.

local function getFileExtension (fname)
  -- Extract file name and then extension.
  -- Assumes a POSIX-compliant name (i.e. / as path separators)
  return fname:match("[^/]+$"):match("[^.]+$")
end

local function split (source, delimiters)
  local elements = {}
  local pattern = '([^'..delimiters..']+)'
  string.gsub(source, pattern, function (value) elements[#elements + 1] = value;  end);
  return elements
end

local function normalizeLang (lang)
  -- Pandoc says language should be a BCP 47 identifier such as "en-US",
  -- SILE only knows about "en" for now...
  return split(lang, "-")[1]
end

return {
  getFileExtension = getFileExtension,
  normalizeLang = normalizeLang,
  createCommand = createCommand,
  createStructuredCommand = createStructuredCommand,
}
