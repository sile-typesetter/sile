local base = require("packages.base")

local package = pl.class(base)
package._name = "pandoc"

-- Process command options that are not actually intended to be options for a specific function but affect the document
-- in other ways, such as setting bookmarks on anything tagged with an ID attribute.
function package:_handlePandocOptions (options)
   local wrapper = SILE.process
   if options.id then
      SU.debug("pandoc", "Set ID on tag")
      SILE.call("pdf:destination", { name = options.id })
   end
   if options.lang then
      SU.debug("pandoc", "Set lang in tag:", options.lang)
      local fontfunc =
         self.commands:pull(self.commands:exists("font:" .. options.lang) and "font:" .. options.lang or "font")
      local innerWrapper = wrapper
      wrapper = function (content)
         innerWrapper(function ()
            fontfunc({ language = options.lang }, content)
         end)
      end
      options.lang = nil
   end
   if options.classes then
      for _, class in pairs(pl.stringx.split(options.classes, ",")) do
         if class == "unnumbered" then
            SU.debug("pandoc", "Convert unnumbered class to legacy heading function option")
            options.numbering = false
         elseif self.commands:exists("class:" .. class) then
            SU.debug("pandoc", "Add inner class wrapper:", class)
            local innerWrapper = wrapper
            wrapper = function (content)
               innerWrapper(function ()
                  SILE.call("class:" .. class, options, content)
               end)
            end
         else
            SU.warn(
               "Unhandled class ‘" .. class .. "’, not mapped to legacy option and no matching wrapper function"
            )
         end
      end
      options.classes = nil
   end
   return wrapper, options
end

function package:_init ()
   base._init(self)
   self:loadPackage("footnotes")
   self:loadPackage("image")
   self:loadPackage("lists")
   self:loadPackage("pdf")
   self:loadPackage("raiselower")
   self:loadPackage("rules")
   self:loadPackage("url")
   self:loadPackage("verbatim")
   self.class:registerPostinit(function ()
      -- Override the url package which styles URLs as code, something Pandoc content tends to double up on
      self.commands:register("urlstyle", function (_, content)
         SILE.process(content)
      end)
   end)
end

