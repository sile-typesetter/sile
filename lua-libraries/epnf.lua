local L = require( "lpeg" )

local assert = assert
local _VERSION = assert( _VERSION )
local string, io = assert( string ), assert( io )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )
local setfenv = setfenv
if _VERSION == "Lua 5.1" then
  assert( setfenv )
end


-- module table
local epnf = {}


-- maximum of two numbers while avoiding math lib as a dependency
local function max( a, b )
  if a < b then return b else return a end
end


-- get the line which p points into, the line number and the position
-- of the beginning of the line
local function getline( s, p )
  local lno, sol = 1, 1
  for i = 1, p do
    if string.sub( s, i, i ) == "\n" then
      lno = lno + 1
      sol = i + 1
    end
  end
  local eol = #s
  for i = sol, #s do
    if string.sub( s, i, i ) == "\n" then
      eol = i - 1
      break
    end
  end
  return string.sub( s, sol, eol ), lno, sol
end


-- raise an error during semantic validation of the ast
local function raise_error( n, msg, s, p )
  local line, lno, sol = getline( s, p )
  assert( p <= #s )
  local clen = max( 70, p+10-sol )
  if #line > clen then
    line = string.sub( line, 1, clen ) .. "..."
  end
  local marker = string.rep( " ", p-sol ) .. "^"
  error( n..":"..lno..": "..msg.."\n"..line.."\n"..marker, 0 )
end


-- parse-error reporting function
local function parse_error( s, p, n, e )
  if p <= #s then
    local msg = "parse error"
    if e then msg = msg .. ", " .. e end
    raise_error( n, msg, s, p )
  else -- parse error at end of input
    local _,lno = string.gsub( s, "\n", "\n" )
    if string.sub( s, -1, -1 ) ~= "\n" then lno = lno + 1 end
    local msg = ": parse error at <eof>"
    if e then msg = msg .. ", " .. e end
    error( n..":"..lno..msg, 0 )
  end
end


local function make_ast_node( id, pos, t )
  t.id = id
  t.pos = pos
  return t
end


-- some useful/common lpeg patterns
local L_Cp = L.Cp()
local L_Carg_1 = L.Carg( 1 )
local function E( msg )
  return L.Cmt( L_Carg_1 * L.Cc( msg ), parse_error )
end
local function EOF( msg )
  return -L.P( 1 ) + E( msg )
end
local letter = L.R( "az", "AZ" ) + L.P"_"
local digit = L.R"09"
local ID = L.C( letter * (letter+digit)^0 )
local function W( s )
  return L.P( s ) * -(letter+digit)
end
local WS = L.S" \r\n\t\f\v"


-- setup an environment where you can easily define lpeg grammars
-- with lots of syntax sugar
function epnf.define( func, g )
  g = g or {}
  local env = {}
  local env_index = {
    START = function( name ) g[ 1 ] = name end,
    E = E,
    EOF = EOF,
    ID = ID,
    W = W,
    WS = WS,
  }
  -- copy lpeg shortcuts
  for k,v in pairs( L ) do
    if string.match( k, "^%u%w*$" ) then
      env_index[ k ] = v
    end
  end
  setmetatable( env_index, { __index = _G } )
  setmetatable( env, {
    __index = env_index,
    __newindex = function( _, name, val )
      g[ name ] = (L.Cc( name ) * L_Cp * L.Ct( val )) / make_ast_node
    end
  } )
  -- call passed function with custom environment (5.1- and 5.2-style)
  if _VERSION == "Lua 5.1" then
    setfenv( func, env )
  end
  func( env )
  assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
  return g
end


-- apply a given grammar to a string and return the ast. also allows
-- to set the name of the string for error messages
function epnf.parse( g, name, input, ... )
  return L.match( L.P( g ), input, 1, name, ... ), name, input
end


-- apply a given grammar to the contents of a file and return the ast
function epnf.parsefile( g, fname, ... )
  local f = assert( io.open( fname, "r" ) )
  local a,n,i = epnf.parse( g, fname, assert( f:read"*a" ), ... )
  f:close()
  return a,n,i
end


-- apply a given grammar to a string and return the ast. automatically
-- picks a sensible name for error messages
function epnf.parsestring( g, str, ... )
  local s = string.sub( str, 1, 20 )
  if #s < #str then s = s .. "..." end
  local name = "[\"" .. string.gsub( s, "\n", "\\n" ) .. "\"]"
  return epnf.parse( g, name, str, ... )
end


local function write( ... ) return io.stderr:write( ... ) end
local function dump_ast( node, prefix )
  if type( node ) == "table" then
    write( "{" )
    if next( node ) ~= nil then
      write( "\n" )
      if type( node.id ) == "string" and
         type( node.pos ) == "number" then
        write( prefix, "  id = ", node.id,
               ",  pos = ", tostring( node.pos ), "\n" )
      end
      for k,v in pairs( node ) do
        if k ~= "id" and k ~= "pos" then
          write( prefix, "  ", tostring( k ), " = " )
          dump_ast( v, prefix.."  " )
        end
      end
    end
    write( prefix, "}\n" )
  else
    write( tostring( node ), "\n" )
  end
end

-- write a string representation of the given ast to stderr for
-- debugging
function epnf.dumpast( node )
  return dump_ast( node, "" )
end


-- export a function for reporting errors during ast validation
epnf.raise = raise_error


-- return module table
return epnf

