-- (c) 2009-2011 John MacFarlane.  Released under MIT license.
-- See the file LICENSE in the source for details.

--- Provides access to all lunamark writers without preloading
-- them.  Writer modules are loaded only when needed.
--
--     local writers = require("lunamark.writer")
--     local htmlwriter = writers.html       -- html writer loaded now
--     local myformat = 'latex'
--     local mywriter = writers[myformat]    -- latex writer loaded now

local G = {}

setmetatable(G,{ __index = function(t,name)
                             local mod = require("lunamark.writer." .. name)
                             rawset(t,name,mod)
                             return t[name]
                            end })

return G
