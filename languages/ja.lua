-- "jlreq" refers to http://www.w3.org/TR/jlreq/
-- "JIS" refers to JIS X 4051

local hiragana = function (c) return c > 0x3040 and c <= 0x309f end
local katakana = function (c) return c > 0x30a0 and c <= 0x30ff end
local kanji = function (c) return c >= 0x4e00 and c <= 0x9fcc end

local classes = { -- from jlreq
  [0x2018] = 1, [0x201C] = 1, [0x0028] = 1, [0x3014] = 1, [0x005B] = 1,
  [0x007B] = 1, [0x3008] = 1, [0x300A] = 1, [0x300C] = 1, [0x300E] = 1,
  [0x3010] = 1, [0x2985] = 1, [0x3018] = 1, [0x3016] = 1, [0x00AB] = 1, [0x301D] = 1,
  [0xFF08] = 1, -- see note 1 of appendix A
  [0x2019] = 2, [0x201D] = 2, [0x0029] = 2, [0x3015] = 2, [0x005D] = 2,
  [0x007D] = 2, [0x3009] = 2, [0x300B] = 2, [0x300D] = 2, [0x300F] = 2,
  [0x3011] = 2, [0x2986] = 2, [0x3019] = 2, [0x3017] = 2, [0x00BB] = 2, [0x301F] = 2,
  [0xFF09] = 2, -- see note 1 of appendix A
  [0x2010] = 3, [0x301C] = 3, [0x30A0] = 3, [0x2013] = 3,
  [0x0021] = 4, [0x003F] = 4, [0x203C] = 4, [0x2047] = 4, [0x2048] = 4, [0x2049] = 4,
  [0x30FB] = 5, [0x003A] = 5, [0x003B] = 5,
  [0x3002] = 6, [0x002E] = 6,
  [0x3001] = 7, [0x002C] = 7,
  [0x2014] = 8, [0x2026] = 8, [0x2025] = 8, [0x3033] = 8, [0x3034] = 8, [0x3035] = 8,
  [0x30FD] = 9, [0x30FE] = 9, [0x309D] = 9, [0x309E] = 9, [0x3005] = 9, [0x303B] = 9,
  [0x30FC] = 10,
  [0x3041] = 11, [0x3043] = 11, [0x3045] = 11, [0x3047] = 11,
  [0x3049] = 11, [0x30A1] = 11, [0x30A3] = 11, [0x30A5] = 11,
  [0x30A7] = 11, [0x30A9] = 11, [0x3063] = 11, [0x3083] = 11,
  [0x3085] = 11, [0x3087] = 11, [0x308E] = 11, [0x3095] = 11,
  [0x3096] = 11, [0x30C3] = 11, [0x30E3] = 11, [0x30E5] = 11,
  [0x30E7] = 11, [0x30EE] = 11, [0x30F5] = 11, [0x30F6] = 11,
  [0x31F0] = 11, [0x31F1] = 11, [0x31F2] = 11, [0x31F3] = 11,
  [0x31F4] = 11, [0x31F5] = 11, [0x31F6] = 11, [0x31F7] = 11,
  [0x31F8] = 11, [0x31F9] = 11, [0x31FA] = 11, [0x31FB] = 11,
  [0x31FC] = 11, [0x31FD] = 11, [0x31FE] = 11, [0x31FF] = 11,
  [0x00A5] = 12, [0x0024] = 12, [0x00A3] = 12, [0x0023] = 12, [0x20AC] = 12, [0x2116] = 12,
  [0x00B0] = 13, [0x2032] = 13, [0x2033] = 13, [0x2103] = 13, [0x00A2] = 13,
  [0x0025] = 13, [0x2030] = 13, [0x33CB] = 13, [0x2113] = 13, [0x3303] = 13,
  [0x330D] = 13, [0x3314] = 13, [0x3318] = 13, [0x3322] = 13, [0x3323] = 13,
  [0x3326] = 13, [0x3327] = 13, [0x332B] = 13, [0x3336] = 13, [0x333B] = 13,
  [0x3349] = 13, [0x334A] = 13, [0x334D] = 13, [0x3351] = 13, [0x3357] = 13,
  [0x338E] = 13, [0x338F] = 13, [0x339C] = 13, [0x339D] = 13, [0x339E] = 13,
  [0x33A1] = 13, [0x33C4] = 13,
  [0x3000] = 14,
}

local jisClass = function (c)
  if c == -1 then return -1 end
  if classes[c] then return classes[c] end
  if hiragana(c) then return 15 end
  if katakana(c) then return 16 end
  if kanji(c) then return 19 end -- Other things are also 19
  return 27 -- this is lazy
end

-- This roughly implements the kinsoku shori given in Appendix C of jlreq
local badBeforeClasses = { [1] = true, [12] = true, [28] = true }
local badAfterClasses = { }
for _, v in ipairs({ 2, 3, 4, 5, 6, 7, 9, 10, 11, 20, 29 }) do badAfterClasses[v] = true end

