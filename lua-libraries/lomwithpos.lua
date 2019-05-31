local lxp = require "lxp"

local tinsert, tremove = table.insert, table.remove
local assert, type, print = assert, type, print

local function startcommand (p, command, options)
  local stack = p:getcallbacks().stack
  local lno, col, pos = p:pos()
  local newelement = { command = command, options = options, lno = lno, col = col}
  tinsert(stack, newelement)
end

local function endcommand (p, command)
  local stack = p:getcallbacks().stack
  local element = tremove(stack)
  assert(element.command == command)
  local level = #stack
  tinsert(stack[level], element)
end

local function text (p, text)
  local stack = p:getcallbacks().stack
  local element = stack[#stack]
  local n = #element
  if type(element[n]) == "string" then
    element[n] = element[n] .. text
  else
    tinsert(element, text)
  end
end

local function parse (o)
  local c = { StartElement = startcommand,
              EndElement = endcommand,
              CharacterData = text,
              _nonstrict = true,
              stack = {{}}
            }
  local p = lxp.new(c)
  local status, err
  if type(o) == "string" then
    status, err = p:parse(o)
    if not status then return nil, err end
  else
    for l in pairs(o) do
      status, err = p:parse(l)
      if not status then return nil, err end
    end
  end
  status, err = p:parse()
  if not status then return nil, err end
  p:close()
  return c.stack[1][1]
end

return { parse = parse }
