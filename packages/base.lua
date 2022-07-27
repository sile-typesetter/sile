local class = pl.class()
class.type = "package"
class._name = "base"

class._initialized = false
class.class = nil

function class:_init (_)
  self.class = SILE.documentState.documentClass or SILE.scratch.half_initialized_class
  if not self.class then
    SU.error("Attempted to initialize package before class, should have been queued in the preamble", true)
  end
  self:declareSettings()
  self:registerRawHandlers()
  self:registerCommands()
end

function class:_post_init ()
  self._initialized = true
end

function class.declareSettings (_) end

function class.registerRawHandlers (_) end

function class.registerCommands (_) end

return class
