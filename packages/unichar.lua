local function utf8encode(code)
  if code < 0 then
    error('Code point must not be negative.')
  elseif code <= 0x7f then
    return string.char(code)
  elseif code <= 0x7ff then
    local c1 = code / 64 + 192
    local c2 = code % 64 + 128
    return string.char(c1, c2)
  elseif code <= 0xffff then
    local c1 = code / 4096 + 224
    local c2 = code % 4096 / 64 + 128
    local c3 = code % 64 + 128
    return string.char(c1, c2, c3)
  elseif code <= 0x10ffff then
    local c1 = code / 262144 + 240
    local c2 = code % 262144 / 4096 + 128
    local c3 = code % 4096 / 64 + 128
    local c4 = code % 64 + 128
    return string.char(c1, c2, c3, c4)
  end
  return ''
end

SILE.registerCommand("unichar", function(options, content)
  local cp = content[1]
  if type(cp) ~= "string" then SU.error("Bad argument to \\unicode") end
  hex = (cp:match("[Uu]%+(%x+)") or cp:match("0[xX](%x+)"))
  if hex then
    cp = tonumber("0x"..hex)
  elseif tonumber(cp) then 
    cp = tonumber(cp)
  end
  SILE.typesetter:typeset(utf8encode(cp))
end)

return { documentation = [[\begin{document}
\script[src=packages/unichar]
SILE is Unicode compatible, and expects its input files to be in the UTF-8 encoding.
(The actual range of Unicode characters supported will depend on the supported ranges
of the fonts that SILE is using to typeset.) Some Unicode characters are hard to
locate on a standard keyboard, and so are difficult to enter into SILE documents.
The \code{unichar} package helps with this problem by providing a command to enter
Unicode codepoints. After loading \code{unichar}, the \code{\\unichar} command becomes
available:

\begin{verbatim}
\line
\\unichar\{U+263A\} \% produces \font[family=Symbola]{\unichar{U+263A}}
\line
\end{verbatim}

If the argument to \code{\\unichar} begins \code{U+}, \code{u+}, \code{0x} or \code{0X}, 
then it is assumed to be a hexadecimal value. Otherwise it is assumed to be a
decimal codepoint.
\end{document}]] }
