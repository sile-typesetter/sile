if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("pdf package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")

SILE.registerCommand("pdf:destination", function (options, _)
  local name = SU.required(options, "name", "pdf:bookmark")
  SILE.typesetter:pushHbox({
    outputYourself = function (_, typesetter, line)
      SILE.outputters.libtexpdf._init()
      local state = typesetter.frame.state
      typesetter.frame:advancePageDirection(-line.height)
      local x, y = state.cursorX, state.cursorY
      typesetter.frame:advancePageDirection(line.height)
      local _y = SILE.documentState.paperSize[2] - y
      pdf.destination(name, x:tonumber(), _y:tonumber())
    end
  })
end)

SILE.registerCommand("pdf:bookmark", function (options, _)
  local dest = SU.required(options, "dest", "pdf:bookmark")
  local title = SU.required(options, "title", "pdf:bookmark")
  local level = options.level or 1
  -- Added UTF8 to UTF16-BE conversion
  -- For annotations and bookmarks, text strings must be encoded using
  -- either PDFDocEncoding or UTF16-BE with a leading byte-order marker.
  -- As PDFDocEncoding supports only limited character repertoire for
  -- European languages, we use UTF-16BE for internationalization.
  local ustr = SU.utf8_to_utf16be_hexencoded(title)
  SILE.typesetter:pushHbox({
    value = nil,
    height = SILE.measurement(0),
    width = SILE.measurement(0),
    depth = SILE.measurement(0),
    outputYourself = function ()
      local d = "<</Title<" .. ustr .. ">/A<</S/GoTo/D(" .. dest .. ")>>>>"
      SILE.outputters.libtexpdf._init()
      pdf.bookmark(d, level)
    end
  })
end)

if SILE.Commands.tocentry then
  SILE.scratch.pdf = { dests = {}, dc = 1 }
  local oldtoc = SILE.Commands.tocentry
  SILE.Commands.tocentry = function (options, content)
    SILE.call("pdf:destination", { name = "dest" .. SILE.scratch.pdf.dc } )
    local title = SU.contentToString(content)
    SILE.call("pdf:bookmark", { title = title, dest = "dest" .. SILE.scratch.pdf.dc, level = options.level })
    oldtoc(options, content)
    SILE.scratch.pdf.dc = SILE.scratch.pdf.dc + 1
  end
end

SILE.registerCommand("pdf:literal", function (_, content)
  SILE.typesetter:pushHbox({
      value = nil,
      height = SILE.measurement(0),
      width = SILE.measurement(0),
      depth = SILE.measurement(0),
      outputYourself = function (_, _, _)
        SILE.outputters.libtexpdf._init()
        pdf.add_content(content[1])
      end
    })
end)

SILE.registerCommand("pdf:link", function (options, content)
  local dest = SU.required(options, "dest", "pdf:link")
  local target = options.external and "/Type/Action/S/URI/URI" or "/S/GoTo/D"
  local llx, lly
  SILE.typesetter:pushHbox({
    value = nil,
    height = SILE.measurement(0),
    width = SILE.measurement(0),
    depth = SILE.measurement(0),
    outputYourself = function (_, typesetter, _)
      llx = typesetter.frame.state.cursorX:tonumber()
      lly = (SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY):tonumber()
      SILE.outputters.libtexpdf._init()
      pdf.begin_annotation()
    end
  })

  local hbox = SILE.call("hbox", {}, content) -- hack

  SILE.typesetter:pushHbox({
    value = nil,
    height = SILE.measurement(0),
    width = SILE.measurement(0),
    depth = SILE.measurement(0),
    outputYourself = function (_, typesetter, _)
      local d = "<</Type/Annot/Subtype/Link/C [ 1 0 0 ]/A<<" .. target .. "(" .. dest .. ")>>>>"
      local x = typesetter.frame.state.cursorX:tonumber()
      local y = (SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY + hbox.height):tonumber()
      pdf.end_annotation(d, llx, lly, x, y)
    end
  })
end)

SILE.registerCommand("pdf:metadata", function (options, _)
  local key = SU.required(options, "key", "pdf:metadata")
  local val = SU.required(options, "val", "pdf:metadata")
  SILE.typesetter:pushHbox({
    value = nil,
    height = SILE.measurement(0),
    width = SILE.measurement(0),
    depth = SILE.measurement(0),
    outputYourself = function (_, _, _)
      SILE.outputter:_init()
      pdf.metadata(key, val)
    end
  })
end)

return { documentation = [[\begin{document}
The \code{pdf} package enables (basic) support for PDF links and table-of-contents
entries. It provides the four commands \command{\\pdf:destination}, \command{\\pdf:link},
\command{\\pdf:bookmark}, and \command{\\pdf:metadata}.

The \command{\\pdf:destination} parameter creates a link target; it expects a
parameter called \code{name} to uniquely identify the target. To create a link to
that location in the document, use \code{\\pdf:link[dest=\goodbreak{}name]\{link content\}}.

To set arbitrary key-value metadata, use something like \code{\\pdf:metadata[key=Author,
value=J. Smith]}. The PDF metadata field names are case-sensitive. Common keys include
\code{Title}, \code{Author}, \code{Subject}, \code{Keywords}, \code{CreationDate}, and
\code{ModDate}.

If the \code{pdf} package is loaded after the \code{tableofcontents} package (e.g.
in a document with the \code{book} class), then a PDF document outline will be generated.
\end{document}]] }
