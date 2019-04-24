if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("pdf package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")

SILE.registerCommand("pdf:destination", function (options, content)
  local name = SU.required(options, "name", "pdf:bookmark")
  SILE.typesetter:pushHbox({
    value = nil,
    height = 0,
    width = 0,
    depth = 0,
    outputYourself = function (self, typesetter)
      SILE.outputters.libtexpdf._init()
      pdf.destination(name, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY)
    end
  })
end)

SILE.registerCommand("pdf:bookmark", function (options, content)
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
    value = nil, height = 0, width = 0, depth = 0,
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

SILE.registerCommand("pdf:literal", function (options, content)
  SILE.typesetter:pushHbox({
      value = nil,
      height = 0,
      width = 0,
      depth = 0,
      outputYourself = function (self, typesetter)
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
    height = 0,
    width = 0,
    depth = 0,
    outputYourself = function (self,typesetter)
      llx = typesetter.frame.state.cursorX
      lly = SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY
      SILE.outputters.libtexpdf._init()
      pdf.begin_annotation()
    end
  })

  local hbox = SILE.Commands["hbox"]({}, content) -- hack

  SILE.typesetter:pushHbox({
    value = nil,
    height = 0,
    width = 0,
    depth = 0,
    outputYourself = function (self,typesetter)
      local d = "<</Type/Annot/Subtype/Link/C [ 1 0 0 ]/A<<" .. target .. "(" .. dest .. ")>>>>"
      pdf.end_annotation(d, llx, lly, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] -typesetter.frame.state.cursorY + hbox.height)
    end
  })
end)

return { documentation = [[\begin{document}
The \code{pdf} package enables (basic) support for PDF links and table-of-contents
entries. It provides the three commands \command{\\pdf:destination}, \command{\\pdf:link}
and \command{\\pdf:bookmark}.

The \command{\\pdf:destination} parameter creates a link target; it expects a
parameter called \code{name} to uniquely identify the target. To create a link to
that location in the document, use \code{\\pdf:link[dest=\goodbreak{}name]\{link content\}}.

If the \code{pdf} package is loaded after the \code{tableofcontents} package (e.g.
in a document with the \code{book} class), then a PDF document outline will be generated.
\end{document}]] }
