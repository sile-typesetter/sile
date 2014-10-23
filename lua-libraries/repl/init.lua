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

-- @class repl
--- This module implements the core functionality of a REPL.

local plugins_lookup_meta = { __mode = 'k' }

local repl         = { _buffer = '', _plugins = setmetatable({}, plugins_lookup_meta), _features = {}, _ifplugin = {}, VERSION = 0.6 }
local select       = select
local loadstring   = loadstring
local dtraceback   = debug.traceback
local setmetatable = setmetatable
local sformat      = string.format
local smatch       = string.match
local error        = error
local setfenv      = require('repl.utils').setfenv

local function gather_results(success, ...)
  local n = select('#', ...)
  return success, { n = n, ... }
end

local function tcopy(t, copy)
  copy = copy or {}

  for k, v in pairs(t) do
    copy[k] = v
  end

  return copy
end

--- Returns the prompt for a given level.
-- @param level The prompt level. Either 1 or 2.
function repl:getprompt(level)
  return level == 1 and '>' or '>>'
end

--- Displays a prompt for the given prompt level.
-- @param level The prompt level. Either 1 or 2.
function repl:prompt(level)
  self:showprompt(self:getprompt(level))
end

--- Returns the name of the REPL.  For usage in chunk compilation.
-- @return The REPL's name.
-- @see load
function repl:name()
  return 'REPL'
end

--- Gets a traceback for an error.
-- @param ... All of the stuff that xpcall passes to error functions.
-- @see xpcall
-- @return A stack trace.  The default implementation returns a simple string-based trace.
function repl:traceback(...)
  return dtraceback(...)
end

--- Uses the compilation error to determine whether or not further input
--- is pending after the last line.  You shouldn't have to override this
--- unless you use an implementation of Lua that varies in its error
--- messages.
-- @param err The compilation error from Lua.
-- @return Whether or not the input should continue after this line.
function repl:detectcontinue(err)
  return smatch(err, "'<eof>'$") or smatch(err, "<eof>$")
end

function repl:compilechunk(chunk)
  return loadstring(chunk, self:name())
end

--- Evaluates a line of input, and displays return value(s).
-- @param line The line to evaluate
-- @return The prompt level (1 or 2)
function repl:handleline(line)
  local chunk  = self._buffer .. line
  local f, err = self:compilechunk(chunk)

  if f then
    self._buffer = ''

    setfenv(f, self:getcontext())
    local success, results = gather_results(xpcall(f, function(...) return self:traceback(...) end))
    if success then
      self:displayresults(results)
    else
      self:displayerror(results[1])
    end
  else
    if self:detectcontinue(err) then
      self._buffer = chunk .. '\n'
      return 2
    else
      self:displayerror(err)
    end
  end

  return 1
end

--- Creates a new REPL object, so you can override methods without fear.
-- @return A REPL clone.
function repl:clone()
  local plugins_copy  = tcopy(self._plugins, setmetatable({}, plugins_lookup_meta))
  local features_copy = tcopy(self._features)
  local ifplugin_copy = {}

  for k, v in pairs(self._ifplugin) do
    ifplugin_copy[k] = tcopy(v)
  end

  return setmetatable({
    _buffer   = '',
    _plugins  = plugins_copy,
    _features = features_copy,
    _ifplugin = ifplugin_copy,
  }, { __index = self })
end

--- Displays the given prompt to the user.  Must be overriden.
-- @param prompt The prompt to display.
function repl:showprompt(prompt)
  error 'You must implement the showprompt method'
end

--- Displays the results from evaluate().  Must be overriden.
-- @param results The results to display. The results are a table, with the integer keys containing the results, and the 'n' key containing the highest integer key.

function repl:displayresults(results)
  error 'You must implement the displayresults method'
end

--- Displays errors from evaluate().  Must be overriden.
-- @param err The error value returned from repl:traceback().
-- @see repl:traceback
function repl:displayerror(err)
  error 'You must implement the displayerror method'
end

--- Checks whether this REPL object has loaded the given plugin.
-- @param plugin The plugin that the REPL may have loaded.
function repl:hasplugin(plugin)
  return self._plugins[plugin]
end

function repl:hasfeature(feature)
  return self._features[feature]
end

function repl:requirefeature(feature)
  if not self:hasfeature(feature) then
    error(sformat('required feature %q not present', feature), 2)
  end
