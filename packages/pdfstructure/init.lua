local base = require("packages.base")

local package = pl.class(base)
package._name = "pdfstructure"

local pdf
local stPointer
local mcid = 0
local actualtext = {}
local structureNumberTree
local numberTreeIndex = 0

local function stNode (notetype)
  return {
    notetype = notetype,
    lang = SILE.settings:get("document.language"),
    kids = {},
    parent = stPointer
  }
end

local function addChild (node)
  stPointer.kids[#(stPointer.kids)+1] = node
  node.parent = stPointer
end

local function ensureStructureNumber (node, pdfnode)
  local p = node.page
  if not pdf.lookup_dictionary(p, "StructParents") then
    pdf.add_dict(p, pdf.parse("/StructParents"), pdf.parse(numberTreeIndex))
    local nums = pdf.lookup_dictionary(structureNumberTree, "Nums")
    pdf.push_array(nums, pdf.parse(numberTreeIndex))
    pdf.push_array(nums, pdf.parse("[]"))
    numberTreeIndex = numberTreeIndex + 1
  end
  local nums = pdf.lookup_dictionary(structureNumberTree, "Nums")
  -- This is an array and its last element is an array
  local r = pdf.get_array(nums, pdf.array_length(nums)-1)
  pdf.push_array(r, pdf.reference(pdfnode))
end

local function dumpTree (node)
  local k = {}
  local pdfNode = pdf.parse("<< /Type /StructElem /S /"..(node.notetype)..">>")
  if #(node.kids) > 0 then
    for i = 1, #(node.kids) do
      k[#k+1] = dumpTree(node.kids[i])
    end
    local kArray = pdf.parse("[]")
    for i = 1, #k do pdf.push_array(kArray, k[i]) end
    pdf.add_dict(pdfNode, pdf.parse("/K"), kArray)
  else
    pdf.add_dict(pdfNode, pdf.parse("/K"), pdf.parse(node.mcid))
  end
  if node.page then
    pdf.add_dict(pdfNode, pdf.parse("/Pg"), pdf.reference(node.page))
    ensureStructureNumber(node, pdfNode)
  end
  if node.lang then
    pdf.add_dict(pdfNode, pdf.parse("/Lang"), pdf.parse("("..node.lang:upper()..")"))
  end

  if node.actualtext then
    pdf.add_dict(pdfNode, pdf.parse("/ActualText"), pdf.string(node.actualtext))
  end
  local ref = pdf.reference(pdfNode)
  pdf.release(pdfNode)
  return ref
end

function package:_init ()
  base._init(self)
  pdf = require("justenoughlibtexpdf")
  local _typeset = SILE.typesetter.typeset
  SILE.typesetter.typeset = function (node, text)
    actualtext[#actualtext] = tostring(actualtext[#actualtext]) .. text
    _typeset(node, text)
  end
  local stRoot = stNode("Document")
  stPointer = stRoot
  self:loadPackage("pdf")
  SILE.outputter:registerHook("prefinish", function()
    local catalog = pdf.get_dictionary("Catalog")
    local structureTree = pdf.parse("<< /Type /StructTreeRoot >>")
    pdf.add_dict(catalog, pdf.parse("/StructTreeRoot"), pdf.reference(structureTree))
    structureNumberTree = pdf.parse("<< /Nums [] >>")
    pdf.add_dict(structureTree, pdf.parse("/ParentTree"), pdf.reference(structureNumberTree))
    pdf.add_dict(structureTree, pdf.parse("/K"), dumpTree(stRoot))
    if structureNumberTree then pdf.release(structureNumberTree) end
    if structureTree then pdf.release(structureTree) end
  end)
end

function package:registerCommands ()

  self:registerCommand("pdf:structure", function (options, content)
    local notetype = SU.required(options, "type", "pdf structure")
    local node = stNode(notetype)
    addChild(node)
    node.lang = SILE.settings:get("document.language")
    if type(SILE.outputter._ensureInit) == "function" then
      SILE.outputter:_ensureInit()
    end
    node.page = pdf.get_dictionary("@THISPAGE")
    node.mcid = mcid
    local oldstPointer = stPointer
    stPointer = node
    actualtext[#actualtext+1] = ""
    if not options.block then
      SILE.call("pdf:literal", {}, {"/"..notetype.." <</MCID "..mcid.." >>BDC"})
      mcid = mcid + 1
      SILE.process(content)
      SILE.call("pdf:literal", {}, {"EMC"})
    else
      SILE.process(content)
    end
    stPointer.actualtext = actualtext[#actualtext]
    actualtext[#actualtext] = nil
    stPointer = oldstPointer
  end)

  self:registerCommand("pdf:literal", function (_, content)
    -- NOTE: This method is used by the pdfstructure package and should
    -- probably be moved elsewhere, so there's no attempt here to delegate
    -- the low-level libtexpdf call to te outputter.
    if SILE.outputter._name ~= "libtexpdf" then
      SU.error("pdf package requires libtexpdf backend")
    end
    SILE.typesetter:pushHbox({
      value = nil,
      height = SILE.types.measurement(0),
      width = SILE.types.measurement(0),
      depth = SILE.types.measurement(0),
      outputYourself = function (_, _, _)
        SILE.outputter:drawRaw (content[1])
      end
    })
  end)

end

package.documentation = [[
\begin{document}
\use[module=packages.pdfstructure]
\pdf:structure[type=P]{%
For PDF documents to be considered accessible, they must contain a description of the PDF’s document structure.
This package allows structure trees to be created and saved to the PDF file.
Currently this provides a low-level interface to creating nodes in the tree;
   classes which require PDF accessibility should use the \autodoc:command{\pdf:structure} command in their sectioning implementation to declare the document structure.
}

\pdf:structure[type=P]{%
See \code{tests/pdf.sil} for an example of using the \autodoc:package{pdfstructure} package to create a PDF/UA compatible document.
}
\end{document}
]]

return package
