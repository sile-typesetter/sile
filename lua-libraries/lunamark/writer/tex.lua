-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- Generic TeX writer for lunamark.
-- It extends [lunamark.writer.generic] and is extended by
-- [lunamark.writer.latex] and [lunamark.writer.context].

local M = {}

local util = require("lunamark.util")
local generic = require("lunamark.writer.generic")
local entities = require("lunamark.entities")
local format = string.format

--- Returns a new TeX writer.
-- For a list ofy fields, see [lunamark.writer.generic].
function M.new(options)
  local options = options or {}
  local TeX = generic.new(options)

  TeX.interblocksep = "\n\n"  -- insensitive to layout

  TeX.containersep = "\n"

  TeX.linebreak = "\\\\"

  TeX.ellipsis = "\\ldots{}"

  TeX.mdash = "---"

  TeX.ndash = "--"

  function TeX.singlequoted(s)
    return format("`%s'",s)
  end

  function TeX.doublequoted(s)
    return format("``%s''",s)
  end

  TeX.escaped = {
     ["{"] = "\\{",
     ["}"] = "\\}",
     ["$"] = "\\$",
     ["%"] = "\\%",
     ["&"] = "\\&",
     ["_"] = "\\_",
     ["#"] = "\\#",
     ["^"] = "\\^{}",
     ["\\"] = "\\char92{}",
     ["~"] = "\\char126{}",
     ["|"] = "\\char124{}",
     ["<"] = "\\char60{}",
     [">"] = "\\char62{}",
     ["["] = "{[}", -- to avoid interpretation as optional argument
     ["]"] = "{]}",
   }

  local str_escaped = {
     ["\226\128\156"] = "``",
     ["\226\128\157"] = "''",
     ["\226\128\152"] = "`",
     ["\226\128\153"] = "'",
     ["\226\128\148"] = "---",
     ["\226\128\147"] = "--",
     ["\194\160"]     = "~",
   }

  local escaper = util.escaper(TeX.escaped, str_escaped)

  TeX.string = escaper

  function TeX.inline_html(s)
    return ""
  end

  function TeX.display_html(s)
    return ""
  end

  function TeX.paragraph(s)
    return s
  end

  return TeX
end

return M
