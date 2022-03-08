--
-- Cross-references for SILE
-- Donated to the SILE typesetter - 2021-2022, Didier Willis
-- License: MIT
--
SILE.scratch.labelrefs = {} -- references being collated in this SILE run
local labelrefs_ = {} -- references from the previous SILE run
local markers_ = {} -- reference labels collated so far (for existence check)
local missing_ = {} -- missing references

-- Collate label references.
-- This method shall be called by supporting classes at the end of each page.
-- (The unused argument is the class)
local moveLabelRefs = function (_)
  local node = SILE.scratch.info.thispage.labelref
    if node then
    for i = 1, #node do
      local marker = node[i].marker
      node[i].pageno = SILE.formatCounter(SILE.scratch.counters.folio)
      SILE.scratch.labelrefs[marker] = node[i]
    end
  end
end

-- Save the references to a file.
-- This method shall be called by supporting classes at the end of the
-- document.
-- (The unused argument is the class)
local writeLabelRefs = function (_)
  local tocdata = pl.pretty.write(SILE.scratch.labelrefs)
  local tocfile, err = io.open(SILE.masterFilename .. '.ref', "w")
  if not tocfile then return SU.error(err) end
  tocfile:write("return " .. tocdata)
  tocfile:close()

  if not pl.tablex.deepcompare(SILE.scratch.labelrefs, labelrefs_) then
    io.stderr:write("\n! Warning: Label references have changed, please rerun SILE to update them.")
  elseif #missing_ > 0 then
    io.stderr:write("\n! Warning: There are unresolved label references ("
      ..table.concat(missing_, ", ")..")")
  end
end

-- Read the reference file.
-- This function is automatically called when the package is initialized.
-- References saved from a previous SILE run are thus available on
-- the next run. Multiple re-runs may be needed to obtain the correct
-- references.
local readLabelRefs = function ()
  local reffile,_ = io.open(SILE.masterFilename .. '.ref')
  if not reffile then
    return
  end
  local doc = reffile:read("*all")
  local labelrefs = assert(load(doc))()
  labelrefs_ = labelrefs
end

-- For sectioning packages:
-- Leverage \tocentry (from the tableofcontents package) if available.
-- We do this to retrieve and store the current section number.
-- This implies the user can only refer to sections actually entered in the
-- TOC. We would need another method if users eventually want want to refer
-- to a section not in the TOC, but is it sound?
local _currentTocEntry = {}
if SILE.Commands["tocentry"] then
  local oldTocEntry = SILE.Commands["tocentry"]
  SILE.registerCommand("tocentry", function (options, content)
    _currentTocEntry.number = options.number
    _currentTocEntry.content = content
    oldTocEntry(options, content)
  end)
end

-- For the lowest numbering scheme, we need to account for potential nesting,
-- so we expose a stack...
-- These two methods are exported for other (non-sectioning) packages
-- to enable cross-references on their own numbered content.
-- Example:
--   local hasRefs = SILE.documentState.documentClass.pushLabelRef
--   if hasRefs then SILE.documentState.documentClass:pushLabelRef(mynumber) end
--   ... do my content stuff ...
--   if hasRefs then SILE.documentState.documentClass:popLabelRef() end
-- I.e. check the current class supports this package, and if so wrap the
-- numbered stuff within these calls.
local _numbers = {}
local pushLabelRef = function (_, number)
  table.insert(_numbers, number)
