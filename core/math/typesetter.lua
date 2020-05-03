-- Interpret a MathML or TeX-like AST, typeset it and add it to the output.
local b = require("core/math/base-elements")
local tex = require("core/math/texlike")

-- convert MathML into mbox
local function ConvertMathML(content)
  if content == nil or content.tag == nil then return nil end
  local convertChildren = function(content)
    local mboxes = {}
    for i, n in ipairs(content) do
      local box = ConvertMathML(n)
      if box then table.insert(mboxes, box) end
    end
    return mboxes
  end
  if content.tag == 'math' then -- toplevel
    return b.newStackbox({ direction='V', children=convertChildren(content) })
  elseif content.tag == 'mrow' then
    return b.newStackbox({ direction='H', children=convertChildren(content) })
  elseif content.tag == 'mi' then
    local script = content.attr.mathvariant and
      b.mathVariantToScriptType(content.attr.mathvariant) or b.scriptType.italic
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mi tag contains "..text..", which is not text")
    end
    return b.newText({ kind='identifier', script=script, text=text })
  elseif content.tag == 'mo' then
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mo tag contains "..text..", which is not text")
    end
    return b.newText({ kind='operator', script=b.scriptType.upright, text=text })
  elseif content.tag == 'mn' then
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mn tag contains "..text..", which is not text")
    end
    if string.sub(text, 1, 1) == "-" then
      text = "−"..string.sub(text, 2)
    end
    return b.newText({ kind='number', script=b.scriptType.upright, text=text })
  elseif content.tag == "mspace" then
    return b.newSpace{width = content.attr.width, height = content.attr.height, depth = content.attr.depth}
  elseif content.tag == 'msub' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in msub') end
    return b.newSubscript({ kind="sub", base=children[1], sub=children[2] })
  elseif content.tag == 'msup' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in msup') end
    return b.newSubscript({ kind="sup", base=children[1], sup=children[2] })
  elseif content.tag == 'msubsup' then
    local children = convertChildren(content)
    if #children ~= 3 then SU.error('Wrong number of children in msubsup') end
    return b.newSubscript({ kind="subsup", base=children[1], sub=children[2], sup=children[3] })
  elseif content.tag == 'mfrac' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in mfrac: '
      ..#children)
    end
    return b.newFraction({ numerator=children[1], denominator=children[2] })
  elseif content.tag == "mtable" then
    local children = convertChildren(content)
    return b.newTable{children = children, options = content.attr}
  elseif content.tag == "mtr" then
    return b.newMtr{children = convertChildren(content)}
  elseif content.tag == "mtd" then
    return b.newStackbox{direction="H", children = convertChildren(content)}
  else
    SU.error("Unknown math command " .. content.tag)
  end
end

SILE.nodefactory.math = {
  newText = b.newText,
  newStackbox = b.newStackbox
}

local function handleMath(mbox, mode)
  if mode == 'display' then
    mbox.mode = b.mathMode.display
  elseif mode == 'text' then
    mbox.mode = b.mathMode.textCramped
  else
    SU.error('Unknown math mode '..mode)
  end
  mbox:styleDescendants()

  mbox:shapeTree()

  if mode == "display" then
    SILE.typesetter:endline()
    SILE.typesetter:pushExplicitVglue(SILE.settings.get("math.displayskip"))
    SILE.call("center", {}, function()
      SILE.typesetter:pushHorizontal(mbox)
    end)
    SILE.typesetter:endline()
    SILE.typesetter:pushExplicitVglue(SILE.settings.get("math.displayskip"))
  else
    SILE.typesetter:pushHorizontal(mbox)
  end
end

SILE.registerCommand("mathml", function (options, content)
  local mode = (options and options.mode) and options.mode or 'text'

  local mbox
  xpcall(function()
      mbox = ConvertMathML(content, mbox)
  end, function(err) print(err); print(debug.traceback()) end)

  handleMath(mbox, mode)
end)

SILE.registerCommand("math", function(options, content)
  local mode = (options and options.mode) and options.mode or "text"

  local mbox
  xpcall(function()
    mbox = ConvertMathML(tex.compileToMathML({}, tex.convertTexlike(content)))
  end, function(err) print(err); print(debug.traceback()) end)

  handleMath(mbox, mode)
end)
