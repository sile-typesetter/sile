local base = require("packages.base")

local package = pl.class(base)
package._name = "retrograde"

local semver = require("rusile").semver

local semver_descending = function (a, b)
   a, b = semver(a), semver(b)
   return a > b
end

-- Default settings that have gone out of fashion
package.default_settings = {
   ["0.15.14"] = {
      ["font.family"] = { "Gentium Book", "Gentium Plus" },
   },
   ["0.15.11"] = {
      -- This was totally a *bug* fix not a pure defaults change, but since many projects ended up relying on the buggy
      -- behavior to have any stretchness in their spaces at all, the "fix" breaks a lot of projects. Just enabling this
      -- isn't a clean revert since if people were mixing and matching methods this wouldn't make everything the same,
      -- but it's more likely to work than having this setting unexpectedly *actually* disabled.
      ["shaper.variablespaces"] = { true, true },
   },
   ["0.15.10"] = {
      ["typesetter.brokenpenalty"] = { 100, 0 },
   },
   ["0.15.0"] = {
      ["shaper.spaceenlargementfactor"] = { 1, 1.2 },
      ["document.parindent"] = { "G<1bs>", "20pt" },
   },
   ["0.9.5"] = {
      ["font.family"] = { "Gentium Plus", "Gentium Basic" },
   },
}

local function _v14_aligns (content)
   SILE.settings:set("typesetter.parfillskip", SILE.types.node.glue())
   SILE.settings:set("document.parindent", SILE.types.node.glue())
   SILE.settings:set("document.spaceskip", SILE.types.length("1spc", 0, 0))
   SILE.process(content)
   SILE.call("par")
end

package.shim_commands = {
   ["0.15.0"] = {
      ["center"] = function (_)
         return function (_, content)
            if #SILE.typesetter.state.nodes ~= 0 then
               SU.warn("\\center environment started after other nodes in a paragraph, may not center as expected")
            end
            SILE.settings:temporarily(function ()
               SILE.settings:set("document.rskip", SILE.types.node.hfillglue())
               SILE.settings:set("document.lskip", SILE.types.node.hfillglue())
               _v14_aligns(content)
            end)
         end
      end,
      ["raggedright"] = function (_)
         return function (_, content)
            SILE.settings:temporarily(function ()
               SILE.settings:set("document.rskip", SILE.types.node.hfillglue())
               _v14_aligns(content)
            end)
         end
      end,
      ["raggedleft"] = function (_)
         return function (_, content)
            SILE.settings:temporarily(function ()
               SILE.settings:set("document.lskip", SILE.types.node.hfillglue())
               _v14_aligns(content)
            end)
         end
      end,
   },
}

package.shim_classes = {
   ["0.15.0"] = {
      ["classes.base.newPar"] = function ()
         local newPar = SILE.documentState.documentClass.newPar
         SILE.documentState.documentClass.newPar = function (typesetter)
            newPar(typesetter)
            SILE.settings:set("current.parindent", nil)
         end
         return function ()
            SILE.classes.book.newPar = newPar
         end
      end,
      ["classes.base.endPar"] = function ()
         local endPar = SILE.documentState.documentClass.endPar
         SILE.documentState.documentClass.endPar = function (typesetter)
            local current_parindent = SILE.settings:get("current.parindent")
            endPar(typesetter)
            SILE.settings:set("current.parindent", current_parindent)
         end
         return function ()
            SILE.classes.book.endPar = endPar
         end
      end,
   },
}

function package:_init (options)
   base._init(self, options)
   self:recede(options.target)
end

function package:recede (target)
   self:recede_defaults(target)
   self:recede_classes(target)
   self:recede_commands(target)
end

function package:_prep (target, type)
   target = semver(target and target or SILE.version)
   SU.debug("retrograde", ("Targeting changes to %s since the release of SILE v%s."):format(type, target))
   local terminal = function (version)
      SU.debug(
         "retrograde",
         ("The next set of changes to %s is from the release of SILE v%s, stopping."):format(type, version)
      )
   end
   return target, terminal
end

function package:recede_defaults (target)
   local semvertarget, terminal = self:_prep(target, "defaults")
   for version, settings in pl.tablex.sort(self.default_settings, semver_descending) do
      version = semver(version)
      if version <= semvertarget then
         terminal(version)
         break
      end
      for parameter, values in pairs(settings) do
         local fresh, legacy = values[1], values[2]
         local current = SILE.settings:get(parameter)
         if tostring(current) ~= tostring(fresh) then
            SU.debug(
               "retrograde",
               ("NOT resetting '%s' as the current value '%s' is not the new default '%s' suggesting other user overrides."):format(
                  parameter,
                  tostring(current),
                  tostring(fresh)
               )
            )
         else
            SU.debug(
               "retrograde",
               ("Resetting '%s' from '%s' to '%s' as it was prior to v%s."):format(
                  parameter,
                  tostring(fresh),
                  tostring(legacy),
                  version
               )
            )
            SILE.settings:set(parameter, legacy, true)
         end
      end
   end
end

function package:recede_classes (target)
   local semvertarget, terminal = self:_prep(target, "classes")
   local reverters = {}
   for version, callbacks in pl.tablex.sort(self.shim_classes, semver_descending) do
      version = semver(version)
      if version <= semvertarget then
         terminal(version)
         break
      end
      for widget, callback in pairs(callbacks) do
         SU.debug("retrograde", ("Shimming '%s' to behavior similar to prior to v%s."):format(widget, version))
         local reverter = callback()
         reverters[widget] = reverter
      end
   end
   return function ()
      for _, reverter in pairs(reverters) do
         reverter()
      end
   end
end

function package:recede_commands (target)
   local semvertarget, terminal = self:_prep(target, "commands")
   local currents = {}
   for version, commands in pl.tablex.sort(self.shim_commands, semver_descending) do
      version = semver(version)
      if version <= semvertarget then
         terminal(version)
         break
      end
      for command, get_function in pairs(commands) do
         SU.debug("retrograde", ("Shimming command '%s' to behavior similar to prior to v%s."):format(command, version))
         local current = SILE.Commands[command]
         currents[command] = current
         SILE.Commands[command] = get_function(current)
      end
   end
   local function reverter ()
      for command, current in pairs(currents) do
         SILE.Commands[command] = current
      end
   end
   return reverter
end

function package:registerCommands ()
   self:registerCommand("recede", function (options, content)
      SILE.call("recede-defaults", options, content)
   end)

   self:registerCommand("recede-defaults", function (options, content)
      if content then
         SILE.settings:temporarily(function ()
            self:recede_defaults(options.target)
            SILE.process(content)
         end)
      else
         self:recede_defaults(options.target)
      end
   end)

   self:registerCommand("recede-classes", function (options, content)
      if content then
         SILE.settings:temporarily(function ()
            local reverter = self:recede_classes(options.target)
            SILE.process(content)
            reverter()
         end)
      else
         self:recede_classes(options.target)
      end
   end)

   self:registerCommand("recede-commands", function (options, content)
      if content then
         local reverter = self:recede_commands(options.target)
         SILE.process(content)
         reverter()
      else
         self:recede_commands(options.target)
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
