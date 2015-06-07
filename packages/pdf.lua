if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("pdf package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")

-- Added UTF8 to UTF16-BE conversion
-- Compatibility UTF8 decoding function implemented in Lua
if (not pcall(function() utf8 = require("utf8") end)) then
  local function utf8_code(ustr)
    local pos = 1
    return function()
      if pos > #ustr then
        return nil
      else
        local c, ucv = 0, 0
        local nbytes = 0
        c = string.byte(ustr, pos)
        pos = pos + 1
        if c < 0x80 then
          ucv    = c
          nbytes = 0
        elseif c >= 0xc0 and c < 0xe0 then -- 110x xxxx
          ucv    = c - 0xc0
          nbytes = 1
        elseif c >= 0xe0 and c < 0xf0 then -- 1110 xxxx
          ucv    = c - 0xe0
          nbytes = 2
        elseif c >= 0xf0 and c < 0xf8 then -- 1111 0xxx
          ucv    = c - 0xf0
          nbytes = 3
        elseif c >= 0xf8 and c < 0xfc then -- 1111 10xx
          ucv    = c - 0xf8
          nbytes = 4
        elseif c >= 0xfc and c < 0xfe then -- 1111 110x
          ucv    = c - 0xfc
          nbytes = 5
        else -- Invalid
          return nil
        end
        if pos + nbytes > #ustr + 1 then -- Invalid
          return nil
        end
        while nbytes > 0 do
          nbytes = nbytes - 1
          c = string.byte(ustr, pos)
          pos = pos + 1
          if c < 0x80 or c >= 0xc0 then -- Invalid
            return nil
          else
            ucv = ucv * 64 + (c - 0x80);
          end
        end
        return ucv
      end
    end
  end
  utf8 = {
    code = utf8_code,
  }
end

SILE.registerCommand("pdf:destination", function (o,c)
  local name = SU.required(o, "name", "pdf:bookmark")
  SILE.typesetter:pushHbox({ 
    value = nil,
    height = 0,
    width = 0,
    depth = 0,
    outputYourself= function (self, typesetter)
      pdf.destination(name, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY)
    end
  });
end)

SILE.registerCommand("pdf:bookmark", function (o,c)
  local dest = SU.required(o, "dest", "pdf:bookmark")
  local title = SU.required(o, "title", "pdf:bookmark")
  local level = o.level or 1
  -- Added UTF8 to UTF16-BE conversion
  -- For annotations and bookmarks, text strings must be encoded using
  -- either PDFDocEncoding or UTF16-BE with a leading byte-order marker.
  -- As PDFDocEncoding supports only limited character repertoire for
  -- European languages, we use UTF-16BE for internationalization.
  local ustr = string.format("%04x", 0xfeff) -- BOM
  for uchr in utf8.code(title) do
    if (uchr < 0x10000) then
      ustr = ustr..string.format("%04x", uchr)
    else -- Surrogate pair
      local sur_hi = (uchr - 0x10000) / 0x400 + 0xd800
      local sur_lo = (uchr - 0x10000) % 0x400 + 0xdc00
      ustr = ustr..string.format("%04x%04x", sur_hi, sur_lo)
    end
  end
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function ()
      local d = "<</Title<"..ustr..">/A<</S/GoTo/D("..dest..")>>>>"
      pdf.bookmark(d, level)
    end
  });
end)

if SILE.Commands.tocentry then
  SILE.scratch.pdf = { dests = {}, dc = 1 }
  local oldtoc = SILE.Commands.tocentry
  SILE.Commands.tocentry = function (o,c)
    SILE.call("pdf:destination", { name = "dest"..SILE.scratch.pdf.dc } )
    SILE.call("pdf:bookmark", { title = c[1], dest = "dest"..SILE.scratch.pdf.dc, level = o.level })
    oldtoc(o,c)
    SILE.scratch.pdf.dc = SILE.scratch.pdf.dc + 1
  end
end

SILE.registerCommand("pdf:link", function (o,c)
  local dest = SU.required(o, "dest", "pdf:link")
  local llx, lly
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter)
      llx = typesetter.frame.state.cursorX
      lly = SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY
      pdf.begin_annotation()
    end
  });

  local hbox = SILE.Commands["hbox"]({}, c) -- hack
  SILE.typesetter:debugState()
  
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter) 
      local d = "<</Type/Annot/Subtype/Link/C [ 1 0 0 ]/A<</S/GoTo/D("..dest..")>>>>"
      pdf.end_annotation(d, llx, lly, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] -typesetter.frame.state.cursorY + hbox.height);
    end
  });end)

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