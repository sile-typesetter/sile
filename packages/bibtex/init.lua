local base = require("packages.base")

local CslProcessor = require("packages.bibtex.csl.processor")

local package = pl.class(base)
package._name = "bibtex"

function package:loadOptPackage (pack)
   local ok, _ = pcall(function ()
      self:loadPackage(pack)
      return true
   end)
   SU.debug("bibtex", "Optional package " .. pack .. (ok and " loaded" or " not loaded"))
   return ok
end

function package:_init ()
   base._init(self)
   self._processor = CslProcessor()

   -- For DOI, PMID, PMCID and URL support.
   self:loadPackage("url")
   -- For underline styling support
   self:loadPackage("rules")
   -- For TeX-like math support (extension)
   self:loadPackage("math")
   -- For superscripting support in number formatting
   -- Play fair: try to load 3rd-party optional textsubsuper package.
   -- If not available, fallback to raiselower to implement textsuperscript
   if not self:loadOptPackage("textsubsuper") then
      SU.debug("bibtex", "Superscripting support using raised and scaled text")
      self:loadPackage("raiselower")
      self:registerCommand("textsuperscript", function (_, content)
         -- Fake more or less ad hoc superscripting
         SILE.call("raise", { height = "0.7ex" }, function ()
            SILE.call("font", { size = "1.5ex" }, content)
         end)
      end)
   end
end

function package:declareSettings ()
   SILE.settings:declare({
      parameter = "bibtex.style", -- Kept for compatibility but no longer used
      type = "string",
      default = "csl",
      help = "BibTeX style",
   })

   -- For CSL hanging-indent or second-field-align
   SILE.settings:declare({
      parameter = "bibliography.indent",
      type = "measurement",
      default = SILE.types.measurement("3em"),
      help = "Left indentation for bibliography entries when the citation style requires it.",
   })
end

--- Get the citation key from the options or content (of a command).
-- @tparam table options Options
-- @tparam table content Content
-- @treturn string Citation key
function package:_getCitationKey (options, content)
   if options.key then
      return options.key
   end
   return SU.ast.contentToString(content)
end

