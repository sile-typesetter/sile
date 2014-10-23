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

-- A plugin that uses linenoise (https://github.com/hoelzro/lua-linenoise) for prompting

local ln = require 'linenoise'

repl:requirefeature 'console'

function override:showprompt(prompt)
  self._prompt = prompt -- XXX how do we make sure other plugins don't step on this?
end

function override:lines()
  return function()
    return ln.linenoise(self._prompt .. ' ')
  end
end

repl:ifplugin('completion', function()
  ln.setcompletion(function(completions, line)
    repl:complete(line, function(completion)
      ln.addcompletion(completions, completion)
    end)
  end)
end)

repl:ifplugin('history', function()
  repl:setuphistorycallbacks {
    load = function(filename)
      ln.historyload(filename)
    end,

    addline = function(line)
      ln.historyadd(line)
    end,

    save = function(filename)
      ln.historysave(filename)
    end,
  }
end)

features = 'input'
