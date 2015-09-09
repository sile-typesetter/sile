if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("pdf package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")

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
  local ustr = SU.utf8_to_utf16be(title)
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

SILE.registerCommand("pdf:literal", function (o,c)
  SILE.typesetter:pushHbox({
      value = nil,
      height = 0,
      width = 0,
      depth = 0,
      outputYourself= function (self, typesetter)
        pdf.add_content(c[1])
      end
    });
end)

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

  SILE.typesetter:pushHbox({
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter)
      local d = "<</Type/Annot/Subtype/Link/C [ 1 0 0 ]/A<</S/GoTo/D("..dest..")>>>>"
      pdf.end_annotation(d, llx, lly, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] -typesetter.frame.state.cursorY + hbox.height);
    end
  });end)

local structureTree
local structureNumberTree
local structureBranch
local mcid = 0

local ensureStructureTree = function ()
  if not structureTree then
    local c = pdf.get_dictionary("Catalog")
    structureTree = pdf.parse("<< /Type /StructTreeRoot >>")
    pdf.add_dict(c,pdf.parse("/StructTreeRoot"),pdf.reference(structureTree))
  end
  if not structureNumberTree then
    structureNumberTree = pdf.parse("<< /Nums [ 0 [] ] >>")
    pdf.add_dict(structureTree,pdf.parse("/ParentTree"),pdf.reference(structureNumberTree))
  end
  return structureTree
end

local addToBranch = function (leaf)
  local k = pdf.lookup_dictionary(structureTree,"K")
  if not k then
    pdf.add_dict(structureTree,pdf.parse("/K"),pdf.reference(leaf))
  end
  if structureBranch then
    local kids = pdf.lookup_dictionary(structureBranch,"K")
    if not kids then
      kids = pdf.parse("[]")
      pdf.add_dict(structureBranch,pdf.parse("/K"), kids)
    end
    pdf.push_array(kids, pdf.reference(leaf))
  else
    local nums = pdf.lookup_dictionary(structureNumberTree, "Nums")
    -- This is an array and its last element is an array
    local r = pdf.get_array(nums, pdf.array_length(nums)-1)
    pdf.push_array(r, pdf.reference(leaf))
  end
end

SILE.registerCommand("pdf:structure:leaf", function (o,c)
  local t = SU.required(o,"type", "pdf structure")
  local lang = o.lang
  ensureStructureTree()
  structureLeaf = pdf.parse("<< /Type /StructElem >>")
  local rLeaf = pdf.reference(structureLeaf)
  -- pdf.add_dict(structureLeaf,pdf.parse("/P"),
  --   structureTree)

  pdf.add_dict(structureLeaf,pdf.parse("/Pg"),
    pdf.reference(pdf.get_dictionary("@THISPAGE")))

  addToBranch(structureLeaf)
  if lang then
    pdf.add_dict(structureLeaf,pdf.parse("/Lang"), pdf.parse("("..lang..")"))
  end
  pdf.add_dict(structureLeaf,pdf.parse("/S"), pdf.parse("/"..t))
  pdf.add_dict(structureLeaf,pdf.parse("/K"), pdf.parse(mcid))
  SILE.call("pdf:literal",{},{"/"..t.." <</MCID "..mcid.." >>BDC"})
  SILE.process(c)
  SILE.call("pdf:literal",{},{"EDC"})
  pdf.release(structureLeaf)

  mcid = mcid + 1
end)

SILE.outputters.libtexpdf.finish = function()
  pdf.endpage()
  if structureNumberTree then pdf.release(structureNumberTree) end
  if structureTree then pdf.release(structureTree) end
  pdf.finish()
end
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
