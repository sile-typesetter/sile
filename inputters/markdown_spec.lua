SILE = require("core.sile")
SILE.backend = "dummy"
SILE.init()
SILE.utilities.error = error

local astToSil = require("core.ast").astToSil

describe("#Markdown #inputter", function ()
  local inputter = SILE.inputters.markdown()

  describe("should parse", function ()
    it("header", function()
      local tree = inputter:parse("# Header\n")
      local sil = astToSil(tree)
      assert.is.equal([[\begin[class="markdown"]{document}
\markdown:internal:header[level="1"]{Header}
\end{document}
]], sil)
    end)
    it("header with attributes", function()
      local tree = inputter:parse("## Header {#hash - lang=en}\n")
      local sil = astToSil(tree)
      assert.is.equal([[\begin[class="markdown"]{document}
\markdown:internal:header[class="unnumbered", id="hash", lang="en", level="2"]{Header}
\end{document}
]], sil)
    end)
    it("basic inline markup", function()
        local tree = inputter:parse("normal **bold** _italic_ `code`")
        local sil = astToSil(tree)
        assert.is.equal([[\begin[class="markdown"]{document}
normal \strong{bold} \em{italic} \code{code}
\end{document}
]], sil)
    end)
    it("horizontal rule", function()
      local tree = inputter:parse("---\n\n")
      local sil = astToSil(tree)
      assert.is.equal([[\begin[class="markdown"]{document}
\fullrule{}
\end{document}
]], sil)
    end)
  end)
  it("span in paragraph", function()
    local tree = inputter:parse("[underlined]{.underline}\n\n")
    local sil = astToSil(tree)
    assert.is.equal([[\begin[class="markdown"]{document}
\markdown:internal:paragraph{\markdown:internal:span[class="underline"]{underlined}}
\end{document}
]], sil)
  end)
  it("bullet list", function()
    local tree = inputter:parse("- Item1\n- Item2\n")
    local sil = astToSil(tree)
    assert.is.equal([[\begin[class="markdown"]{document}
\itemize{\item{Item1}\item{Item2}}
\end{document}
]], sil)
  end)
end)
