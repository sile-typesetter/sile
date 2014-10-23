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

local history_file

local function invokecallback(self, name, ...)
  if not self._history_callbacks then
    return
  end

  local impl = self._history_callbacks[name]
  return impl(...)
end

local function init()
  if os.getenv 'HOME' then
    history_file = os.getenv('HOME') .. '/.rep.lua.history'
  end
end

-- XXX I don't know if this callback setup way
--     is the best way to go about this (in fact
--     I'm pretty sure it isn't), but I just need
--     something that works right now.
function repl:setuphistorycallbacks(callbacks)
  self._history_callbacks = callbacks

  if history_file then
    invokecallback(self, 'load', history_file)
  end
end

function after:handleline(line)
  invokecallback(self, 'addline', line)
end

function before:shutdown()
  if history_file then
    invokecallback(self, 'save', history_file)
  end
end

features = 'history'

init()
