--
-- Documentation tooling for package designers.
--

SILE.registerCommand("package-documentation", function (options, _)
  local package = SU.required(options, "src", "src for package documentation")
  SU.debug("autodoc", package)
  local exports = require(package)
  if type(exports) ~= "table" or not exports.documentation then
    SU.error("Undocumented package "..package)
  end
  SILE.process(
    SILE.inputs.TeXlike.docToTree(
      exports.documentation
    )
  )
end)

-- Styling hook

SILE.registerCommand("autodoc:style", function (_, content)
  -- options.type can be used to distinguish the type of item and style
  -- it accordingly, redefining this command.
  -- Here by default, though, just typeset it in \code.
  SILE.call("code", {}, content)
end)

-- Documenting a setting with good line-breaks

local inputfilter = SILE.require("packages/inputfilter").exports
local settingFilter = function (node, content)
  if type(node) == "table" then return node end
  local result = {}
  for token in SU.gtoke(node, "[%.]") do
    if token.string then
      result[#result+1] = token.string
    else
        result[#result+1] = token.separator
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = 100 }, nil
        )
    end
  end
  return result
end

SILE.registerCommand("autodoc:setting", function (options, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  if #content ~= 1 then SU.error("Expected a single element") end
  local name = type(content[1] == "string") and content[1]
  if not name then SU.error("Unexpected setting '"..name.."'") end
  -- Conditional existence check (can be disable is passing check=false), e.g.
  -- for settings that would be define in another context.
  if SU.boolean(options.check, true) then
    SILE.settings.get(name) -- will issue an error if unknown
  end
  -- Inserts breakpoints after dots
  local nameWithBreaks = inputfilter.transformContent(content, settingFilter)

  SILE.call("autodoc:style", { type = "setting" }, nameWithBreaks)
end, "Outputs a settings name in code, ensuring good line breaks and possibly checking their existence.")

return {
  documentation = [[\begin{document}
This package extracts documentation information from other packages. It’s used to
construct the SILE manual. Keeping package documentation in the package itself
keeps the documentation near the implementation, which (in theory) makes it easy
for documentation and implementation to be in sync.

For that purpose, it provides the \code{\\package-documentation[src=\em{package}]}
command.

Properly documented packages should export a \code{documentation} string
containing their documentation, as a SILE document.

For documenters and package authors, it also provides commands that can be used in their package
documentation to present various pieces of information in a consistent way.

Setting names can be fairly long (e.g. \em{namespace.area.some-stuff}).
The \code{\\autodoc:setting} command helps line-breaking them automatically at
appropriate points, so that package authors do not have care about them
manually.

\end{document}]]
}
