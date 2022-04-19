-- (c) 2009-2011 John MacFarlane, Hans Hagen.  Released under MIT license.
-- See the file LICENSE in the source for details.

local util = require("lunamark.util")
local lpeg = require("lpeg")
local entities = require("lunamark.entities")
local lower, upper, gsub, format, length =
  string.lower, string.upper, string.gsub, string.format, string.len
local P, R, S, V, C, Cg, Cb, Cmt, Cc, Ct, B, Cs =
  lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cg, lpeg.Cb,
  lpeg.Cmt, lpeg.Cc, lpeg.Ct, lpeg.B, lpeg.Cs
local lpegmatch = lpeg.match
local expand_tabs_in_line = util.expand_tabs_in_line
local luautf8 = require("lua-utf8")

local M = {}

local rope_to_string = util.rope_to_string

-- Normalize a markdown reference tag.  (Make lowercase, and collapse
-- adjacent whitespace characters.)
local function normalize_tag(tag)
  return luautf8.lower(gsub(rope_to_string(tag), "[ \n\r\t]+", " "))
end

------------------------------------------------------------------------------
-- Character parsers
------------------------------------------------------------------------------

local percent                = P("%")
local at                     = P("@")
local comma                  = P(",")
local asterisk               = P("*")
local dash                   = P("-")
local plus                   = P("+")
local underscore             = P("_")
local period                 = P(".")
local hash                   = P("#")
local ampersand              = P("&")
local backtick               = P("`")
local less                   = P("<")
local more                   = P(">")
local space                  = P(" ")
local squote                 = P("'")
local dquote                 = P('"')
local lparent                = P("(")
local rparent                = P(")")
local lbracket               = P("[")
local rbracket               = P("]")
local circumflex             = P("^")
local slash                  = P("/")
local equal                  = P("=")
local colon                  = P(":")
local semicolon              = P(";")
local exclamation            = P("!")
local tilde                  = P("~")
local tab                    = P("\t")
local newline                = P("\n")
local tightblocksep          = P("\001")

