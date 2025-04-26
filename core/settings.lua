--- core settings registry instance
--- @module SILE.settings

local deprecator = function ()
   SU.deprecated("SILE.settings.*", "SILE.settings:*", "0.13.0", "0.15.0")
end

--- @type settings
local registry = require("types.registry")
local settings = pl.class(registry)
settings._name = "settings"

function settings:_init ()
   registry._init(self)
   self.state = {}
   self.stateQueue = {}
   self.hooks = {}

   self:declare({
      parameter = "document.parindent",
      type = "glue",
      default = SILE.types.node.glue("1bs"),
      help = "Glue at start of paragraph",
   })

   self:declare({
      parameter = "document.baselineskip",
      type = "vglue",
      default = SILE.types.node.vglue("1.2em plus 1pt"),
      help = "Leading",
   })

   self:declare({
      parameter = "document.lineskip",
      type = "vglue",
      default = SILE.types.node.vglue("1pt"),
      help = "Leading",
   })

   self:declare({
      parameter = "document.parskip",
      type = "vglue",
      default = SILE.types.node.vglue("0pt plus 1pt"),
      help = "Leading",
   })

   self:declare({
      parameter = "document.spaceskip",
      type = "length or nil",
      default = nil,
      help = "The length of a space (if nil, then measured from the font)",
   })

   self:declare({
      parameter = "document.rskip",
      type = "glue or nil",
      default = nil,
      help = "Skip to be added to right side of line",
   })

   self:declare({
      parameter = "document.lskip",
      type = "glue or nil",
      default = nil,
      help = "Skip to be added to left side of line",
   })

   self:declare({
      parameter = "document.zenkakuchar",
      default = "あ",
      type = "string",
      help = "The character measured to determine the length of a zenkaku width (全角幅)",
   })

   SILE.commands:register(self, "set", function (options, content)
      local makedefault = SU.boolean(options.makedefault, false)
      local reset = SU.boolean(options.reset, false)
      local value = options.value
      if content and (type(content) == "function" or content[1]) then
         if makedefault then
            SU.warn(
               "Are you sure meant to set default settings *and* pass content to ostensibly apply them to temporarily?"
            )
         end
         self:temporarily(parent, function ()
            if options.parameter then
               local parameter = SU.required(options, "parameter", "\\set command")
               self:set(parent, parameter, value, makedefault, reset)
            end
            SILE.process(content)
         end)
      else
         local parameter = SU.required(options, "parameter", "\\set command")
         self:set(parent, parameter, value, makedefault, reset)
      end
   end, "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)")

   return registry._init(self, parent)
end

--- Stash the current values of all settings in a stack to be returned to later
function settings:pushState (_parent)
   if not self then
      return deprecator()
   end
   table.insert(self.stateQueue, self.state)
   self.state = pl.tablex.copy(self.state)
end

--- Return the most recently pushed set of values in the setting stack
function settings:popState (parent)
   if not self then
      return deprecator()
   end
   local previous = self.state
   self.state = table.remove(self.stateQueue)
   for parameter, oldvalue in pairs(previous) do
      if self.hooks[parameter] then
         local newvalue = self.state[parameter]
         if oldvalue ~= newvalue then
            self:set(parent, parameter, newvalue)
         end
      end
   end
   self:_runAllHooks(parent)
end

--- Declare a new setting
function settings:declare (parent, spec)
   if not spec then
      return deprecator()
   end
   if self:exists(parent, spec.parameter) then
      SU.debug("settings", "WARNING: Redeclaring setting", spec.parameter)
   else
      self._registry[spec.parameter] = {}
      self.hooks[spec.parameter] = {}
      if spec.hook then
         self:registerHook(parent, spec.parameter, spec.hook)
      end
   end
   local callback = function (value)
      self:runHooks(parent, spec.parameter, value)
   end
   local setting = SILE.types.setting(spec.parameter, spec.type, spec.default, spec.help, callback)
   return self:push(parent, setting)
end

--- Reset all settings to their registered default values.
function settings:reset (_parent)
   for _, setting in pairs(self.state) do
      setting:reset()
   end
end

--- Restore all settings to the value they had in the top-level state,
-- that is at the tap of the settings stack (normally the document level).
function settings:toplevelState (parent)
   if not self then
      return deprecator()
   end
   if #self.stateQueue ~= 0 then
      for parameter, _ in pairs(self.state) do
         -- Bypass self:set() as the latter performs some tests and a cast,
         -- but the setting might not have been defined in the top level state
         local setting = self:pull(parent, parameter)
         setting.value = self.stateQueue[1][parameter]
      end
   end
end

