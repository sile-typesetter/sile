-- Interpret a MathML or TeX-like AST, typeset it and add it to the output.
local b = require("packages/math/base-elements")
local tex = require("packages/math/texlike")

local ConvertMathML

local function convertChildren(tree)
  local mboxes = {}
  for _, n in ipairs(tree) do
    local box = ConvertMathML(n)
    if box then table.insert(mboxes, box) end
  end
  return mboxes
end

-- convert MathML into mbox
function ConvertMathML(content)
  if content == nil or content.command == nil then return nil end
  if content.command == 'math' or content.command == 'mathml' then -- toplevel
    return b.stackbox('V', convertChildren(content))
  elseif content.command == 'mrow' then
    return b.stackbox('H', convertChildren(content))
  elseif content.command == 'mi' then
    local script = content.options.mathvariant and
      b.mathVariantToScriptType(content.options.mathvariant) or b.scriptType.italic
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mi command contains "..text..", which is not text")
    end
    return b.text('identifier', script, text)
  elseif content.command == 'mo' then
    local script = content.options.mathvariant and
      b.mathVariantToScriptType(content.options.mathvariant) or b.scriptType.upright
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mo command contains "..text..", which is not text")
    end
    return b.text('operator', script, text)
  elseif content.command == 'mn' then
    local script = content.options.mathvariant and
      b.mathVariantToScriptType(content.options.mathvariant) or b.scriptType.upright
    local text = content[1]
    if type(text) ~= "string" then
      SU.error("mn command contains "..text..", which is not text")
    end
    if string.sub(text, 1, 1) == "-" then
      text = "−"..string.sub(text, 2)
    end
    return b.text('number', script, text)
  elseif content.command == "mspace" then
    return b.space(
      SILE.length(content.options.width),
      SILE.length(content.options.height),
      SILE.length(content.options.depth))
  elseif content.command == 'msub' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in msub') end
    return b.newSubscript({ kind="sub", base=children[1], sub=children[2] })
  elseif content.command == 'msup' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in msup') end
    return b.newSubscript({ kind="sup", base=children[1], sup=children[2] })
  elseif content.command == 'msubsup' then
    local children = convertChildren(content)
    if #children ~= 3 then SU.error('Wrong number of children in msubsup') end
    return b.newSubscript({ kind="subsup", base=children[1], sub=children[2], sup=children[3] })
  elseif content.command == 'mfrac' then
    local children = convertChildren(content)
    if #children ~= 2 then SU.error('Wrong number of children in mfrac: '
      ..#children)
    end
    return b.fraction(children[1], children[2])
  elseif content.command == "mtable" or content.command == "table" then
    local children = convertChildren(content)
    return b.table(children, content.options)
  elseif content.command == "mtr" then
    return b.mtr(convertChildren(content))
  elseif content.command == "mtd" then
    return b.stackbox("H", convertChildren(content))
  else
    SU.error("Unknown math command " .. content.command)
  end
end

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
