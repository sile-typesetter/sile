local function registerCommands (_)

  SILE.registerCommand("unichar", function(_, content)
    local cp = content[1]
    if type(cp) ~= "string" then SU.error("Bad argument to \\unicode") end
    local hlist = SILE.typesetter.state.nodes
    local char = SU.utf8charfromcodepoint(cp)
    if #hlist > 1 and hlist[#hlist].is_unshaped then
      hlist[#hlist].text = hlist[#hlist].text .. char
    else
      SILE.typesetter:typeset(char)
    end
  end)

end

return {
  registerCommands = registerCommands,
  documentation = [[\begin{document}
\script[src=packages/unichar]
SILE is Unicode compatible, and expects its input files to be in the UTF-8 encoding.
(The actual range of Unicode characters supported will depend on the supported ranges
of the fonts that SILE is using to typeset.) Some Unicode characters are hard to
locate on a standard keyboard, and so are difficult to enter into SILE documents.
The \autodoc:package{unichar} package helps with this problem by providing a command to enter
Unicode codepoints. After loading \autodoc:package{unichar}, the \autodoc:command{\unichar} command becomes
available:

\begin{verbatim}
\line
\\unichar\{U+263A\} \% produces \font[family=Symbola]{\unichar{U+263A}}
\line
\end{verbatim}

If the argument to \autodoc:command{\unichar} begins \code{U+}, \code{u+}, \code{0x} or \code{0X},
then it is assumed to be a hexadecimal value. Otherwise it is assumed to be a
decimal codepoint.
\end{document}]] }
