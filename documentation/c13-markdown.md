# Appendix on SILE and Markdown

::: {custom-style=raggedleft}
"Markdown is intended to be as easy-to-read and easy-to-write as is feasible."^[From the
original [Markdown syntax specification](https://daringfireball.net/projects/markdown/syntax).]
:::

While the original Markdown format was indeed quite simple, it quickly became a landmark for
technical documentation. Several variants emerged. Amongst other solutions, the Pandoc converter
started supporting a nice set of interesting extensions for lists, footnotes, tables,
etc.^[See [IETF RFC 7764, section 3.3](https://datatracker.ietf.org/doc/html/rfc7764#section-3.3).]
---So that nowadays, Markdown, enriched with these extensions, may be quite appealing to writers and
authors alike.

Within SILE’s aim to produce beautiful printed documents, it's a pretty reasonable assumption that
such writers and authors may want to use this fine typesetter with their Markdown content, without
having to learn the SILE language and its specifics (but not, either, fully excluding it for some
advanced capabilities).

There is actually more than one solution to achieve great results in that direction:

 1. Directly using the native converter provided with SILE itself,
 1. Using the Pandoc software to generate an ouput suitable for SILE,
     a) Either with a version of Pandoc that supports a SILE writer,
     a) Or with a Pandoc custom Lua writer.

Each of them has its advantages, and a few limitations as well.

[comment]: # (THIS TEXT SHOULD NOT APPEAR IN THE OUTPUT. It is actually the most platform independent comment in Mardown.)

## The native markdown package

Guess what, the very chapter you are currently reading is entirely processed with it.
Once you have loaded the `\autodoc:package{markdown}`{=sile} package,
the `\autodoc:command{\include[src=<file>]}`{=sile} command supports reading a Markdown file[^other-ways].
The speedy Markdown parsing relies on John MacFarlane's excellent **lunamark** Lua library.

[^other-ways]: The astute reader already knows, from the previous chapters, that there are other ways (e.g. with
command-line options) to tell SILE how to process a file in some format --- so we just stick
to the basics here.

```
\script[src=packages/markdown]
\include[src=somefile.md]
```

### Basic typesetting

As it can be seen here, sectioning obviously works^[With a small caveat. The package maps heading
levels to `\chapter`, `\section`, `\subsection`, `\subsubsection` and uses a very basic fallback
if these are not found (or if the sectioning level gets past that point). The implication, therefore,
is that the class or other packages have to provide the relevant implementations.] and paragraphs
are of course supported.
As of formatting, *italic*, **bold**, and `code` all work as expected.

Three dashes on a standalone line (as well as asterisks or underscores)
produce an horizontal rule.

***

Several Pandoc-like extensions to Markdown are supported.
Notably, the converter comes by default with smart typography enabled: three dashes (`---`) in an
inline text sequence are converted to an em-dash (---), two dashes (`--`)
to an en-dash useful for ranges (ex., "it's at pages 12--14"), and three dots
(`...`) to an ellipsis (...)

By the way, note, from the above example, that smart quotes and apostrophes are also automatically handled.

Likewise, superscripts and subscripts are available : H~2~O is a liquid, 2^10^ is 1024. This was
obtained with `H~2~O` and `2^10^` respectively.

Other nice features include:

 - ~~deletions~~ with `~~deletions~~`
 - [underlines]{.underline} with `[underlines]{.underline}`
 -  and even [Small Caps]{.smallcaps}, as `[Small Caps]{.smallcaps}`

The two latter cases use the extended Pandoc-inspired "span" syntax, which is also useful for languages
and custom styles (see futher below). They also use the CSS-like class notation that several
Pandoc writers recognize.

### Lists

Unordered lists (a.k.a. itemized or bullet lists) are obviously supported, or
we would not have been able to use them in the previous section.

Ordered lists are supported as well, and also accept some of the "fancy lists" features
from Pandoc. The starting number is honored, and you have the flexibility to use
digits, roman numbers or letters (in upper or lower case).
The end delimiter, besides the standard period, can also be a closing parenthesis.

 B. This list use uppercase letters and starts at 2. Er... at "B", that is.
     i) Roman number...
     i) ... followed by a right parenthesis rather than a period.

By the way,

 1. Nesting...

    ... works as intended.

     - Fruits
        - Apple
        - Orange
     - Vegetables
        - Carrot
        - Potato

    And that's all about regular lists.

Task lists following the GitHub-Flavored Markdown (GFM) format are supported too:

 - [ ] Unchecked item
 - [x] Checked item

Definition lists^[As in Pandoc, using the syntax of PHP Markdown Extra with some
extensions.] are also decently supported:

apples
  : Good for making applesauce.

citrus
  : Like oranges but yellow.

### Block quotes

> Block quotes are written like so.
>
> > They can be nested.

There's a small catch here. If your class or previously loaded packages provide
a `blockquote` environment, it will be used. Otherwise, the converter uses its
own fallback method.

### Links and footnotes

