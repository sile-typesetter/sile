SILE.hyphenator.languages.grc = { patterns={} }

SILE.nodeMakers.grc = pl.class({
    _base = SILE.nodeMakers.unicode,
    iterator = function (self, items)
      return coroutine.wrap(function ()
        for i = 1, #items do
          self:addToken(items[i].text, items[i])
          self:makeToken()
          self:makePenalty()
          coroutine.yield(SILE.nodefactory.glue("0pt plus 2pt"))
        end
      end)
    end
  })

local swap = SILE.nodefactory.vbox({})
swap.outputYourself = function (_, typesetter, _)
  typesetter.frame.direction = typesetter.frame.direction == "LTR-TTB" and "RTL-TTB" or "LTR-TTB"
  typesetter.frame:newLine()
end

SILE.registerCommand("boustrophedon", function (_, content)
  SILE.typesetter:leaveHmode()
  local saveBoxup = SILE.typesetter.boxUpNodes
  local swaps = 0
  SILE.typesetter.boxUpNodes = function (self)
    local vboxlist = saveBoxup(self)
    local nl = {}
    for i = 1, #vboxlist do
      nl[#nl+1] = vboxlist[i]
      if nl[#nl].is_vbox then
        nl[#nl+1] = swap
        swaps = swaps + 1
      end
    end
    return nl
  end
  SILE.process(content)
  SILE.typesetter:leaveHmode()
  SILE.typesetter.boxUpNodes = saveBoxup
  if swaps % 2 == 1 then
    SILE.typesetter:pushVbox(swap)
  end
end)

return {
documentation = [[\begin{document}

Partly designed to show off SILE’s extensibility, and partly designed for
real use by classicists, the \autodoc:package{boustrophedon} package allows you to typeset
ancient Greek texts in the ‘ox-turning’ layout—the first line is
written left to right as normal, but the next is set right to
left, then left to right, and so on. To use it, you will need to set the font’s language to ancient
Greek (\code{grc}) and wrap text in a \autodoc:environment{boustrophedon} environment:

\set[parameter=document.parindent,value=0]{\par
\begin{boustrophedon}
\font[size=22pt,family=Gentium Plus,language=grc]
\noindent{}ΧΑΙΡΕΔΕΜΟΤΟΔΕΣΕΜΑΠΑΤΕΡΕΣΤΕΣΕΘΑΝΟΝΤΟΣΑΝΦΙΧΑΡΕΣΑΓΑΘΟΝΠΑΙΔΑΟΛΟΦΘΡΟΜΕΝΟΣΦΑΙΔΙΜΟΣΕΠΟΙΕ
\end{boustrophedon}
}

(Under normal circumstances, that line would appear as \font[language=grc,family=Gentium Plus]{
ΧΑΙΡΕΔΕΜΟΤΟΔΕΣΕΜΑΠΑΤΕΡΕΣΤΕΣΕΘΑΝΟΝΤΟΣΑΝΦΙΧΑΡΕΣΑΓΑΘΟΝΠΑΙΔΑΟΛΟΦΘΡΟΜΕΝΟΣΦΑΙΔΙΜΟΣΕΠΟΙΕ
}.)

\end{document}]] }