end

function repl:ifplugin(plugin, action)
  if self:hasplugin(plugin) then
    action()
  else
    local pending_actions = self._ifplugin[plugin]

    if not pending_actions then
      pending_actions        = {}
      self._ifplugin[plugin] = pending_actions
    end

    pending_actions[#pending_actions + 1] = action
  end
end

local function setup_before(repl)
  local mt = {}

  function mt:__newindex(key, value)
    if type(value) ~= 'function' then
      error(tostring(value) .. " is not a function", 2)
    end

    local old_value = repl[key]

    if old_value == nil then
      error(sformat("The '%s' method does not exist", key), 2)
    end

    repl[key] = function(...)
      value(...)
      return old_value(...)
    end
  end

  return setmetatable({}, mt)
end

local function setup_after(repl)
  local mt = {}

  function mt:__newindex(key, value)
    if type(value) ~= 'function' then
      error(tostring(value) .. " is not a function", 2)
    end

    local old_value = repl[key]

    if old_value == nil then
      error(sformat("The '%s' method does not exist", key), 2)
    end

    repl[key] = function(...)
      local _, results = gather_results(true, old_value(...))
      value(...)
      return unpack(results, 1, results.n)
    end
  end

  return setmetatable({}, mt)
end

local function setup_around(repl)
  local mt = {}

  function mt:__newindex(key, value)
    if type(value) ~= 'function' then
      error(tostring(value) .. " is not a function", 2)
    end

    local old_value = repl[key]

    if old_value == nil then
      error(sformat("The '%s' method does not exist", key), 2)
    end

    repl[key] = function(self, ...)
      return value(self, old_value, ...)
    end
  end

  return setmetatable({}, mt)
end

local function setup_override(repl)
  local mt = {}

  function mt:__newindex(key, value)
    if type(value) ~= 'function' then
      error(tostring(value) .. " is not a function", 2)
    end

    local old_value = repl[key]

    if old_value == nil then
      error(sformat("The '%s' method does not exist", key), 2)
    end

    repl[key] = value
  end

  return setmetatable({}, mt)
end

local function setup_repl(repl)
  local mt = {}

  function mt:__newindex(key, value)
    local old_value = repl[key]

    if old_value ~= nil then
      error(sformat("The '%s' method already exists", key), 2)
    end

    repl[key] = value
  end

  function mt:__index(key)
    local value = repl[key]

    if type(value) == 'function' then
      -- XXX cache this?
      return function(_, ...)
        return value(repl, ...)
      end
    end

    return value
  end

  return setmetatable({}, mt)
end

-- TODO use lua-procure for this (eventually)
local function findchunk(name)
  for _, loader in pairs(package.loaders) do
    local chunk = loader(name)

    if type(chunk) == 'function' then
      return chunk
    end
  end

  error('unable to locate plugin', 3)
end

function repl:loadplugin(chunk)
  if self:hasplugin(chunk) then
    error(sformat('plugin %q has already been loaded', tostring(chunk)), 2)
  end
  self._plugins[chunk] = true

  local actions         = self._ifplugin[chunk]
  self._ifplugin[chunk] = nil

  if type(chunk) == 'string' then
    chunk = findchunk('repl.plugins.' .. chunk)
  end

  local plugin_env = {
    repl     = setup_repl(self),
    before   = setup_before(self),
    after    = setup_after(self),
    around   = setup_around(self),
    override = setup_override(self),
    init     = function() end,
  }

  local function ro_globals(_, key, _)
    error(sformat('global environment is read-only (key = %q)', key), 2)
  end

  plugin_env._G       = plugin_env
  plugin_env.features = {}
  setmetatable(plugin_env, { __index = _G, __newindex = ro_globals })

  setfenv(chunk, plugin_env)
  chunk()

  local features = plugin_env.features or {}

  if type(features) == 'string' then
    features = { features }
  end

  for _, feature in ipairs(features) do
    if self._features[feature] then
      error(sformat('feature %q already present', feature), 2)
    end

    self._features[feature] = true
  end

  if actions then
    for _, action in ipairs(actions) do
      action()
    end
  end
end

-- XXX how to guarantee this gets called?
function repl:shutdown()
end

function repl:getcontext()
  return _G
end

return repl
