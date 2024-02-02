--- SILE AST utilities
--
local ast = {}

--- Find a command node in a SILE AST tree,
--- looking only at the first level.
--- (We're not reimplementing XPath here.)
---@param tree      table       AST tree
---@param command   string      command name
---@return          table|nil   AST command node
function ast.findInTree (tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return tree[i]
    end
  end
end

--- Find and extract (remove) a command node in a SILE AST tree,
--- looking only at the first level.
---@param tree      table       AST tree
---@param command   string      command name
---@return          table|nil   AST command node
function ast.removeFromTree (tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return table.remove(tree, i)
    end
  end
end

--- Create a command from a simple content tree.
--- It encapsulates the content in a command node.
---@param command   string      command name
---@param options   table       command options
---@param content   table       child AST tree
---@param position  table       position in source (or parent AST command node)
---@return          table       AST command node
function ast.createCommand (command, options, content, position)
  local result = { content }
  result.options = options or {}
  result.command = command
  result.id = "command"
  if position then
    result.col = position.col or 0
    result.lno = position.lno or 0
    result.pos = position.pos or 0
  else
    result.col = 0
    result.lno = 0
    result.pos = 0
  end
  return result
end

--- Create a command from a structured content tree.
--- The content is normally a table of an already prepared content list.
---@param command   string    command name
---@param options   table     command options
---@param content   table     child AST tree
---@param position  table     position in source (or parent AST command node)
---@return          table     AST command node
function ast.createStructuredCommand (command, options, content, position)
  local result = type(content) == "table" and content or { content }
  result.options = options or {}
  result.command = command
  result.id = "command"
  if position then
    result.col = position.col or 0
    result.lno = position.lno or 0
    result.pos = position.pos or 0
  else
    result.col = 0
    result.lno = 0
    result.pos = 0
  end
  return result
end

--- Extract the sub-content tree from a (command) node,
--- that is the child nodes of the (command) node.
---@param content   table   AST tree
---@return          table   AST tree
function ast.subContent (content)
  local out = {}
  for _, val in ipairs(content) do
    out[#out+1] = val
  end
  return out
end

-- String trimming
local function trimLeft (str)
  return str:gsub("^%s*", "")
end
local function trimRight (str)
  return str:gsub("%s*$", "")
end

--- Content tree trimming: remove leading and trailing spaces, but from
--- a content tree i.e. possibly containing several elements.
---@param content   table   AST tree
---@return          table   AST tree
function ast.trimSubContent (content)
  if #content == 0 then
    return
  end
  if type(content[1]) == "string" then
    content[1] = trimLeft(content[1])
    if content[1] == "" then
      table.remove(content, 1)
    end
  end
  if type(content[#content]) == "string" then
    content[#content] = trimRight(content[#content])
    if content[#content] == "" then
      table.remove(content, #content)
    end
  end
  return content
end

--- Process the AST walking through content nodes as a "structure":
--- Text nodes are ignored (e.g. usually just spaces due to indentation)
--- Command options are enriched with their "true" node position, so we can later
--- refer to it (as with an XPath pos()).
---@param content   table   AST tree
function ast.processAsStructure (content)
  local iElem = 0
  local nElem = 0
  for i = 1, #content do
    if type(content[i]) == "table" then
      nElem = nElem + 1
    end
  end
  for i = 1, #content do
    if type(content[i]) == "table" then
      iElem = iElem + 1
      content[i].options._pos_ = iElem
      content[i].options._last_ = iElem == nElem
      SILE.process({ content[i] })
    end
    -- All text nodes in ignored in structure tags.
  end
end

--- Call `action` on each content AST node, recursively, including `content` itself.
--- Not called on leaves, i.e. strings.
---@param content   table       AST tree
---@param action    function    function to call on each node
function ast.walkContent (content, action)
  if type(content) ~= "table" then
    return
  end
  action(content)
  for i = 1, #content do
    ast.walkContent(content[i], action)
  end
end

--- Strip position, line and column recursively from a content tree.
--- This can be used to remove position details where we do not want them,
--- e.g. in table of contents entries (referring to the original content,
--- regardless where it was exactly, for the purpose of checking whether
--- the table of contents changed.)
---@param content   table   AST tree
---@return          table   AST tree
function ast.stripContentPos (content)
  if type(content) ~= "table" then
    return content
  end
  local stripped = {}
  for k, v in pairs(content) do
    if type(v) == "table" then
      v = ast.stripContentPos(v)
    end
    stripped[k] = v
  end
  if content.id or content.command then
    stripped.pos, stripped.col, stripped.lno = nil, nil, nil
  end
  return stripped
end

--- Flatten content trees into just the string components (allows passing
--- objects with complex structures to functions that need plain strings)
--- @param content   table   AST tree
--- @return          string  string representation of content
function ast.contentToString (content)
  local string = ""
  for i = 1, #content do
    if type(content[i]) == "table" and type(content[i][1]) == "string" then
      string = string .. content[i][1]
    elseif type(content[i]) == "string" then
      -- Work around PEG parser returning env tags as content
      -- TODO: refactor capture groups in PEG parser
      if content.command == content[i] and content[i] == content[i+1] then
        break
      end
      string = string .. content[i]
    end
  end
  return string
end

--- Check whether a content AST tree is empty.
---@param content   table     AST tree
---@return          boolean   true if content is not empty
function ast.hasContent (content)
  return type(content) == "function" or type(content) == "table" and #content > 0
end

return ast
