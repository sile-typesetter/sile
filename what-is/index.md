---
layout: static
title: What is SILE?
---

SILE is a typesetting system. 
Its job is to produce beautiful printed documents. 
The best way to understand what SILE is and what it does is to compare it to other systems which you may have heard of.

## SILE versus Word

When most people produce printed documents using a computer, they usually use software such as Word (part of Microsoft Office) or Writer (part of Open/LibreOffice) or similar–word processing software. 
SILE is not a word processor; it is a typesetting system. 
There are several important differences.

The job of a word processor is to produce a document that looks exactly like what you type on the screen. 
SILE takes what you type and considers it instructions for producing a document that looks as good as possible.

For instance, in a word processor, you keep typing and when you hit the right margin, your cursor will move to the next line. 
It is showing you where the lines will break. SILE doesn’t show you where the lines will break, because it doesn’t know yet. 
You can type and type and type as long a line as you like, and when SILE comes to process your instructions, it will consider your input (up to) three times over in order to work out how to best to break the lines to form a paragraph.
Did we end two successive lines with a hyphenated word? Go back and try again.

Similarly for page breaks. 
When you type into a word processor, at some point you will spill over onto a new page. 
In SILE, you keep typing, because the page breaks are determined after considering the layout of the whole document.

Word processors often describe themselves as WYSIWYG–What You See Is What You Get. 
SILE is cheerfully *not* WYSIWYG. 
In fact, you don’t see what you get until you get it. 
Rather, SILE documents are prepared initially in a *text editor*–a piece of software which focuses on the text itself and not what it looks like–and then ran through SILE in order to produce a PDF document.

In other words, SILE is a *language* for describing what you want to happen, and SILE will make certain formatting decisions about the best way for those instructions to be turned into print.

## SILE versus TeX

Ah, some people will say, that sounds very much like TeX. 
If you don’t know much about TeX or don’t care, you can probably skip this section.

But it’s true. 
SILE owes an awful lot of its heritage to TeX. 
It would be terribly immodest to claim that a little project like SILE was a worthy successor to the ancient and venerable creation of the Professor of the Art of Computer Programming, but… really, SILE is basically a modern rewrite of TeX.

TeX was one of the earliest typesetting systems, and had to make a lot of design decisions somewhat in a vacuum. 
Some of those design decisions have stood the test of time–and TeX is still an extremely well-used typesetting system more than thirty years after its inception, which is a testament to its design and performance–but many others have not. 
In fact, most of the development of TeX since Knuth’s era has involved removing his early decisions and replacing them with technologies which have become the industry standard: 
we use TrueType fonts, not METAFONTs (xetex); 
PDFs, not DVIs (pstex, pdftex); 
Unicode, not 7-bit ASCII (xetex again); 
markup languages and embedded programming languages, not macro languages (xmltex, luatex).
At this point, the parts of TeX that people actually _use_ are 1) the box-and-glue model, 2) the hyphenation algorithm, and 3) the line-breaking algorithm.

SILE follows TeX in each of these three areas; it contains a slavish port of the TeX line-breaking algorithm which has been tested to produce exactly the same output as TeX given equivalent input. 
But as SILE is itself written in an interpreted language, it is very easy to extend or alter the behaviour of the SILE typesetter.

For instance, one of the things that TeX can’t do particularly well is typesetting on a grid. 
This is something that people typesetting bibles really need to have. 
There are various hacks to try to make it happen, but they’re all horrible. 
In SILE, you can alter the behaviour of the typesetter and write a very short add-on package to enable grid typesetting.

Of course, nobody uses plain TeX–they all use LaTeX equivalents plus a huge repository of packages available from the CTAN. 
SILE does not benefit from the large ecosystem and community that has grown up around TeX; in that sense, TeX will remain streets ahead of SILE for some time to come. 
But in terms of *capabilities*, SILE is already certainly equivalent to, if not somewhat more advanced than, TeX.

## SILE versus InDesign

The other tool that people reach for when designing printed material on a computer is InDesign.

InDesign is a complex, expensive, commercial publishing tool. 
It’s highly graphical–you click and drag to move areas of text and images around the screen. 
SILE is a free, open source typesetting tool which is entirely text-based; you enter commands in a separate editing tool, save those commands into a file, and hand it to SILE for typesetting. 
And yet the two systems do have a number of common features.

In InDesign, text is flowed into *frames* on the page. 
SILE also uses the concept of frames to determine where text should appear on the page, and so it’s possible to use SILE to generate page layouts which are more flexible and more complex than that afforded by TeX.

Another thing which people use InDesign for is to turn structured data in XML format–catalogues, directories and the like–into print. 
The way you do this in InDesign is to declare what styling should apply to each XML element, and as the data is read in, InDesign formats the content according to the rules that you have declared.\supereject

You can do exactly the same thing in SILE, except you have a lot more control over how the XML elements get styled, because you can run any SILE command you like for a given element, including calling out to Lua code to style a piece of XML. 
Since SILE is a command-line filter, armed with appropriate styling instructions you can go from an XML file to a PDF in one shot. 
Which is quite nice.

In the final chapters of this book, we’ll look at some extended examples of creating a *class file* for styling a complex XML document into a PDF with SILE.

## Conclusion

SILE takes some textual instructions and turns them into PDF output. 
It has features inspired by TeX and InDesign, but seeks to be more flexible, extensible and programmable than them. 
It’s useful both for typesetting documents such as this one written in the SILE language, and as a processing system for styling and outputting structured data.
