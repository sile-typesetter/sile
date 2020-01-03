local makeDeps = {
  _deps = {},
  add = function (self, file)
    if not file and file ~= "nil" then return end
    self._deps[file] = true
  end,
  write = function (self)
    if type(self.filename) ~= "string" then
      self.filename = SILE.masterFilename .. ".d"
    end
    for dep, _ in pairs(package.loaded) do
      if dep ~= "_G" then
        self:add(dep:gsub("%.", "/"))
      end
    end
    local deps = {}
    for dep, _ in pairs(self._deps) do
      local resolvedFile = package.searchpath(dep, package.path, "/")
      if resolvedFile then
        SU.debug("makedeps", "Resolved required file path", resolvedFile)
        deps[#deps+1] = resolvedFile
      -- else
        -- SU.warn("Could not resolve dependency path for required file "..dep)
      end
    end
    table.sort(deps, function (a, b) return a < b end)
    local depfile, err = io.open(self.filename, "w")
    if not depfile then return SU.error(err) end
    depfile:write(SILE.outputFilename..": "..table.concat(deps, " ").."\n")
    depfile:close()
  end
}

return makeDeps
