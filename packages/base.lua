local base = pl.class()
base.type = "package"
base._name = "base"

base._initialized = false
base.class = nil

function base:_init (_)
  self.class = SILE.documentState.documentClass
  if not self.class then
    SU.error("Attempted to initialize package before class, should have been queued in the preamble", true)
  end
  self:declareSettings()
  self:registerRawHandlers()
  self:registerCommands()
  self._initialized = true
end

function base.declareSettings (_) end

function base.registerRawHandlers (_) end

function base.registerCommands (_) end

return base
