SILE.registerCommand("package-documentation", function (options, _)
  local package = SU.required(options, "src", "src for package documentation")
  io.stderr:write("<"..package..">")
  SILE.process(
    SILE.inputs.TeXlike.docToTree(
      require(package).documentation
    )
  )
end)
