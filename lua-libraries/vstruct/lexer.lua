-- Implements the lexer for vstruct format strings.
-- Returns a function which, given a source string, returns a table of lexer
-- operations closed over that source.

-- Copyright (c) 2011 Ben "ToxicFrog" Kelly

local lexis = {}

local function lexeme(name)
  return function(pattern)
    lexis[#lexis+1] = { name=name, pattern="^"..pattern }
  end
end

lexeme (false)    "%s+"         -- whitespace
lexeme (false)    "%-%-[^\n]*"  -- comments
lexeme "key"      "([%a_][%w_.]*):"
lexeme "io"       "([-+@<>=])"
lexeme "io"       "([%a_]+)"
lexeme "number"   "([%d.,]+)"
lexeme "splice"   "&(%S+)"
lexeme "{"        "%{"
lexeme "}"        "%}"
lexeme "("        "%("
lexeme ")"        "%)"
lexeme "*"        "%*"
lexeme "["        "%["
lexeme "]"        "%]"
lexeme "|"        "%|"

return function(source)
  local orig = source
  local index = 1
  local hadwhitespace = false
  
  local function where()
    return ("character %d ('%s')"):format(index, source:sub(1,4))
  end

  local function find_match()
    for _,lexeme in ipairs(lexis) do
      if source:match(lexeme.pattern) then
        return lexeme,select(2, source:find(lexeme.pattern))
      end
    end
    error (("Lexical error in format string at %s."):format(where()))
  end

  local function eat_whitespace()
    local function aux()
      if #source == 0 then return end
      local match,size = find_match()
      
      if not match.name then
        hadwhitespace = true
        source = source:sub(size+1, -1)
        index = index + size
        return aux()
      end
    end
    hadwhitespace = false
    return aux()
  end

  local function whitespace()
    return hadwhitespace
  end
  
  local function next()
    eat_whitespace()

    if #source == 0 then return { text = nil, type = "EOF" } end

    local lexeme,size,text = find_match()

    source = source:sub(size+1, -1)
    index = index+size

    return { text = text, type = lexeme.name }
  end

  local function peek()
    eat_whitespace()

    if #source == 0 then return { text = nil, type = "EOF" } end

    local lexeme,size,text = find_match()

    return { text = text, type = lexeme.name }
  end

  return {
    next = next;
    peek = peek;
    where = where;
    whitespace = whitespace;
    tokens = function() return next end;
  }
end

