SILE = require("core.sile")
local lfs = require("lfs")

describe("#packages like", function ()

  local _, dir_obj = lfs.dir("packages")
  local file = dir_obj:next()

  it("foo", function() end)

  while file do
    local pkg, ok = file:gsub(".lua$", "")
    if ok == 1
      and pkg ~= "color-fonts"
      and pkg ~= "font-fallback"
      and pkg ~= "pandoc"
      and pkg ~= "pdf"
      and pkg ~= "pdfstructure"
      and pkg ~= "url"
      then
      describe(pkg, function ()

        it("should load", function ()
          assert.has.no.error(function() require("packages." .. pkg) end)
        end)

        it("should have #documentation", function ()
          local mod = require("packages." .. pkg)
          assert.truthy(type(mod) == "table")
          assert.truthy(mod.documentation)
        end)

      end)
    end
    file = dir_obj:next()
  end

end)
