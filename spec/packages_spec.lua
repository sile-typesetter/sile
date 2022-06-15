SILE = require("core.sile")
local lfs = require("lfs")

describe("#package", function ()

  for pkg in lfs.dir("packages") do

    if pkg ~= ".." and pkg ~= "."
      and pkg ~= "pandoc"
      and pkg ~= "pdf"
      and pkg ~= "pdfstructure"
      and pkg ~= "url"
      then

      describe(pkg, function ()

        local pack

        it("should load", function ()
          assert.has.no.error(function()
            pack = require("packages." .. pkg)
          end)
        end)

        it("return a module", function ()
          assert.truthy(type(pack) == "table")
        end)

        it("be documented", function ()
          assert.string(pack.documentation)
        end)

      end)

    end

  end

end)
