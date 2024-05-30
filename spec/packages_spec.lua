SILE = require("core.sile")
local lfs = require("lfs")

describe("#package", function ()
   for pkg in lfs.dir("packages") do
      if pkg ~= ".." and pkg ~= "." and pkg ~= "base.lua" and not pkg:match("~$") then
         describe(pkg, function ()
            local pack

            it("should load", function ()
               assert.has.no.error(function ()
                  pack = require("packages." .. pkg)
               end)
            end)

            it("inherit from the base package", function ()
               assert.is.truthy(pack.type == "package")
            end)

            it("return a module", function ()
               assert.is.truthy(type(pack) == "table")
            end)

            it("be documented", function ()
               assert.is.string(pack.documentation)
            end)
         end)
      end
   end
end)
