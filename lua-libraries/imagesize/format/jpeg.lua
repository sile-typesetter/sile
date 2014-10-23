-- Andrew Tong, werdna@ugcs.caltech.edu           February 14, 1995
-- modified slightly by alex@ed.ac.uk
-- and further still by rjray@blackperl.com
-- optimization and general re-write from tmetro@vl.com

local Util = require "imagesize.util"

local MIME_TYPE = "image/jpeg"

local MARKER = 0xFF         -- Section marker.

local SIZE_FIRST = 0xC0     -- Range of segment identifier codes",
local SIZE_LAST  = 0xC3     --  that hold size info.

local function size (stream, options)
    -- Dummy read to skip header ID
    stream:read(2)

    while true do
        local length = 4
        local segheader = stream:read(length)
        if not segheader or segheader:len() ~= length then
            return nil, nil, "end of file before JPEG size found"
        end

        -- Extract the segment header.
        local marker, code = segheader:byte(1, 2)
        length = Util.get_uint16_be(segheader, 3)

        -- Verify that it's a valid segment.
        if marker ~= MARKER then
            -- Was it there?
            return nil, nil, "JPEG marker not found"
        elseif code >= SIZE_FIRST and code <= SIZE_LAST then
            -- Segments that contain size info
            length = 5
            local sizeinfo = stream:read(length)
            if not sizeinfo or sizeinfo:len() ~= length then
                return nil, nil, "JPEG file's size info incomplete"
            end
            return Util.get_uint16_be(sizeinfo, 4),
                   Util.get_uint16_be(sizeinfo, 2), MIME_TYPE
        else
            -- Dummy read to skip over data
            stream:read(length - 2)
        end
    end
end

return size
-- vi:ts=4 sw=4 expandtab
