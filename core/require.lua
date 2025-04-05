local function require_ (dependency, pathprefix, deprecation_ack)
   if pathprefix and not deprecation_ack then
      local notice = string.format(
         [[
  Please don't use the path prefix mechanism; it was intended to provide
  alternate paths to override core components but never worked well and is
  causing portability problems. Just use Lua idiomatic module loading:
      SILE.require("%s", "%s") → SILE.require("%s.%s")]],
         dependency,
         pathprefix,
         pathprefix,
         dependency
      )
      SU.deprecated("SILE.require", "SILE.require", "0.13.0", nil, notice)
   end
   dependency = dependency:gsub(".lua$", "")
   local status, lib
   if pathprefix then
      -- Note this is not a *path*, it is a module identifier:
      -- https://github.com/sile-typesetter/sile/issues/1861
      status, lib = pcall(require, pl.stringx.join(".", { pathprefix, dependency }))
   end
   if not status then
      local prefixederror = lib
      status, lib = pcall(require, dependency)
      if not status then
         SU.error(
            ("Unable to find module '%s'%s"):format(
               dependency,
               SILE.traceback and ((pathprefix and "\n  " .. prefixederror or "") .. "\n  " .. lib) or ""
            )
         )
      end
   end
   local class = SILE.documentState.documentClass
   if not class and not deprecation_ack then
      SU.warn(string.format(
         [[
            SILE.require() is only supported in documents, packages, or class init

            It will not function fully before the class is instantiated. Please just use
            the Lua require() function directly:

              SILE.require("%s") → require("%s")
         ]],
         dependency,
         dependency
      ))
   end
   if type(lib) == "table" and class then
      if lib.type == "package" then
         lib(class)
      else
         class:initPackage(lib)
      end
   end
   return lib
end

local function resolveFile (filename, pathprefix)
   local candidates = {}
   -- Start with the raw file name as given prefixed with a path if requested
   if pathprefix then
      candidates[#candidates + 1] = pl.path.join(pathprefix, "?")
   end
   -- Also check the raw file name without a path
   candidates[#candidates + 1] = "?"
   -- Iterate through the directory of the master file, the SILE_PATH variable, and the current directory
   -- Check for prefixed paths first, then the plain path in that fails
   if SILE.masterDir then
      for path in SU.gtoke(SILE.masterDir .. ";" .. tostring(os.getenv("SILE_PATH")), ";") do
         if path.string and path.string ~= "nil" then
            if pathprefix then
               candidates[#candidates + 1] = pl.path.join(path.string, pathprefix, "?")
            end
            candidates[#candidates + 1] = pl.path.join(path.string, "?")
         end
      end
   end
   -- Return the first candidate that exists, also checking the .sil suffix
   local path = table.concat(candidates, ";")
   local resolved, err = package.searchpath(filename, path, "/")
   if resolved then
      if SILE.makeDeps then
         SILE.makeDeps:add(resolved)
      end
   elseif SU.debugging("paths") then
      SU.debug("paths", ("Unable to find file '%s': %s"):format(filename, err))
   end
   return resolved
end

return {
   require = require_,
   resolveFile = resolveFile,
}