end
local popLabelRef = function (_)
  if #_numbers > 0 then
    _numbers[#_numbers] = nil
  end
end

-- Link support when pdf:link is available
local linkWrapper = function (dest, func)
  if dest and SILE.Commands["pdf:link"] then
    SILE.call("pdf:link", { dest = dest }, func)
  else
    func()
  end
end

-- If a reference marker has already been met, it is above us (supra)
-- else it must be after us (infra).
  local isSupra = function(marker)
    return markers_[marker] ~= nil and true or false
  end

-- LOW-LEVEL/INTERNAL COMMANDS

SILE.registerCommand("refentry", function (options, content)
  if markers_[options.marker] ~= nil then
    SU.warn("Duplicate label '"..options.marker.."': this is possibly an error")
  end
  markers_[options.marker] = true -- Just store seen markers

  local dest
  if SILE.Commands["pdf:destination"] then
    dest = "ref:" .. options.marker
    SILE.call("pdf:destination", { name = dest })
  end
  SILE.call("info", {
    category = "labelref",
    value = {
      marker = options.marker,
      title = content,
      section = options.section,
      number = options.number,
      link = dest
      -- pageno will be added when infonodes are moved.
    }
  })
end, "Inserts a reference infonode.")

SILE.registerCommand("ref:unknown", function (options, _)
  local marker = SU.required(options, "marker", "ref")
  SILE.call("font", { weight = 700 }, { "‹missing reference›"})
  -- The warn option is not documented to avoid its abuse. It's only
  -- convenience so that we can voluntarily show a missing reference in
  -- the package documentation without the user being spammed...
  if SU.boolean(options.warn, true) then
    SU.warn("Label reference '"..marker.."' has not yet been resolved")
    missing_[#missing_ + 1] = marker
  end
end, "Warns the user and outputs ‹missing reference› for unresolved label references.")

SILE.registerCommand("ref:supra", function (_, _)
  SILE.call("font", { style = "italic", language = "und" }, { "supra" })
end, "Relative reference is above (supra).")

SILE.registerCommand("ref:infra", function (_, _)
  SILE.call("font", { style = "italic", language = "und" }, { "infra" })
end, "Relative reference is below (infra).")

-- END-USER COMMANDS

SILE.registerCommand("label", function (options, content)
  local marker = SU.required(options, "marker", "label")
  local currentNumber = _numbers[#_numbers]
  SILE.call("refentry", { marker = marker, section = _currentTocEntry.number, number = currentNumber }, _currentTocEntry.content)
  -- We don't really expect a content, let's ship it out anyway, so that if the
  -- user accidentally had a group afterwards, it's not lost.
  SILE.process(content)
end, "Registers a label reference at the current point in the document.")

SILE.registerCommand("ref", function (options, content)
  local marker = SU.required(options, "marker", "ref")
  local t = options.type or "default"

  local node = labelrefs_[marker]
  if not node then
    SILE.call("ref:unknown", options)
  else
    linkWrapper(SU.boolean(options.linking, true) and node.link, function ()
      if t == "relative" then
        if isSupra(marker) then
          SILE.call("ref:supra")
        else
          SILE.call("ref:infra")
        end
      else
        if t == "page" then
          SILE.typesetter:typeset(""..node.pageno)
        elseif t == "section" then
          if not node.section then
            SILE.call("ref:unknown", options)
          else
            SILE.typesetter:typeset(""..node.section)
          end
        elseif t == "title" then
          if not node.title then
            SILE.call("ref:unknown", options)
          else
            SILE.process(node.title)
          end
        elseif t == "default" then
          -- Closest numbering in that order: number, section or page
          if not node.number then
            if not node.section then
              SILE.typesetter:typeset(""..node.pageno)
            else
              SILE.typesetter:typeset(""..node.section)
            end
          else
            SILE.typesetter:typeset(""..node.number)
          end
        else
          SU.error("Unknown reference type '"..t.."'")
        end
        if SU.boolean(options.relative, false) then
          SILE.typesetter:typeset(" ")
          if isSupra(marker) then
            SILE.call("ref:supra")
          else
            SILE.call("ref:infra")
          end
        end
      end
    end)
  end
  -- We don't really expect a content, let's ship it out anyway, so that if the
  -- user accidentally had a group afterwards, it's not lost.
  SILE.process(content)
end, "Prints a reference for the given label marker.")

SILE.registerCommand("pageref", function (options, content)
  options.type = "page"
  SILE.call("ref", options, content)
end, "Convenience command to print a page reference.")

-- EXPORTS

return {
  exports = {
    writeLabelRefs = writeLabelRefs,
    moveLabelRefs = moveLabelRefs,
    pushLabelRef = pushLabelRef,
    popLabelRef = popLabelRef,
  },
  init = function (self)
    self:loadPackage("infonode")
    readLabelRefs()
  end,
  documentation = [[\begin{document}
The \label[marker=labelrefs:head]\autodoc:package{labelrefs} package provides tools for classes
and packages to support cross-references within a document.

From a document author perspective, the commands \autodoc:command{\label} and \autodoc:command{\ref}
are then available. Both take a \autodoc:parameter{marker} parameter, which can be any reference string.
They do not expect any argument; if one is passed, though, it is just processed as-is.

The \autodoc:command{\label} command is used to reference a given point in a document. Let us
do it just here\label[marker=labelrefs:test]. It does not print anything, but we now have
a reference, just before this sentence.

The \autodoc:command{\ref} command is used to refer to the point with the specified marker and
print out a resolved value depending on the \autodoc:parameter{type} option.

The page number is always available as \autodoc:command{\ref[marker=<marker>, type=page]}\footnote{The
package also provides the \autodoc:command{\pageref[marker=<marker>]} command as a mere convenience
alias.}: our label is on page \pageref[marker=labelrefs:test].

In a book-like class, the current sectioning level (chapter, section, etc.) is also
available\footnote{\label[marker=fn:example]Actually, the package currently leverages the
\autodoc:command[check=false]{\tocentry} command if it exists, so assumes section entries
explicitly marked for being excluded from the table of contents will not be referred to.
That’s a guess in the dark, so do not hesitate reporting an issue.}, by number or title.
The current section number corresponds to \autodoc:command{\ref[marker=<marker>, type=section]}.
So here we should be in \ref[marker=labelrefs:test,type=section], if this documentation is included
in some sort of book.
The current section title corresponds to \autodoc:command{\ref[marker=<marker>, type=title]}.
Here, “\ref[marker=labelrefs:test,type=title]” (with us adding the quotes).

If referencing a marker that does not exist or a section which is not
available, a warning is reported and the printed output is \ref[marker=do:not:exist, warn=false].

\label[marker=labelrefs:fn]If this package is loaded after a footnote package, then we also get the footnote
number for a label in a footnote, with \autodoc:command{\ref[marker=<marker>, type=default]}.
For instance, let’s pretend with want to refer the reader to note \ref[marker=fn:example,type=default].

This \autodoc:value{default} type is actually the most general and, as its name implies,
the default one if you omit specifying a type. If the referenced label is not in a
numbered object such as a footnote — or say, in the future, a figure or table caption (provided
appropriate package support) — then the section number is printed. In other terms, you get the
closest item numbering value.

This author knows some editors are pedantic and actually confesses the same guilt. This
package therefore supports another type, \autodoc:value{relative}, which would not
have needed such a machinery. Easy, this package description started \ref[marker=labelrefs:head,
type=relative] and ends \ref[marker=labelrefs:foot, type=relative]. And it even accepts, on all
the above-mentioned flavors of the \autodoc:command{\ref} command, a \autodoc:parameter{relative} option
that may be set to true. So it started on page \pageref[marker=labelrefs:head,relative=true] and
ends on page \pageref[marker=labelrefs:foot,relative=true]. Blatant pedantry, for sure, but
a fault confessed is half redressed. Let’s pretend that \em{sometimes}, it might help
obtaining better line breaks.

As a final note, if the \autodoc:package{pdf} package is loaded before using label commands,
then hyperlinks will be enabled on references. You may disable this behavior
by setting the \autodoc:parameter{linking} option to false on the \autodoc:command{\ref} command.

\em{For class designers:} The package exports two Lua methods, \code{moveLabelRefs} and
\code{writeLabelRefs}. The former should be called at the end of each page to collate
label references. The latter should be called at the end of the document, to save the
references to a file which is read when the package is initialized. Also, this package has
to be loaded after the table of contents package, as it updates its
\autodoc:command[check=false]{\tocentry} command, as stated in note \ref[marker=fn:example].

\em{For package designers:} The package exports two Lua methods, \code{pushLabelRef}
and \code{popLabelRef}. The former takes a formatted number as argument. To enable
cross-referencing in your own package, whatever your numbering scheme is, you may test for their
availability in your supporting class
(e.g. checking \code{SILE.documentState.documentClass.pushLabelRef} exists)
and then wrap your code within them.
\label[marker=labelrefs:foot]

\end{document}]]
}
