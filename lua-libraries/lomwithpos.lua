local lxp = require "lxp"

local function startcommand (parser, command, options)
  local stack = parser:getcallbacks().stack
  local lno, col, pos = parser:pos()
  local element = { command = command, options = options, lno = lno, col = col }
  table.insert(stack, element)
end

local function endcommand (parser, command)
  local stack = parser:getcallbacks().stack
  local element = table.remove(stack)
  assert(element.command == command)
  local level = #stack
  table.insert(stack[level], element)
end

local function text (parser, text)
  local stack = parser:getcallbacks().stack
  local element = stack[#stack]
  local n = #element
  if type(element[n]) == "string" then
    element[n] = element[n] .. text
  else
    table.insert(element, text)
  end
end

local function parse (doc)
  local content = { StartElement = startcommand,
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

return { parse = parse }
