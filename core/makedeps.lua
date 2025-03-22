local makeDeps = {
   _deps = {},

   add = function (self, filename)
      SU.debug("makedeps", "Adding:", filename)
      local resolvedFile, msg = package.searchpath(filename:gsub("^@?%./", ""), "?;" .. package.path, "/")
      if not resolvedFile then
         SU.error("Cannot resolve file '" .. filename .. "' as a dependency:" .. msg)
      end
      self._deps[resolvedFile] = true
   end,

   add_modules = function (self)
      for dep, _ in pairs(package.loaded) do
         if dep ~= "_G" then
            SU.debug("makedeps", "Adding if module is loadable file:", dep)
            local resolvedFile = package.searchpath(dep:gsub("%.", "/"), package.path, "/")
            if resolvedFile then
               self._deps[resolvedFile] = true
            end
         end
      end
   end,

   write = function (self)
      self:add_modules()
      if type(self.filename) ~= "string" then
         self.filename = pl.path.splitext(SILE.input.filenames[1]) .. ".d"
      end
      local depfile, err = io.open(self.filename, "w")
      if not depfile then
         return SU.error(err)
      end
      local target = ("%s %s: %s\n"):format(SILE.outputter:getOutputFilename(), self.filename, self._deps)
      depfile:write(target)
      depfile:close()
   end,
}

setmetatable(makeDeps._deps, {
   __tostring = function (self)
      local deps = {}
      for dep, _ in pairs(self) do
         deps[#deps + 1] = dep
      end
      table.sort(deps, function (a, b)
         return a < b
      end)
      return table.concat(deps, " ")
   end,
})

return makeDeps
