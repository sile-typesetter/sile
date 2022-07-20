local base = pl.class()
base.type = "package"
base._name = "base"

base._initialized = false
base.class = nil

function base:_init (class)
  self.class = class
  self:declareSettings()
  self:registerCommands()
  self._initialized = true
end

function base:declareSettings () end

function base:registerCommands () end

return base
