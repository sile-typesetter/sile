local package = pl.class()
package.type = "package"
package._name = "base"

package._initialized = false
package.class = nil

function package:_init (_)
  self.class = SILE.documentState.documentClass or SILE.scratch.half_initialized_class
  if not self.class then
    SU.error("Attempted to initialize package before class, should have been queued in the preamble", true)
  end
  self:declareSettings()
  self:registerRawHandlers()
  self:registerCommands()
end

function package:_post_init ()
  self._initialized = true
end

function package.declareSettings (_) end

function package.registerRawHandlers (_) end

function package.registerCommands (_) end

return package
