-- (c) 2009-2011 John MacFarlane.  Released under MIT license.
-- See the file LICENSE in the source for details.

--- Provides access to all lunamark readers without preloading
-- them.  Reader modules are loaded only when needed.
--
--     local readers = require("lunamark.reader")
--     local htmlreader = readers.html       -- html reader loaded now
--     local myformat = 'markdown'
--     local myreader = readers[myformat]    -- markdown reader loaded now

local G = {}

setmetatable(G,{ __index = function(t,name)
                             local mod = require("lunamark.reader." .. name)
                             rawset(t,name,mod)
                             return t[name]
                            end })

return G
