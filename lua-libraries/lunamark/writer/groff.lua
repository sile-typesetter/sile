-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- Generic groff writer for lunamark.
-- This is currently used as the basis for [lunamark.writer.man].
-- In principle other groff-based writers could also extend it.

local M = {}

local util = require("lunamark.util")
local generic = require("lunamark.writer.generic")

--- Returns a new Groff writer.
-- For a list of all fields, see [lunamark.writer.generic].
function M.new(options)
  options = options or {}
  local Groff = generic.new(options)

  Groff.interblocksep = "\n\n"  -- insensitive to layout

  Groff.containersep = "\n"

  Groff.linebreak = ".br\n"

  Groff.ellipsis = "\\&..."

  Groff.mdash = "\\[em]"

  Groff.ndash = "\\[en]"

  Groff.nbsp = "\\~"

  function Groff.singlequoted(s)
    return {"`",s,"'"}
  end

  function Groff.doublequoted(s)
    return {"\\[lq]",s,"\\[rq]"}
  end

  Groff.escaped = {
     ["@"] = "\\@",
     ["\\"] = "\\\\",
   }

  local escaped_utf8_triplet = {
    ["\226\128\156"] = "\\[lq]",
    ["\226\128\157"] = "\\[rq]",
    ["\226\128\152"] = "`",
    ["\226\128\153"] = "'",
    ["\226\128\148"] = "\\[em]",
    ["\226\128\147"] = "\\[en]",
    ["\194\160"]     = "\\ ",
  }

  local escape = util.escaper(Groff.escaped, escaped_utf8_triplet)

  Groff.string = escape

  Groff.citation = escape

  function Groff.inline_html()
  end

  function Groff.display_html()
  end

  function Groff.code(s)
    return {"\\f[C]",s,"\\f[]"}
  end

  function Groff.emphasis(s)
    return {"\\f[I]",s,"\\f[]"}
  end

  function Groff.strong(s)
    return {"\\f[B]",s,"\\f[]"}
  end

  return Groff
end

return M
