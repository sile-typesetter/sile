---
post_author: Simon Cozens
post_gravatar: 11cdaff4c6f9b290db40f69d3b20caf1
---
Right now SILE is in a state of flux. There doesn't appear to be much going on in the SILE repository but actually there is a lot of coding happening behind the scenes.

The Pango/Cairo backend got SILE started and producing useful output, but it was never intended to be a permanent solution. The Cairo PDF writer only supports creation of simple PDFs, and does not include features such as document structure, thumbnails, hyperlinks, annotations and so on.

Although I was hoping to replace it eventually, my hand has been forced by some bug reports on Linux where Pango was not positioning the glyphs with sufficient accuracy, leading to badly letter-spaced text. So, SILE is moving to [Harfbuzz][] for text shaping and a different PDF library.

The first part is done, and there is a Harfbuzz shaper written. The second part is proving more troublesome. There are several PDF libraries out there but none of them really provide what SILE needs. The nearest is [PoDoFo][], and I have SILE working with Harfbuzz and PoDoFo, but it requires a number of patches applied to the latest development source of the PoDoFo library. This obviously isn't a great way for people to install and deploy SILE.

So, since we're going to have to ship our own PDF library with SILE anyway, my latest thought is, why don't we actually ship a good one? And it turns out the best one available is the one which turns TeX's DVIs (and XeTeX's XDVs) into PDFs. Unfortunately, it's currently quite tightly bound to xdvipdfm, and is not actually a library yet. Right now, I'm turning it into a separate library so it can ship with SILE, and SILE will eventually be driven by Harfbuzz/[libtexpdf][].

[Harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
[PoDoFo]: http://podofo.sourceforge.net
[libtexpdf]: https://github.com/simoncozens/dvipdfm-x/tree/libtexpdf
