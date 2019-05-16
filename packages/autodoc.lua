SILE.registerCommand("package-documentation", function (o,c)
  local package = SU.required(o, "src", "src for package documentation")
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
