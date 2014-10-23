-- Copyright (c) 2011-2014 Rob Hoelz <rob@hoelz.ro>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-- @class repl.console
--- This module implements a command line-based REPL,
--- similar to the standalone Lua interpreter.

local sync_repl    = require 'repl.sync'
local console_repl = sync_repl:clone()
local stdout       = io.stdout
local stdin        = io.stdin
local print        = print
local unpack       = unpack

-- @see repl:showprompt(prompt)
function console_repl:showprompt(prompt)
  stdout:write(prompt .. ' ')
end

-- @see repl.sync:lines()
function console_repl:lines()
  return stdin:lines()
end

-- @see repl:displayresults(results)
function console_repl:displayresults(results)
  if results.n == 0 then
    return
  end

  print(unpack(results, 1, results.n))
end

-- @see repl:displayerror(err)
function console_repl:displayerror(err)
  print(err)
end

console_repl._features.console = true

return console_repl
