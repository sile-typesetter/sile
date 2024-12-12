SILE = require("core.sile")
SILE.input.backend = "dummy"
SILE.init()
SILE.utilities.error = error

describe("#SIL #inputter", function ()
   local inputter = SILE.inputters.sil()

   describe("should parse", function ()
      it("commands with content", function ()
         local t = inputter:parse([[\foo{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("bar", t[1])
      end)

      it("commands without content", function ()
         local t = inputter:parse([[\foo{\foo bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("foo", t[1].command)
         assert.is.equal(" bar", t[2])
         assert.is.equal(nil, t[1][1])
      end)

      it("commands with arg", function ()
         local t = inputter:parse([[\foo[baz=qiz]{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz", t.options.baz)
         assert.is.equal("bar", t[1])
      end)

      it("commands with multiple args", function ()
         local t = inputter:parse([[\foo[baz=qiz,qiz=baz]{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz", t.options.baz)
         assert.is.equal("baz", t.options.qiz)
         assert.is.equal("bar", t[1])
      end)

      it("commands with quoted arg", function ()
         local t = inputter:parse([[\foo[baz="qiz qiz"]{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz qiz", t.options.baz)
         assert.is.equal("bar", t[1])
      end)

      it("commands with space around args and values", function ()
         local t = inputter:parse([[\foo[ baz = qiz qiz ]{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz qiz", t.options.baz)
      end)

      it("commands with multiple quoted args", function ()
         local t = inputter:parse([[\foo[baz="qiz, qiz",qiz="baz, baz"]{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz, qiz", t.options.baz)
         assert.is.equal("baz, baz", t.options.qiz)
         assert.is.equal("bar", t[1])
      end)

      it("commands with quoted arg with escape", function ()
         local t = inputter:parse([[\foo[baz="qiz \"qiz\""]{bar}]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal('qiz "qiz"', t.options.baz)
         assert.is.equal("bar", t[1])
      end)

      it("fragments with multiple top level nodes", function ()
         local t = inputter:parse([[foo \bar{baz}]])[1]
         assert.is.equal("document", t.command)
         assert.is.equal("foo ", t[1][1])
         assert.is.equal("bar", t[1][2].command)
         assert.is.equal("baz", t[1][2][1])
      end)

      it("commands and environments to equivalent syntax trees", function ()
         local t1 = inputter:parse([[\document{\em{emphasis}}]])[1]
         local t2 = inputter:parse([[\begin{document}\begin{em}emphasis\end{em}\end{document}]])[1]
         -- The "col" positions will differ, and we don't care about them
         -- The "id" will differ, make it identical for comparison
         local s1 = pl.pretty.write(t1, ""):gsub("col=%d+", "col=N")
         local s2 = pl.pretty.write(t2, ""):gsub('id="environment"', 'id="command"'):gsub("col=%d+", "col=N")
         assert.is.equal(s1, s2)
      end)
   end)

   describe("should reject", function ()
      it("commands with bad characters", function ()
         local pattern = "parse error, Unexpected character at end of input"
         assert.has_error.match(function ()
            inputter:parse([[\"]])
         end, pattern)
         assert.has_error.match(function ()
            inputter:parse([[\']])
         end, pattern)
         assert.has_error.match(function ()
            inputter:parse([[\"o]])
         end, pattern)
      end)

      it("unclosed commands", function ()
         assert.has_error.matches(function ()
            inputter:parse([[\foo{bar]])
         end, "parse error at <eof>, %} expected")
      end)

      it("unclosed environments", function ()
         assert.has_error.matches(function ()
            inputter:parse([[\begin{foo}bar]])
         end, "parse error at <eof>, Environment begun but never ended")
      end)

      it("mismatched environments", function ()
         assert.has_error.matches(function ()
            inputter:parse([[\begin{foo}\begin{bar}baz\end{foo}\end{bar}]])
         end, "parse error, Environment mismatch")
      end)
   end)
end)
