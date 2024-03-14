--- pdf package
--- @use packages.pdf

-- This package and its commands are perhaps ill-named:
-- Exception made of the pdf:literal command below, the concepts of links
-- (anchor, target), bookmarks, and metadata are not specific to PDF.
--
local base = require("packages.base")

local package = pl.class(base)
package._name = "pdf"

function package:registerCommands ()

  self:registerCommand("pdf:destination", function (options, _)
    local name = SU.required(options, "name", "pdf:destination")
    SILE.typesetter:pushHbox({
      outputYourself = function (_, typesetter, line)
        local state = typesetter.frame.state
        typesetter.frame:advancePageDirection(-line.height)
        local x, y = state.cursorX, state.cursorY
        typesetter.frame:advancePageDirection(line.height)
        local _y = SILE.documentState.paperSize[2] - y
        SILE.outputter:setLinkAnchor(name, x, _y)
      end
    })
  end)

  self:registerCommand("pdf:bookmark", function (options, _)
    local dest = SU.required(options, "dest", "pdf:bookmark")
    local title = SU.required(options, "title", "pdf:bookmark")
    local level = SU.cast("integer", options.level or 1)
    SILE.typesetter:pushHbox({
      value = nil,
      height = SILE.types.measurement(0),
      width = SILE.types.measurement(0),
      depth = SILE.types.measurement(0),
      outputYourself = function ()
        SILE.outputter:setBookmark(dest, title, level)
      end
    })
  end)

  -- TODO: Shim to pdfannotations package
  -- self:registerCommand("pdf:literal", function (_, content)
  self:registerCommand("pdf:link", function (options, content)
    local dest = SU.required(options, "dest", "pdf:link")
    local external = SU.boolean(options.external, false)
    local borderwidth = options.borderwidth and SU.cast("measurement", options.borderwidth):tonumber() or 0
    local bordercolor = SILE.types.color(options.bordercolor or "blue")
    local borderoffset = SU.cast("measurement", options.borderoffset or "1pt"):tonumber()
    local opts = {
      external = external,
      borderstyle = options.borderstyle,
      bordercolor = bordercolor,
      borderwidth = borderwidth,
      borderoffset = borderoffset
    }

    SILE.typesetter:liner("pdf:link", content,
      function (box, typesetter, line)
        local x0 = typesetter.frame.state.cursorX:tonumber()
        local y0 = (SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY):tonumber()
        SILE.outputter:beginLink(dest, opts)

        -- Build the content.
        -- Cursor will be moved by the actual definitive size.
        box:outputContent(typesetter, line)
        local x1 = typesetter.frame.state.cursorX:tonumber()
        local y1 = (SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY + box.height):tonumber()

        SILE.outputter:endLink(dest, opts, x0, y0, x1, y1) -- Unstable API
      end
    )

  end)

  self:registerCommand("pdf:metadata", function (options, _)
    local key = SU.required(options, "key", "pdf:metadata")
    if options.val ~= nil then
      SU.deprecated("\\pdf:metadata[…, val=…]", "\\pdf:metadata[…, value=…]", "0.12.0", "0.13.0")
    end
    local value = SU.required(options, "value", "pdf:metadata")

    SILE.outputter:setMetadata(key, value)
  end)

end

package.documentation = [[
\begin{document}
The \autodoc:package{pdf} package enables basic support for PDF links and table-of-contents entries.
It provides the four commands \autodoc:command{\pdf:destination}, \autodoc:command{\pdf:link}, \autodoc:command{\pdf:bookmark}, and \autodoc:command{\pdf:metadata}.

The \autodoc:command{\pdf:destination} parameter creates a link target;
   it expects a parameter called \autodoc:parameter{name} to uniquely identify the target.
To create a link to that location in the document, use \autodoc:command{\pdf:link[dest=<name>]{<content>}}.

The \autodoc:command{\pdf:link} command accepts several options defining its border style:
   a \autodoc:parameter{borderwidth} length setting the border width (defaults to \code{0}, meaning no border),
   a \autodoc:parameter{borderstyle} string (can be set to \code{underline} or \code{dashed}, otherwise a solid box),
   a \autodoc:parameter{bordercolor} color specification for this border (defaults to \code{blue}),
   and finally a \autodoc:parameter{borderoffset} length for adjusting the border with some vertical space above the content and below the baseline (defaults to \code{1pt}).
Note that PDF renderers may vary on how they honor these border styling features on link annotations.

It also has an \autodoc:parameter{external} option for URL links, which is not intended to be used directly—refer to the \autodoc:package{url} package for more flexibility typesetting external links.

To set arbitrary key-value metadata, use something like \autodoc:command{\pdf:metadata[key=Author, value=J. Smith]}.
The PDF metadata field names are case-sensitive.
Common keys include \code{Title}, \code{Author}, \code{Subject}, \code{Keywords}, \code{CreationDate}, and \code{ModDate}.
\end{document}
]]

return package
