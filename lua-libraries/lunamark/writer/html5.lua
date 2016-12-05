-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- HTML 5 writer for lunamark.
-- Extends [lunamark.writer.html], but uses `<section>` tags for sections
-- if `options.containers` is true.

local M = {}

local html = require("lunamark.writer.html")

--- Returns a new HTML 5 writer.
-- `options` is as in `lunamark.writer.html`.
-- For a list of fields, see [lunamark.writer.generic].
function M.new(options)
  options = options or {}
  local Html5 = html.new(options)

  Html5.container = "section"

  Html5.template = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$title</title>
</head>
<body>
$body
</body>
</html>
]]

  return Html5
end

return M
