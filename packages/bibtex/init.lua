local base = require("packages.base")

local package = pl.class(base)
package._name = "bibtex"

local lpeg = require("lpeg")
local epnf = require("epnf")

local Bibliography

local identifier = (SILE.parserBits.identifier + lpeg.S":-")^1

local balanced = lpeg.C{ "{" * lpeg.P(" ")^0 * lpeg.C(((1 - lpeg.S"{}") + lpeg.V(1))^0) * "}" } / function (...) local t={...}; return t[2] end
local doubleq = lpeg.C( lpeg.P '"' * lpeg.C(((1 - lpeg.S '"\r\n\f\\') + (lpeg.P '\\' * 1)) ^ 0) * '"' )

-- luacheck: push ignore
---@diagnostic disable: undefined-global, unused-local, lowercase-global
local bibtexparser = epnf.define(function (_ENV)
  local _ = WS^0
  local sep = lpeg.S(",;") * _
  local myID = C(identifier + lpeg.P(1)) / function (t) return t end
  local myTag = C(identifier + lpeg.P(1)) / function (t) return t:lower() end
  local value = balanced + doubleq + myID
  local pair = lpeg.Cg(myTag * _ * "=" * _ * C(value)) * _ * sep^-1   / function (...) local t= {...}; return t[1], t[#t] end
  local list = lpeg.Cf(lpeg.Ct("") * pair^0, rawset)
  local commentKey = lpeg.Cmt(R("az", "AZ")^1, function(_, _, a)
    return a:lower() == "comment"
  end)

  START "document"
  document = (V"comment" + V"entry")^1 -- order important: @comment must have precedence over @other
    * (-1 + E("Unexpected character at end of input"))
  comment  = WS +
    ( V"blockcomment" + (P("%") * (1-lpeg.S("\r\n"))^0 * lpeg.S("\r\n")) /function () return "" end) -- Don't bother telling me about comments
  blockcomment = (P("@") * commentKey) + balanced/function () return "" end -- Don't bother telling me about comments
  entry = Ct( P("@") * Cg(myTag, "type") * _ * P("{") * _ * Cg(myID, "label") * _ * sep * list * P("}") * _ )
end)
-- luacheck: pop
---@diagnostic enable: undefined-global, unused-local, lowercase-global

local parseBibtex = function (fn)
  fn = SILE.resolveFile(fn) or SU.error("Unable to resolve Bibtex file "..fn)
  local fh, e = io.open(fn)
  if e then SU.error("Error reading bibliography file: "..e) end
  local doc = fh:read("*all")
  local t = epnf.parsestring(bibtexparser, doc)
  if not t or not t[1] or t.id ~= "document" then
    SU.error("Error parsing bibtex")
  end
  local entries = {}
  for i =1,#t do
    if t[i].id == "entry" then
      local ent = t[i][1]
      entries[ent.label] = {type = ent.type, attributes = ent[1]}
    end
  end
  return entries
end

function package:_init ()
  base._init(self)
  SILE.scratch.bibtex = { bib = {} }
  Bibliography = require("packages.bibtex.bibliography")
end

function package.declareSettings (_)
  SILE.settings:declare({
    parameter = "bibtex.style",
    type = "string",
    default = "chicago",
    help = "BibTeX style"
  })
end

function package:registerCommands ()

  self:registerCommand("loadbibliography", function (options, _)
    local file = SU.required(options, "file", "loadbibliography")
    SILE.scratch.bibtex.bib = parseBibtex(file) -- Later we'll do multiple bibliogs, but not now
  end)

  self:registerCommand("bibstyle", function (_, _)
    SU.deprecated("\\bibstyle", '\\set[parameter=bibtex.style]', "0.13.2", "0.14.0")
  end)

  self:registerCommand("cite", function (options, content)
    if not options.key then options.key = SU.contentToString(content) end
    local style = SILE.settings:get("bibtex.style")
    local bibstyle = require("packages.bibtex.styles." .. style)
    local cite = Bibliography.produceCitation(options, SILE.scratch.bibtex.bib, bibstyle)
    if cite == Bibliography.Errors.UNKNOWN_REFERENCE then
      SU.warn("Unknown reference in citation "..options.key)
      return
    end
    SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
  end)

  self:registerCommand("reference", function (options, content)
    if not options.key then options.key = SU.contentToString(content) end
    local style = SILE.settings:get("bibtex.style")
    local bibstyle = require("packages.bibtex.styles." .. style)
    local cite, err = Bibliography.produceReference(options, SILE.scratch.bibtex.bib, bibstyle)
    if cite == Bibliography.Errors.UNKNOWN_REFERENCE then
      SU.warn("Unknown reference in citation " .. tostring(options.key))
      return
    end
    if cite == Bibliography.Errors.UNKNOWN_TYPE then
      SU.warn("Unknown type @"..err.." in citation for reference "..options.key)
      return
    end
    SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
  end)

end

package.documentation = [[
\begin{document}
BibTeX is a citation management system.
It was originally designed for TeX but has since been integrated into a variety of situations.

This experimental package allows SILE to read and process BibTeX \code{.bib} files and output citations and full text references.
(It doesn’t currently produce full bibliography listings.)

To load a BibTeX file, issue the command \autodoc:command{\loadbibliography[file=<whatever.bib>]}

To produce an inline citation, call \autodoc:command{\cite{<key>}}, which will typeset something like “Jones 1982”.
If you want to cite a particular page number, use \autodoc:command{\cite[page=22]{<key>}}.

To produce a full reference, use \autodoc:command{\reference{<key>}}.

Currently, the only supported bibliography style is Chicago referencing, but other styles should be easy to implement.
Adapt \code{packages/bibtex/styles/chicago.lua} as necessary.
\end{document}
]]

return package
