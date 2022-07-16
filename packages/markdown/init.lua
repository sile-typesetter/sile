--
-- Markdown native support for SILE
-- Using the lunamark library.
--
local utils = require("packages.markdown.utils")

local function simpleCommandWrapper (name)
  -- Simple wrapper argound a SILE command
  return function (s)
    if SILE.Commands[name] then
      return utils.createCommand (name, {}, s)
    end
    SU.warn("Unexpected command \\"..name.." (missing support for proper markdown processing)")
    return s
  end
end

-- A few mappings functions and tables

local listStyle = {
  Decimal = "arabic",
  UpperRoman = "Roman",
  LowerRoman = "roman",
  UpperAlpha = "Alpha",
  LowerAlpha = "alpha",
}
local listDelim = {
  OneParen = ")",
  Period = ".",
}

local function tableCellAlign (align)
  if align == 'l' then
    return 'left'
  elseif align == 'r' then
    return 'right'
  elseif align == 'c' then
    return 'center'
  else
    return 'default'
  end
end

-- Lunamark writer for SILE
-- Yay, direct lunamark AST conversion to SILE AST

local function SileAstWriter (options)
  local generic = require("lunamark.writer.generic")
  local writer = generic.new(options or {})

  -- Simple one-to-one mappings between lunamark AST and SILE

  writer.note = simpleCommandWrapper("markdown:internal:footnote")
  writer.strong = simpleCommandWrapper("strong")
  writer.paragraph = simpleCommandWrapper("markdown:internal:paragraph")
  writer.code = simpleCommandWrapper("code")
  writer.emphasis = simpleCommandWrapper("em")
  writer.strikeout = simpleCommandWrapper("strikethrough")
  writer.subscript = simpleCommandWrapper("textsubscript")
  writer.superscript = simpleCommandWrapper("textsuperscript")
  writer.blockquote = simpleCommandWrapper("markdown:internal:blockquote")
  writer.verbatim = simpleCommandWrapper("verbatim")
  writer.listitem = simpleCommandWrapper("item")
  writer.hrule = simpleCommandWrapper("fullrule")

  -- More complex mapping cases

  writer.header = function (s, level)
    return utils.createCommand("markdown:internal:header", { level = level }, s)
  end

  writer.bulletlist = function (items)
    local contents = {}
    for i = 1, #items do contents[i] = writer.listitem(items[i]) end
    return utils.createStructuredCommand("itemize", {}, contents)
  end

  writer.tasklist = function (items)
    local contents = {}
    for i = 1, #items do
      local bullet = (items[i][1] == "[X]") and "☑" or "☐"
      contents[i] = utils.createCommand("item", { bullet = bullet }, items[i][2])
     end
    return utils.createStructuredCommand("itemize", {}, contents)
  end

  writer.orderedlist = function (items, _, startnum, numstyle, numdelim) -- items, tight, ...
    local display = numstyle and listStyle[numstyle]
    local after = numdelim and listDelim[numdelim]
    local contents = {}
    for i= 1, #items do contents[i] = writer.listitem(items[i]) end
    return utils.createStructuredCommand("enumerate", { start = startnum or 1, display = display, after = after }, contents)
  end

  writer.link = function (label, uri, _) -- label, uri, title
    return utils.createCommand("markdown:internal:link", { src = uri }, { label })
  end

  writer.image = function (_, src, _, attr) -- label, src, title, attr
    local opts = attr or {} -- passthru (class and key-value pairs)
    opts.src = src
    return utils.createCommand("markdown:internal:image" , opts)
  end

  writer.span = function (content, attr)
    return utils.createCommand("markdown:internal:span" , attr, content)
  end

  writer.div = function (content, attr)
    return utils.createCommand("markdown:internal:div" , attr, content)
  end

  writer.fenced_code = function (s, _, _) -- s, infostring, attr
    return utils.createCommand("verbatim", {}, s)
  end

  writer.rawinline = function (content, format, _) -- content, format, attr
    return utils.createCommand("markdown:internal:rawinline", { format = format }, content)
  end

  writer.rawblock = function (content, format, _) -- content, format, attr
    return utils.createCommand("markdown:internal:rawblock", { format = format }, content)
  end

  writer.table = function (rows, caption) -- rows, caption
    -- caption is a text Str
    -- rows[1] has the headers
    -- rows[2] has the alignments (I know, it's weird...)
    -- then other rows follow
    local aligns = rows[2]
    local numberOfCols = #aligns
    local ptableRows = {}

    local headerCols = {}
    for j, column in ipairs(rows[1]) do
      local col = utils.createCommand("cell", { valign="middle", halign = tableCellAlign(aligns[j]) }, column)
      headerCols[#headerCols+1] = col
    end
    ptableRows[#ptableRows+1] = utils.createStructuredCommand("row", { background = "#eee" }, headerCols)

    for i = 3, #rows do
      local row = rows[i]
      local ptableCols = {}
      for j, column in ipairs(row) do
        local col = utils.createCommand("cell", { valign = "middle", halign = tableCellAlign(aligns[j]) }, column)
        ptableCols[#ptableCols+1] = col
      end
      ptableRows[#ptableRows+1] = utils.createStructuredCommand("row", {}, ptableCols)
    end

    local cWidth = {}
    for i = 1, numberOfCols do
      cWidth[i] = string.format("%.0f%%lw", 100 / numberOfCols)
    end
    local ptable = utils.createStructuredCommand("ptable", { header = true, cols = table.concat(cWidth, " ") }, ptableRows)

    if not caption then
      return ptable
    end

    local captioned = { ptable, utils.createCommand("caption", {}, caption) }
    local tablecmd = SILE.Commands["captioned-table"] and "captioned-table" or "markdown:fallback:captioned-table"
    return utils.createStructuredCommand(tablecmd, {}, captioned)
  end

  writer.definitionlist = function (items, _) -- items, tight
    local buffer = {}
    for _, item in ipairs(items) do
      buffer[#buffer + 1] = utils.createCommand("markdown:internal:term", {}, item.term)
      buffer[#buffer + 1] = utils.createStructuredCommand("markdown:internal:definition", {}, item.definitions)
    end
    return utils.createStructuredCommand("markdown:internal:paragraph", {}, buffer)
  end

  -- Final AST conversion logic.
  --   The lunamark "AST" is made of "ropes":
  --     "A rope is an array whose elements may be ropes, strings, numbers,
  --     or functions."
  --   The default implementation flattens that to a string, so we overrride it,
  --   in order to extract the AST and convert it to the SILE AST.
  --
  --   The methods that were overriden above actually started to introduce SILE
  --   AST command structures in place of some ropes. Therefore, we now walk
  --   these "extended" ropes merge the output, flattened to some degree, into
  --   a final SILE AST that we can process.

  function writer.rope_to_output (rope)
    local function walk(node)
      local out
      local ropeType = type(node)

      if ropeType == "string" then
        out = node
      elseif ropeType == "table" then
        local elements = {}
        -- Recursively expand and the the node list
        for i = 1, #node do
          local child = walk(node[i])
          if type(child) == "string" then
            -- Assemble consecutive strings
            if type(elements[#elements]) == "string" then
              elements[#elements] = elements[#elements] .. child
            elseif #child > 0 then
              elements[#elements+1] = child
            end
            -- Empty strings are skipped
          else
            elements[#elements+1] = child
          end
        end
        -- Copy the key-value pairs, i.e. in our case a potential SILE command
        -- (with "command", "options", etc. fields)
        for key, value in pairs(node) do
          if type(key)=="string" then
            elements[key] = value
           end
        end
        out = elements
      elseif ropeType == "function" then
        out = walk(node())
      else
        -- Not sure when it actually occurs (not observed on some sample
        -- Markdown files), but the lunamark original util.rope_to_string()
        -- says it can.
        out = tonumber(node)
      end

      -- Pure array nestings can be simplified without impact,
      -- generating a smaller resulting AST (and usually with more string
      -- elements being reassembled)
      if type(out) == "table" and #out == 1 and not out.command then
        out = out[1]
      end
      return out
    end
    return walk(rope)
  end

  return writer
end

local function init (class, _)
  class:loadPackage("markdown.commands")

  -- Extend inputters.

  SILE.inputs.markdown = {
    order = 2,
    appropriate = function (fn, _)
      return fn:match("md$") or fn:match("markdown$")
    end,
    process = function (data)
      local lunamark = require("lunamark")
      local reader = lunamark.reader.markdown
      local writer = SileAstWriter({
        layout = "compact" -- The default layout is to output \n\n as inter-block separator
                           -- Let's cancel it, and insert our own \par where needed.
      })
      local parse = reader.new(writer, {
        smart = true,
        strikeout = true,
        subscript=true,
        superscript = true,
        definition_lists = true,
        notes = true,
        inline_notes = true,
        fenced_code_blocks = true,
        fenced_code_attributes = true,
        bracketed_spans = true,
        fenced_divs = true,
        raw_attribute = true,
        link_attributes = true,
        startnum = true,
        fancy_lists = true,
        task_list = true,
        hash_enumerators = true,
        table_captions = true,
        pipe_table = true,
      })
      local t = parse(data)
      -- The Markdown parsing returns a string or a table.
      -- Wrap it in some structure so we can just process it.
      t = { [1] = t, id = "document", options = { class = "markdown" }}
      SILE.process(t)
    end
  }
end

return {
  init = init,
  documentation = [[\begin{document}
The \autodoc:package{markdown} package allows you to use Markdown, with plenty of additional
features and extensions, as your alternative format of choice for documents —without leaving
aside hooks to SILE, when felt necessary\footnote{So you get the best of two worlds, for an
efficient and direct Markdown to PDF conversion.}.

Once you have loaded the package, the \autodoc:command{\include[src=<file>]} command supports
natively reading and processing a Markdown file:

\begin{verbatim}
\\script[src=packages/markdown]
\\include[src=somefile.md]
\end{verbatim}

\smallskip

The speedy Markdown parsing relies on John MacFarlane’s excellent \strong{lunamark} Lua library,
which empovers this package and thus allows native processing of Markdown directly within SILE,
as a first-class language.

A whole dedicated chapter is dedicated to the topic, including a discussion on alternatives,
in an appendix to the SILE manual. Please refer to it for more details and an exhaustive
presentation of the capabilities.
\end{document}]]
}
