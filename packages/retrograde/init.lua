local base = require("packages.base")

local package = pl.class(base)
package._name = "retrograde"

local semver = require("semver")

local semver_descending = function (a, b)
   a, b = semver(a), semver(b)
   return a > b
end

-- Default settings that have gone out of fashion
package.default_settings = {
}

function package:_init (options)
  base._init(self, options)
  self:defaults(options.target)
end

function package:defaults (target)
  target = semver(target and target or SILE.version)
  local target_hit = false
  for version, settings in pl.tablex.sort(self.default_settings, semver_descending) do
     for parameter, value in pairs(settings) do
        SILE.settings:set(parameter, value, true)
     end
     if target_hit then break end
     if semver(version) <= target then target_hit = true end
  end
end

function package:registerCommands ()

  self:registerCommand("defaults", function (options, content)
     if content then
        SILE.settings:temporarily(function ()
           self:defaults(options.target)
        end)
     else
        self:defaults(options.target)
     end
  end)

end

return package