function package:registerCommands ()
   -- Document level stuff

   -- Blocks

   self.commands:register("BlockQuote", function (_, content)
      SILE.call("quote", {}, content)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("BulletList", function (options, content)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("itemize", options_, content)
      end)
   end)

   self.commands:register("CodeBlock", function (options, content)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("verbatim", options_, content)
      end)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("DefinitionList", function (_, content)
      SILE.process(content)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("Div", function (options, content)
      self:_handlePandocOptions(options)(content)
      SILE.typesetter:leaveHmode()
   end, "Generic block wrapper")

   self.commands:register("Header", function (options, content)
      local analog = options.type
      options.level, options.type = nil, nil
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         if analog and self.commands:exists(analog) then
            SILE.call(analog, options_, content)
         else
            SILE.process(content)
         end
      end)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("HorizontalRule", function (_, _)
      SILE.call("center", {}, function ()
         SILE.call("raise", { height = "0.8ex" }, function ()
            SILE.call("hrule", { height = "0.5pt", width = "50%lw" })
         end)
      end)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("LineBlock", function (_, content)
      SILE.process(content)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("Null", function (_, _)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("OrderedList", function (options, content)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("enumerate", options_, content)
      end)
   end)

   self.commands:register("Para", function (_, content)
      SILE.process(content)
      SILE.call("par")
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("Plain", function (_, content)
      SILE.process(content)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("RawBlock", function (options, content)
      local format = options.format
      SU.debug("pandoc", format)
      -- TODO: execute as script? pass to different input parser?
      SILE.process(content)
      SILE.typesetter:leaveHmode()
   end)

   self.commands:register("Table", function (options, content)
      SU.debug("pandoc", options.caption)
      -- TODO: options.caption
      -- TODO: options.align
      -- TODO: options.width
      -- TODO: options.headers
      SILE.process(content)
      SILE.typesetter:leaveHmode()
   end)

   -- Inlines

   self.commands:register("Cite", function (options, content)
      SU.debug("pandoc", options, content)
      -- TODO: options is citation list?
   end, "Creates a Cite inline element")

   self.commands:register("Code", function (options, content)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("code", options_, content)
      end)
   end, "Creates a Code inline element")

   self.commands:register("Emph", function (_, content)
      SILE.call("em", {}, content)
   end, "Creates an inline element representing emphasized text.")

   self.commands:register("Image", function (options, _)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("img", options_)
      end)
   end, "Creates a Image inline element")

   self.commands:register("LineBreak", function (_, _)
      SILE.call("break")
   end, "Create a LineBreak inline element")

   self.commands:register("Link", function (options, content)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("url", options_, content)
      end)
   end, "Creates a link inline element, usually a hyperlink.")

   self.commands:register("Nbsp", function (_, _)
      SILE.typesetter:typeset(" ")
   end, "Output a non-breaking space.")

   self.commands:register("Math", function (options, content)
      SU.debug("pandoc", options)
      -- TODO options is math type
      SILE.process(content)
   end, "Creates a Math element, either inline or displayed.")

   self.commands:register("Note", function (_, content)
      SILE.call("footnote", {}, content)
   end, "Creates a Note inline element")

   self.commands:register("Quoted", function (options, content)
      SU.debug("pandoc", options.type)
      -- TODO: options.type
      SILE.process(content)
   end, "Creates a Quoted inline element given the quote type and quoted content.")

   self.commands:register("RawInline", function (options, content)
      local format = options.format
      SU.debug("pandoc", format)
      -- TODO: execute as script? pass to different input parser?
      SILE.process(content)
   end, "Creates a Quoted inline element given the quote type and quoted content.")

   self.commands:register("SmallCaps", function (_, content)
      SILE.call("font", { features = "+smcp" }, content)
   end, "Creates text rendered in small caps")

   self.commands:register("Span", function (options, content)
      self:_handlePandocOptions(options)(content)
   end, "Creates a Span inline element")

   self.commands:register("Strikeout", function (_, content)
      SILE.call("strikethrough", {}, content)
   end, "Creates text which is striked out.")

   self.commands:register("Strong", function (_, content)
      SILE.call("strong", {}, content)
   end, "Creates a Strong element, whose text is usually displayed in a bold font.")

   local scriptOffset = "0.7ex"
   local scriptSize = "1.5ex"

   self.commands:register("Subscript", function (_, content)
      SILE.call("lower", { height = scriptOffset }, function ()
         SILE.call("font", { size = scriptSize }, content)
      end)
   end, "Creates a Subscript inline element")

   self.commands:register("Superscript", function (_, content)
      SILE.call("raise", { height = scriptOffset }, function ()
         SILE.call("font", { size = scriptSize }, content)
      end)
   end, "Creates a Superscript inline element")

   -- Utility wrapper classes

   self.commands:register("class:csl-no-emph", function (_, content)
      SILE.call("font", { style = "Roman" }, content)
   end, "Inline upright wrapper")

   self.commands:register("class:csl-no-strong", function (_, content)
      SILE.call("font", { weight = 400 }, content)
   end, "Inline normal weight wrapper")

   self.commands:register("class:csl-no-smallcaps", function (_, content)
      SILE.call("font", { features = "-smcp" }, content)
   end, "Inline smallcaps disable wrapper")

   -- Non native types

   self.commands:register("ListItem", function (options, content)
      local wrapper, options_ = self:_handlePandocOptions(options)
      wrapper(function ()
         SILE.call("item", options_, content)
      end)
   end)

   self.commands:register("ListItemTerm", function (_, content)
      SILE.call("smallskip")
      SILE.call("strong", {}, content)
      SILE.typesetter:typeset(" : ")
   end)

   self.commands:register("ListItemDefinition", function (_, content)
      SILE.process(content)
      SILE.call("smallskip")
   end)
end

package.documentation = [[
\begin{document}

Cover all the possible commands Pandoc's SILE export might throw at us.

\end{document}
]]

return package
