-- Abstract Syntax Tree module for vstruct
-- This module implements the parser for vstruct format definitions. It is a
-- fairly simple recursive-descent parser that constructs an AST using Lua
-- tables, and then generates lua source from it.

-- See ast/*.lua for the implementations of various node types in the AST,
-- and see lexer.lua for the implementation of the lexer.

-- Copyright (c) 2011 Ben "ToxicFrog" Kelly

local vstruct = require "vstruct"
local lexer  = require "vstruct.lexer"

local ast = {}
local cache = {}

-- load the implementations of the various AST node types
for _,node in ipairs { "IO", "List", "Name", "Table", "Repeat", "Root", "Bitpack" } do
  ast[node] = require ((...).."."..node)
end

-- given a source string, compile it
-- returns a table containing pack and unpack functions and the original
-- source - see README#vstruct.compile for a description.
--
-- if (vstruct.cache) is non-nil, will return the cached version, if present
-- if (vstruct.cache) is true, will create a new cache entry, if needed
function ast.parse(source)
  local lex = lexer(source)
  local root = ast.List()
  
  for node in (function() return ast.next(lex) end) do
    root:append(node)
  end
  
  return ast.Root(root)
end

-- used by the rest of the parser to report syntax errors
function ast.error(lex, expected)
  error("vstruct: parsing format string at "..lex.where()..": expected "..expected..", got "..lex.peek().type)
end

-- Everything below this line is internal to the recursive descent parser

function ast.io(lex)
  local io = ast.raw_io(lex)
  if io.hasvalue then
    return ast.Name(nil, io)
  else
    return io
  end
end

function ast.raw_io(lex)
  local name = lex.next().text
  local next = lex.peek()
  
  if next and next.type == "number" and not lex.whitespace() then
    return ast.IO(name, lex.next().text)
  else
    return ast.IO(name, nil)
  end
end

function ast.key(lex)
  local name = lex.next().text
  local next = lex.peek()
  
  if next.type == "io" then
    local io = ast.raw_io(lex)
    if not io.hasvalue then
      ast.error(lex, "value (io specifier or table) - format '"..name.."' has no value")
    end
    return ast.Name(name, io)
  elseif next.type == "{" then
    return ast.Name(name, ast.raw_table(lex))
  else
    ast.error(lex, "value (io specifier or table)")
  end
end

function ast.next(lex)
  local tok = lex.peek()
  
  if tok.type == "EOF" then
    return nil
  end
  
  if tok.type == '(' then
    return ast.group(lex)
  
  elseif tok.type == '{' then
    return ast.table(lex)
  
  elseif tok.type == '[' then
    return ast.bitpack(lex)
    
  elseif tok.type == "io" then
    return ast.io(lex)
  
  elseif tok.type == "key" then
    return ast.key(lex)
    
  elseif tok.type == "number" then
    return ast.repetition(lex)
    
  elseif tok.type == "control" then
    return ast.control(lex)

  elseif tok.type == "splice" then
    return ast.splice(lex)
    
  else
    ast.error(lex, "'(', '{', '[', name, number, control, or io specifier")
  end
end

function ast.next_until(lex, type)
  return function()
    local tok = lex.peek()

    if tok.type == 'EOF' then
      ast.error(lex, type)
    end
    
    if tok.type == type then
      return nil
    end
    
    return ast.next(lex)
  end
end

function ast.splice(lex)
  local name = lex.next().text

  local root = vstruct.registry[name]
  if not root then
    error("vstruct: attempt to splice in format '"..name.."', which is not registered")
  end

  return root[1]
end

function ast.repetition(lex)
  local count = tonumber(lex.next().text)
  ast.require(lex, "*");

  return ast.Repeat(count, ast.next(lex))
end

function ast.group(lex)
  ast.require(lex, '(')
  
  local group = ast.List()
  group.tag = "group"
  
  for next in ast.next_until(lex, ')') do
    group:append(next)
  end
  
  ast.require(lex, ')')
  return group
end

function ast.table(lex)
  return ast.Name(nil, ast.raw_table(lex))
end

function ast.raw_table(lex)
  ast.require(lex, '{')
  
  local group = ast.Table()
  
  for next in ast.next_until(lex, '}') do
    group:append(next)
  end
  
  ast.require(lex, '}')
  return group
end

function ast.bitpack(lex)
  ast.require(lex, "[")
  
  local bitpack = ast.Bitpack(tonumber(ast.require(lex, "number").text))
  
  ast.require(lex, "|")
  
  for next in ast.next_until(lex, ']') do
    bitpack:append(next)
  end
  
  ast.require(lex, "]")
  bitpack:finalize()
  return bitpack
end

function ast.require(lex, type)
  local t = lex.next()
  
  if t.type ~= type then
    ast.error(lex, type)
  end
  
  return t
end

return ast

--[[

format -> commands

command -> repeat | bitpack | group | named | value | control | splice

repeat -> NUMBER '*' command | command '*' NUMBER
bitpack -> '[' NUMBER '|' commands ']'
group -> '(' commands ')'

named -> NAME ':' value
value -> table | primitive
table -> '{' commands '}'

splice -> '&' NAME

primitive -> ATOM NUMBERS

control -> SEEK NUMBER | ENDIANNESS

--]]