--- Get the value of a setting
-- @tparam string parameter The full name of the setting to fetch.
-- @return Value of setting
function settings:get (parent, parameter)
   -- HACK FIXME https://github.com/sile-typesetter/sile/issues/1699
   -- See comment on set() below.
   if parameter == "current.parindent" then
      return SILE.typesetter and SILE.typesetter.state.parindent
   end
   if not parameter then
      return deprecator()
   end
   local setting = self:pull(parent, parameter)
   if not setting then
      SU.error("Undefined setting '" .. parameter .. "'")
   end
   return setting:get()
end

--- Set the value of a setting
-- @tparam string parameter The full name of the setting to change.
-- @param value The new value to change it to.
-- @tparam[opt=false] boolean makedefault Whether to make this the new default value.
-- @tparam[opt=false] boolean reset Whether to reset the value to the current default value.
function settings:set (parent, parameter, value, makedefault, reset)
   -- HACK FIXME https://github.com/sile-typesetter/sile/issues/1699
   -- Anything dubbed current.xxx should likely NOT be a "setting" (subject
   -- to being pushed/popped via temporary stacking) and actually has its
   -- own lifecycle (e.g. reset for the next paragraph).
   -- These should be rather typesetter states, or something to that extent
   -- yet to clarify. Notably, current.parindent falls in that category,
   -- BUT probably current.hangAfter and current.hangIndent too.
   -- To avoid breaking too much code yet without being sure of the solution,
   -- we implement a hack of sorts for current.parindent only.
   -- Note moreover that current.parindent is currently probably a bad concept
   -- anyway:
   --   - It can be nil (= document.parindent applies)
   --   - It can be a zero-glue (\noindent, ragged environments, etc.)
   --   - It can be a valued glue set to document.parindent
   --     (e.g. from \indent, and document.parindent thus applies)
   --   - It could be another valued glue (uh, use case to ascertain)
   -- What we would _likely_ only need to track is whether document.parindent
   -- applies or not on the paragraph just composed afterwards...
   if parameter == "current.parindent" then
      if SILE.typesetter and not SILE.typesetter.state.hmodeOnly then
         SILE.typesetter.state.parindent = SU.cast("glue or nil", value)
      end
      return
   end
   if type(self) ~= "table" then
      return deprecator()
   end
   local setting = self:pull(parent, parameter)
   if not setting then
      SU.error("Undefined setting '" .. parameter .. "'")
   end
   if reset then
      if makedefault then
         SU.error("Can't set a new default and revert to and old default setting at the same time")
      end
      SU.deprecated("settings:set(parameter, _, _, _, true)", "settings:reset(parameter)", "0.16.0", "0.17.0")
      setting:reset()
   else
      -- if makedefault then
      --    SU.deprecated("settings:set(parameter, value, _, true)", "settings:setDefault(parameter, value)", "0.16.0", "0.17.0")
      -- end
      setting:set(value, makedefault)
   end
end

function settings:reset(parent, parameter)
   local setting = self:pull(parent, parameter)
   setting:reset()
end

--- Register a callback hook to be run when a setting changes.
-- @tparam string parameter Name of the setting to add a hook to.
-- @tparam function func Callback function accepting one argument (the new value).
function settings:registerHook (_parent, parameter, func)
   table.insert(self.hooks[parameter], func)
end

--- Trigger execution of callback hooks for a given setting.
-- @tparam string parameter The name of the parameter changes.
-- @param value The new value of the setting, passed as the first argument to the hook function.
function settings:runHooks (_parent, parameter, value)
   self.state[parameter] = value
   if self.hooks[parameter] then
      for _, func in ipairs(self.hooks[parameter]) do
         SU.debug("settings", "Running setting hook for", parameter)
         func(value)
      end
   end
end

function settings:_runAllHooks (parent)
   SU.debug("settings", "Running all hooks after push/pop")
   for parameter, _ in pairs(self.hooks) do
      local setting = self:pull(parent, parameter)
      self:runHooks(parent, parameter, setting:get())
   end
end

--- Isolate a block of processing so that setting changes made during the block don't last past the block.
-- (Under the hood this just uses `:pushState()`, the processes the function, then runs `:popState()`)
-- @tparam function func A function wrapping the actions to take without affecting settings for future use.
function settings:temporarily (parent, func)
   if not func then
      return deprecator()
   end
   self:pushState(parent)
   func()
   self:popState(parent)
end

--- Create a settings wrapper function that applies current settings to later content processing.
--- @treturn function a closure function accepting one argument (content) to process using
--- typesetter settings as they are at the time of closure creation.
function settings:wrap (parent)
   if not self then
      return deprecator()
   end
   local clSettings = pl.tablex.copy(self.state)
   return function (content)
      table.insert(self.stateQueue, self.state)
      self.state = clSettings
      SILE.process(content)
      self:popState(parent)
   end
end

return settings
