local module = pl.class()

module._name = "base"

module._initialized = false

-- A list (ordered) of methods to run on initialization, but we also track which function signatures have been run
-- already in this table per module type so we don't duplicate or clobber things that have been done. Since we're
-- tracknig the Lua function hash not the method name this shouldn't catch overridden methods.
local run_once = {
   "_declareOptions",
   "declareOptions",
   "_declareSettings",
   "declareSettings",
   "_registerRawHandlers",
   "registerRawHandlers",
   "_registerCommands",
   "registerCommands",
   "_declareFrames",
   "declareFrames",
   "_setOptions",
   "setOptions",
}

local function script_path ()
   local src = debug.getinfo(3, "S").source:sub(2)
   local base = src:match("(.*[/\\])")
   return base
end

function module:_init (options)
   self.commands = SILE.commands:forModule(self)
   self.frames = SILE.frames:forModule(self)
   self.settings = SILE.settings:forModule(self)
   if not self.type then
      SU.error("Attempted it initialize module with no type")
   end
   -- Avoid direct use of base modules intended as prototypes
   if self._name == "base" then
      local type_group = "SILE." .. self.type .. "s"
      SU.deprecated(type_group .. ".base", type_group .. ".default", "0.15.11", "0.16.0")
   end
   -- Ease access to assets relative to module
   self.basedir = script_path()
   for _, method in ipairs(run_once) do
      -- Note string.format(%p) would be nicer than tostring() but only LuaJIT and Lua 5.4 support it
      local method_hash = tostring(self[method]) .. self.type
      SU.debug("modules", self.type, self._name, method, run_once[method_hash] and "(skip)")
      if not run_once[method_hash] then
         run_once[method_hash] = true
         if method:match("Options$") then
            self[method](self, options)
         else
            self[method](self)
         end
      end
   end
end

function module:_post_init ()
   self._initialized = true
end

function module:_declareOptions () end
function module:declareOptions () end

function module:_declareSettings () end
function module:declareSettings () end

function module:_registerRawHandlers () end
function module:registerRawHandlers () end

function module:registerRawHandler (format, callback)
   SILE.rawHandlers[format] = callback
end

function module:_registerCommands () end
function module:registerCommands () end

--- Register a function as a SILE command.
-- Takes any Lua function and registers it for use as a SILE command (which will in turn be used to process any content
-- nodes identified with the command name.
--
-- @tparam string name Name of cammand to register.
-- @tparam function func Callback function to use as command handler.
-- @tparam[opt] nil|string help User friendly short usage string for use in error messages, documentation, etc.
-- @tparam[opt] nil|string pack Information identifying the module registering the command for use in error and usage
-- messages. Usually auto-detected.
function module:registerCommand (name, func, help, pack, defaults)
   SU.deprecated("module:registerCommand", "module.commands:register", "0.16.0", "0.17.0")
   return self.commands:register(name, func, help, pack, defaults)
end

function module:_declareFrames () end
function module:declareFrames () end

function module:_setOptions () end
function module:setOptions () end

return module
