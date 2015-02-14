Here are a few interesting things that have been going on lately. If you are interested in SILE, you should probably try using SILE from the [repository][] head.

* Support has been added for [OpenType features][]! SILE now supports all your historic ligatures, swash characters, stylistic sets, kerning, fractions, diacritics, CJK shaping and character width, and any other clever things that your font can do.

* A subtle but pernicious [bug][] in the line-breaking engine has been fixed! This only manifested itself when centering paragraphs. Previously, centered paragraphs would fill from the final line upwards, leaving a few orphaned words on the first line. Now, it correctly fills from the first line down.

* Support has been added for compiling with older versions of autotools, libpng and so on; if you couldn't get SILE to compile before, you should now.

* SILE originally supported Lua version 5.1, but after adding compatibility for 5.2, main development broke 5.1. 5.1 compatibility has been restored, so SILE now works on both versions.

* Simon gave a [talk][] to the FOSDEM conference explaining SILE's development and design philosophy. We'll post the video as soon as it's available.

[repository]: https://github.com/simoncozens/sile/commits/master
[talk]: https://fosdem.org/2015/schedule/event/introducing_sile/
[bug]: https://github.com/simoncozens/sile/commit/b966a0634d295fe3bc4484744ab4deb8594f701a
[OpenType features]: https://github.com/simoncozens/sile/blob/master/examples/ligature.sil
