return function()
    local plain = require "classes.plain"
    local class = plain()
    SILE.documentState.documentClass = class

    class:loadPackage("frametricks")

    SILE.call("showframe",{ id = "all"})
    for i = 1, 50 do
        SILE.call("supereject")
    end

end
