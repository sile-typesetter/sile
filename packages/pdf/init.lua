local pdf

local function borderColor (color)
  if color then
    if color.r then return "/C [" .. color.r .. " " .. color.g .. " " .. color.b .. "]" end
    if color.c then return "/C [" .. color.c .. " " .. color.m .. " " .. color.y .. " " .. color.k .. "]" end
    if color.l then return "/C [" .. color.l .. "]" end
  end
  return ""
end

local function borderStyle (style, width)
  if style == "underline" then return "/BS<</Type/Border/S/U/W " .. width .. ">>" end
  if style == "dashed" then return "/BS<</Type/Border/S/D/D[3 2]/W " .. width .. ">>" end
  return "/Border[0 0 " .. width .. "]"
end

local function validate_date (date)
  return string.match(date, [[^D:%d+%s*-%s*%d%d%s*'%s*%d%d%s*'?$]]) ~= nil
end

local function init (_, _)

  pdf = require("justenoughlibtexpdf")

  if SILE.outputter._name ~= "libtexpdf" then
    SU.error("pdf package requires libtexpdf backend")
  end

end

local function registerCommands (_)

  SILE.registerCommand("pdf:destination", function (options, _)
    local name = SU.required(options, "name", "pdf:destination")
    SILE.typesetter:pushHbox({
      outputYourself = function (_, typesetter, line)
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
        pdf.bookmark(d, level)
      end
    })
  end)

  SILE.registerCommand("pdf:literal", function (_, content)
    SILE.typesetter:pushHbox({
      value = nil,
      height = SILE.measurement(0),
      width = SILE.measurement(0),
      depth = SILE.measurement(0),
      outputYourself = function (_, _, _)
        pdf.add_content(content[1])
      end
    })
  end)

  SILE.registerCommand("pdf:link", function (options, content)
    local dest = SU.required(options, "dest", "pdf:link")
    local target = options.external and "/Type/Action/S/URI/URI" or "/S/GoTo/D"
    local borderwidth = options.borderwidth and SU.cast("measurement", options.borderwidth):tonumber() or 0
    local bordercolor = borderColor(SILE.colorparser(options.bordercolor or "blue"))
    local borderoffset = SU.cast("measurement", options.borderoffset or "1pt"):tonumber()
    local borderstyle = borderStyle(options.borderstyle, borderwidth)
    local llx, lly
    SILE.typesetter:pushHbox({
      value = nil,
      height = SILE.measurement(0),
      width = SILE.measurement(0),
      depth = SILE.measurement(0),
      outputYourself = function (_, typesetter, _)
        llx = typesetter.frame.state.cursorX:tonumber()
        lly = (SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY):tonumber()
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
        local d = "<</Type/Annot/Subtype/Link" .. borderstyle .. bordercolor .. "/A<<" .. target .. "(" .. dest .. ")>>>>"
        local x = typesetter.frame.state.cursorX:tonumber()
        local y = (SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY + hbox.height):tonumber()
        pdf.end_annotation(d, llx , lly - borderoffset, x, y + borderoffset)
      end
    })
  end)

  SILE.registerCommand("pdf:metadata", function (options, _)
    local key = SU.required(options, "key", "pdf:metadata")
    if options.val ~= nil then
      SU.deprecated("\\pdf:metadata[…, val=…]", "\\pdf:metadata[…, value=…]", "0.12.0", "0.13.0")
    end
    local value = SU.required(options, "value", "pdf:metadata")

    if key == "Trapped" then
      SU.warn("Skipping special metadata key \\Trapped")
      return
    end

    if key == "ModDate" or key == "CreationDate" then
      if not validate_date(value) then
        SU.warn("Invalid date: " .. value)
        return
      end
    else
      -- see comment in pdf:bookmark
      value = SU.utf8_to_utf16be(value)
    end
    SILE.typesetter:pushHbox({
      value = nil,
      height = SILE.measurement(0),
      width = SILE.measurement(0),
      depth = SILE.measurement(0),
      outputYourself = function (_, _, _)
        pdf.metadata(key, value)
      end
    })
  end)

end

return {
  init = init,
  registerCommands = registerCommands,
  documentation = [[
\begin{document}
The \autodoc:package{pdf} package enables (basic) support for PDF links and table-of-contents
entries. It provides the four commands \autodoc:command{\pdf:destination}, \autodoc:command{\pdf:link},
\autodoc:command{\pdf:bookmark}, and \autodoc:command{\pdf:metadata}.

The \autodoc:command{\pdf:destination} parameter creates a link target; it expects a
parameter called \autodoc:parameter{name} to uniquely identify the target. To create a link to
that location in the document, use \autodoc:command{\pdf:link[dest=<name>]{<content>}}.

The \autodoc:command{\pdf:link} command accepts several options defining its border style:
a \autodoc:parameter{borderwidth} length setting the border width (defaults to 0, meaning no border),
a \autodoc:parameter{borderstyle} string (can be set to “underline” or “dashed”, otherwise a
solid box),
a \autodoc:parameter{bordercolor} color specification for this border (defaults to blue),
and finally a \autodoc:parameter{borderoffset} length for adjusting the border with some vertical space
above the content and below the baseline (defaults to 1pt). Note that PDF renderers may vary on how
they honor these border styling features on link annotations.

It also has an \autodoc:parameter{external} option for URL links, which is not intended to be used
directly—refer to the \autodoc:package{url} package for more flexibility typesetting external
links.

To set arbitrary key-value metadata, use something like \autodoc:command{\pdf:metadata[key=Author,
value=J. Smith]}. The PDF metadata field names are case-sensitive. Common keys include
\code{Title}, \code{Author}, \code{Subject}, \code{Keywords}, \code{CreationDate}, and
\code{ModDate}.
\end{document}
]]}
