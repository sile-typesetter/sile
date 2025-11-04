-- Interpret a MathML or TeX-like AST, typeset it and add it to the output.
local lpeg = require("lpeg")
local atoms = require("packages.math.atoms")
local b = require("packages.math.base-elements")
local syms = require("packages.math.unicode-symbols")
local accents = require("packages.math.unicode-accents")
local mathvariants = require("packages.math.unicode-mathvariants")
local mathVariantToScriptType, scriptType = mathvariants.mathVariantToScriptType, mathvariants.scriptType

local ConvertMathML

-- See MathML Core "Algorithm for determining the form of an embellished operator"
local scriptedElements = {
   mmultiscripts = true,
   mover = true,
   msub = true,
   msubsup = true,
   msup = true,
   munder = true,
   munderover = true,
}
local groupingElements = {
   maction = true,
   math = true,
   merror = true,
   mphantom = true,
   mprescripts = true,
   mrow = true,
   mstyle = true,
   semantics = true,
}
local spaceLikeElements = {
   mtext = true,
   mspace = true,
}

-- Space like elements are:
-- an mtext or mspace;
-- or a grouping element or mpadded all of whose in-flow children are space-like.
local function isSpaceLike (tree)
   if spaceLikeElements[tree.command] then
      return true
   end
   if groupingElements[tree.command] or tree.command == "mpadded" then
      for _, n in ipairs(tree) do
         if not isSpaceLike(n) then
            return false
         end
      end
      return true
   end
end
-- Grouping-like elements in this operator embellishing context are:
-- a grouping element
-- or an mpadded or msqrt element.
local isGroupingLike = function (tree)
   return groupingElements[tree.command] or tree.command == "mpadded" or tree.command == "msqrt"
end

local function embellishOperatorInPlace (tree)
   local lastChild
   local lastMo
   local groupLike = isGroupingLike(tree)
   local scripLike = scriptedElements[tree.command]
   for _, n in ipairs(tree) do
      -- FIXME Maybe ncomplete vs. "core form" (of other elements) in MathML Core
      -- This specification would make anyone's eyes bleed :D
      if n.command == "mo" then
         lastMo = n
         n.options.form = n.options.form
            or groupLike and not lastChild and "prefix" -- first-in-flow child
            or scripLike and lastChild and "postfix" -- last-in-flow child of a scripted element other than the first
            or nil
      end
      if n.command and not isSpaceLike(n) then
         lastChild = n
      end
   end
   if lastMo then
      lastMo.options.form = lastMo.options.form
         or groupLike and lastMo == lastChild and "postfix" -- last-in-flow child
         or nil
   end
end

local function convertChildren (tree)
   local mboxes = {}
   embellishOperatorInPlace(tree)
   for _, n in ipairs(tree) do
      local box = ConvertMathML(nil, n)
      if box then
         table.insert(mboxes, box)
      end
   end
   return mboxes
end

local function convertFirstChild (tree)
   -- We need to loop until the first non-nil box is found, because
   -- we may have blank lines in the tree.
   for _, n in ipairs(tree) do
      local box = ConvertMathML(nil, n)
      if box then
         return box
      end
   end
end

