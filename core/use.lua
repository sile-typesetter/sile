local function suggest_luarocks (module)
   local guessed_module_name = module:gsub(".*%.", "") .. ".sile"
   return ([[

      If the expected module is a 3rd party extension you may need to install
      it using LuaRocks. The details of how to do this are highly dependent on
      your system and preferred installation method, but as an example
      installing a 3rd party SILE module to a project-local tree where might
      look like this:

        luarocks --lua-version %s --tree lua_modules install %s

      This will install the LuaRock(s) to your project. Note this takes
      advantage of the fact that SILE checks for modules in the path
      'lua_modules' relative to the current input file by default. SILE also
      automatically checks the default system Lua path by default, so using
      `--global` will also work.

      In the event you use a different path to the LuaRocks tree, you must also
      set an environment variable to teach SILE about how to find the tree
      *before* it runs. This can be aided by asking LuaRocks to come up with a
      path and evaling the result in the shell before running SILE. This only
      needs to be done once in each shell, (obviously substituting 'path' for
      your actual path):

        eval $(luarocks --lua-version %s --tree path)

      Thereafter running `sile` as normal in the same shell should work as
      expected. This code can be used in your shell's initialization script
      to avoid having to do it manually in each new shell. This is true for
      user home directory installations using `--local` or any specific values
      for `--tree` other than 'lua_modules'.

      As an anternative to setting up environment variables when using a
      non-default tree location, you can use the `--luarocks-tree` option to
      add path(s) at runtime. This is simpler to type, but must be used on each
      and every invocation. The value for tree should be the same as used when
      installing the LuaRock(s), or an appropriate full path to the location
      used by `--local` (generally "$HOME/.luarocks"):

        sile --luarocks-tree path %s

    ]]):format(SILE.lua_version, guessed_module_name, SILE.lua_version, pl.stringx.join(" ", _G.arg or {}))
end

local function use (module, options, reload)
   local status, pack
   if type(module) == "string" then
      if module:match("/") then
         SU.warn(([[
            Module names should not include platform-specific path separators

            Using slashes like '/' or '\' in a module name looks like a path segment. This
            may appear to work in some cases, but breaks cross platform compatibility.
            Even on the platform with the matching separator, this can lead to packages
            getting loaded more than once because Lua will cache one each of the different
            formats. Please use '.' separators which are automatically translated to the
            correct platform one. For example a correct use statement would be:

              \use[module=%s] instead of \use[module=%s].
         ]]):format(module:gsub("/", "."), module))
      end
      status, pack = pcall(require, module)
      if not status then
         SU.error(
            ("Unable to use '%s':\n%s%s"):format(
               module,
               SILE.traceback and ("    Lua " .. pack) or "",
               suggest_luarocks(module)
            )
         )
      end
   elseif type(module) == "table" then
      pack = module
   end
   local name = pack._name
   local class = SILE.documentState.documentClass
   if not pack.type then
      SU.error("Modules must declare their type")
   elseif pack.type == "class" then
      SILE.classes[name] = pack
      if class then
         SU.error("Cannot load a class after one is already instantiated")
      end
      SILE.scratch.class_from_uses = pack
   elseif pack.type == "inputter" then
      SILE.inputters[name] = pack
      SILE.inputter = pack(options)
   elseif pack.type == "outputter" then
      SILE.outputters[name] = pack
      SILE.outputter = pack(options)
   elseif pack.type == "shaper" then
      SILE.shapers[name] = pack
      SILE.shaper = pack(options)
   elseif pack.type == "typesetter" then
      SILE.typesetters[name] = pack
      SILE.typesetter = pack(options)
   elseif pack.type == "linebreaker" then
      SILE.linebreakers[name] = pack
      if SILE.typesetter then
         SILE.typesetter.linebreaker = pack(options)
      end
   elseif pack.type == "pagebuilder" then
      SILE.pagebuilders[name] = pack
      if SILE.typesetter then
         SILE.typesetter.pagebuilder = pack(options)
      end
   elseif pack.type == "package" then
      SILE.packages[pack._name] = pack
      if class then
         class:loadPackage(pack, options, reload)
      else
         table.insert(SILE.input.preambles, { pack = pack, options = options })
      end
   end
end

return use