--- Create a new markdown parser.
--
-- *   `writer` is a writer table (see [lunamark.writer.generic]).
--
-- *   `options` is a table with parsing options.
--     The following fields are significant:
--
--     `alter_syntax`
--     :   Function from syntax table to syntax table,
--         allowing the user to change or extend the markdown syntax.
--         For an example, see the documentation for `lunamark`.
--
--     `references`
--     :   A table of references to be used in resolving links
--         in the document.  The keys should be all lowercase, with
--         spaces and newlines collapsed into single spaces.
--         Example:
--
--             { foo: { url = "/url", title = "my title" },
--               bar: { url = "http://fsf.org" } }
--
--     `preserve_tabs`
--     :   Preserve tabs instead of converting to spaces.
--
--     `smart`
--     :   Parse quotation marks, dashes, ellipses intelligently.
--
--     `startnum`
--     :   Make the opening number in an ordered list significant.
--
--     `notes`
--     :   Enable footnotes as in pandoc.
--
--     `definition_lists`
--     :   Enable definition lists as in pandoc.
--
--     `citations`
--     :   Enable citations as in pandoc.
--
--     `fenced_code_blocks`
--     :   Enable fenced code blocks.
--
--     `pandoc_title_blocks`
--     :   Parse pandoc-style title block at the beginning of document:
--
--             % Title
--             % Author1; Author2
--             % Date
--
--     `lua_metadata`
--     :   Enable lua metadata.  This is an HTML comment block
--         that starts with `<!--@` and contains lua code.
--         The lua code is interpreted in a sandbox, and
--         any variables defined are added to the metadata.
--         The function `markdown` (also `m`) is defined and can
--         be used to ensure that string fields are parsed
--         as markdown; otherwise, they will be read literally.
--
--     `require_blank_before_blockquote`
--     :   Require a blank line between a paragraph and a following
--         block quote.
--
--     `require_blank_before_header`
--     :   Require a blank line between a paragraph and a following
--         header.
--
--     `require_blank_before_fenced_code_block`
--     :   Require a blank line between a paragraph and a following
--         fenced code block.
--
--     `hash_enumerators`
--     :   Allow `#` instead of a digit for an ordered list enumerator
--         (equivalent to `1`).
--
-- *   Returns a converter function that converts a markdown string
--     using `writer`, returning the parsed document as first result,
--     and a table containing any extracted metadata as the second
--     result. The converter assumes that the input has unix
--     line endings (newline).  If the input might have DOS
--     line endings, a simple `gsub("\r","")` should take care of them.
function M.new(writer, options)
  options = options or {}

  local function expandtabs(s)
    if s:find("\t") then
      return s:gsub("[^\n]*",expand_tabs_in_line)
    else
      return s
    end
  end

  if options.preserve_tabs then
    expandtabs = function(s) return s end
  end

  ------------------------------------------------------------------------------

  local syntax
  local blocks
  local inlines
  local inlines_no_link
  local inlines_nbsp

  local function create_parser(name, grammar)
    return function(str)
      local res = lpeg.match(grammar(), str)
      if res == nil then
        error(format("%s failed on:\n%s", name, str:sub(1,20)))
      else
        return res
      end
    end
  end

  local parse_blocks = create_parser("parse_blocks",
    function() return blocks end)
  local parse_inlines = create_parser("parse_inlines",
    function() return inlines end)
  local parse_inlines_no_link = create_parser("parse_inlines_no_link",
    function() return inlines_no_link end)
  local parse_inlines_nbsp = create_parser("parse_inlines_nbsp",
    function() return inlines_nbsp end)

  local parse_markdown

  ------------------------------------------------------------------------------
  -- Generic parsers
  ------------------------------------------------------------------------------

  local digit                  = R("09")
  local hexdigit               = R("09","af","AF")
  local letter                 = R("AZ","az")
  local alphanumeric           = R("AZ","az","09")
  local keyword                = letter * alphanumeric^0
  local internal_punctuation   = S(":;,.#$%&-+?<>~/")

  local doubleasterisks        = P("**")
  local doubleunderscores      = P("__")
  local fourspaces             = P("    ")

  local any                    = P(1)
  local fail                   = any - 1

  local escapable              = S("\\`*_{}[]()+_.!<>#-~:^@;")
  local anyescaped             = P("\\") / "" * escapable
                               + any

  local spacechar              = S("\t ")
  local spacing                = S(" \n\r\t")
  local nonspacechar           = any - spacing

  local specialchar
  if options.smart then
    specialchar                = S("*_`&[]<!\\'\"-.@")
  else
    specialchar                = S("*_`&[]<!\\-@")
  end

  local normalchar             = any -
                                 (specialchar + spacing + tightblocksep)
  local optionalspace          = spacechar^0
  local eof                    = - any
  local nonindentspace         = space^-3 * - spacechar
  local indent                 = space^-3 * tab
                               + fourspaces / ""
  local linechar               = P(1 - newline)

  local blankline              = optionalspace * newline / "\n"
  local blanklines             = blankline^0
  local skipblanklines         = (optionalspace * newline)^0
  local indentedline           = indent    /"" * C(linechar^1 * newline^-1)
  local optionallyindentedline = indent^-1 /"" * C(linechar^1 * newline^-1)
  local sp                     = spacing^0
  local spnl                   = optionalspace * (newline * optionalspace)^-1
  local line                   = linechar^0 * newline
                               + linechar^1 * eof
  local nonemptyline           = line - blankline

  local chunk = line * (optionallyindentedline - blankline)^0

  -- block followed by 0 or more optionally
  -- indented blocks with first line indented.
  local function indented_blocks(bl)
    return Cs( bl
             * (blankline^1 * indent * -blankline * bl)^0
             * blankline^1 )
  end

  -----------------------------------------------------------------------------
  -- Parsers used for markdown lists
  -----------------------------------------------------------------------------

  local bulletchar = C(plus + asterisk + dash)

  local bullet     = ( bulletchar * #spacing * (tab + space^-3)
                     + space * bulletchar * #spacing * (tab + space^-2)
                     + space * space * bulletchar * #spacing * (tab + space^-1)
                     + space * space * space * bulletchar * #spacing
                     )

  local dig
  if options.hash_enumerators then
    dig = digit + hash
  else
    dig = digit
  end

  local enumerator = C(dig^3 * period) * #spacing
                   + C(dig^2 * period) * #spacing * (tab + space^1)
                   + C(dig * period) * #spacing * (tab + space^-2)
                   + space * C(dig^2 * period) * #spacing
                   + space * C(dig * period) * #spacing * (tab + space^-1)
                   + space * space * C(dig^1 * period) * #spacing

  -----------------------------------------------------------------------------
  -- Parsers used for markdown code spans
  -----------------------------------------------------------------------------

  local openticks   = Cg(backtick^1, "ticks")

  local function captures_equal_length(s,i,a,b)
    return #a == #b and i
  end

  local closeticks  = space^-1 *
                      Cmt(C(backtick^1) * Cb("ticks"), captures_equal_length)*1

  local intickschar = (any - S(" \n\r`"))
                    + (newline * -blankline)
                    + (space - closeticks)
                    + (backtick^1 - closeticks)

  local inticks     = openticks * space^-1 * C(intickschar^1) * closeticks

  -----------------------------------------------------------------------------
  -- Parsers used for fenced code blocks
  -----------------------------------------------------------------------------

  local function captures_geq_length(s,i,a,b)
    return #a >= #b and i
  end

  local infostring     = (linechar - (backtick + space^1 * newline))^0

  local fenceindent
  local function fencehead(char)
    return               C(nonindentspace) / function(s) fenceindent = #s end
                       * Cg(char^3, "fencelength")
                       * optionalspace * C(infostring) * optionalspace
                       * newline + eof
  end

  local function fencetail(char)
    return               nonindentspace
                       * Cmt(C(char^3) * Cb("fencelength"),
                             captures_geq_length)
                       * optionalspace * (newline + eof)
  end

  local function fencedline(char)
    return               C(line - fencetail(char))
                       / function(s)
                           return s:gsub("^" .. string.rep(" ?",
                             fenceindent), "")
                         end
  end

  -----------------------------------------------------------------------------
  -- Parsers used for markdown tags and links
  -----------------------------------------------------------------------------

  local leader        = space^-3

  -- in balanced brackets, parentheses, quotes:
  local bracketed     = P{ lbracket
                         * ((anyescaped - (lbracket + rbracket + blankline^2)) + V(1))^0
                         * rbracket }

  local inparens      = P{ lparent
                         * ((anyescaped - (lparent + rparent + blankline^2)) + V(1))^0
                         * rparent }

  local squoted       = P{ squote * alphanumeric
                         * ((anyescaped - (squote + blankline^2)) + V(1))^0
                         * squote }

  local dquoted       = P{ dquote * alphanumeric
                         * ((anyescaped - (dquote + blankline^2)) + V(1))^0
                         * dquote }

  -- bracketed 'tag' for markdown links, allowing nested brackets:
  local tag           = lbracket
                      * Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped - (rbracket + blankline^2)))^0)
                      * rbracket

  -- url for markdown links, allowing balanced parentheses:
  local url           = less * Cs((anyescaped-more)^0) * more
                      + Cs((inparens + (anyescaped-spacing-rparent))^1)

  -- quoted text possibly with nested quotes:
  local title_s       = squote  * Cs(((anyescaped-squote) + squoted)^0) * squote

  local title_d       = dquote  * Cs(((anyescaped-dquote) + dquoted)^0) * dquote

  local title_p       = lparent
                      * Cs((inparens + (anyescaped-rparent))^0)
                      * rparent

  local title         = title_d + title_s + title_p

  local optionaltitle = spnl * title * spacechar^0
                      + Cc("")

  ------------------------------------------------------------------------------
  -- Citations
  ------------------------------------------------------------------------------

  local citation_name = Cs(dash^-1) * at
                      * Cs(alphanumeric
                          * (alphanumeric + internal_punctuation
                              - comma - semicolon)^0)

  local citation_body_prenote
                      = Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped
                               - (rbracket + blankline^2))
                           - (spnl * dash^-1 * at))^0)

  local citation_body_postnote
                      = Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped
                               - (rbracket + semicolon + blankline^2))
                           - (spnl * rbracket))^0)

  local citation_body_chunk
                      = citation_body_prenote
                      * spnl * citation_name
                      * (comma * spnl)^-1
                      * citation_body_postnote

  local citation_body = citation_body_chunk
                      * (semicolon * spnl * citation_body_chunk)^0

  local citation_headless_body
                      = Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped
                               - (rbracket + at + semicolon + blankline^2))
                           - (spnl * rbracket))^0)
                      * (sp * semicolon * spnl * citation_body_chunk)^0

  local function citations(text_cites, raw_cites)
      local function normalize(str)
          if str == "" then
              str = nil
          else
              str = (options.citation_nbsps and parse_inlines_nbsp or
                parse_inlines)(str)
          end
          return str
      end

      local cites = {}
      for i = 1,#raw_cites,4 do
          cites[#cites+1] = {
              prenote = normalize(raw_cites[i]),
              suppress_author = raw_cites[i+1] == "-",
              name = writer.string(raw_cites[i+2]),
              postnote = normalize(raw_cites[i+3]),
          }
      end
      return writer.citations(text_cites, cites)
  end

  ------------------------------------------------------------------------------
  -- Footnotes
  ------------------------------------------------------------------------------

  local rawnotes = {}

  local function strip_first_char(s)
    return s:sub(2)
  end

  -- like indirect_link
  local function lookup_note(ref)
    return function()
      local found = rawnotes[normalize_tag(ref)]
      if found then
        return writer.note(parse_blocks(found))
      else
        return {"[", parse_inlines("^" .. ref), "]"}
      end
    end
  end

  local function register_note(ref,rawnote)
    rawnotes[normalize_tag(ref)] = rawnote
    return ""
  end

  local RawNoteRef = #(lbracket * circumflex) * tag / strip_first_char

  local NoteRef    = RawNoteRef / lookup_note

  local NoteBlock

  if options.notes then
    NoteBlock = leader * RawNoteRef * colon * spnl * indented_blocks(chunk)
              / register_note
  else
    NoteBlock = fail
  end

  ------------------------------------------------------------------------------
  -- Helpers for links and references
  ------------------------------------------------------------------------------

  -- List of references defined in the document
  local references

  -- add a reference to the list
  local function register_link(tag,url,title)
      references[normalize_tag(tag)] = { url = url, title = title }
      return ""
  end

  -- parse a reference definition:  [foo]: /bar "title"
  local define_reference_parser =
    leader * tag * colon * spacechar^0 * url * optionaltitle * blankline^1

  -- lookup link reference and return either
  -- the link or nil and fallback text.
  local function lookup_reference(label,sps,tag)
      local tagpart
      if not tag then
          tag = label
          tagpart = ""
      elseif tag == "" then
          tag = label
          tagpart = "[]"
      else
          tagpart = {"[", parse_inlines(tag), "]"}
      end
      if sps then
        tagpart = {sps, tagpart}
      end
      local r = references[normalize_tag(tag)]
      if r then
        return r
      else
        return nil, {"[", parse_inlines(label), "]", tagpart}
      end
  end

  -- lookup link reference and return a link, if the reference is found,
  -- or a bracketed label otherwise.
  local function indirect_link(label,sps,tag)
    return function()
      local r,fallback = lookup_reference(label,sps,tag)
      if r then
        return writer.link(parse_inlines_no_link(label), r.url, r.title)
      else
        return fallback
      end
    end
  end

  -- lookup image reference and return an image, if the reference is found,
  -- or a bracketed label otherwise.
  local function indirect_image(label,sps,tag)
    return function()
      local r,fallback = lookup_reference(label,sps,tag)
      if r then
        return writer.image(writer.string(label), r.url, r.title)
      else
        return {"!", fallback}
      end
    end
  end

  ------------------------------------------------------------------------------
  -- HTML
  ------------------------------------------------------------------------------

  -- case-insensitive match (we assume s is lowercase). must be single byte encoding
  local function keyword_exact(s)
    local parser = P(0)
    for i=1,#s do
      local c = s:sub(i,i)
      local m = c .. upper(c)
      parser = parser * S(m)
    end
    return parser
  end

  local block_keyword =
      keyword_exact("address") + keyword_exact("blockquote") +
      keyword_exact("center") + keyword_exact("del") +
      keyword_exact("dir") + keyword_exact("div") +
      keyword_exact("p") + keyword_exact("pre") + keyword_exact("li") +
      keyword_exact("ol") + keyword_exact("ul") + keyword_exact("dl") +
      keyword_exact("dd") + keyword_exact("form") + keyword_exact("fieldset") +
      keyword_exact("isindex") + keyword_exact("ins") +
      keyword_exact("menu") + keyword_exact("noframes") +
      keyword_exact("frameset") + keyword_exact("h1") + keyword_exact("h2") +
      keyword_exact("h3") + keyword_exact("h4") + keyword_exact("h5") +
      keyword_exact("h6") + keyword_exact("hr") + keyword_exact("script") +
      keyword_exact("noscript") + keyword_exact("table") +
      keyword_exact("tbody") + keyword_exact("tfoot") +
      keyword_exact("thead") + keyword_exact("th") +
      keyword_exact("td") + keyword_exact("tr")

  -- There is no reason to support bad html, so we expect quoted attributes
  local htmlattributevalue  = squote * (any - (blankline + squote))^0 * squote
                            + dquote * (any - (blankline + dquote))^0 * dquote

  local htmlattribute       = spacing^1 * (alphanumeric + S("_-"))^1 * sp * equal
                            * sp * htmlattributevalue

  local htmlcomment         = P("<!--") * (any - P("-->"))^0 * P("-->")

  local htmlinstruction     = P("<?")   * (any - P("?>" ))^0 * P("?>" )

  local openelt_any = less * keyword * htmlattribute^0 * sp * more

  local function openelt_exact(s)
    return (less * sp * keyword_exact(s) * htmlattribute^0 * sp * more)
  end

  local openelt_block = sp * block_keyword * htmlattribute^0 * sp * more

  local closeelt_any = less * sp * slash * keyword * sp * more

  local function closeelt_exact(s)
    return (less * sp * slash * keyword_exact(s) * sp * more)
  end

  local emptyelt_any = less * sp * keyword * htmlattribute^0 * sp * slash * more

  local emptyelt_block = less * sp * block_keyword * htmlattribute^0 * sp * slash * more

  local displaytext         = (any - less)^1

  -- return content between two matched HTML tags
  local function in_matched(s)
    return { openelt_exact(s)
           * (V(1) + displaytext + (less - closeelt_exact(s)))^0
           * closeelt_exact(s) }
  end

  local function parse_matched_tags(s,pos)
    local t = lower(lpegmatch(C(keyword),s,pos))
    return lpegmatch(in_matched(t),s,pos-1)
  end

  local in_matched_block_tags = less * Cmt(#openelt_block, parse_matched_tags)

  local displayhtml = htmlcomment
                    + emptyelt_block
                    + openelt_exact("hr")
                    + in_matched_block_tags
                    + htmlinstruction

  local inlinehtml  = emptyelt_any
                    + htmlcomment
                    + htmlinstruction
                    + openelt_any
                    + closeelt_any

  ------------------------------------------------------------------------------
  -- Entities
  ------------------------------------------------------------------------------

  local hexentity = ampersand * hash * S("Xx") * C(hexdigit    ^1) * semicolon
  local decentity = ampersand * hash           * C(digit       ^1) * semicolon
  local tagentity = ampersand *                  C(alphanumeric^1) * semicolon

  ------------------------------------------------------------------------------
  -- Inline elements
  ------------------------------------------------------------------------------

  local Inline    = V("Inline")

  local Str       = normalchar^1 / writer.string

  local Ellipsis  = P("...") / writer.ellipsis

  local Dash      = P("---") * -dash / writer.mdash
                  + P("--") * -dash / writer.ndash
                  + P("-") * #digit * B(digit*1, 2) / writer.ndash

  local DoubleQuoted = dquote * Ct((Inline - dquote)^1) * dquote
                     / writer.doublequoted

  local squote_start = squote * -spacing

  local squote_end = squote * B(nonspacechar*1, 2)

  local SingleQuoted = squote_start * Ct((Inline - squote_end)^1) * squote_end
                     / writer.singlequoted

  local Apostrophe = squote * B(nonspacechar*1, 2) / "’"

  local Smart      = Ellipsis + Dash + SingleQuoted + DoubleQuoted + Apostrophe

  local Symbol    = (specialchar - tightblocksep) / writer.string

  local Code      = inticks / writer.code

  local bqstart      = more
  local headerstart  = hash
                     + (line * (equal^1 + dash^1) * optionalspace * newline)
  local fencestart   = fencehead(backtick) + fencehead(tilde)

  if options.require_blank_before_blockquote then
    bqstart = fail
  end

  if options.require_blank_before_header then
    headerstart = fail
  end

  if not options.fenced_code_blocks or
    options.blank_before_fenced_code_blocks then
    fencestart = fail
  end

  local Endline   = newline * -( -- newline, but not before...
                        blankline -- paragraph break
                      + tightblocksep  -- nested list
                      + eof       -- end of document
                      + bqstart
                      + headerstart
                      + fencestart
                    ) * spacechar^0 / writer.space

  local Space     = spacechar^2 * Endline / writer.linebreak
                  + spacechar^1 * Endline^-1 * eof / ""
                  + spacechar^1 * Endline^-1 * optionalspace / writer.space

  local NonbreakingEndline
                  = newline * -( -- newline, but not before...
                        blankline -- paragraph break
                      + tightblocksep  -- nested list
                      + eof       -- end of document
                      + bqstart
                      + headerstart
                      + fencestart
                    ) * spacechar^0 / writer.nbsp

  local NonbreakingSpace
                  = spacechar^2 * Endline / writer.linebreak
                  + spacechar^1 * Endline^-1 * eof / ""
                  + spacechar^1 * Endline^-1 * optionalspace / writer.nbsp

  -- parse many p between starter and ender
  local function between(p, starter, ender)
      local ender2 = B(nonspacechar) * ender
      return (starter * #nonspacechar * Ct(p * (p - ender2)^0) * ender2)
  end

  local Strong = ( between(Inline, doubleasterisks, doubleasterisks)
                 + between(Inline, doubleunderscores, doubleunderscores)
                 ) / writer.strong

  local Emph   = ( between(Inline, asterisk, asterisk)
                 + between(Inline, underscore, underscore)
                 ) / writer.emphasis

  local urlchar = anyescaped - newline - more

  local AutoLinkUrl   = less
                      * C(alphanumeric^1 * P("://") * urlchar^1)
                      * more
                      / function(url) return writer.link(writer.string(url),url) end

  local AutoLinkEmail = less
                      * C((alphanumeric + S("-._+"))^1 * P("@") * urlchar^1)
                      * more
                      / function(email) return writer.link(writer.string(email),"mailto:"..email) end

  local DirectLink    = (tag / parse_inlines_no_link)  -- no links inside links
                      * spnl
                      * lparent
                      * (url + Cc(""))  -- link can be empty [foo]()
                      * optionaltitle
                      * rparent
                      / writer.link

  local IndirectLink = tag * (C(spnl) * tag)^-1 / indirect_link

  -- parse a link or image (direct or indirect)
  local Link          = DirectLink + IndirectLink

  local DirectImage   = exclamation
                      * (tag / parse_inlines)
                      * spnl
                      * lparent
                      * (url + Cc(""))  -- link can be empty [foo]()
                      * optionaltitle
                      * rparent
                      / writer.image

  local IndirectImage  = exclamation * tag * (C(spnl) * tag)^-1 / indirect_image

  local Image         = DirectImage + IndirectImage

  local TextCitations = Ct(Cc("")
                      * citation_name
                      * ((spnl
                           * lbracket
                           * citation_headless_body
                           * rbracket) + Cc(""))) /
                        function(raw_cites)
                            return citations(true, raw_cites)
                        end

  local ParenthesizedCitations
                      = Ct(lbracket
                      * citation_body
                      * rbracket) /
                        function(raw_cites)
                            return citations(false, raw_cites)
                        end

  local Citations     = TextCitations + ParenthesizedCitations

  -- avoid parsing long strings of * or _ as emph/strong
  local UlOrStarLine  = asterisk^4 + underscore^4 / writer.string

  local EscapedChar   = S("\\") * C(escapable) / writer.string

  local InlineHtml    = C(inlinehtml) / writer.inline_html

  local HtmlEntity    = hexentity / entities.hex_entity  / writer.string
                      + decentity / entities.dec_entity  / writer.string
                      + tagentity / entities.char_entity / writer.string

  ------------------------------------------------------------------------------
  -- Block elements
  ------------------------------------------------------------------------------

  local Block          = V("Block")

  local DisplayHtml    = C(displayhtml) / expandtabs / writer.display_html

  local Verbatim       = Cs( (blanklines
                           * ((indentedline - blankline))^1)^1
                           ) / expandtabs / writer.verbatim

  local TildeFencedCodeBlock
                       = fencehead(tilde)
                       * Cs(fencedline(tilde)^0)
                       * fencetail(tilde)

  local BacktickFencedCodeBlock
                       = fencehead(backtick)
                       * Cs(fencedline(backtick)^0)
                       * fencetail(backtick)

  local FencedCodeBlock
                       = (TildeFencedCodeBlock + BacktickFencedCodeBlock)
                       / function(infostring, code)
                             return writer.fenced_code(
                                 expandtabs(code),
                                 writer.string(infostring))
                         end

  -- strip off leading > and indents, and run through blocks
  local Blockquote     = Cs((
            ((leader * more * space^-1)/"" * linechar^0 * newline)^1
          * (-blankline * linechar^1 * newline)^0
          * blankline^0
          )^1) / parse_blocks / writer.blockquote

  local function lineof(c)
      return (leader * (P(c) * optionalspace)^3 * newline * blankline^1)
  end

  local HorizontalRule = ( lineof(asterisk)
                         + lineof(dash)
                         + lineof(underscore)
                         ) / writer.hrule

  local Reference      = define_reference_parser / register_link

  local Paragraph      = nonindentspace * Ct(Inline^1) * newline
                       * ( blankline^1
                         + #hash
                         + #(leader * more * space^-1)
                         )
                       / writer.paragraph

  local Plain          = nonindentspace * Ct(Inline^1) / writer.plain

  ------------------------------------------------------------------------------
  -- Lists
  ------------------------------------------------------------------------------

  local starter = bullet + enumerator

  -- we use \001 as a separator between a tight list item and a
  -- nested list under it.
  local NestedList            = Cs((optionallyindentedline - starter)^1)
                              / function(a) return "\001"..a end

  local ListBlockLine         = optionallyindentedline
                                - blankline - (indent^-1 * starter)

  local ListBlock             = line * ListBlockLine^0

  local ListContinuationBlock = blanklines * (indent / "") * ListBlock

  local function TightListItem(starter)
      return -HorizontalRule
             * (Cs(starter / "" * ListBlock * NestedList^-1) / parse_blocks)
             * -(blanklines * indent)
  end

  local function LooseListItem(starter)
      return -HorizontalRule
             * Cs( starter / "" * ListBlock * Cc("\n")
               * (NestedList + ListContinuationBlock^0)
               * (blanklines / "\n\n")
               ) / parse_blocks
  end

  local BulletList = ( Ct(TightListItem(bullet)^1)
                       * Cc(true) * skipblanklines * -bullet
                     + Ct(LooseListItem(bullet)^1)
                       * Cc(false) * skipblanklines ) / writer.bulletlist

  local function ordered_list(s,tight,startnum)
    if options.startnum then
      startnum = tonumber(startnum) or 1  -- fallback for '#'
    else
      startnum = nil
    end
    return writer.orderedlist(s,tight,startnum)
  end

  local OrderedList = Cg(enumerator, "listtype") *
                      ( Ct(TightListItem(Cb("listtype")) * TightListItem(enumerator)^0)
                        * Cc(true) * skipblanklines * -enumerator
                      + Ct(LooseListItem(Cb("listtype")) * LooseListItem(enumerator)^0)
                        * Cc(false) * skipblanklines
                      ) * Cb("listtype") / ordered_list

  local defstartchar = S("~:")
  local defstart     = ( defstartchar * #spacing * (tab + space^-3)
                     + space * defstartchar * #spacing * (tab + space^-2)
                     + space * space * defstartchar * #spacing * (tab + space^-1)
                     + space * space * space * defstartchar * #spacing
                     )

  local dlchunk = Cs(line * (indentedline - blankline)^0)

  local function definition_list_item(term, defs, tight)
    return { term = parse_inlines(term), definitions = defs }
  end

  local DefinitionListItemLoose = C(line) * skipblanklines
                           * Ct((defstart * indented_blocks(dlchunk) / parse_blocks)^1)
                           * Cc(false)
                           / definition_list_item

  local DefinitionListItemTight = C(line)
                           * Ct((defstart * dlchunk / parse_blocks)^1)
                           * Cc(true)
                           / definition_list_item

  local DefinitionList =  ( Ct(DefinitionListItemLoose^1) * Cc(false)
                          +  Ct(DefinitionListItemTight^1)
                             * (skipblanklines * -DefinitionListItemLoose * Cc(true))
                          ) / writer.definitionlist

  ------------------------------------------------------------------------------
  -- Lua metadata
  ------------------------------------------------------------------------------

  local function lua_metadata(s)  -- run lua code in comment in sandbox
    local env = { m = parse_markdown, markdown = parse_blocks }
    local scode = s:match("^<!%-%-@%s*(.*)%-%->")
    local untrusted_table, message = load(scode, nil, "t", env)
    if not untrusted_table then
      util.err(message, 37)
    end
    local ok, msg = pcall(untrusted_table)
    if not ok then
      util.err(msg)
    end
    for k,v in pairs(env) do
      writer.set_metadata(k,v)
    end
    return ""
  end

  local LuaMeta = fail
  if options.lua_metadata then
    LuaMeta = #P("<!--@") * htmlcomment / lua_metadata
  end

  ------------------------------------------------------------------------------
  -- Pandoc title block parser
  ------------------------------------------------------------------------------

  local pandoc_title =
      percent * optionalspace
    * C(line * (spacechar * nonemptyline)^0) / parse_inlines
  local pandoc_author =
      spacechar * optionalspace
    * C((anyescaped - newline - semicolon)^0)
    * (semicolon + newline)
  local pandoc_authors =
    percent * Ct((pandoc_author / parse_inlines)^0) * newline^-1
  local pandoc_date =
    percent * optionalspace * C(line) / parse_inlines
  local pandoc_title_block =
      (pandoc_title + Cc(""))
    * (pandoc_authors + Cc({}))
    * (pandoc_date + Cc(""))
    * C(P(1)^0)

  ------------------------------------------------------------------------------
  -- Blank
  ------------------------------------------------------------------------------

  local Blank          = blankline / ""
                       + LuaMeta
                       + NoteBlock
                       + Reference
                       + (tightblocksep / "\n")

  ------------------------------------------------------------------------------
  -- Headers
  ------------------------------------------------------------------------------

  -- parse Atx heading start and return level
  local HeadingStart = #hash * C(hash^-6) * -hash / length

  -- parse setext header ending and return level
  local HeadingLevel = equal^1 * Cc(1) + dash^1 * Cc(2)

  local function strip_atx_end(s)
    return s:gsub("[#%s]*\n$","")
  end

  -- parse atx header
  local AtxHeader = Cg(HeadingStart,"level")
                     * optionalspace
                     * (C(line) / strip_atx_end / parse_inlines)
                     * Cb("level")
                     / writer.header

  -- parse setext header
  local SetextHeader = #(line * S("=-"))
                     * Ct(line / parse_inlines)
                     * HeadingLevel
                     * optionalspace * newline
                     / writer.header

  ------------------------------------------------------------------------------
  -- Syntax specification
  ------------------------------------------------------------------------------

  syntax =
    { "Blocks",

      Blocks                = Blank^0 *
                              Block^-1 *
                              (Blank^0 / function() return writer.interblocksep end * Block)^0 *
                              Blank^0 *
                              eof,

      Blank                 = Blank,

      Block                 = V("Blockquote")
                            + V("Verbatim")
                            + V("FencedCodeBlock")
                            + V("HorizontalRule")
                            + V("BulletList")
                            + V("OrderedList")
                            + V("Header")
                            + V("DefinitionList")
                            + V("DisplayHtml")
                            + V("Paragraph")
                            + V("Plain"),

      Blockquote            = Blockquote,
      Verbatim              = Verbatim,
      FencedCodeBlock       = FencedCodeBlock,
      HorizontalRule        = HorizontalRule,
      BulletList            = BulletList,
      OrderedList           = OrderedList,
      Header                = AtxHeader + SetextHeader,
      DefinitionList        = DefinitionList,
      DisplayHtml           = DisplayHtml,
      Paragraph             = Paragraph,
      Plain                 = Plain,

      Inline                = V("Str")
                            + V("Space")
                            + V("Endline")
                            + V("UlOrStarLine")
                            + V("Strong")
                            + V("Emph")
                            + V("NoteRef")
                            + V("Citations")
                            + V("Link")
                            + V("Image")
                            + V("Code")
                            + V("AutoLinkUrl")
                            + V("AutoLinkEmail")
                            + V("InlineHtml")
                            + V("HtmlEntity")
                            + V("EscapedChar")
                            + V("Smart")
                            + V("Symbol"),

      Str                   = Str,
      Space                 = Space,
      Endline               = Endline,
      UlOrStarLine          = UlOrStarLine,
      Strong                = Strong,
      Emph                  = Emph,
      NoteRef               = NoteRef,
      Citations             = Citations,
      Link                  = Link,
      Image                 = Image,
      Code                  = Code,
      AutoLinkUrl           = AutoLinkUrl,
      AutoLinkEmail         = AutoLinkEmail,
      InlineHtml            = InlineHtml,
      HtmlEntity            = HtmlEntity,
      EscapedChar           = EscapedChar,
      Smart                 = Smart,
      Symbol                = Symbol,
    }

  if not options.definition_lists then
    syntax.DefinitionList = fail
  end

  if not options.fenced_code_blocks then
    syntax.FencedCodeBlock = fail
  end

  if not options.citations then
    syntax.Citations = fail
  end

  if not options.notes then
    syntax.NoteRef = fail
  end

  if not options.smart then
    syntax.Smart = fail
  end

  if options.alter_syntax and type(options.alter_syntax) == "function" then
    syntax = options.alter_syntax(syntax)
  end

  blocks = Ct(syntax)

  local inlines_t = util.table_copy(syntax)
  inlines_t[1] = "Inlines"
  inlines_t.Inlines = Inline^0 * (spacing^0 * eof / "")
  inlines = Ct(inlines_t)

  local inlines_no_link_t = util.table_copy(inlines_t)
  inlines_no_link_t.Link = fail
  inlines_no_link = Ct(inlines_no_link_t)

  local inlines_nbsp_t = util.table_copy(inlines_t)
  inlines_nbsp_t.Endline = NonbreakingEndline
  inlines_nbsp_t.Space = NonbreakingSpace
  inlines_nbsp = Ct(inlines_nbsp_t)

  ------------------------------------------------------------------------------
  -- Exported conversion function
  ------------------------------------------------------------------------------

  -- inp is a string; line endings are assumed to be LF (unix-style)
  -- and tabs are assumed to be expanded.
  parse_markdown =
    function(inp)
      references = options.references or {}
      if options.pandoc_title_blocks then
        local title, authors, date, rest = lpegmatch(pandoc_title_block, inp)
        writer.set_metadata("title",title)
        writer.set_metadata("author",authors)
        writer.set_metadata("date",date)
        inp = rest
      end
      local result = { writer.start_document(), parse_blocks(inp), writer.stop_document() }
      return writer.merge(result), writer.get_metadata()
  end

  return parse_markdown
end

return M