-- convert MathML into mbox
function ConvertMathML (_, content)
   if content == nil or content.command == nil then
      return nil
   end
   local attributes = content.options

   if content.command == "math" or content.command == "mathml" then -- toplevel
      return b.stackbox(attributes, "H", convertChildren(content))
   end

   if content.command == "mrow" then
      local ret = b.stackbox(attributes, "H", convertChildren(content))
      -- Internal property to keep tracks or paired open/close in TeX-like syntax
      ret.is_paired = content.is_paired
      return ret
   end

   if content.command == "mphantom" then
      return b.phantom(attributes, convertChildren(content))
   end

   if content.command == "mi" then
      local script = attributes.mathvariant and mathVariantToScriptType(attributes.mathvariant)
      local text = content[1]
      if type(text) ~= "string" then
         SU.error("mi command contains content which is not text")
      end
      script = script or (luautf8.len(text) == 1 and scriptType.italic or scriptType.upright)
      return b.text("identifier", {}, script, text)
   end

   if content.command == "mo" then
      attributes.form = attributes.form or "infix"
      local script = attributes.mathvariant and mathVariantToScriptType(attributes.mathvariant)
         or scriptType.upright
      local text = content[1]
      local attr = {}
      if luautf8.len(text) == 1 then
         -- Re-encode single combining character as non-combining when feasible.
         -- HACK: This is for "accents", but it's not what MathML Core expects.
         -- See comment on that function.
         text = accents.makeNonCombining(text)
      end
      -- Attributes from the (default) operator table
      if syms.operatorDict[text] then
         attr.atom = syms.operatorDict[text].atom
         local forms = syms.operatorDict[text].forms
         local defaultOps = forms and (forms[attributes.form] or forms.infix or forms.prefix or forms.postfix)
         if defaultOps then
            for attribute, value in pairs(defaultOps) do
               attr[attribute] = value
            end
         end
      end
      -- Overwrite with attributes from the element
      for attribute, value in pairs(attributes) do
         attr[attribute] = value
      end
      if attributes.atom then
         if not atoms.types[attributes.atom] then
            SU.error("Unknown atom type " .. attributes.atom)
         else
            attr.atom = atoms.types[attributes.atom]
         end
      end
      if type(text) ~= "string" then
         SU.error("mo command contains content which is not text")
      end
      local cp = text and luautf8.len(text) == 1 and luautf8.codepoint(text, 1)
      if cp and cp >= 0x2061 and cp <= 0x2064 then
         -- "Invisible operators"
         --  - Several test cases in Joe Javawaski's Browser Test and the
         --  - The MathML Test Suite use these too, with ad hoc spacing attributes.
         -- MathML Core doesn't mention anything special about these.
         -- MathML4 §8.3: "They are especially important new additions to the UCS
         -- because they provide textual clues which can increase the quality of
         -- print rendering (...)" (Note the absence of indication on how "print"
         -- rendering is supposed to be improved.)
         -- MathML4 §3.1.1: "they usually render invisibly (...) but may influence
         -- visual spacing." (Note the ill-defined "usually" and "may" in this
         -- specification.)
         -- The best we can do is to suppress these operators, but handle any
         -- explicitspacing (despite not handling rsup/rspace attributes on other
         -- operators in our TeX-based spacing logic).
         -- stylua: ignore start
         local number = lpeg.R("09")^0  * (lpeg.P(".")^-1 * lpeg.R("09")^1)^0 / tonumber
         -- stylua: ignore end
         -- 0 something is 0 in whatever unit (ex. "0", "0mu", "0em" etc.)
         local rspace, lspace = number:match(attr.rspace), number:match(attr.lspace)
         if rspace == 0 and lspace == 0 then
            return nil -- Just skip the invisible operator.
         end
         -- Skip it but honor the non-zero spacing.
         if rspace == 0 then
            return b.space({
               width = attr.lspace,
               height = 0,
               depth = 0,
            })
         end
         if lspace == 0 then
            return b.space({
               width = attr.rspace,
               height = 0,
               depth = 0,
            })
         end
         -- I haven't found examples of invisible operators with both rspace and lspace set,
         -- but it may happen, whatever spaces around something invisible mean.
         -- We'll just stack the spaces in this case (as we can only return one box).
         return b.stackbox({}, "H", {
            b.space({
               width = attr.lspace,
               height = 0,
               depth = 0,
            }),
            b.space({
               width = attr.rspace,
               height = 0,
               depth = 0,
            }),
         })
      end
      return b.text("operator", attr, script, text)
   end

   if content.command == "mn" then
      local script = attributes.mathvariant and mathVariantToScriptType(attributes.mathvariant)
         or scriptType.upright
      local text = content[1]
      if type(text) ~= "string" then
         SU.error("mn command contains content which is not text")
      end
      if string.sub(text, 1, 1) == "-" then
         text = "−" .. string.sub(text, 2)
      end
      return b.text("number", {}, script, text)
   end

   if content.command == "mspace" then
      return b.space(attributes)
   end

   if content.command == "msub" then
      local children = convertChildren(content)
      if #children ~= 2 then
         SU.error("Wrong number of children in msub")
      end
      return b.newSubscript(attributes, { base = children[1], sub = children[2] })
   end

   if content.command == "msup" then
      local children = convertChildren(content)
      if #children ~= 2 then
         SU.error("Wrong number of children in msup")
      end
      return b.newSubscript(attributes, { base = children[1], sup = children[2] })
   end

   if content.command == "msubsup" then
      local children = convertChildren(content)
      if #children ~= 3 then
         SU.error("Wrong number of children in msubsup")
      end
      return b.newSubscript(attributes, { base = children[1], sub = children[2], sup = children[3] })
   end

   if content.command == "munder" then
      local children = convertChildren(content)
      if #children ~= 2 then
         SU.error("Wrong number of children in munder" .. #children)
      end
      local elt = b.newUnderOver(attributes, { base = children[1], sub = children[2] })
      elt.movablelimits = content.is_hacked_movablelimits
      return elt
   end

   if content.command == "mover" then
      local children = convertChildren(content)
      if #children ~= 2 then
         SU.error("Wrong number of children in mover")
      end
      local elt = b.newUnderOver(attributes, { base = children[1], sup = children[2] })
      elt.movablelimits = content.is_hacked_movablelimits
      return elt
   end

   if content.command == "munderover" then
      local children = convertChildren(content)
      if #children ~= 3 then
         SU.error("Wrong number of children in munderover")
      end
      return b.newUnderOver(attributes, { base = children[1], sub = children[2], sup = children[3] })
   end

   if content.command == "mfrac" then
      local children = convertChildren(content)
      if #children ~= 2 then
         SU.error("Wrong number of children in mfrac: " .. #children)
      end
      return SU.boolean(attributes.bevelled, false)
            and b.bevelledFraction(attributes, children[1], children[2])
         or b.fraction(attributes, children[1], children[2])
   end

   if content.command == "msqrt" then
      local children = convertChildren(content)
      -- "The <msqrt> element generates an anonymous <mrow> box called the msqrt base
      return b.sqrt(attributes, b.stackbox({}, "H", children))
   end

   if content.command == "mroot" then
      local children = convertChildren(content)
      return b.sqrt(attributes, children[1], children[2])
   end

   if content.command == "mtable" or content.command == "table" then
      local children = convertChildren(content)
      return b.table(attributes, children)
   end

   if content.command == "mtr" then
      return b.mtr(attributes, convertChildren(content))
   end

   if content.command == "mtd" then
      return b.stackbox(attributes, "H", convertChildren(content))
   end

   if content.command == "mtext" or content.command == "ms" then
      if #content > 1 then
         SU.error("Wrong number of children in " .. content.command .. ": " .. #content)
      end
      local text = content[1] or "" -- empty mtext is allowed, and found in examples...
      if type(text) ~= "string" then
         SU.error(content.command .. " command contains content which is not text")
      end
      -- MathML Core 3.2.1.1 Layout of <mtext> has some wording about forced line breaks
      -- and soft wrap opportunities: ignored here.
      -- There's also some explanations about CSS, italic correction etc. which we ignore too.
      text = text:gsub("[\n\r]", " ")
      return b.text("string", {}, scriptType.upright, text:gsub("%s+", " "))
   end

   if content.command == "maction" then
      -- MathML Core 3.6: display as mrow, ignoring all but the first child
      return b.stackbox(attributes, "H", { convertFirstChild(content) })
   end

   if content.command == "mstyle" then
      -- It's an mrow, but with some extra style attributes).
      return b.stackbox(attributes, "H", convertChildren(content))
   end

   if content.command == "mpadded" then
      -- MathML Core 3.3.6.1: The <mpadded> element generates an anonymous <mrow> box
      -- called the "impadded inner box"
      return b.padded(attributes, b.stackbox({}, "H", convertChildren(content)))
   end

   if content.command == "menclose" then
      -- MathML4 §3.3.9:  The <menclose> element accepts a single argument possibly
      -- being an inferred mrow of multiple children.
      return b.enclose(attributes, b.stackbox({}, "H", convertChildren(content)))
   end
   SU.error("Unknown math command " .. content.command)
end

local function handleMath (_, mbox, options)
   local mode = options and options.mode or "text"
   local counter = SU.boolean(options.numbered, false) and "equation"
   counter = options.counter or counter -- overrides the default "equation" counter

   if mode == "display" then
      mbox.mode = b.mathMode.display
   elseif mode == "text" then
      mbox.mode = b.mathMode.textCramped
   else
      SU.error("Unknown math mode " .. mode)
   end

   SU.debug("math", function ()
      return "Resulting mbox: " .. tostring(mbox)
   end)
   mbox:styleDescendants()
   mbox:shapeTree()

   if mode == "display" then
      -- See https://github.com/sile-typesetter/sile/issues/2160
      --    We are not exactly doing the right things here with respect to
      --    paragraphing expectations.
      -- The vertical penalty will flush the previous paragraph, if any.
      SILE.call("penalty", { penalty = SILE.settings:get("math.predisplaypenalty"), vertical = true })
      SILE.typesetter:pushExplicitVglue(SILE.settings:get("math.displayskip"))
      -- Repeating the penalty after the skip does not hurt but should not be
      -- necessary if our page builder did its stuff correctly.
      SILE.call("penalty", { penalty = SILE.settings:get("math.predisplaypenalty"), vertical = true })
      SILE.settings:temporarily(function ()
         -- Center the equation in the space available up to the counter (if any),
         -- respecting the fixed part of the left and right skips.
         local lskip = SILE.settings:get("document.lskip") or SILE.types.node.glue()
         local rskip = SILE.settings:get("document.rskip") or SILE.types.node.glue()
         SILE.settings:set("document.parindent", SILE.types.node.glue())
         SILE.settings:set("current.parindent", SILE.types.node.glue())
         SILE.settings:set("document.lskip", SILE.types.node.hfillglue(lskip.width.length))
         SILE.settings:set("document.rskip", SILE.types.node.glue(rskip.width.length))
         SILE.settings:set("typesetter.parfillskip", SILE.types.node.glue())
         SILE.settings:set("document.spaceskip", SILE.types.length("1spc", 0, 0))
         SILE.typesetter:pushHorizontal(mbox)
         SILE.typesetter:pushExplicitGlue(SILE.types.node.hfillglue())
         if counter then
            options.counter = counter
            SILE.call("increment-counter", { id = counter })
            SILE.call("math:numberingstyle", options)
         elseif options.number then
            SILE.call("math:numberingstyle", options)
         end
         -- The vertical penalty will flush the equation.
         -- It must be done in the temporary settings block, because these have
         -- to apply as line boxes are being built.
         SILE.call("penalty", { penalty = SILE.settings:get("math.postdisplaypenalty"), vertical = true })
      end)
      SILE.typesetter:pushExplicitVglue(SILE.settings:get("math.displayskip"))
      -- Repeating: Same remark as for the predisplay penalty above.
      SILE.call("penalty", { penalty = SILE.settings:get("math.postdisplaypenalty"), vertical = true })
   else
      SILE.typesetter:pushHorizontal(mbox)
   end
end

return { ConvertMathML, handleMath }
