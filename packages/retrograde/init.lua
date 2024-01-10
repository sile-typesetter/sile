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
   ["0.15.0"] = {
      ["shaper.spaceenlargementfactor"] = 1.2,
      ["document.parindent"] = "20pt",
   },
   ["0.9.5"] = {
      ["font.family"] = "Gentium Basic",
   },
}

function package:_init (options)
  base._init(self, options)
  self:recede(options.target)
end

function package:recede (target)
   self:recede_defaults(target)
end

function package._prep (_, target, type)
  target = semver(target and target or SILE.version)
  SU.debug("retrograde", ("Targeting %s changes back as far as the release of SILE v%s."):format(type, target))
  local terminal = function (version)
   SU.debug("retrograde", ("The next set of %s changes is from the release of SILE v%s, stopping."):format(type, version))
  end
  return target, terminal
end

function package:recede_defaults (target)
  local semvertarget, terminal = self:_prep(target, "default")
  local target_hit = false
  for version, settings in pl.tablex.sort(self.default_settings, semver_descending) do
     version = semver(version)
     if target_hit then
        terminal()
        break
     end
     for parameter, value in pairs(settings) do
        SU.debug("retrograde", ("Resetting '%s' to '%s' as it was prior to v%s."):format(parameter, tostring(value), version))
        SILE.settings:set(parameter, value, true)
     end
     if version <= semvertarget then target_hit = true end
  end
end

function package:registerCommands ()

  self:registerCommand("recede", function (options, content)
     SILE.call("recede-defaults", options, content)
  end)

  self:registerCommand("recede-defaults", function (options, content)
     if content then
        SILE.settings:temporarily(function ()
           self:recede_defaults(options.target)
        end)
     else
        self:recede_defaults(options.target)
     end
  end)

end

local doctarget = "v" .. tostring(semver(SILE.version))
package.documentation = ([[
\begin{document}

From time to time, the default behavior of a function or value of a setting in SILE might change with a new release.
If these changes are expected to cause document reflows they will be noted in release notes as breaking changes.
That generally means old documents will have to be updated to keep rending the same way.
On a best-effort basis (not a guarantee) this package tries to restore earlier default behaviors and settings.

For settings this is relatively simple.
You just set the old default value explicitly in your document or project.
But first, knowing what those are requires a careful reading of the release notes.
Then you have to chase down the incantations to set the old values.
This package tries to restore as many previous setting values as possible to make old documents render like they would have in previous releases without changing the documents themselves (beyond loading this package).

For functions things are a little more complex, but for as many cases as possible we'll try to allow swapping old versions of code.

None of this is a guarantee that your old document will be stable in new versions of SILE.
All of this is a danger zone.

From inside a document, use \autodoc:command{\use[module=packages.retrograde,target=%s]} to load features from SILE %s.

This can also be triggered from the command line with no changes to a document:

\begin{autodoc:codeblock}
$ sile -u 'packages.retrograde[target=%s]'
\end{autodoc:codeblock}

\end{document}
]]):format(doctarget, doctarget, doctarget)

return package
