local base = pl.class()
base.type = "package"
base._name = "base"

base._initialized = false

function base:_init ()
  SU.dump("prototype package")
  self._initialized = true
end

function base:unload ()
  if self._initialized then
    self._initialized = false
  end
end

base.documentation = ""

return base