local function breakAllowed (before, after)
  local bc = jisClass(before)
  local ac = jisClass(after)
  if badBeforeClasses[bc] then return false end
  if badAfterClasses[ac] then return false end
  if bc == 8 and ac == 8 then
    if before == after then return false else return true end
  end
  -- The following rule is not in jlreq but it stops the algorithm from breaking
  -- up Latin words!
  if bc == 27 and ac == 27 then return false end
  return true
end

local function intercharacterspace (before, after)
  local bc = jisClass(before)
  local ac = jisClass(after)
  -- This rule is not in jlreq but it stops situations like 1：2 getting munched
  if (bc == 5 and ac == 27) or (bc == 27 and ac == 5) then return 0 end

  -- jlreq expects yakumono to contain no following space, so recommends half
  -- a space afterwards. However, in real world fonts, yakumono occupies a full
  -- zenkaku width with trailing space built into the glyph. So we do not add
  -- space there. Instead, where no space is stipulated, we add negative space
  -- to counteract the trailing space in the glyph.
  if ac == 5 then return "-0.25zw" end
  if bc == 5 then return "-0.25zw" end
  if bc == 7 and ac == 1 then return "-0.5zw" end
  if bc == 2 and ac == 1 then return "-0.5zw" end
  if bc == -1 and ac == 1 then return "-0.5zw" end
  if bc == 6 or bc == 7 then
    if ac == 2 or ac == 6 or ac == 7 then return "-0.25zw" end
    return 0
  end
  if (bc == 9 or bc == 10 or bc == 11 or bc == 15 or bc == 16 or bc == 19) and
    (ac == 21 or ac == 24 or ac == 25) then
    return "0.25zw"
  end

  return 0
end

local function stretchability (before, after)
  local bc = jisClass(before)
  local ac = jisClass(after)
  -- somewhat simplified from table 6 of jlreq
  if ac == 1 then return "0.25zw" end
  if ac < 8 then return 0 end
  if bc == 4 and (ac == 21 or ac==24 or ac==25 or ac==27) then
    return "0.5zw"
  end
  if bc < 8 then return 0 end
  return "0.25zw" -- somewhat simplified
end

local function shrinkability (before, after)
  local bc = jisClass(before)
  local ac = jisClass(after)
  -- This rule is not in jlreq but it stops situations like 1：2 getting munched
  if (bc == 5 and ac == 27) or (bc == 27 and ac == 5) then return 0 end
  -- somewhat simplified from table 5 of jlreq
  if ac == 1 then return "0.5zw" end
  if ac == 5 then return "0.25zw" end
  if bc == 5 then return "0.25zw" end
  if bc == 7 then return "0.5zw" end
  return 0
end

-- local okbreak = SILE.nodefactory.penalty(0)

SILE.nodeMakers.ja = pl.class(SILE.nodeMakers.base)

function SILE.nodeMakers.ja:iterator (items)
  local options = self.options
  return coroutine.wrap(function ()
    local db
    local lastcp = -1
    local lastchar = ""
    local space = "%s" -- XXX
    for i = 1, #items do
      local item = items[i]
      local uchar = items[i].text
      local thiscp = SU.codepoint(uchar)
      db = lastchar.. "|" .. uchar
      if string.match(uchar, space) then
        db = db .. " S"
        coroutine.yield(SILE.shaper:makeSpaceNode(options, item))
      else
        local length = SILE.length(
          intercharacterspace(lastcp, thiscp),
          stretchability(lastcp, thiscp),
          shrinkability(lastcp, thiscp)
        )
        if breakAllowed(lastcp, thiscp) then
          db = db .." G ".. tostring(length)
          coroutine.yield(SILE.nodefactory.glue(length))
        elseif length.length ~= 0 or length.stretch ~= 0 or length.shrink ~= 0 then
          db = db .." K ".. tostring(length)
          coroutine.yield(SILE.nodefactory.kern(length))
        else db = db .. " N"
        end
        if jisClass(thiscp) == 5 or jisClass(thiscp) == 6 then
          local node = SILE.shaper:formNnode({ item }, uchar, options)
          node.hangable = true
          coroutine.yield(node)
        else
          coroutine.yield(SILE.shaper:formNnode({ item }, uchar, options))
        end
      end
      lastcp =thiscp
      lastchar = uchar
      SU.debug("ja", db)
    end
  end)
end

return {
  init = function ()

    SILE.hyphenator.languages.ja = { patterns={} }

    SILE.registerCommand("book:chapter:post:ja", function (_, _)
      SILE.call("fluent", {}, { "book-chapter-post" })
      SILE.call("medskip")
    end)

    -- jlreq measures distances in units of 1em, but also assumes that an em is the
    -- width of a full-width character. In SILE terms it isn't: measuring an "m" in
    -- a 10pt Japanese font gets you 5 points. So we measure a full-width character
    -- and use that as a unit. We call it zw following ptex (zenkaku width)
    SILE.units["zw"] = {
      relative = true,
      definition = function (v)
        return v * SILE.shaper:measureChar("あ").width
      end
    }

  end
}
