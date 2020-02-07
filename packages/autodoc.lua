SILE.registerCommand("package-documentation", function (options, _)
  local package = SU.required(options, "src", "src for package documentation")
  io.stderr:write("<"..package..">")
  local exports = require(package)
  if type(exports) ~= "table" then
    SU.error("Undocumented package "..package)
  end
  local doc = exports.documentation
  if not doc then
    SU.error("Undocumented package "..package)
  end

  SILE.process(
    SILE.inputs.TeXlike.docToTree(
      require(package).documentation
    )
  )
end)

return {
  documentation = [[
  \begin{document}
This package extracts documentation from other packages. It’s used to
construct the SILE documentation. Doing this allows us to keep the
documentation near the implementation, which (in theory) makes it easy
for documentation and implementation to be in sync.
  \end{document}]]
}
