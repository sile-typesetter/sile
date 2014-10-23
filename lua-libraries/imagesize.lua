-- Perl version copyright (c) 2008 by Randy J. Ray, all rights reserved
-- Lua port copyright (c) 2008 Geoff Richards.
--
-- Copying and distribution are permitted under the terms of the Artistic
-- License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php) or
-- the GNU LGPL (http://www.opensource.org/licenses/lgpl-license.php).
--
-- Once upon a time, this code was lifted almost verbatim from wwwis by Alex
-- Knowles, alex@ed.ac.uk. Since then, even I barely recognize it. It has
-- contributions, fixes, additions and enhancements from all over the world.

local M = { _NAME = "imagesize" }

local TYPE_MAP = {
    ["^GIF8[7,9]a"]          = "gif",
    ["^\255\216"]            = "jpeg",
    ["^\137PNG\13\10\26\10"] = "png",
    ["^P[1-7]"]              = "pnm",   -- also XVpics
    ["#define%s+%S+%s+%d+"]  = "xbm",
    ["/%* XPM %*/"]          = "xpm",
    ["^MM%z%*"]              = "tiff",
    ["^II%*%z"]              = "tiff",
    ["^BM"]                  = "bmp",
    ["^8BPS"]                = "psd",
    ["^PCD_OPA"]             = "pcd",
    ["^[FC]WS"]              = "swf",
    ["^\138MNG\13\10\26\10"] = "mng",
    ["^gimp xcf "]           = "xcf",   -- TODO - usually gziped
}

-- This is empty because each option's defaults are handled individually
-- by the modules for the specific file format.  This is here just to avoid
-- creating a new empty table every time.  It should never change.
local DEFAULT_OPTIONS = {}

function M.imgsize (filename, options)
    options = options or DEFAULT_OPTIONS

    local filetype = type(filename)
    local file, closefile, origoffset
    if filetype == "string" or filetype == "number" then
        file, err = io.open(filename, "rb")
        if not file then
            return nil, nil, "error opening file '" .. filename .. "': " .. err
        end
        closefile = true
    else
        file, closefile = filename, false
        origoffset = file:seek()
    end

    local header = file:read(256)
    if not header then return nil, nil, "file is empty" end
    local ok, err = file:seek("set")
    if not ok then return nil, nil, "error seeking in file: " .. err end

    for pattern, format in pairs(TYPE_MAP) do
        if header:find(pattern) then
            local sizefunc = require("imagesize.format." .. format)
            local x, y, id = sizefunc(file, options)
            if closefile then file:close() end
            if origoffset then file:seek("set", origoffset) end
            return x, y, id
        end
    end

    if closefile then file:close() end
    if origoffset then file:seek("set", origoffset) end
    return nil, nil, "file format not recognized"
end

-- This StringFile class is a very simple read-only file handle for reading
-- from a string.  It supports just enough of the normal file handle API to
-- do what the format functions need.
local StringFile = {}
StringFile.__index = StringFile

function StringFile:read (bytes)
    assert(type(bytes) == "number",
           "this mock file handle can only read a number of bytes")
    if self._offset >= self._data:len() then return nil end
    local buf = self._data:sub(self._offset + 1, self._offset + bytes)
    self._offset = self._offset + bytes
    return buf
end

function StringFile:seek (whence, offset)
    if not whence and not offset then return self._offset end
    assert(whence == "set", "this mock file handle can only seek with 'set'")
    offset = offset or 0
    self._offset = offset
    return offset
end

local function _line_iter (self)
    if self._offset >= self._data:len() then return nil end
    local _, endp, line = self._data:find("([^\n]*)\n?", self._offset + 1)
    self._offset = endp
    return line
end
function StringFile:lines () return _line_iter, self end

function M.imgsize_string (s, options)
    local file = setmetatable({
        _data = s,
        _offset = 0,
    }, StringFile)
    return M.imgsize(file, options)
end

return M
-- vi:ts=4 sw=4 expandtab
