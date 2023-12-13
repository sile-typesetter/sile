local base = require("inputters.base")
local lxp = require("lxp")

local inputter = pl.class(base)
inputter._name = "xml"

inputter.order = 2

local function startcommand (parser, command, options)
  local stack = parser:getcallbacks().stack
  local lno, col, pos = parser:pos()
  local position = { lno = lno, col = col, pos = pos }
  -- create an empty command which content will be filled on closing tag
  local element = SU.ast.createCommand(command, options, nil, position)
  table.insert(stack, element)
end

local function endcommand (parser, command)
  local stack = parser:getcallbacks().stack
  local element = table.remove(stack)
  assert(element.command == command)
  local level = #stack
  table.insert(stack[level], element)
end

local function text (parser, msg)
  local stack = parser:getcallbacks().stack
  local element = stack[#stack]
  local n = #element
  if type(element[n]) == "string" then
    element[n] = element[n] .. msg
  else
    table.insert(element, msg)
  end
end

local function parse (doc)
  local content = {
    StartElement = startcommand,
    EndElement = endcommand,
    CharacterData = text,
    _nonstrict = true,
    stack = {{}}
  }
  local parser = lxp.new(content)
  local status, err
  if type(doc) == "string" then
    status, err = parser:parse(doc)
    if not status then return nil, err end
  else
    for element in pairs(doc) do
      status, err = parser:parse(element)
      if not status then return nil, err end
    end
  end
  status, err = parser:parse()
  if not status then return nil, err end
  parser:close()
  return content.stack[1][1]
end

function inputter.appropriate (round, filename, doc)
  if round == 1 then
    return filename:match(".xml$")
  elseif round == 2 then
    local sniff = doc:sub(1, 100):gsub("begin.*", "") or ""
    local promising = sniff:match("<")
    return promising and inputter.appropriate(3, filename, doc)
  elseif round == 3 then
    local _, err = parse(doc)
    return not err
  end
end

function inputter.parse (_, doc)
  local tree, err = parse(doc)
  if not tree then
    SU.error(err)
  end
  -- XML documents can have any root element, and it should be up to the class
  -- to supply handling far whatever that element that is in a specific format.
  -- Hence we wrap the actual DOM in an extra element of our own if and only if
  -- it doesn't look like a native SILE one already.
  local rootelement = tree.command
  if rootelement ~= "sile" and rootelement ~= "document" then
    tree = SU.ast.createCommand("document", {}, tree)
  end
  return { tree }
end

return inputter
