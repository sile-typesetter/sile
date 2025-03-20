--- core settings instance
--- @module SILE.settings

local deprecator = function ()
   SU.deprecated("SILE.settings.*", "SILE.settings:*", "0.13.0", "0.15.0")
end

--- @type settings
local settings = pl.class()

function settings:_init ()
   self.state = {}
   self.declarations = {}
   self.stateQueue = {}
   self.defaults = {}
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

   SILE.registerCommand(
      "set",
      function (options, content)
         local makedefault = SU.boolean(options.makedefault, false)
         local reset = SU.boolean(options.reset, false)
         local value = options.value
         if content and (type(content) == "function" or content[1]) then
            if makedefault then
               SU.warn(
                  "Are you sure meant to set default settings *and* pass content to ostensibly apply them to temporarily?"
               )
            end
            self:temporarily(function ()
               if options.parameter then
                  local parameter = SU.required(options, "parameter", "\\set command")
                  self:set(parameter, value, makedefault, reset)
               end
               SILE.process(content)
            end)
         else
            local parameter = SU.required(options, "parameter", "\\set command")
            self:set(parameter, value, makedefault, reset)
         end
      end,
      "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)",
      nil,
      true
   )
end

--- Stash the current values of all settings in a stack to be returned to later
function settings:pushState ()
   if not self then
      return deprecator()
   end
   table.insert(self.stateQueue, self.state)
   self.state = pl.tablex.copy(self.state)
end

--- Return the most recently pushed set of values in the setting stack
function settings:popState ()
   if not self then
      return deprecator()
   end
   local previous = self.state
   self.state = table.remove(self.stateQueue)
   for parameter, oldvalue in pairs(previous) do
      if self.hooks[parameter] then
         local newvalue = self.state[parameter]
         if oldvalue ~= newvalue then
            self:runHooks(parameter, newvalue)
         end
      end
   end
end

--- Declare a new setting
--- @tparam table specs { parameter, type, default, help, hook, ... } declaration specification
function settings:declare (spec)
   if not spec then
      return deprecator()
   end
   if spec.name then
      SU.deprecated(
         "'name' argument of SILE.settings:declare",
         "'parameter' argument of SILE.settings:declare",
         "0.10.10",
         "0.11.0"
      )
   end
   if self.declarations[spec.parameter] then
      SU.debug("settings", "Attempt to re-declare setting:", spec.parameter)
      return
   end
   self.declarations[spec.parameter] = spec
   self.hooks[spec.parameter] = {}
   if spec.hook then
      self:registerHook(spec.parameter, spec.hook)
   end
   self:set(spec.parameter, spec.default, true)
end

--- Reset all settings to their registered default values.
function settings:reset ()
   if not self then
      return deprecator()
   end
   for k, _ in pairs(self.state) do
      self:set(k, self.defaults[k])
   end
end

--- Restore all settings to the value they had in the top-level state,
-- that is at the tap of the settings stack (normally the document level).
function settings:toplevelState ()
   if not self then
      return deprecator()
   end
   if #self.stateQueue ~= 0 then
      for parameter, _ in pairs(self.state) do
         -- Bypass self:set() as the latter performs some tests and a cast,
         -- but the setting might not have been defined in the top level state
         -- (in which case, assume the default value).
         self.state[parameter] = self.stateQueue[1][parameter] or self.defaults[parameter]
      end
   end
end

--- Get the value of a setting
-- @tparam string parameter The full name of the setting to fetch.
-- @return Value of setting
function settings:get (parameter)
   -- HACK FIXME https://github.com/sile-typesetter/sile/issues/1699
   -- See comment on set() below.
   if parameter == "current.parindent" then
      return SILE.typesetter and SILE.typesetter.state.parindent
   end
   if not parameter then
      return deprecator()
   end
   if not self.declarations[parameter] then
      SU.error("Undefined setting '" .. parameter .. "'")
   end
   if type(self.state[parameter]) ~= "nil" then
      return self.state[parameter]
   else
      return self.defaults[parameter]
   end
end

--- Set the value of a setting
-- @tparam string parameter The full name of the setting to change.
-- @param value The new value to change it to.
-- @tparam[opt=false] boolean makedefault Whether to make this the new default value.
-- @tparam[opt=false] boolean reset Whether to reset the value to the current default value.
function settings:set (parameter, value, makedefault, reset)
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
   if not self.declarations[parameter] then
      SU.error("Undefined setting '" .. parameter .. "'")
   end
   if reset then
      if makedefault then
         SU.error("Can't set a new default and revert to and old default setting at the same time")
      end
      value = self.defaults[parameter]
   else
      value = SU.cast(self.declarations[parameter].type, value)
   end
   self.state[parameter] = value
   if makedefault then
      self.defaults[parameter] = value
   end
   self:runHooks(parameter, value)
end

--- Register a callback hook to be run when a setting changes.
-- @tparam string parameter Name of the setting to add a hook to.
-- @tparam function func Callback function accepting one argument (the new value).
function settings:registerHook (parameter, func)
   table.insert(self.hooks[parameter], func)
end

--- Trigger execution of callback hooks for a given setting.
-- @tparam string parameter The name of the parameter changes.
-- @param value The new value of the setting, passed as the first argument to the hook function.
function settings:runHooks (parameter, value)
   if self.hooks[parameter] then
      for _, func in ipairs(self.hooks[parameter]) do
         SU.debug("classhooks", "Running setting hook for", parameter)
         func(value)
      end
   end
end

--- Isolate a block of processing so that setting changes made during the block don't last past the block.
-- (Under the hood this just uses `:pushState()`, the processes the function, then runs `:popState()`)
-- @tparam function func A function wrapping the actions to take without affecting settings for future use.
function settings:temporarily (func)
   if not func then
      return deprecator()
   end
   self:pushState()
   func()
   self:popState()
end

--- Create a settings wrapper function that applies current settings to later content processing.
--- @treturn function a closure function accepting one argument (content) to process using
--- typesetter settings as they are at the time of closure creation.
function settings:wrap ()
   if not self then
      return deprecator()
   end
   local clSettings = pl.tablex.copy(self.state)
   return function (content)
      table.insert(self.stateQueue, self.state)
      self.state = clSettings
      SILE.process(content)
      self:popState()
   end
end

return settings