Here is a link to [the SILE website](https://sile-typesetter.org/).
It might not be visible in the PDF output, but hover it and click. It just works.

Here is a footnote call[^1].

[^1]: An here is some footnote text. But there were already a few foonotes earlier in this
chapter. Let's just add, as you can check in the source for this chapter, that the
converter supports several syntaxes for footnotes.

### Languages

Language changes within the text are supported, either around "div" blocks or inline
"span" elements (both of those are Pandoc-like extensions to standard Markdown).
It is not much visible below, obviously, but the language setting
affects the hyphenation and other properties. In the case of French, for instance,
you can see the special thin space before the exclamation point, or the internal
spacing around quoted text:

::: {lang=fr}
> Cette citation est en français!
:::

Or inline in text: [«Encore du français!»]{lang=fr}

This was obtained with:

```
::: {lang=fr}
> Cette citation est en français!
:::

Or inline in text: [«Encore du français!»]{lang=fr}
```

### Custom styles

On the "div" and "span" extended elements, the converter also supports the `{custom-style="..."}`
attribute.
This is, as a matter of fact, the same syntax as proposed by Pandoc, for instance, in
its **docx** writer, to specify a specific, possibly user-defined, custom style (in that case,
a Word style, obviously). So yes, if you had a Pandoc-Markdown document styled for Word,
you might consider switching to SILE is an option!

If such a named style exists, it is applied. Erm. What does it mean? Well, in the default
implementation, if there is a corresponding SILE command by that name, the converter invokes
it. Otherwise, it just ignores the style and processes the content as-is.
It thus allows you to use some interesting SILE features. For instance, here is some block
of text marked as "center":

::: {custom-style="center"}
This is SILE at its best.
:::

And some inline [message]{custom-style="strong"}, marked as "strong". That's a fairly
contrived way to obtain a bold text, but you get the underlying idea.

This logic is implemented in the `\autodoc:command{\markdown:custom-style:hook}`{=sile}
command. Package or class designers may override this hook to support any other
other styling mechanism they may have or want. But basically, this is one of the
way to use SILE commands in Markdown. While you could invoke _any_ SILE command with
this feature, we recommend, though, to restrict it to styling. You will see, further below,
another more powerful way to leverage Markdown with SILE’s full processing capabilities.

### Images

Here is an image: ![](./documentation/gutenberg.png "An exemplary image"){width=1.5cm}

![](./packages/svg/smiley.svg){height=0.9em} SVG is supported too.

You can specify the required image width and/or height, as done just above actually,
by appending the `{width=... height=...}` attributes^[And possibly other attributes,
they are all passed through to the underlying SILE package.] after the usual Markdown
image syntax ---Note that any unit system supported by SILE is accepted.

### Tables

The converter only supports the PHP-like "pipe table" syntax at this point, with an optional
caption.

| Right | Left | Default | Center |
|------:|:-----|---------|:------:|
|  12   |  12  |    12   |    12  |
|  123  |  123 |   123   |   123  |

  : Demonstration of a pipe table.

Regarding captioned tables, there's again a catch. If your class or previously loaded packages
provide a `captioned-table` environment, it will be wrapped around the table (and it is then assumed to
take care of a `\caption` content, i.e. to extract and display it appropriately).  Otherwise,
the converter uses its own fallback method.

### Code blocks

Verbatim code and "fenced code blocks" work:

```lua
function fib (n)
  -- Fibonacci numbers
  if n < 2 then return 1 end
  return fib(n - 2) + fib(n - 1)
end
```

### Raw blocks

Last but not least, the converter supports a `{=sile}` annotation on code blocks, to pass
through their content in SILE language, as shown below.[^raw-comment]

[^raw-comment]: This is also a Pandoc-inspired extension to standard Markdown. Other `{=xxx}` annotations
than those described in this section are skipped (i.e. their whole content is ignored).
`That's a \LaTeX{} construct, so it's skipped in the SILE output.`{=latex}

```{=sile}
For instance, this \em{entire} sentence is typeset in a \em{raw block}, in SILE language.
```

Likewise, this is available on inline code elements: `\em{idem.}`{=sile}

This was obtained with:

~~~
```{=sile}
For instance, this \em{entire} sentence is typeset in a \em{raw block}, in SILE language.
```

Likewise, this is available on inline code elements: `\em{idem.}`{=sile}
~~~


It also supports `{=sile-lua}` to pass Lua code, as in a SILE `\script`. This is just
a convenience compared to the preceding one, but it allows you to exactly type
the content as if it was in a code block (i.e. without having to bother wrapping
it in a script).

```{=sile-lua}
SILE.call("em", {}, { 'This' })
SILE.typesetter:typeset(" is called from Lua.")
```

This was generated by:

~~~
```{=sile-lua}
SILE.call("em", {}, { 'This' })
SILE.typesetter:typeset(" is called from Lua.")
```
~~~

You now have the best of two worlds in your hands, bridging together Markdown and SILE
so that you can achieve wonderful things, we have no idea of. Surprise us!

## The Pandoc-based converters

In the event where the native solution would fall short for you ---e.g. would you need some extension
it doesn't yet support--- you may want to use Pandoc directly for converting your document to an
output suitable for SILE. This way, you could also, if need be, further tweak it manually.

The following solutions are still experimental proof-of-concepts, but you may give them a chance,
and help us fill the gaps.

### Using a Pandoc SILE writer and the pandoc package

There is no official SILE writer for Pandoc yet, but some efforts have been done in that direction.
It therefore requires installing a Pandoc fork^[<https://github.com/alerque/pandoc/commits/sile4>],
which is not merged upstream at this date.

You then need to use the SILE `\autodoc:package{pandoc}`{=sile} package, which provides the
required command mappings between the Pandoc-to-SILE writer and the rest of the software.

### Using a Pandoc "custom writer" in Lua

Pandoc also supports "custom writers" developed in Lua^[<https://pandoc.org/custom-writers.html>].

This custom writer API is fairly recent and might change. Actually, besides a "Classic style" API,
there's now also a "New style" API...  While such custom writers may have some rough edges, the idea
is quite appealing nevertheless. After all, SILE is mostly written in Lua, so the skills are there
in the community.

Again, there is no official solution using this conversion path, but some pretty neat
experimental results have been
achieved^[<https://github.com/Omikhleia/omikhleia-sile-packages/blob/main/examples/markdown-sample.pdf>].
That custom writer targets a specific (non-standard) class and a bunch of specific packages, which might
not have been ported to the latest version of SILE... This said, you can also certainly help pushing the
idea forward!
