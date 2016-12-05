-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- LaTeX writer for lunamark.
-- Extends the [lunamark.writer.tex].

local M = {}

local tex = require("lunamark.writer.tex")
local util = require("lunamark.util")
local format = string.format

--- Returns a new LaTeX writer.
--
-- *   `options` is a table with parsing options.
--     The following fields are significant:
--
--     `citations`
--     :   Enable citations as in pandoc. Either a boolean or one of
--         the following strings should be specified:
--
--         - `latex`    -- produce basic LaTeX2e citations,
--         - `natbib`   -- produce citations for the Natbib package, or
--         - `biblatex` -- produce citations for the BibLaTeX package.
--
-- For a list of fields in the writer, see [lunamark.writer.generic].
function M.new(options)
  options = options or {}
  local LaTeX = tex.new(options)

  function LaTeX.code(s)
    return {"\\texttt{",LaTeX.string(s),"}"}
  end

  function LaTeX.link(lab,src,tit)
    return {"\\href{",LaTeX.string(src),"}{",lab,"}"}
  end

  function LaTeX.image(lab,src,tit)
    return {"\\includegraphics{",LaTeX.string(src),"}"}
  end

  local function listitem(s)
    return {"\\item ",s}
  end

  function LaTeX.bulletlist(items)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = listitem(item)
    end
    local contents = util.intersperse(buffer,"\n")
    return {"\\begin{itemize}\n",contents,"\n\\end{itemize}"}
  end

  function LaTeX.orderedlist(items)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = listitem(item)
    end
    local contents = util.intersperse(buffer,"\n")
    return {"\\begin{enumerate}\n",contents,"\n\\end{enumerate}"}
  end

  function LaTeX.emphasis(s)
    return {"\\emph{",s,"}"}
  end

  function LaTeX.strong(s)
    return {"\\textbf{",s,"}"}
  end

  function LaTeX.blockquote(s)
    return {"\\begin{quote}\n",s,"\n\\end{quote}"}
  end

  function LaTeX.verbatim(s)
    return {"\\begin{verbatim}\n",s,"\\end{verbatim}"}
  end

  LaTeX.fenced_code = LaTeX.verbatim

  function LaTeX.header(s,level)
    local cmd
    if level == 1 then
      cmd = "\\section"
    elseif level == 2 then
      cmd = "\\subsection"
    elseif level == 3 then
      cmd = "\\subsubsection"
    elseif level == 4 then
      cmd = "\\paragraph"
    elseif level == 5 then
      cmd = "\\subparagraph"
    else
      cmd = ""
    end
    return {cmd,"{",s,"}"}
  end

  LaTeX.hrule = "\\hspace{\\fill}\\rule{.6\\linewidth}{0.4pt}\\hspace{\\fill}"

  function LaTeX.note(contents)
    return {"\\footnote{",contents,"}"}
  end

  local function citation_optargs(cite)
    if cite.prenote and cite.postnote then
      return {"[", cite.prenote, "][", cite.postnote, "]"}
    elseif cite.prenote and not cite.postnote then
      return {"[", cite.prenote, "][]"}
    elseif not cite.prenote and cite.postnote then
      return {"[", cite.postnote, "]"}
    else
      return ""
    end
  end

  if options.citations == true or options.citations == "latex" then
    --- Basic LaTeX2e citations
    function LaTeX.citations(_, cites)
      local buffer = {}
      local opened_braces = false
      for i, cite in ipairs(cites) do
        if cite.prenote or cite.postnote then -- A separate complex citation
          buffer[#buffer + 1] = {opened_braces and "}" or "",
            cite.prenote and {i == 1 and "" or " ", cite.prenote, "~"} or
            "", {(i == 1 or cite.prenote) and "" or " ", "\\cite"},
            cite.postnote and {"[", cite.postnote, "]"} or "", "{", cite.name,
            cite_postnote and {"~", cite_postnote} or "", "}"}
          opened_braces = false
        else -- A string of simple citations
          buffer[#buffer + 1] = {opened_braces and ", " or {i == 1 and "" or
            " ", "\\cite{"}, cite.name}
          opened_braces = true
        end
      end
      if opened_braces then
        buffer[#buffer + 1] = "}"
      end
      return buffer
    end
  elseif options.citations == "natbib" then
    --- NatBib citations
    function LaTeX.citations(text_cites, cites)
      if #cites == 1 then -- A single citation
        local cite = cites[1]
        if text_cites then
          return {"\\citet", citation_optargs(cite), "{", cite.name, "}"}
        else
          return {cite.suppress_author and "\\citeyearpar" or "\\citep",
            citation_optargs(cite), "{", cite.name, "}"}
        end
      else -- A string of citations
        local complex = false
        local last_suppressed = nil
        for _, cite in ipairs(cites) do
          if cite.prenote or cite.postnote or
             cite.suppress_author == not last_suppressed then
            complex = true
            break
          end
          last_suppressed = cite.suppress_author
        end
        if complex then -- A string of complex citations
          local buffer = {"\\citetext{"}
          for i, cite in ipairs(cites) do
            buffer[#buffer + 1] = {i ~= 1 and "; " or "", cite.suppress_author
              and "\\citeyear" or (text_cites and "\\citealt" or "\\citealp"),
              citation_optargs(cite), "{", cite.name, "}"}
          end
          buffer[#buffer + 1] = "}"
          return buffer
        else -- A string of simple citations
          local buffer = {}
          for i, cite in ipairs(cites) do
            buffer[#buffer + 1] = {i == 1 and (text_cites and "\\citet{" or
              "\\citep{") or ", ", cite.name}
          end
          buffer[#buffer + 1] = "}"
          return buffer
        end
      end
    end
  elseif options.citations == "biblatex" then
    --- BibLaTeX citations
    function LaTeX.citations(text_cites, cites)
      if #cites == 1 then -- A single citation
        local cite = cites[1]
        if text_cites then
          return {"\\textcite", citation_optargs(cite), "{", cite.name, "}"}
        else
          return {"\\autocite", cite.suppress_author and "*" or "",
            citation_optargs(cite), "{", cite.name, "}"}
        end
      else -- A string of citations
        local buffer = {text_cites and "\\textcites" or "\\autocites"}
        for _, cite in ipairs(cites) do
          buffer[#buffer + 1] = {citation_optargs(cite), "{", cite.name, "}"}
        end
        return buffer
      end
    end
  end

  function LaTeX.definitionlist(items)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = format("\\item[%s]\n%s",
        item.term, util.intersperse(item.definitions, LaTeX.interblocksep))
    end
    local contents = util.intersperse(buffer, LaTeX.containersep)
    return {"\\begin{description}\n",contents,"\n\\end{description}"}
  end

  LaTeX.template = [===[
\documentclass{article}
\usepackage{amssymb,amsmath}
\usepackage{ifxetex,ifluatex}
\ifxetex
  \usepackage{fontspec,xltxtra,xunicode}
  \defaultfontfeatures{Mapping=tex-text,Scale=MatchLowercase}
\else
  \ifluatex
    \usepackage{fontspec}
    \defaultfontfeatures{Mapping=tex-text,Scale=MatchLowercase}
  \else
    \usepackage[utf8]{inputenc}
  \fi
\fi
\ifxetex
  \usepackage[setpagesize=false, % page size defined by xetex
              unicode=false, % unicode breaks when used with xetex
              xetex]{hyperref}
\else
  \usepackage[unicode=true]{hyperref}
\fi
\hypersetup{breaklinks=true, pdfborder={0 0 0}}
\setlength{\parindent}{0pt}
\setlength{\parskip}{6pt plus 2pt minus 1pt}
\setlength{\emergencystretch}{3em}  % prevent overfull lines
\setcounter{secnumdepth}{0}

\title{$title}
\author{$sepby{author}[=[$it]=][=[ \and ]=]}
\date{$date}

\begin{document}

$if{ title }[[\maketitle
]]
$body

\end{document}
]===]

  return LaTeX
end

return M