function package:registerCommands ()
   -- Bibliography loading

   self:registerCommand("loadbibliography", function (options, _)
      local file = SU.required(options, "file", "loadbibliography")

      self._processor:loadBibliography(file)
   end, "Load a bibliography file, merging it with the current bibliography database.")

   -- Style and locale loading

   self:registerCommand("bibliographystyle", function (options, _)
      local sty = SU.required(options, "style", "bibliographystyle")
      local lang = options.lang -- Can be nil

      self._processor:setBibliographyStyle(sty, lang, {
         localizedPunctuation = SU.boolean(options.localizedPunctuation, false),
         italicExtension = SU.boolean(options.italicExtension, true),
         mathExtension = SU.boolean(options.mathExtension, true),
         breakISBN = SU.boolean(options.breakISBN, true),
      })
   end, "Set the bibliography style and locale for citations and references.")

   -- Citation commands

   self:registerCommand("nocite", function (options, content)
      local key = self:_getCitationKey(options, content)
      self._processor:nocite(key)
   end, "Mark an entry as cited without actually producing a citation.")

   self:registerCommand("cite", function (options, content)
      local key = self:_getCitationKey(options, content)
      options.key = key
      local cite = self._processor:cite(options)
      if cite then
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a single citation.")

   self:registerCommand("cites", function (_, content)
      if type(content) ~= "table" then
         SU.error("Table content expected in \\cites")
      end
      -- Extract sub-commands
      local children = {}
      for _, child in ipairs(content) do
         if type(child) == "table" then
            if child.command == "cite" then
               local key = self:_getCitationKey(child.options, child)
               child.options.key = key
               table.insert(children, child.options)
            elseif child.command == "nocite" then
               local key = self:_getCitationKey(child.options, child)
               self._processor:nocite(key)
            else
               SU.error("Only \\cite and \\nocite commands are allowed in \\cites")
            end
         end
         -- Silently ignore other content (normally only blank lines)
      end
      local cite = self._processor:cites(children)
      if cite then
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
      end
   end, "Produce a group of citations.")

   self:registerCommand("reference", function (options, content)
      local key = self:_getCitationKey(options, content)
      local ref = self._processor:reference(key)
      if ref then
         SILE.processString(("<sile>%s</sile>"):format(ref), "xml")
      end
   end, "Produce a single bibliographic reference.")

   self:registerCommand("printbibliography", function (options, _)
      local cite = self._processor:bibliography(options)
      local engine = self._processor:getCslEngine()

      if not SILE.typesetter:vmode() then
         SILE.call("par")
      end
      SILE.settings:temporarily(function ()
         local hanging_indent = SU.boolean(engine.bibliography.options["hanging-indent"], false)
         local must_align = engine.bibliography.options["second-field-align"]
         local lskip = (SILE.settings:get("document.lskip") or SILE.types.node.glue()):absolute()
         if hanging_indent or must_align then
            -- Respective to the fixed part of the current lskip, all lines are indented
            -- but the first one.
            local indent = SILE.settings:get("bibliography.indent"):absolute()
            SILE.settings:set("document.lskip", lskip.width + indent)
            SILE.settings:set("document.parindent", -indent)
            SILE.settings:set("current.parindent", -indent)
         else
            -- Fixed part of the current lskip, and no paragraph indentation
            SILE.settings:set("document.lskip", lskip.width)
            SILE.settings:set("document.parindent", SILE.types.length())
            SILE.settings:set("current.parindent", SILE.types.length())
         end
         SILE.processString(("<sile>%s</sile>"):format(cite), "xml")
         SILE.call("par")
      end)
   end, "Produce a bibliography of references.")

   -- Hooks for CSL processing

   self:registerCommand("bibSmallCaps", function (_, content)
      -- To avoid attributes in the CSL-processed content
      SILE.call("font", { features = "+smcp" }, content)
   end)

   self:registerCommand("bibSuperScript", function (_, content)
      -- Superscripted content from CSL may contain characters that are not
      -- available in the font even with +sups.
      -- E.g. ACS style uses superscripted numbers for references, but also
      -- comma-separated lists of numbers, or ranges with an en-dash.
      -- We want to be consistent between all these cases, so we always
      -- use fake superscripts.
      SILE.call("textsuperscript", { fake = true }, content)
   end)

   -- CSL 1.0.2 appendix VI
   -- "If the bibliography entry for an item renders any of the following
   -- identifiers, the identifier should be anchored as a link, with the
   -- target of the link as follows:
   --   url: output as is
   --   doi: prepend with “https://doi.org/”
   --   pmid: prepend with “https://www.ncbi.nlm.nih.gov/pubmed/”
   --   pmcid: prepend with “https://www.ncbi.nlm.nih.gov/pmc/articles/”
   -- NOT IMPLEMENTED:
   --   "Citation processors should include an option flag for calling
   --   applications to disable bibliography linking behavior."
   -- (But users can redefine these commands to their liking...)
   self:registerCommand("bibLink", function (options, content)
      SILE.call("href", { src = options.src }, {
         SU.ast.createCommand("url", {}, { content[1] }),
      })
   end)
   self:registerCommand("bibURL", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         -- Play safe
         link = "https://" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self:registerCommand("bibDOI", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://doi.org/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self:registerCommand("bibPMID", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://www.ncbi.nlm.nih.gov/pubmed/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)
   self:registerCommand("bibPMCID", function (_, content)
      local link = content[1]
      if not link:match("^https?://") then
         link = "https://www.ncbi.nlm.nih.gov/pmc/articles/" .. link
      end
      SILE.call("bibLink", { src = link }, content)
   end)

   self:registerCommand("bibRule", function (_, content)
      local n = content[1] and tonumber(content[1]) or 3
      local width = n .. "em"
      SILE.call("raise", { height = "0.4ex" }, function ()
         SILE.call("hrule", { height = "0.4pt", width = width })
      end)
   end)

   self:registerCommand("bibBoxForIndent", function (_, content)
      local hbox = SILE.typesetter:makeHbox(content)
      local margin = SILE.types.length(SILE.settings:get("bibliography.indent"):absolute())
      if hbox.width > margin then
         SILE.typesetter:pushHbox(hbox)
         SILE.typesetter:typeset(" ")
      else
         hbox.width = margin
         SILE.typesetter:pushHbox(hbox)
      end
   end)

   self:registerCommand("bibParagraph", function (_, content)
      SILE.process(content)
      SILE.call("par")
   end)

   self:registerCommand("bibRelated", function (_, content)
      SILE.settings:temporarily(function ()
         local indent = SILE.settings:get("bibliography.indent"):absolute()
         local lskip = (SILE.settings:get("document.lskip") or SILE.types.node.glue()):absolute()
         SILE.settings:set("font.size", 0.9 * SILE.settings:get("font.size"))
         SILE.settings:set("document.lskip", lskip.width + indent)
         SILE.process(content)
      end)
   end)
end

package.documentation = [[
\begin{document}
BibTeX is a citation management system.
It was originally designed for TeX but has since been integrated into a variety of situations.
This experimental package allows SILE to read and process Bib(La)TeX \code{.bib} files and output citations and full text references.

\smallskip
\noindent
\em{Loading a bibliography}
\novbreak

\indent
To load a BibTeX file, issue the command \autodoc:command{\loadbibliography[file=<whatever.bib>]}.
You can load multiple files, and the entries will be merged into a single bibliography database.

\smallskip
\noindent
\em{Producing citations and references}
\novbreak

\indent
The package relies the Citation Style Language (CSL) standard to format citations and bibliographic references.

You should first invoke \autodoc:command{\bibliographystyle[style=<style>, lang=<lang>]}, where \autodoc:parameter{style} is the name of the CSL style file (without the \code{.csl} extension), and \autodoc:parameter{lang} is the language code of the CSL locale to use (e.g., \code{en-US}).

The command accepts a few additional options:

\begin{itemize}
\item{\autodoc:parameter{localizedPunctuation} (default \code{false}): whether to use localized punctuation – this is non-standard but may be useful when using a style that was not designed for the target language;}
\item{\autodoc:parameter{italicExtension} (default \code{true}): whether to convert \code{_text_} to italic text (“à la Markdown”);}
\item{\autodoc:parameter{mathExtension} (default \code{true}): whether to recognize \code{$formula$} as math formulae in (a subset of the) TeX-like syntax.}
\item{\autodoc:parameter{breakISBN} (default \code{true}): whether to allow breaking ISBN and ISSN at their dashes.}
\end{itemize}

The locale and styles files are searched in the \code{csl/locales} and \code{csl/styles} directories, respectively, in your project directory, or in the Lua package path.
For convenience and testing, SILE bundles the \code{chicago-author-date} and \code{chicago-author-date-fr} styles, and the \code{en-US} and \code{fr-FR} locales.
If you don’t specify a style or locale, the author-date style and the \code{en-US} locale will be used.

To produce an inline citation, call \autodoc:command{\cite{<key>}}, which will typeset something like “(Jones 1982)”.
If you want to cite a particular page number, use \autodoc:command{\cite[page=22]{<key>}}. Other “locator”  options are available (article, chapter, column, line, note, paragraph, section, volume, etc.) – see the CSL documentation for details.
Some frequent abbreviations are also supported (art, chap, col, fig…)

To mark an entry as cited without actually producing a citation, use \autodoc:command{\nocite{<key>}}.
This is useful when you want to include an entry in the bibliography without citing it in the text.

To generate multiple citations grouped correctly, use \autodoc:command{\cites{\cite{<key1>} \cite{<key2>}, …}}.
This wrapper command only accepts \autodoc:command{\cite} and \autodoc:command{\nocite} elements following their standard syntax.
Any other element triggers an error, and any text content is silently ignored.

To produce a bibliography of cited references, use \autodoc:command{\printbibliography}.
After printing the bibliography, the list of cited entries will be cleared. This allows you to start fresh for subsequent uses (e.g., in a different chapter).

If you want to include all entries in the bibliography, not just those that have been cited, set the option \autodoc:parameter{cited} to false.

In that case, the \autodoc:parameter{filter} option can be used to filter the entries to be included in the bibliography.
It accepts list of space-separated filters, such as \code{type-book} or \code{not-type-book}, or \code{keyword-foo} or \code{not-keyword-foo}, \code{issued-2020} or \code{issued-2023-2025}.

You can also use the \autodoc:parameter{related=true} option to include related entries in a smaller section after a main entry.
The may be useful when, for reviews of a work, which you may find interesting to have directly after the main entry for that work.

To produce a bibliographic reference, use \autodoc:command{\reference{<key>}}.
Note that this command is not intended for actual use, but for testing purposes.
It may be removed in the future.

\smallskip
\noindent
\em{Notes on the supported BibTeX syntax}
\novbreak

\indent
The BibTeX file format is a plain text format for bibliographies.

The \code{@type\{…\}} syntax is used to specify an entry, where \code{type} is the type of the entry, and is case-insensitive.
Any content outside entries is ignored.

The \code{@preamble} and \code{@comment} special entries are ignored.
The former is specific to TeX-based systems, and the latter is a comment (everything between the balanced braces is ignored).

The \code{@string\{key=value\}} special entry is used to define a string or “abbreviation,” for use in other subsequent entries.

The \code{@xdata} entry is used to define an entry that can be used as a reference in other entries.
Such entries are not printed in the bibliography.
Normally, they cannot be cited directly.
In this implementation, a warning is raised if they are; but as they have no known type, their formatting is not well-defined, and might not be meaningful.

Regular bibliography entries have the following syntax:

\begin[type=autodoc:codeblock]{raw}
@type{key,
  field1 = value1,
  field2 = value2,
  …
}
\end{raw}

The entry key is a unique identifier for the entry, and is case-sensitive.
Entries consist of fields, which are key-value pairs.
The field names are case-insensitive.
Spaces and line breaks are not important, except for readability.
On the contrary, commas are compulsory between any two fields of an entry.

String values shall be enclosed in either double quotes or curly braces.
The latter allows using quotes inside the string, while the former does not without escaping them with a backslash.

When string values are not enclosed in quotes or braces, they must not contain any whitespace characters.
The value is then considered to be a reference to an abbreviation previously defined in a \code{@string} entry.
If no such abbreviation is found, the value is considered to be a string literal.
(This allows a decent fallback for fields where curly braces or double quotes could historically be omitted, such as numerical values, and one-word strings.)

String values are assumed to be in the UTF-8 encoding, and shall not contain (La)TeX commands.
Special character sequences from TeX (such as \code{`} assumed to be an opening quote) are not supported.
There are exceptions to this rule.
Notably, the \code{~} character can be used to represent a non-breaking space (when not backslash-escaped), and the \code{\\&} sequence is accepted (though this implementation does not mandate escaping ampersands).
With the CSL renderer, see also the non-standard extensions above.

Values can also be composed by concatenating strings, using the \code{#} character.

Besides using string references, entries have two other \em{parent-child} inheritance mechanisms allowing to reuse fields from other entries, without repeating them: the \code{crossref} and \code{xdata} fields.

The \code{crossref} field is used to reference another entry by its key.
The \code{xdata} field accepts a comma-separated list of keys of entries that are to be inherited.

Some BibTeX implementations automatically include entries referenced with the \code{crossref} field in the bibliography, when a certain threshold is met.
This implementation does not do that.

Depending on the types of the parent and child entries, the child entry may inherit some or all fields from the parent entry, and some inherited fields may be reassigned in the child entry.
For instance, the \code{title} in a \code{@collection} entry is inherited as the \code{booktitle} field in a \code{@incollection} child entry.
Some BibTeX implementations allow configuring the data inheritance behavior, but this implementation does not.
It is also currently quite limited on the fields that are reassigned, and only provides a subset of the mappings defined in the BibLaTeX manual, appendix B.

Here is an example of a BibTeX file showing some of the abovementioned features:

\begin[type=autodoc:codeblock]{raw}
@string{JIT = "Journal of Interesting Things"}
...
This text is ignored
...
@xdata{jit-vol1-iss2,
  journal = JIT # { (JIT)},
  year    = {2020},
  month   = {jan},
  volume  = {1},
  number  = {2},
}
@article{my-article,
  author  = {Doe, John and Smith, Jane}
  title   = {Theories & Practices},
  xdata   = {jit-1-2},
  pages   = {100--200},
}
\end{raw}

Some fields have a special syntax.
The \code{author}, \code{editor} and \code{translator} fields accept a list of names, separated by the keyword \code{and}.
The legacy \code{month} field accepts a three-letter abbreviation for the month in English, or a number from 1 to 12.
The more powerful \code{date} field accepts a date-time following the ISO 8601-2 Extended Date/Time Format specification level 1 (such as \code{YYYY-MM-DD}, or a date range \code{YYYY-MM-DD/YYYY-MM-DD}, and more).
\end{document}
]]

return package
