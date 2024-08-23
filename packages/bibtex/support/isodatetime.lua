-- ISO 8601-2 Extended Date/Time Format Level 1 (partial)
-- See https://www.loc.gov/standards/datetime/
-- Not yet supported, but unlikely to be needed in a bibliographic context:
--    Year prefix by Y (before -9999 or after 9999)
--    Unspecified digit(s) from the right (e.g. 202X, 2024-XX, etc.)

-- Examples:
-- "2020-01" (January 2020)
-- "2020-23" (Autumn 2020)
-- "2020-11-01" (November 1, 2020)
-- "2020-12-01T12:13:55+01:23" (December 1, 2020, 12:13:55 PM, UTC+1:23)
-- "2020-12-01T12:13:55Z" (December 1, 2020, 12:13:55 PM, UTC)
-- "2020-12-01T12:13:55" (December 1, 2020, 12:13:55 PM, local considered as UTC here)
-- "2033?" (2033, approximate / circa)
-- "2033-01~" (January 2033, approximate month
-- "2033-01-12%" (January 12, 2033, approximate day)
-- "2033-01-01/2033-01-12" (January 1-12, 2033)
-- "/2033-01-12" (up to January 12, 2033)
-- "2033-01-31/" (from January 31, 2033)

local lpeg = require("lpeg")
local R, S, P, C, Ct, Cg = lpeg.R, lpeg.S, lpeg.P, lpeg.C, lpeg.Ct, lpeg.Cg

local digit = R("09")
local dash = P("-")
local colon = P(":")
local slash = P("/")
local yapprox = P("?") / function ()
   return "true"
end
local mapprox = P("~") / function ()
   return "true"
end
local dapprox = P("%") / function ()
   return "true"
end
-- time
local D2 = digit * digit / tonumber
local offset = P("Z")
   + C(S("+-"))
      * C(D2)
      * colon
      * C(D2)
      / function (s, h, m)
         local sign = s == "+" and 1 or -1
         return { hour = h * sign, minute = m * sign }
      end
local timespec = P("T")
   * Cg(D2, "hour")
   * colon
   * Cg(D2, "minute")
   * colon
   * Cg(D2, "second")
   * Cg(offset ^ -1, "offset")
-- year from -9999 to 9999
local D4 = digit * digit * digit * digit / tonumber
local year = D4 + P(dash) * D4
-- month 01-12
local month = (P("0") * R("19") + P("1") * R("02")) / tonumber
-- season 21-24 (Spring, Summer, Autumn, Winter)
local season = P("2") * R("14") / function (s)
   return tonumber(s) - 20
end
-- day 01-31 (unverified)
local day = D2 / tonumber
-- date
local datespec = Cg(year, "year") * Cg(yapprox, "approximate")
   + Cg(year, "year") * (dash * Cg(month, "month") * Cg(mapprox, "approximate"))
   + Cg(year, "year") * (dash * Cg(month, "month") * (dash * Cg(day, "day") * Cg(dapprox, "approximate")))
   + Cg(year, "year") * (dash * Cg(season, "season"))
   + Cg(year, "year") * (dash * Cg(month, "month") * (dash * Cg(day, "day") * timespec ^ -1) ^ -1) ^ -1
local date = Ct(datespec)
   / function (t)
      return {
         year = t.year,
         season = t.season,
         month = t.month,
         approximate = t.approximate,
         day = t.day,
         -- N.B Local time does not make sense in a blibliographic context
         -- so we ignore the offset and consider all times to be UTC even without a Z
         hour = t.hour,
         minute = t.minute,
         second = t.second,
      }
   end
local startdate = Ct(date * slash * date ^ -1)
   / function (t)
      local approx = t[1].approximate or t[2] and t[2].approximate
      return {
         approximate = approx,
         range = true,
         startdate = t[1],
         enddate = t[2],
      }
   end
local enddateonly = slash
   * date
   / function (t)
      return {
         aproximate = t.approximate,
         range = true,
         enddate = t,
      }
   end
local dateinterval = startdate + enddateonly
local END = P(-1)
local isodatetimspec = (dateinterval + date) * END

--- Parse an ISO 8601 date/time string.
-- For a single date, the fields are year, month, day, season, hour, minute,
-- second, and approximate (true/false).
-- For date ranges, the start and/or end dates are returned in a table, with
-- the range field set to true for convenience.
-- @tparam string dt The date/time string
-- @treturn table A table with the parsed date/time, or nil if the string could not be parsed
local function isodatetime (dt)
   return lpeg.match(isodatetimspec, dt)
end

return isodatetime
