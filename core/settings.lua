local deprecator = function ()
   SU.deprecated("SILE.settings.*", "SILE.settings:*", "0.13.0", "0.15.0")
   return SILE.settings
end

local settings = pl.class()

function settings:_init ()
   self.state = {}
   self.declarations = {}
   self.stateQueue = {}
   self.defaults = {}

   self:declare({
      parameter = "document.language",
      type = "string",
      default = "en",
      help = "Locale for localized language support",
   })

   self:declare({
      parameter = "document.parindent",
      type = "glue",
      default = SILE.nodefactory.glue("20pt"),
      help = "Glue at start of paragraph",
   })

   self:declare({
      parameter = "document.baselineskip",
      type = "vglue",
      default = SILE.nodefactory.vglue("1.2em plus 1pt"),
      help = "Leading",
   })

   self:declare({
      parameter = "document.lineskip",
      type = "vglue",
      default = SILE.nodefactory.vglue("1pt"),
      help = "Leading",
   })

   self:declare({
      parameter = "document.parskip",
      type = "vglue",
      default = SILE.nodefactory.vglue("0pt plus 1pt"),
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
         local parameter = SU.required(options, "parameter", "\\set command")
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
               self:set(parameter, value, makedefault, reset)
               SILE.process(content)
            end)
         else
            self:set(parameter, value, makedefault, reset)
         end
      end,
      "Set a SILE parameter <parameter> to value <value> (restoring the value afterwards if <content> is provided)",
      nil,
      true
   )
end

function settings:pushState ()
   if not self then
      self = deprecator()
   end
   table.insert(self.stateQueue, self.state)
   self.state = pl.tablex.copy(self.state)
end

function settings:popState ()
   if not self then
      self = deprecator()
   end
   self.state = table.remove(self.stateQueue)
end

function settings:declare (spec)
   if not spec then
      self, spec = deprecator(), self
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
      SU.debug("settings", "Attempt to re-declare setting: " .. spec.parameter)
      return
   end
   self.declarations[spec.parameter] = spec
   self:set(spec.parameter, spec.default, true)
end

--- Reset all settings to their default value.
function settings:reset ()
   if not self then
      self = deprecator()
   end
   for k, _ in pairs(self.state) do
      self:set(k, self.defaults[k])
   end
end

--- Restore all settings to the value they had in the top-level state,
-- that is at the head of the settings stack (normally the document
-- level).
function settings:toplevelState ()
   if not self then
      self = deprecator()
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

function settings:get (parameter)
   -- HACK FIXME https://github.com/sile-typesetter/sile/issues/1699
   -- See comment on set() below.
   if parameter == "current.parindent" then
      return SILE.typesetter and SILE.typesetter.state.parindent
   end
   if not parameter then
      self, parameter = deprecator(), self
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
      self, parameter, value, makedefault, reset = deprecator(), self, parameter, value, makedefault
   end
   if not self.declarations[parameter] then
      SU.error("Undefined setting '" .. parameter .. "'")
   end
   if reset then
      if makedefault then
         SU.error("Can't set a new default and revert to and old default setting at the same time!")
      end
      value = self.defaults[parameter]
   else
      value = SU.cast(self.declarations[parameter].type, value)
   end
   self.state[parameter] = value
   if makedefault then
      self.defaults[parameter] = value
   end
end

function settings:temporarily (func)
   if not func then
      self, func = deprecator(), self
   end
   self:pushState()
   func()
   self:popState()
end

function settings:wrap () -- Returns a closure which applies the current state, later
   if not self then
      self = deprecator()
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
