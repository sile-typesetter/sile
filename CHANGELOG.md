# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [0.13.3](https://github.com/sile-typesetter/sile/compare/v0.13.2...v0.13.3) (2022-07-15)


### Features

* **packages:** Add minimal support for usual BibTeX types (bibtex) ([292a2f2](https://github.com/sile-typesetter/sile/commit/292a2f2b2367a93a97add70fa42191b5b5bb800c))


### Bug Fixes

* **build:** Update Flake to work with Nix >= 2.10 ([3d5a18c](https://github.com/sile-typesetter/sile/commit/3d5a18cf8b202060e6c884fa3d73150f0aec9e58))
* **core:** Avoid duplicate paths blocking directory searches ([7a7209f](https://github.com/sile-typesetter/sile/commit/7a7209fff9fb0b2ca8a59816dae55e201b0c1208))
* **core:** Avoid error when outputting overflow warnings with specific measurements ([cb51ed5](https://github.com/sile-typesetter/sile/commit/cb51ed525684fab85c99e29474e0ba58806ba1ac)), closes [#945](https://github.com/sile-typesetter/sile/issues/945)
* **outputter:** Non-RGB colors shall work with the debug outputter ([#1469](https://github.com/sile-typesetter/sile/issues/1469)) ([41fbdf4](https://github.com/sile-typesetter/sile/commit/41fbdf44659385171f813576373be36556023a73))
* **packages:** BibTeX types/tags are case-insensitive, etc ([61c1fc6](https://github.com/sile-typesetter/sile/commit/61c1fc6209bfbfffa38a05f9d3986bfb50c8a840))
* **packages:** Make \script command properly initialize packages ([9ded7e1](https://github.com/sile-typesetter/sile/commit/9ded7e1c2aaa03cb4da25ff2ef49c15d40497f9a))

### [0.13.2](https://github.com/sile-typesetter/sile/compare/v0.13.1...v0.13.2) (2022-06-29)


### Features

* **core:** Add presets for some ANSI paper sizes and ArchE variants ([0f26756](https://github.com/sile-typesetter/sile/commit/0f267563c6f674d61c91485f771e825e83489590))
* **languages:** Add full Esperanto language support ([b740709](https://github.com/sile-typesetter/sile/commit/b7407090ab4feac9107454db0f328c3d886a0631))
* **packages:** Add 'lists' package (bullets and enumerations) ([6af3c62](https://github.com/sile-typesetter/sile/commit/6af3c62822ac334c64e2c46d8def11c51a017093))
* **packages:** Add more options for custom 'lists"' styling ([3167410](https://github.com/sile-typesetter/sile/commit/316741033da7edff44cb933a311f3b5080b763c7))
* **packages:** Handle font fallback when glyph named null returned on shape falure ([09c0a86](https://github.com/sile-typesetter/sile/commit/09c0a8647105bbddac155f3414cda2bc481a86ca))
* **packages:** Pass through font-specific options to fallback fonts ([fb29442](https://github.com/sile-typesetter/sile/commit/fb2944233ea13e10729ada47aa8b72db44ea8a30))


### Bug Fixes

* **classes:** Clarify the scopes of `tate` and `jplain` ([db83e9e](https://github.com/sile-typesetter/sile/commit/db83e9ede06dedf89112a7d9d76e185df90f6dba))
* **classes:** Fix circular reference in pecha class ([4501ec0](https://github.com/sile-typesetter/sile/commit/4501ec07cb0ec5183485fb39b965d8267cf176e0))
* **classes:** Fix diglot and triglot class instantiation ([71af1a9](https://github.com/sile-typesetter/sile/commit/71af1a94b41e3d86715a369092d1ea6ffeeb6a5b))
* **core:** Make paper size parser case insensitive, e.g. 'a4' or 'A4' ([af441c8](https://github.com/sile-typesetter/sile/commit/af441c8b381cae3ea18169105e951d60fcb5255f))
* **measurements:** Move the zenkaku width (zw) unit into core ([cfe5060](https://github.com/sile-typesetter/sile/commit/cfe506001387a81f37dd9612444b066e138ba179))
* **packages:** Correct fall-back font processing ([d3cc59b](https://github.com/sile-typesetter/sile/commit/d3cc59b9f32eefd06780f4984d066007283434dc))
* **packages:** Correct package load path for colored dropcaps ([41a0c17](https://github.com/sile-typesetter/sile/commit/41a0c17bee08f1e127b3d1cd4f3ee9cc4283aeac))
* **packages:** Fix coding errors in untested corners of bibtex package ([804b1a5](https://github.com/sile-typesetter/sile/commit/804b1a548615054cf810850d1c5cd01ad20c47fb))
* **packages:** Fix loading TOC twice resetting pdf links ([97797b8](https://github.com/sile-typesetter/sile/commit/97797b89b7cc195f1011495ec87ad1b94121464e))
* **shaper:** Handle switching between color & fallback shapers in single document ([04f2d5d](https://github.com/sile-typesetter/sile/commit/04f2d5df94373cc75e02b51f5847d7247a2025e7))
* **utilities:** Raise Lua error instead of manually aborting if inside pcall() ([6e70a17](https://github.com/sile-typesetter/sile/commit/6e70a17562f298234e85862df30d12dfdc963f48))

### [0.13.1](https://github.com/sile-typesetter/sile/compare/v0.13.0...v0.13.1) (2022-06-18)


### Features

* **build:** Update libtexpdf to support new hardware platforms ([da1182e](https://github.com/sile-typesetter/sile/commit/da1182ec3601d9a4ea5b2529c6d0de4108bbf211))
* **packages:** Add hrulefill command to the "rules" package ([ccd3371](https://github.com/sile-typesetter/sile/commit/ccd3371aafa4f314c9d2a967106e03c373cf1a35))
* **packages:** Add strikethrough command to the rules package ([#1422](https://github.com/sile-typesetter/sile/issues/1422)) ([f230a3a](https://github.com/sile-typesetter/sile/commit/f230a3aae72cf84075623165ce6ded0c9aa2bdd0))
* **packages:** Use new strikethrough when rendering Panndoc's SILE writer ([20d19eb](https://github.com/sile-typesetter/sile/commit/20d19eb849307a1067006a595b2e4f2b92e53112))


### Bug Fixes

* **build:** Make sure i18n/ dir is actually distributed ([#1445](https://github.com/sile-typesetter/sile/issues/1445)) ([61ed8e1](https://github.com/sile-typesetter/sile/commit/61ed8e13eee3c2f5f802605a9da5f25ad0040164))
* **packages:** Add more props to keep CJK from tipping over, per [#1245](https://github.com/sile-typesetter/sile/issues/1245) ([381b9f1](https://github.com/sile-typesetter/sile/commit/381b9f14d10e1bbcf0b117642c4c13e3dcd4c620))
* **packages:** Leaders shall be an explicit (non-discardable) glue ([631ba21](https://github.com/sile-typesetter/sile/commit/631ba21c182389dd5a68241a36d1eb4fb13c895b))
* **packages:** The fullrule now extends over a full standalone line ([8fe57c8](https://github.com/sile-typesetter/sile/commit/8fe57c844f2a093d7abe35dfe6c63d5df5ab7115))

## [0.13.0](https://github.com/sile-typesetter/sile/compare/v0.12.5...v0.13.0) (2022-06-09)


### ⚠ BREAKING CHANGES

* **settings:** All the functions under `SILE.settings.*()` should now be
  called using the instance notation `SILE.settings:*()`. Usage should be
  shimmed with a warning for now.

  Changing this in your code is relatively easy with a search and replace.
  As an example with a project in Git, you could use perl like this:

  ```console
  funcs="pushState|popState|declare|reset|toplevelState|get|set|temporarily|wrap"
  git ls-files | xargs -n1 perl -i -pne "s#(SILE\.settings)\.($funcs)#\1:\2#g"
  ```

* **typesetter:** Making a new instance of the typesetter should now be
  done by *calling* `SILE.defaultTypesetter()` instead of copying the
  object. It has been changed from a std.object to a Penlight class. As
  such the correct initialization function is also now `_init()` instead
  of `init()`. A shim is in place to catch legacy usage, but this will be
  removed in the future.

* **deps:** All calls to the Lua default string library have been
  using a version monkey-patched by stdlib. This has created all sorts of
  issues including not being able to properly use some of Lua's default
  features and conflicts with out explicit meta methods. Also we're busy
  dropping dependency stdlib altogether.

  If you were relying on it for any of your string operations, replace
  `string.func()` with `std.string.func()`. For now `std` is being
  provided by SILE, but if you use it in your projects please add it as
  a direct dependency yourself since that will eventually be removed as
  well.

  By the way in case anything ever `git bisect`s back to here, one way to
  test if your problem is related to this change or not (especially if you
  have downstream code that might have built on the assumption SILE's Lua
  strings were monkey patched) is to load it manually yourself:

  ```console
  $ sile -e 'require("std.string").monkey_patch()' your_file.sil
  ```
* **classes:** This changes the way classes are represented as Lua
  objects and the mechanism used for inheritance. While shims will be in
  place to catch most cases that use old syntax it is not possible to
  grantee 100% API compatibility. If you have classes that do anything
  remotely fancy (i.e. not just copy/paste from SILE examples) they may or
  may not work at all; and even if they do they should be updated to
  explicitly use the new API.

### Features

* **classes:** Add hook system for more versatile packages ([9287721](https://github.com/sile-typesetter/sile/commit/9287721217970a6262a25f5fe697ac211d1ebaca))
* **languages:** Add \ftl command to make adding fluent localizations easy ([b331456](https://github.com/sile-typesetter/sile/commit/b3314564afa5d4e38dc5f28277b13aa9dbe8668b))
* **languages:** Add fluent() command to output translations ([ad87995](https://github.com/sile-typesetter/sile/commit/ad87995ebbbce464b3a7075961db29e681607823))
* **languages:** Validate languages against CLDR database ([f96a331](https://github.com/sile-typesetter/sile/commit/f96a33133ecefa641e06139f90bc6b1931be5656))


### Bug Fixes

* **backends:** Add Pango shaper when selecting Cairo backend ([bbc2817](https://github.com/sile-typesetter/sile/commit/bbc2817c01e20ba04c5fe7d4c40de4c9b5155ffc))
* **backends:** Always output pdf on finish() even if no content ([3af7a94](https://github.com/sile-typesetter/sile/commit/3af7a94d39b11555cf2159f5f4a9c416259f7fa3))
* **backends:** Correct image sizing in Cairo and Podofo backends ([f2785ad](https://github.com/sile-typesetter/sile/commit/f2785ade39842caf40519239ee58e3db3e17cc9d))
* **core:** Avoid throwing deprecation errors when just inspecting SILE's internals ([b303059](https://github.com/sile-typesetter/sile/commit/b303059fe85d323d8a459e8025340464f4bdd0dd))
* **core:** Justify lines with ligatures (workaround) ([cf2cb3a](https://github.com/sile-typesetter/sile/commit/cf2cb3a34e72132705bda3e9fbe4bb97ac37e1f8))
* **core:** Patch Penlight 1.9.0 compatibility issue ([092fbd3](https://github.com/sile-typesetter/sile/commit/092fbd38c60677a92029a8504d5baa8c9e25c37b))
* **languages:** Correct bogus usage of resource loading / error catching ([fb1fd7f](https://github.com/sile-typesetter/sile/commit/fb1fd7f1cb39ee7d36b6d5253da94f906afba8f2))
* **packages:** An hrule with depth shall not affect current baseline ([c759892](https://github.com/sile-typesetter/sile/commit/c759892d09b9ffa1c3c2d25d69d0324b34884b13))
* **packages:** Don't destroy frames when defining masters, only when switching to one ([b7de7ca](https://github.com/sile-typesetter/sile/commit/b7de7caadf5b07f819f3e483f0f1712d06d9facc))
* **packages:** Fix autodoc parsing, typeset string not series of bytes ([14f6126](https://github.com/sile-typesetter/sile/commit/14f61266b6b19835d1019d94015d2e0bfa2612b1))


### Miscellaneous Chores

* **deps:** Drop std.string.monkey_patch() ([e8b2bdf](https://github.com/sile-typesetter/sile/commit/e8b2bdf96b50646698c75961fddff2da26ce57ec))


### Code Refactoring

* **classes:** Convert class inheritance from stdlib to Penlight ([f7dafe0](https://github.com/sile-typesetter/sile/commit/f7dafe0623a981e9532fbb0108876517786bd1d8))
* **settings:** Change settings object to be self referential ([dd97d05](https://github.com/sile-typesetter/sile/commit/dd97d05cf02e89213492d1308544177a482de7ea))
* **typesetter:** Change typesetter instancing to Penlight model ([a9400ad](https://github.com/sile-typesetter/sile/commit/a9400ad0e759b6b8787b4307c10984ce91e354dc))

### [0.12.5](https://github.com/sile-typesetter/sile/compare/v0.12.4...v0.12.5) (2022-04-18)


### Features

* **packages:** Align leaders vertically ([#875](https://github.com/sile-typesetter/sile/issues/875)) ([8b5d418](https://github.com/sile-typesetter/sile/commit/8b5d4189222f4221592dbb93cb7a65c4838262a6))


### Bug Fixes

* **build:** Catch and complete unfinished library builds ([91ff438](https://github.com/sile-typesetter/sile/commit/91ff43859cfa645f6ea43d2485e5df69e793b306))
* **build:** Use BSD compatible scripting in `make selfcheck` ([319e0c5](https://github.com/sile-typesetter/sile/commit/319e0c5752415cd3c7fea4541e9a5ab8cfcb1358))
* **build:** Use POSIX compatible shell syntax in configure ([55e64ab](https://github.com/sile-typesetter/sile/commit/55e64ab984fa3ec02de36b0ebe478462f490993d))
* **deps:** Correct include to work with current LuaRocks packages ([#1357](https://github.com/sile-typesetter/sile/issues/1357)) ([b584be5](https://github.com/sile-typesetter/sile/commit/b584be5253b1d97d6fc742e7b0b19a3ffd71c384))
* **languages:** French punctuation spacing must honor current font options ([724daf4](https://github.com/sile-typesetter/sile/commit/724daf43b5a2d5a8e501c14f858592fa4763454f))
* **packages:** Better TOC title extraction for PDF bookmark ([#1029](https://github.com/sile-typesetter/sile/issues/1029)) ([5a65701](https://github.com/sile-typesetter/sile/commit/5a657012a4d8fae78a4fa07b3059d319b2b396fa))
* **packages:** The dotfill must stretch as an hfill ([#1343](https://github.com/sile-typesetter/sile/issues/1343)) ([c94a4b5](https://github.com/sile-typesetter/sile/commit/c94a4b5adfe44f89c36d59370e69b67fe2630e21))

### [0.12.4](https://github.com/sile-typesetter/sile/compare/v0.12.3...v0.12.4) (2022-03-03)


### Bug Fixes

* **docker:** Fix GHCR → Docker Hub copy used when releasing ([e5d83d0](https://github.com/sile-typesetter/sile/commit/e5d83d01a68e83ad951e31033a865a922c01859b))
* **packages:** Avoid infinite loop when re-enabling BiDi ([b4d691b](https://github.com/sile-typesetter/sile/commit/b4d691b29ff4b28f80a93f6c0731164725f84055))

### [0.12.3](https://github.com/sile-typesetter/sile/compare/v0.12.2...v0.12.3) (2022-03-02)


### Bug Fixes

* **frames:** Inherit class direction setting in new frames ([35c8a25](https://github.com/sile-typesetter/sile/commit/35c8a255c2a19d4f25dc5f60e40d76a52d2ac601))
* **packages:** Make boxaround respect shrink/strech (rules package) ([9d8f708](https://github.com/sile-typesetter/sile/commit/9d8f7086e1f469a24b032307b43dc801fe10fd92))
* **packages:** Make underline respect shrink/strech (rules package) ([a5d99f0](https://github.com/sile-typesetter/sile/commit/a5d99f0619bb58309313ece1ba320a5e465681a2))
* **typesetter:** Enable bidi for default typesetter on package load ([6a8d7f4](https://github.com/sile-typesetter/sile/commit/6a8d7f400faca53d825f1fea000d51f5e967addb))

### [0.12.2](https://github.com/sile-typesetter/sile/compare/v0.12.1...v0.12.2) (2022-01-28)


### Bug Fixes

* **shaper:** Fix line length calcs with negative width word spacing ([685d12d](https://github.com/sile-typesetter/sile/commit/685d12dc71797d69c7f24a6c6ced0d47dc404704)), closes [#579](https://github.com/sile-typesetter/sile/issues/579)

### [0.12.1](https://github.com/sile-typesetter/sile/compare/v0.12.0...v0.12.1) (2022-01-12)


### Features

* **build:** Accommodate SOURCE_DATE_EPOCH for reproducible builds ([16c81a8](https://github.com/sile-typesetter/sile/commit/16c81a8dfb191238d65610380d648437a6492f2e))
* **classes:** Add \noop function for versatile SILE.call() use ([2b04507](https://github.com/sile-typesetter/sile/commit/2b045078120c52ccc948cc663936504153285132))
* **core:** Add OpenType post (v1) table parser ([a985aed](https://github.com/sile-typesetter/sile/commit/a985aedbd5553987f63be04f9b74d1a6b2299952))
* **core:** Implement Knuth's hangAfter and hangIndent ([5417189](https://github.com/sile-typesetter/sile/commit/54171894f3f1415f33891192631f54af47db9c28))
* **core:** Implement paragraph duration hanging indent settings ([18ee23b](https://github.com/sile-typesetter/sile/commit/18ee23bc1271ba1be7aee98c8346b3f9c225d9dc))
* **core:** Implement paragraph shaping (parshape) ([c2c0235](https://github.com/sile-typesetter/sile/commit/c2c0235717202c811673379dd6b54118468b327e))
* **packages:** Add dropcaps package ([cb9105a](https://github.com/sile-typesetter/sile/commit/cb9105a676e8e0efad29bb62d135fd0d02ef6d1d))
* **packages:** Add shift, raise, and size options to dropcaps ([0a88948](https://github.com/sile-typesetter/sile/commit/0a88948e5028e4f3b82ad7ee689d5f53e0358ddd))
* **packages:** Implement color option for dropcaps ([d042bcf](https://github.com/sile-typesetter/sile/commit/d042bcf31dcd52d1a51dad527f727834ca8e22d9))
* **packages:** Use font's post table to determine underline position ([ae1b929](https://github.com/sile-typesetter/sile/commit/ae1b929cfe3bd1784bd2962a5ccb8b53b47377d7))


### Bug Fixes

* **backends:** Move Lua 5.1 macro so covers whole file ([9b40772](https://github.com/sile-typesetter/sile/commit/9b40772920602bd1a9543d38bf9cf5e51d1f4b24))
* **classes:** Reset state when calling running headers ([ec0a7b8](https://github.com/sile-typesetter/sile/commit/ec0a7b8d0494f83cbfd546bee3896af2a944c6a0))
* **classes:** Unnumbered book sections shall not display a number in running headers ([4afde42](https://github.com/sile-typesetter/sile/commit/4afde429179b5bcff2f5f713ed0bb4cc103475a5))
* Fixes name of accented math symbol, eliminates duplicate newStandardHspace assignment ([4c38f1a](https://github.com/sile-typesetter/sile/commit/4c38f1a50ee3ce4a661bbd04b3382d57362e952f)), closes [#1274](https://github.com/sile-typesetter/sile/issues/1274)
* **languages:** Correct hyphenation after apostrophe in French and Catalan ([4c93891](https://github.com/sile-typesetter/sile/commit/4c93891f3bbc2b95e5dca99eee46ab72d2248b9e))
* **languages:** Correct synchronisation between indexes in French word breaking ([94ca931](https://github.com/sile-typesetter/sile/commit/94ca931e968b682c81a30dce7deace629b97afa2))
* **languages:** Repair broken French hyphenation patterns ([c25d9d7](https://github.com/sile-typesetter/sile/commit/c25d9d7d7ff1ed2d1a291de1396795f4c9a72700))
* **packages:** Add \pdf:metadata support for dates ([1b87305](https://github.com/sile-typesetter/sile/commit/1b87305b7503c1c7deb88793b428d5278b42f14c))
* **packages:** Apply OpenType x and y offsets to color fonts ([d66dc5f](https://github.com/sile-typesetter/sile/commit/d66dc5fadaaa4992f6d33101023541c6b0ab93f2)), closes [#1147](https://github.com/sile-typesetter/sile/issues/1147)
* **packages:** Correct rebox to not output duplicate content ([2802d9b](https://github.com/sile-typesetter/sile/commit/2802d9b14318a514da5fa56bfb60f67b698db51b))
* **packages:** Don't over-isolate functions run in Pandoc imports ([#1254](https://github.com/sile-typesetter/sile/issues/1254)) ([84507a5](https://github.com/sile-typesetter/sile/commit/84507a546ac63f7f40e65abbfe6831ff4c19f046))
* **utilities:** Fix UTF-16 encode/decode utility functions ([7180081](https://github.com/sile-typesetter/sile/commit/71800815daf6275a35aa6578de56a84f043e5317)), closes [#1280](https://github.com/sile-typesetter/sile/issues/1280)
* **utilities:** Set language of roman numerals to Latin to avoid casing issues ([#1253](https://github.com/sile-typesetter/sile/issues/1253)) ([95c4e2c](https://github.com/sile-typesetter/sile/commit/95c4e2c0e1b1291849edf7ac8e456a954097286c))

## [0.12.0](https://github.com/sile-typesetter/sile/compare/v0.11.1...v0.12.0) (2021-09-22)


### ⚠ BREAKING CHANGES

* **packages:** Previous to this release footnote and folio frames took
  their font settings from a new typesetter with default settings. With
  this release the settings are now derived from the typesetter in the
  default frame, hence inheriting font family, size, leading, and other
  settings. Values can still be set using the same functions, but relative
  values such as font sizes are based on a different base.

### Features

* **core:** Add MATH variants table parser ([b6c554e](https://github.com/sile-typesetter/sile/commit/b6c554e0d309302c69402263217a59e0e129ca09))
* **core:** Add OpenType MATH table parser ([835da21](https://github.com/sile-typesetter/sile/commit/835da217b2aeaf53d7a172d18a887d77cc13f666))
* **math:** Add ‘debug’ option to math command ([58cc9dc](https://github.com/sile-typesetter/sile/commit/58cc9dc8a96dde36bc77e385faa72014b348408f))
* **math:** Add “big operator” support ([5b9a150](https://github.com/sile-typesetter/sile/commit/5b9a1509f9ca0fa55068fcd1da64714c7ce84dfa))
* **math:** Add fixes to support less complete fonts ([1c22af3](https://github.com/sile-typesetter/sile/commit/1c22af373bf08badfd9b09b01974f255ee738054))
* **math:** Add italic correction to superscript; correct subscript size ([d81fdee](https://github.com/sile-typesetter/sile/commit/d81fdee7321107507e92def15a60b289abc6e1be))
* **math:** Add math.font.filename setting ([522d70b](https://github.com/sile-typesetter/sile/commit/522d70bb518e978da3ba60f0ff5689063f589638))
* **math:** Add math.font.size setting ([5077d1c](https://github.com/sile-typesetter/sile/commit/5077d1c06405dc25316600a680d922d4ab87b204))
* **math:** Add operator defaults ([14bdf1a](https://github.com/sile-typesetter/sile/commit/14bdf1a0dd1e6c3db1c281a1e0c4b2f540d2b91a))
* **math:** Add parameter to draw debug boxes around math components ([2458d18](https://github.com/sile-typesetter/sile/commit/2458d188af912171101f9af456f2ab19b7184a20))
* **math:** Add parameters and support mathvariant param for mi tag ([869dca8](https://github.com/sile-typesetter/sile/commit/869dca86f0c0979145260d1d9a8a22d9dab6e47d))
* **math:** Add plain text support ([3a09e9d](https://github.com/sile-typesetter/sile/commit/3a09e9d1d9c05dfec3f9433541ed5b8512dda373))
* **math:** Add subscript and superscript; add math constants ([0489c04](https://github.com/sile-typesetter/sile/commit/0489c04d944df52a1396cd5c902344ef8c53db2d))
* **math:** Add support for “symbol macros”, expanding to strings ([27658f5](https://github.com/sile-typesetter/sile/commit/27658f517c59567842839776589e76b7cc062b74))
* **math:** Add support for fractions ([6f4fc24](https://github.com/sile-typesetter/sile/commit/6f4fc24d69c38beb9c623aeb12e3362d4489c884))
* **math:** Add tags for some mathematical symbols ([b9fd771](https://github.com/sile-typesetter/sile/commit/b9fd771007418566939d716a9a413d959c9bda2f))
* **math:** Add tex-like math parser ([edceaf7](https://github.com/sile-typesetter/sile/commit/edceaf7dfb5c644daec27915f2106195a7a08c5a))
* **math:** Allow vertical stacking of top-level ‘mrow’s ([56b553c](https://github.com/sile-typesetter/sile/commit/56b553c1821104eda2fdd2e34ac1b2f06882ee81))
* **math:** Center display math neatly ([8951378](https://github.com/sile-typesetter/sile/commit/8951378c1b9ad076699256d116314fae98705c7f))
* **math:** Implement and use munder and mover ([61eac7a](https://github.com/sile-typesetter/sile/commit/61eac7a95c8a05e255e61285fcc7776ac4123d35))
* **math:** Implement generic bbox shaper ([9c86aff](https://github.com/sile-typesetter/sile/commit/9c86aff63ab072fe0a54fe06d8fbb3e27250a8cb))
* **math:** Output error if rending with non-math font ([c79617b](https://github.com/sile-typesetter/sile/commit/c79617bad7f4aba8c8ecd6b3dc50b5676b6cbf47))
* **math:** Replace leading `-` with `−` in numbers ([f8d490c](https://github.com/sile-typesetter/sile/commit/f8d490ccb298f730176d300100ebc0fec6c6128e))
* **math:** Support double-struck identifiers ([29674bf](https://github.com/sile-typesetter/sile/commit/29674bf069d46a0e6694ac6e7ef11b4c4864f43d))
* **math:** Support for simple macros ([5b4ecf7](https://github.com/sile-typesetter/sile/commit/5b4ecf72ca5718d73c24c97c8aa0806e5a12d519))
* **math:** Support italic ([c9b2884](https://github.com/sile-typesetter/sile/commit/c9b2884ad98cc4102f04ae6e158e0b4821a61ef8))
* **math:** Support more integral-like operators ([90a6c44](https://github.com/sile-typesetter/sile/commit/90a6c44e931e24f3696e8adec905a318f9134062))
* **math:** Support of UTF-8 in texmath, support of mo, mi and mn in-grammar ([959d1cc](https://github.com/sile-typesetter/sile/commit/959d1cce7b3d01f2e4d8182726b5c20f97194f4b))
* **math:** Turn "-" (hyphen) into "−" (minus) in math ([fbed523](https://github.com/sile-typesetter/sile/commit/fbed523f4792af569c2548c25d0d941f0b464b60))
* **packages:** Add border style and color to hyperlinks ([bb880be](https://github.com/sile-typesetter/sile/commit/bb880bed7b8564591d2600a98786d05a24086d2b))
* **packages:** Add function to remove last added fallback font ([acf987b](https://github.com/sile-typesetter/sile/commit/acf987b23b8ebf8446d9e65fa42fcb1c1fa34528))
* **packages:** Add linking support to toc entries ([e589cb9](https://github.com/sile-typesetter/sile/commit/e589cb96ba24ef06c0bda1297729f8925f8d1550))
* **packages:** Add toc depth option and hooks for showing section numbers ([c48fcde](https://github.com/sile-typesetter/sile/commit/c48fcdeebe4bf0a1b75f5f722fad1268e797831d))
* **packages:** Allow URLs to have many breakpoints ([#1233](https://github.com/sile-typesetter/sile/issues/1233)) ([b145605](https://github.com/sile-typesetter/sile/commit/b145605f5326e54fbf3cbf88bc2d334c403ba685))
* **packages:** Warn if toc contents have changed ([5b6eed8](https://github.com/sile-typesetter/sile/commit/5b6eed8c39670a58a4c3d9e1fcb07504ade96df1))
* **tooling:** Enable use as a Nix flake ([8b503bb](https://github.com/sile-typesetter/sile/commit/8b503bb74bb51b388d0140cac5848902858b8e58))


### Bug Fixes

* **classes:** Don't increment counters on unnumbered book sections ([6cfca4d](https://github.com/sile-typesetter/sile/commit/6cfca4d86885a5df4ca6f0d46153d5b3e925f4ee))
* **core:** Correct --help output to reflect required values ([da487ec](https://github.com/sile-typesetter/sile/commit/da487ec0c1295d3a54ff50f22dd63fd28e2b80b1))
* **languages:** Add test 704 for French punctuations, fix expected 621 and 702 results ([8e9b056](https://github.com/sile-typesetter/sile/commit/8e9b056664214f59326b2b7d1cc5c9af1d74522e))
* **languages:** Correct Armenian support to use ISO 639 code ‘hy’ ([ffafbe6](https://github.com/sile-typesetter/sile/commit/ffafbe617743ad43a781edce08836d0d88f5da2b))
* **languages:** Correct punctuation rules for French ([95c2398](https://github.com/sile-typesetter/sile/commit/95c23982f407299cd57e7b41c162a10f0e992f77))
* **languages:** Don't initialize Japanese unless actually called for ([3aba931](https://github.com/sile-typesetter/sile/commit/3aba931ecf773a4dc7d881912f21bd952b9760a1))
* **languages:** Shortcut ICU soft breaks in French ([ed8734c](https://github.com/sile-typesetter/sile/commit/ed8734cb19020554f951ebb970c999a9592f41b7))
* **math:** Fix underover error with sub wider than base but no sup ([bc87393](https://github.com/sile-typesetter/sile/commit/bc87393b952eef2429aef27e45508636c1dc1551))
* **packages:** Don't replace shaper unless actually initializing color-fonts package ([269ca59](https://github.com/sile-typesetter/sile/commit/269ca5923c5588303dc8fcf2d33e32cdd072419c))
* **packages:** Fix deprecation warning command in package docs ([a69d774](https://github.com/sile-typesetter/sile/commit/a69d7747bb5e6643add953c458739aafcfee105b))
* **packages:** Reset footnote and folio settings top level state ([3795a4e](https://github.com/sile-typesetter/sile/commit/3795a4e83823642a69e481cecd15a4966053fd71))
* **shaper:** Fix memory leak in Harfbuzz library ([#1243](https://github.com/sile-typesetter/sile/issues/1243)) ([035dcc8](https://github.com/sile-typesetter/sile/commit/035dcc8d46bba8bb2ec3a2df634c6c747d4a2526))

### [0.11.1](https://github.com/sile-typesetter/sile/compare/v0.11.0...v0.11.1) (2021-09-03)


### Bug Fixes

* **build:** Avoid implied line continuation in makefile ([f2af48f](https://github.com/sile-typesetter/sile/commit/f2af48f2157f5727369f1ad4e049c84ae10af5ea))
* **build:** Require Git even building tarballs, used by package manager ([aba8662](https://github.com/sile-typesetter/sile/commit/aba86623034ff2a6eee2b8883865e1985f8152e3))
* **languages:** Update deprecated syntax in language options ([3fb1719](https://github.com/sile-typesetter/sile/commit/3fb1719ddab00f4aded435213393b09b98e83342))

## [0.11.0](https://github.com/sile-typesetter/sile/compare/v0.10.15...v0.11.0) (2021-09-01)


### ⚠ BREAKING CHANGES

* **packages:** Previous to this release any and all leading between
  paragraphs (as set with document.parskip) –even a 0 height skip– would
  result in the skip of one full empty grid space — as if parskip had been
  set to something approximating a full line height.  This change corrects
  the calculation so if a 0 height skip is added and everything fits, the
  next line or paragraph will continue uninterrupted in the next grid
  slot.  To get the previous layout behavior back, document.parskip must
  be explicitly set to be something larger than 0.  Even a minimal 1pt
  skip will result in paragraph spacing that includes one full grid height
  left blank as before:

  ```sile
  \set[parameter=document.parskip,value=1lh]
  ```

* **utilities:** Previous return value for breadcrumbs:contains() was
  just an depth index with -1 indicating no match. This made sense when
  I wrote it, but coming back to it for a new project I expected a boolean
  return value. Returning two values seems like the best option, but given
  the function naming it seemed to make sense to return the boolean first,
  hence the API breakage.

### Features

* **actions:** Use tagged images for faster CI job spin up ([6a00388](https://github.com/sile-typesetter/sile/commit/6a003888153d76a1951d396296109afd074e44be))
* **build:** Add configure flag --disable-dependency-checks ([5caf413](https://github.com/sile-typesetter/sile/commit/5caf41335e51c8656962b6800b9a9be0a94a897e))
* **docker:** Build, tag, and push images to GHCR ([3988339](https://github.com/sile-typesetter/sile/commit/398833939b240a595bb97e75aef04249a8e6dbe8))
* **measurements:** Add ‘hm’ (himetric) unit ([f4b6b62](https://github.com/sile-typesetter/sile/commit/f4b6b626bef5851da1ec010b742d5cd8949996eb))
* **measurements:** Add ‘twip’ unit ([cf9d5a7](https://github.com/sile-typesetter/sile/commit/cf9d5a79660f9ffb625e6ea4753f06d7f62bbd38))
* **packages:** Map unnumbered class to legacy opts in Pandoc package ([#1167](https://github.com/sile-typesetter/sile/issues/1167)) ([2868da2](https://github.com/sile-typesetter/sile/commit/2868da2d93475331a9cdef49abd68b538d3e0783))


### Bug Fixes

* **core:** Avoid crash on warn by using correct function ([b403ad9](https://github.com/sile-typesetter/sile/commit/b403ad93cbe820b78635de176c150ffe6153eff1))
* **packages:** Avoid crash on warn by using correct function ([5d05be1](https://github.com/sile-typesetter/sile/commit/5d05be1520b9818db706259afccd25dd5dec5002))
* **packages:** Avoid unnecessary skips to next grid space ([6424369](https://github.com/sile-typesetter/sile/commit/6424369ae8da4df34737ca413767008450bf5d2c))
* **packages:** Correctly handle color fonts on TTB pages ([9b35d6a](https://github.com/sile-typesetter/sile/commit/9b35d6ace8284d29439ed56617efb5e07e61145b)), closes [#1171](https://github.com/sile-typesetter/sile/issues/1171)


### Code Refactoring

* **utilities:** Change breadcrumbs:contains() to return <bool, index> ([a987394](https://github.com/sile-typesetter/sile/commit/a9873946883f215bfb97dddbc6b8fe06233c4b6f))

### [0.10.15](https://github.com/sile-typesetter/sile/compare/v0.10.14...v0.10.15) (2021-03-02)


### Features

* **fonts:** Allow for code to be run when a font is first loaded ([bdf05ab](https://github.com/sile-typesetter/sile/commit/bdf05ab8bfef72da4f251d471646d1387aedd905))
* **packages:** Add \font-feature command ([e2cf008](https://github.com/sile-typesetter/sile/commit/e2cf00842a71b090080a101613f5d6d4a70d4c37))
* **packages:** Add complex-spaces package ([#1148](https://github.com/sile-typesetter/sile/issues/1148)) ([b7451ae](https://github.com/sile-typesetter/sile/commit/b7451ae513b003b76531f24bebb35204488b6b0b))


### Bug Fixes

* **cli:** Re-enable access to repl, input argument not required ([a6434ee](https://github.com/sile-typesetter/sile/commit/a6434ee414fc870efd22f50f5da239f902cd5b94))
* **core:** Allow builtin Lua bitwise operators on Lua 5.4 ([5f0c2c7](https://github.com/sile-typesetter/sile/commit/5f0c2c7e929bc9c040b28019e3be648feddbd846))
* **docker:** Switch to BuildKit and make Docker Hub cooperate ([783b104](https://github.com/sile-typesetter/sile/commit/783b104df99a99ef3271322ba8086f995abab945))
* **docker:** Use patched glibc to work around outdated hosts ([fa2532c](https://github.com/sile-typesetter/sile/commit/fa2532c140383ea414867340f047c9e8cc05ec7f))
* **docker:** Use patched glibc to work around outdated hosts ([#1141](https://github.com/sile-typesetter/sile/issues/1141)) ([bf74417](https://github.com/sile-typesetter/sile/commit/bf74417aee5f9cc671f8a53b6802a5d242076875))
* **docker:** Work around libtexpdf build having side effects ([33510d9](https://github.com/sile-typesetter/sile/commit/33510d90b5b74396eac8c9e46f6bbbb952010415))
* **packages:** Add CharacterVariant to features ([929eca2](https://github.com/sile-typesetter/sile/commit/929eca2ea45cc3adeab8c3780d94980a7012541a))
* **utilities:** Correct UTF-8/UTF-16 conversions ([4863ed6](https://github.com/sile-typesetter/sile/commit/4863ed679f25fd7f1761879098ffb80e4e4e55ea))


### Reverts

* Revert "chore(build): Remove obsolete macOS workarounds" ([f5cf7c0](https://github.com/sile-typesetter/sile/commit/f5cf7c0dc29934ef6f55870c9f04ab0bc66e40b9))

### [0.10.14](https://github.com/sile-typesetter/sile/compare/v0.10.13...v0.10.14) (2021-02-03)


### Features

* **core:** Make luautf8 library available in global scope ([ab7e745](https://github.com/sile-typesetter/sile/commit/ab7e74574c8c624f2a54d6d9e07bf7e6b98e0c98))


### Bug Fixes

* **build:** Run autoupdate to fix autoconf issues ([ab8307b](https://github.com/sile-typesetter/sile/commit/ab8307b407a7e23f336628ece6c9adb50391bdb3))
* **core:** Decode UTF-16BE strings in Windows platform name entries ([e7662f8](https://github.com/sile-typesetter/sile/commit/e7662f84064ef4c96261373e66a8d2268bbcd0d3))
* **debug:** Use UTF8 safe substring function in trace stack ([495a5bf](https://github.com/sile-typesetter/sile/commit/495a5bf7c4dd8a5d2de18c71f873ce1852fe0d7f))
* **manual:** Small error ([d738b62](https://github.com/sile-typesetter/sile/commit/d738b62e95a54acf69459f805009ff90a45653a5))

### [0.10.13](https://github.com/sile-typesetter/sile/compare/v0.10.12...v0.10.13) (2020-11-30)


### Features

* **classes:** Allow footnotes in plain class if package loaded ([42c1ceb](https://github.com/sile-typesetter/sile/commit/42c1cebcac07d5bc52fcb027e3055012fefc7dd9))
* **classes:** Run deferred package init() on late load ([0224fe3](https://github.com/sile-typesetter/sile/commit/0224fe369b7abd788999e271b5dfacfb929270b2))


### Bug Fixes

* **backends:** Add complex shaping data to debug backend ([a1a6509](https://github.com/sile-typesetter/sile/commit/a1a65099dcb398ccf61a8ed53d15a9678ca8cb2b))
* **backends:** Don't crash if debug output precedes regular ([19c21f2](https://github.com/sile-typesetter/sile/commit/19c21f24c097bcdc5728b00f73bb710a8598c3c0))
* **build:** Don't abuse libtool internals (for NetBSD packaging) ([#1084](https://github.com/sile-typesetter/sile/issues/1084)) ([048c8b5](https://github.com/sile-typesetter/sile/commit/048c8b58b9c58de104f84e89c19c983d5a0f71df))
* **classes:** Define \strong weight=700, not 600 ([#1097](https://github.com/sile-typesetter/sile/issues/1097)) ([68abf91](https://github.com/sile-typesetter/sile/commit/68abf914608b0ba1dcc680499f52b9dc3d48566b))
* **packages:** Add default options to simpletable ([1f10c97](https://github.com/sile-typesetter/sile/commit/1f10c97f7ce3b71642bd9519109ac5ac56f5613e))
* **packages:** Correct math operations on grid spacing ([5286188](https://github.com/sile-typesetter/sile/commit/5286188dfa0e73e5fad3ac7aa79c791bb0dcd2fd))
* **packages:** Turn off complex flag for items in \latin-in-tate ([b20690f](https://github.com/sile-typesetter/sile/commit/b20690f5501ff1adf2459e13e942f3e570b177d7))

### [0.10.12](https://github.com/sile-typesetter/sile/compare/v0.10.11...v0.10.12) (2020-10-10)


### Bug Fixes

* **backends:** _drawString should take an offset ([#1079](https://github.com/sile-typesetter/sile/issues/1079)) ([594ae03](https://github.com/sile-typesetter/sile/commit/594ae03676680f6caa63a016ab72e3341774ba35)), closes [#1078](https://github.com/sile-typesetter/sile/issues/1078)
* **packages:** \verbatim:font can process text ([#1076](https://github.com/sile-typesetter/sile/issues/1076)) ([eb4fb1a](https://github.com/sile-typesetter/sile/commit/eb4fb1a37f060bb34dcb3c7f34e9d95b6e07613c))

### [0.10.11](https://github.com/sile-typesetter/sile/compare/v0.10.10...v0.10.11) (2020-09-25)


### Features

* **actions:** Add configuration file to run as GitHub Action ([ee2d509](https://github.com/sile-typesetter/sile/commit/ee2d50992f2209f7c871acf4983d4267f5c5cc87))
* **backends:** Modify setCursor() to handle relative movements ([7caa9c8](https://github.com/sile-typesetter/sile/commit/7caa9c82bbf0bd021e316893ffb2b2693ceeac55))
* **classes:** Make it possible to not use parent class framesets ([99b9f50](https://github.com/sile-typesetter/sile/commit/99b9f506954298dbc4ceabe4197609a7c5ac70f2))
* **cli:** Add Lua interpreter info to --version ([bf5210d](https://github.com/sile-typesetter/sile/commit/bf5210d17259591d95042109dedafc693b60d199))


### Bug Fixes

* **backends:** Properly switch between normal and debug fonts ([b53896e](https://github.com/sile-typesetter/sile/commit/b53896e1fea42f639074f0bba40504ba85eda19c))
* **classes:** Identify triglot class as triglot not diglot ([495654a](https://github.com/sile-typesetter/sile/commit/495654ac5d180af09ba9e71461ab78a6af43a1dc))
* **classes:** Make declareFrames() workable by passing ids ([27b6b4a](https://github.com/sile-typesetter/sile/commit/27b6b4abfe8f54d2b6360b51b2de1ca7d152608e))
* **classes:** Move class setup code into deferred class:init() ([6f470d7](https://github.com/sile-typesetter/sile/commit/6f470d70e2774c98971a78a581439361f98891e6))
* **core:** Patch Penlight 1.9.0 compatibility issue ([1eb4290](https://github.com/sile-typesetter/sile/commit/1eb42909dee1e9946316b7acf357b38677f34b2a))
* **packages:** Allow Hanmen frame creation to use optional ID arg ([7853d5a](https://github.com/sile-typesetter/sile/commit/7853d5a398d6ce18a9dbec67873091af110b596a))
* **packages:** Fix hole drawing from svg in PDF ([6521fd0](https://github.com/sile-typesetter/sile/commit/6521fd0323d03eea1437a11876f1d4c10f8c17d5))
* **packages:** Remove extra space in \code in url ([b90cd37](https://github.com/sile-typesetter/sile/commit/b90cd376c81615fec9d9c076b399c94951dc1f60)), closes [#1056](https://github.com/sile-typesetter/sile/issues/1056)
* **tooling:** Expand variables so fonts are known dependencies of tests ([88ac888](https://github.com/sile-typesetter/sile/commit/88ac88805c138397d7cf94f8b7864d65956a7e13))


### Performance Improvements

* **backends:** Reuse variables instead of recalculating values ([02cce40](https://github.com/sile-typesetter/sile/commit/02cce408c209fd59fbd531d2e8bdd4625964c4ee))

### [0.10.10](https://github.com/sile-typesetter/sile/compare/v0.10.9...v0.10.10) (2020-08-14)


### Features

* **build:** Detect and use luajit first ([601dfc4](https://github.com/sile-typesetter/sile/commit/601dfc42bcde4f8f8963c162e162db2a37dc8110))
* **build:** Detect LuaJIT if explicitly configured to want it ([c3e8089](https://github.com/sile-typesetter/sile/commit/c3e80897ddb2c51bc4a7b15bc0332a4bb304fec8))
* **classes:** Add warning to \noindent if called after input ([f29b9d9](https://github.com/sile-typesetter/sile/commit/f29b9d9daa56519717b09461ffb72fa53de2f75c))
* **packages:** Allow scaling SVGs by width or height ([44588b5](https://github.com/sile-typesetter/sile/commit/44588b56be70b35f73664223e4cf87e2a524e4c1))
* **settings:** Add a way to reset single setting to defaults ([f318cdf](https://github.com/sile-typesetter/sile/commit/f318cdfb2b24d896d582f75025093f5db0479f33))
* **settings:** Bring Lua settings.set to parity with \set ([d73b08c](https://github.com/sile-typesetter/sile/commit/d73b08c0419d14fde78df19761738dccefbd7efa))


### Bug Fixes

* **classes:** Reset parindent's inside \center command ([7b62f74](https://github.com/sile-typesetter/sile/commit/7b62f7426f57dd870631972529a9669680adfebe))
* **core:** Always compare like-types so LuaJIT can run ([c608090](https://github.com/sile-typesetter/sile/commit/c6080900b71de5e44ebb910d4b8aa1a6b4a7fe02))
* **core:** Don't read zero-length name table entries ([bcd9a9e](https://github.com/sile-typesetter/sile/commit/bcd9a9eb3d3d8b84d1ffa95c77224cf87079cdaa)), closes [#1015](https://github.com/sile-typesetter/sile/issues/1015)
* **examples:** Properly center title in showoff document ([55717fb](https://github.com/sile-typesetter/sile/commit/55717fb6eb682d2349c403c7f32e54ef042bb681))
* **frames:** Discard content (usually whitespace) inside \pagetemplate ([3b7085b](https://github.com/sile-typesetter/sile/commit/3b7085b150771ded2fa217b23f89935e6231d090))
* **frames:** Draw frame debug lines exactly on frame lines ([db92edc](https://github.com/sile-typesetter/sile/commit/db92edcd1056da29cede15202daea844444cb031))
* **languages:** Stop Japanese resetting global chapter post macro ([836f199](https://github.com/sile-typesetter/sile/commit/836f199737f8fc99b9377ab354bef36d9d542fd7))
* **packages:** Align pullquote ending mark with outside margin ([8b808db](https://github.com/sile-typesetter/sile/commit/8b808db61e712f62817e0a25590db4bb320f6e8b))
* **packages:** Draw rules in the writing direction ([18bca68](https://github.com/sile-typesetter/sile/commit/18bca68cfe9d5d061d5a86e485a28fbb712f8e28))
* **packages:** Error if asked to add bogus dependencies ([59e2b56](https://github.com/sile-typesetter/sile/commit/59e2b568535136f40bfa60e9dc36cfb7a9855d4b))
* **packages:** Fix indentation of second paragraph in pullquotes ([a8525e5](https://github.com/sile-typesetter/sile/commit/a8525e575bd56cce7a6a635cc3e0f827593f5e11))
* **packages:** List \include files in makedeps ([bf670ab](https://github.com/sile-typesetter/sile/commit/bf670ab5d323886cd62c7193ee0598472e0e40c1))
* **packages:** Orient rules for all 8 directions ([bc4a33a](https://github.com/sile-typesetter/sile/commit/bc4a33a73cd7f4550e6dc547a31505f6865e38fe))
* **packages:** Place PDF bookmarks at top of current line ([ce30d83](https://github.com/sile-typesetter/sile/commit/ce30d83347e8d3bae6c044112ec265695a0bb1c6))
* **utilities:** Use deterministic sort for sorted pairs ([99e2b59](https://github.com/sile-typesetter/sile/commit/99e2b593e06e4ee5a1162e8ce3da2bec8512e3b3))

### [0.10.9](https://github.com/sile-typesetter/sile/compare/v0.10.8...v0.10.9) (2020-07-24)


### Features

* **build:** Install manual to $(pdfdir) if configure --with-manual ([ee33ff7](https://github.com/sile-typesetter/sile/commit/ee33ff71c2d978c637c01433663ccd7baf7e8fcc))
* **core:** Allow adding --debug flag multiple times ([9ac2838](https://github.com/sile-typesetter/sile/commit/9ac28382beb226785f574f89353f7acb720fb949))


### Bug Fixes

* **build:** Correct typo in dependencies for building docs ([ad548a5](https://github.com/sile-typesetter/sile/commit/ad548a5e0c32ef5bd99f951594a9e49161aa5941))
* **build:** Ship blank lua_modules install list in source packages ([7939970](https://github.com/sile-typesetter/sile/commit/7939970397414554c45dcfe486dc736b8fb2e4fe))
* **build:** Touch Makefile.in to avoid automake errors ([e7f4627](https://github.com/sile-typesetter/sile/commit/e7f4627a8cf8e6498b7c1c22b633579644a1d72a))
* **build:** Work around src/libtexpdf subdirs using side-effects ([26d6769](https://github.com/sile-typesetter/sile/commit/26d6769a32c3985d18d314cf0281663d5545e650))
* **core:** Iterate on sequential data with ipairs() or SU.sortedpairs() ([9db0a28](https://github.com/sile-typesetter/sile/commit/9db0a28d5c64caf9d64200d359f477bd375469eb))
* **debug:** Fix math in hbox debugging ([6c0029d](https://github.com/sile-typesetter/sile/commit/6c0029df469e89ce809ff833a3fa631eee14f77e))
* **packages:** Combine unichar output with existing unshaped node ([712bc92](https://github.com/sile-typesetter/sile/commit/712bc925dfc1601111922d4bd9089ad161867020))
* **packages:** Use sortedpairs to avoid non-determinism ([a28ef06](https://github.com/sile-typesetter/sile/commit/a28ef06b2aa1265018078e258280fc2f9a7dc348))
* **utilities:** Add sorted pairs function ([5aad397](https://github.com/sile-typesetter/sile/commit/5aad3975cc92b2641337bd65e2919ee198fe8669))

### [0.10.8](https://github.com/sile-typesetter/sile/compare/v0.10.7...v0.10.8) (2020-07-18)


### Features

* **build:** Output hints about how to compile from repo snapshots ([596cd9f](https://github.com/sile-typesetter/sile/commit/596cd9f27cd24237d863ffde7725e95186da04fb))


### Bug Fixes

* **build:** Avoid possible race condition on first bulid ([b937c95](https://github.com/sile-typesetter/sile/commit/b937c9509e86aeec25ee1db9c0726151e3214d82))
* **build:** Use BSD compatible find syntax ([c96683e](https://github.com/sile-typesetter/sile/commit/c96683ef5d015ccc540214acb8b20a86f8e0ae78))
* **build:** Use BSD compatible touch syntax ([25eb6fd](https://github.com/sile-typesetter/sile/commit/25eb6fda81eb6ad9c0afc4e656eca0a31620ed00))
* **docker:** Make sure Lua modules installation works on the first pass ([f0c3e26](https://github.com/sile-typesetter/sile/commit/f0c3e2683d78de82d2395dcd0a6c5ca5d1d4081b))


### Performance Improvements

* **build:** Save a ./configure cycle by bootstraping the version ([2997d05](https://github.com/sile-typesetter/sile/commit/2997d05d433492633dc6db68032ded1ef91edd1c))


### Reverts

* Revert "chore(build): Save a double-configure on first download/build" ([ef56de4](https://github.com/sile-typesetter/sile/commit/ef56de4114faf8c95e9da7c7c1d258b6221a086c))

### [0.10.7](https://github.com/sile-typesetter/sile/compare/v0.10.6...v0.10.7) (2020-07-16)


### Bug Fixes

* **build:** Merge Github Actions release step with build ([b2d77ab](https://github.com/sile-typesetter/sile/commit/b2d77ab05da064d0a51aa6b8ee85e90ddeb0b63b))

### [0.10.6](https://github.com/sile-typesetter/sile/compare/v0.10.5...v0.10.6) (2020-07-16)


### Features

* **build:** Add --with-install-examples option to configure & make ([245e8a6](https://github.com/sile-typesetter/sile/commit/245e8a6bff0b012bfa12a5a6f9bc7609a6b42af3))
* **build:** Add --with-install-manual option to configure & make ([3415b3a](https://github.com/sile-typesetter/sile/commit/3415b3a7a6557871698b0fe9d9f512a6adc2854e))
* **inputs:** Allow (escaped) quote mark in quoted command options ([2e9d1b5](https://github.com/sile-typesetter/sile/commit/2e9d1b5fe599e1c445a70ca2f4d957dfff37e9c0))


### Bug Fixes

* **build:** Always distribute Lua_modules even if build uses system ([e75ece7](https://github.com/sile-typesetter/sile/commit/e75ece7fb88703ab39e1ac97e6c5385a59950aed))
* **build:** Correct typo in test dependencies causing no font downloads ([ad49a85](https://github.com/sile-typesetter/sile/commit/ad49a85dafbb5cf4e12326f0ffd1da755791c715))
* **build:** Correct typo in test dependencies causing no font downloads ([09a653a](https://github.com/sile-typesetter/sile/commit/09a653a7768e5e8006614fc7d4703c82996d17b6))
* **build:** Explicitly filter packaging *.lua and *.sil to avoid cruft ([a89773d](https://github.com/sile-typesetter/sile/commit/a89773d48dbd9a54f6939c8722a18dcd2d67755e))
* **build:** Fix conflations between Lua source types ([163959f](https://github.com/sile-typesetter/sile/commit/163959f267966507f2627afdca48d01db0a3a3ae))
* **build:** Handle any combo of --with-manual and --with-examples flags ([145a86e](https://github.com/sile-typesetter/sile/commit/145a86edd99b9bae054e0e68245f90b512695ab0))
* **build:** Mark `make busted` as PHONY so it always runs ([23b81ac](https://github.com/sile-typesetter/sile/commit/23b81ac1ac79fb6f3c9c9be0fd38a50b972b7dde))
* **build:** Move dynamically generated file lists out of automake ([f626867](https://github.com/sile-typesetter/sile/commit/f626867221fa57af3a3d90ad87e0bc0c80581d71))
* **classes:** Use Hack as default monospace font ([0e61067](https://github.com/sile-typesetter/sile/commit/0e610675c173c177c444f8212668bbb5dd6a36d0))
* **core:** Handle empty content in macros using \process ([2dc6d66](https://github.com/sile-typesetter/sile/commit/2dc6d66b9002ae46de5e764cfffb88c4a4b16c9f))
* **frames:** Reset font to Gentium to output frame IDs ([102dd09](https://github.com/sile-typesetter/sile/commit/102dd09d548eb48ba752994d59c9237d63a42143)), closes [#915](https://github.com/sile-typesetter/sile/issues/915)
* **inputs:** Disallow 'begin' and 'end' as environment names ([b13b99a](https://github.com/sile-typesetter/sile/commit/b13b99a7ad3e7acddf7e66b920f2bf553ef4682a))
* **inputs:** Only allow reserved characters as 1-char commands ([2a4c095](https://github.com/sile-typesetter/sile/commit/2a4c095826fc0fb16831aac35b400b64a564acc3))
* **packages:** Assure PDF initialization first-output can be rotated ([0613ab1](https://github.com/sile-typesetter/sile/commit/0613ab16c14faf046c164d09e89e987df28c5371))
* **packages:** Cast measurements to numbers before use in PDF functions ([5f2d2e3](https://github.com/sile-typesetter/sile/commit/5f2d2e3c356c379acdbfc8da7bf36384421aad79))
* **packages:** Fix measurement-to-number issue in SVG ([168dffc](https://github.com/sile-typesetter/sile/commit/168dffc6bd6aa21ef8ac32ea6987c9dd64a98101))
* **packages:** Improve multi-paragraph pullquotes ([7d3f355](https://github.com/sile-typesetter/sile/commit/7d3f355c8e06f6411943ed32d9d51c55c0567a19)), closes [#865](https://github.com/sile-typesetter/sile/issues/865)
* **packages:** Ruby class should not affect document language ([#926](https://github.com/sile-typesetter/sile/issues/926)) ([8034aa1](https://github.com/sile-typesetter/sile/commit/8034aa1fa74ac254e8dff4ea4ca8bf57b7a9b01c))
* **packages:** Tate should not affect document language ([#932](https://github.com/sile-typesetter/sile/issues/932)) ([193fded](https://github.com/sile-typesetter/sile/commit/193fded67edb7d33f65e3ebeb7b571285da5a8cd))
* **tooling:** Allow `make dist` on systems without native lua packages ([5758085](https://github.com/sile-typesetter/sile/commit/57580853ada84c5af9c821646d01a07329f3e1fc))


### Reverts

* Revert "ci(travis): Bump Luarocks install to 3.3.1" ([97fb476](https://github.com/sile-typesetter/sile/commit/97fb47693d74a56a6e223e5c19bc4281348eda36))

### [0.10.5](https://github.com/sile-typesetter/sile/compare/v0.10.4...v0.10.5) (2020-07-03)


### Features

* **build:** Add `make check` fast self-check target, fixes [#835](https://github.com/sile-typesetter/sile/issues/835) ([89cefef](https://github.com/sile-typesetter/sile/commit/89cefefe758a00b9b310ba4df53320f9c74ce696))
* **shaper:** Add tracking setting and implement for harfbuzz ([9e1dec7](https://github.com/sile-typesetter/sile/commit/9e1dec7a0a71db6c17dded2fce8b61867bb0a523))


### Bug Fixes

* **build:** Check for luarocks if not configured --with-system-luarocks ([e8770ce](https://github.com/sile-typesetter/sile/commit/e8770ce2d1085752e2383adcb11acf8222225cd7))
* **core:** Account for possibilty that there are no working fallbacks ([391f44e](https://github.com/sile-typesetter/sile/commit/391f44eb7cd93351404bbbe89167d5acca466bff))
* **core:** Gracefully do nothing when SILE.process() passed nothing ([1085049](https://github.com/sile-typesetter/sile/commit/1085049310cce11728f74dd7d46571bc579d7afb))
* **core:** Revamp macro system to fix [#535](https://github.com/sile-typesetter/sile/issues/535) ([47a0af8](https://github.com/sile-typesetter/sile/commit/47a0af8e922f5122f6af41d3809b2f1248c2ac2d))
* **frames:** Avoid possible infinite loop when looking for a frame ([157dfc8](https://github.com/sile-typesetter/sile/commit/157dfc815e0888c604581ac38766d5858450bcf8))
* **frames:** Rely on __tostring() meta method, toString() is no more ([77b8956](https://github.com/sile-typesetter/sile/commit/77b8956b890d85763e87ecab742bbfad970a528f))
* **nodes:** Fix calling non-existent nodefactory function ([#864](https://github.com/sile-typesetter/sile/issues/864)) ([9580a15](https://github.com/sile-typesetter/sile/commit/9580a15e8efddbae9c91116beac2210e6ce893cf))
* **packages:** Center dotfill in the event only one dot fits ([95181d2](https://github.com/sile-typesetter/sile/commit/95181d2b1827f56d4f3de3775f8aa2d4b16c0735))
* **packages:** Don't let dotfill content be stretchy ([079ff97](https://github.com/sile-typesetter/sile/commit/079ff971462515edbebddd04f6572b91c4c80904))

### [0.10.4](https://github.com/sile-typesetter/sile/compare/v0.10.3...v0.10.4) (2020-04-21)


### Bug Fixes

* **build:** Fix version detection in sparse git checkouts ([#803](https://github.com/sile-typesetter/sile/issues/803)) ([#818](https://github.com/sile-typesetter/sile/issues/818)) ([dcd0023](https://github.com/sile-typesetter/sile/commit/dcd00236f20a70e2610319441b4bb4c10b96cc02))
* **core:** Return correct length from icu.bidi_runs with surrogate pairs ([000515f](https://github.com/sile-typesetter/sile/commit/000515fccd68f7467ee199c064634d4ce25bfc18)), closes [#839](https://github.com/sile-typesetter/sile/issues/839)
* **docker:** Work around fresh GNU coreutils bombing Docker Hub ([#851](https://github.com/sile-typesetter/sile/issues/851)) ([ed49fbb](https://github.com/sile-typesetter/sile/commit/ed49fbbf1128c03f3e4358d89086f16cbd786be6))
* **languages:** Localize TOC title functions ([#849](https://github.com/sile-typesetter/sile/issues/849)) ([1ab4345](https://github.com/sile-typesetter/sile/commit/1ab434582aa3f555212f021cc47ad5d354a570b8))
* **packages:** Update PDF package to use correct measurement types ([79e24ca](https://github.com/sile-typesetter/sile/commit/79e24ca71bef1f3d5b2f9e978bbef1bb8a5a5b03))
* **packages:** Update Tate package to use correct measurement types ([180024f](https://github.com/sile-typesetter/sile/commit/180024f29c3002317a27df042139ae97b79907ad))
* **tooling:** Add missing lua-cosmo dependency for Markdown class ([#822](https://github.com/sile-typesetter/sile/issues/822)) ([ea81598](https://github.com/sile-typesetter/sile/commit/ea815984d27d15770613a57f019284136fbf3bbd))
* **typesetter:** Make `typesetter.breakwidth` a measurement ([721280d](https://github.com/sile-typesetter/sile/commit/721280dde51d834ab170efb75eba73771f5cda59))

### [0.10.3](https://github.com/sile-typesetter/sile/compare/v0.10.2...v0.10.3) (2020-02-04)


### Bug Fixes

* **tooling:** Make sure Lua modules get included in source tarball ([ef5bb53](https://github.com/sile-typesetter/sile/commit/ef5bb53e73204bed18edf89aa3aac67ef15846a2))
* **tooling:** Unblock standard-version release number bumping ([7b18cd5](https://github.com/sile-typesetter/sile/commit/7b18cd5decbc94879fd752c601cc73e25e41e8d6)), closes [#816](https://github.com/sile-typesetter/sile/issues/816)

### [0.10.2](https://github.com/sile-typesetter/sile/compare/v0.10.1...v0.10.2) (2020-02-03)


### Bug Fixes

* **build:** Don't include build *.so modules in dist ([4eb2a73](https://github.com/sile-typesetter/sile/commit/4eb2a731b131bab0c1f86ac12b112e2b9035cb15))
* **build:** Fix version detection in sparse git checkouts ([#803](https://github.com/sile-typesetter/sile/issues/803)) ([e46091f](https://github.com/sile-typesetter/sile/commit/e46091f7f9051b6daed07bfc76d05ab550adde2b))
* **build:** Include modules for all supported Lua versions in dist ([a4e9f03](https://github.com/sile-typesetter/sile/commit/a4e9f0380243684737f884a2111615f391170324))
* **build:** Look for Lua 5.3 executables with the version in their name ([3952bf8](https://github.com/sile-typesetter/sile/commit/3952bf8de762723ec6dff950bc9a498fe6e991d3))

### [0.10.1](https://github.com/sile-typesetter/sile/compare/v0.10.0...v0.10.1) (2020-01-24)


### Bug Fixes

* **backends:** Implement cursor tracking to roughly simulate glues ([26afcec](https://github.com/sile-typesetter/sile/commit/26afcec76912f88cc25bbeb70a6cc8850d999516))
* **core:** Actually deprecate old nodefactory instantiators ([774f0fc](https://github.com/sile-typesetter/sile/commit/774f0fce2c3ac6519f9fb98d91f71daa5aa88d8e))
* **measurements:** Actually deprecate old constructors ([bfdb1b8](https://github.com/sile-typesetter/sile/commit/bfdb1b86986968e3f9d132fae1e4cb01b9623d9d))
* **nodes:** Fix pushHbox() regression, recognize zerohoxes ([#789](https://github.com/sile-typesetter/sile/issues/789)) ([dae51f1](https://github.com/sile-typesetter/sile/commit/dae51f1d8d993647220a61dbdde59caa670d10ba))


### New Features

* **backends:** Aproximate space and break in text output to PDF ([9577ae4](https://github.com/sile-typesetter/sile/commit/9577ae4610a2a70f50078b7f0789bf842ab8ef1d))
* **docker:** Add dockerfile and setup to build an image ([4424d44](https://github.com/sile-typesetter/sile/commit/4424d4469905edf43815464d74229184b4710aad))
* **docker:** Add method to inject fonts into Docker container ([104124a](https://github.com/sile-typesetter/sile/commit/104124a1d9019399561c7c64e9590a3175de6ce3))

## [0.10.0](https://github.com/sile-typesetter/sile/compare/v0.9.5...v0.10.0) (2020-01-13)


### ⚠ BREAKING CHANGES

* This removes the auto-guessing file extension
  mechanism that allowed *.sil files to be loaded without specifying the
  full file name with extensions. A command like `sile test` will no
  longer find and build sile.sil, you must run `sile test.sil`. The
  mechanism that was doing this was a hack than only worked in some
  scenarios anyway, and dropping it instead of trying to cover all the
  edge cases will make it that much easier to use and document.
  Importantly it avoids edge cases where both *.xml, *.sil, and/or *.lua
  files all have the same name and the loader really has so idea which one
  you mean.

  Note that _packages_ may still be loaded with no file extension, this
  does not affect the `require()` mechanism that looks for *.lua and
  various other incantations by default.

### Bug Fixes

* **build:** Bludgeon autoconftools to respect our will ([b256cb9](https://github.com/sile-typesetter/sile/commit/b256cb9e041434d43af314fb826cb26514cbb947))
* **build:** Correct Makefile syntax oopses ([a831a4f](https://github.com/sile-typesetter/sile/commit/a831a4fc99ff10a56110240c5621474065089f45))
* **build:** Deautoconfiscate, undoing race condition setup by ee1834a ([f09bb08](https://github.com/sile-typesetter/sile/commit/f09bb08c651cf9c3eef6dce9fc7f3a538a9b405c))
* **build:** Don't let autoconf warn when hack run too early ([56a0714](https://github.com/sile-typesetter/sile/commit/56a07142e2ae091498e67fe4d0d2e15b1f82d061))
* **build:** Use POSIX compatable shell arguments ([#712](https://github.com/sile-typesetter/sile/issues/712)) ([c0542ca](https://github.com/sile-typesetter/sile/commit/c0542ca6715946192fdfe4abb239a3ea6705d784))
* **build:** Use version detection that works w/out git ([f94e9d8](https://github.com/sile-typesetter/sile/commit/f94e9d8caaae03a7d1b02c42dddf19efb56b13c9))
* **classes:** Don't try to load layout modules until init() ([b58c861](https://github.com/sile-typesetter/sile/commit/b58c8610d3e725dbf3d538f2e3ce8958207c410d))
* **core:** Add Lua 5.1 compatibility hack to makedeps code ([067d410](https://github.com/sile-typesetter/sile/commit/067d41072c3464ec086350ba36192a0d486f9536))
* **core:** Close makedeps before final output so timestamp is earlier ([f1b5df5](https://github.com/sile-typesetter/sile/commit/f1b5df5c0be7a4bfc6a3c12eea31411da930619f))
* **core:** Correct Lua bloopers using standard syntax ([af7d101](https://github.com/sile-typesetter/sile/commit/af7d1017155f85aec9dcad1bbad30476871d947e))
* **core:** Don't bother require() by mucking around in custom resolver ([e0e2548](https://github.com/sile-typesetter/sile/commit/e0e25480d3e44b696d719b569ea72590b7cbf07c))
* **core:** Don't dump debug information to stdout ([4e96548](https://github.com/sile-typesetter/sile/commit/4e9654808ae0402e88293c098d61ba5f455400a1))
* **core:** Don't instantiate objects in class definitions ([4cdb663](https://github.com/sile-typesetter/sile/commit/4cdb663605a858b2376eb2773805ca2518d5c3dd))
* **core:** Don't let units deal in length objects more than necessary ([6dff532](https://github.com/sile-typesetter/sile/commit/6dff532b37805fcc17d30d7bb1a05b332eff2eed))
* **core:** Fix bugs in path handling ([d16af88](https://github.com/sile-typesetter/sile/commit/d16af88ac8d9786c6011ed0cf17dddef49ba5210))
* **core:** Guess original parent of split frames post page break ([#765](https://github.com/sile-typesetter/sile/issues/765)) ([791c054](https://github.com/sile-typesetter/sile/commit/791c054f8fa718464302972446194397c484dd51))
* **core:** Hack problem with side effects in vglues ([7c908c9](https://github.com/sile-typesetter/sile/commit/7c908c9f769f9a56b84c9dc6d86eeaf34f08b0bb))
* **core:** Let require() do the work of finding files ([e82c0e9](https://github.com/sile-typesetter/sile/commit/e82c0e9d7d941861f722fbde57bc2a6dfa069d72))
* **core:** Restructure Lua path order to only prefix default ([3f2c553](https://github.com/sile-typesetter/sile/commit/3f2c55318df49973e0967fcc04ee901e8b69f91a))
* **core:** Show correct declaration file for doTexlike \defines ([f96ef83](https://github.com/sile-typesetter/sile/commit/f96ef836dcb862ddefb4c8bf24fcf89ed76139da))
* **core:** Smash bug in frameparser, handle whitespace consistently ([1e07e1c](https://github.com/sile-typesetter/sile/commit/1e07e1c3f1a75f803b25c3b9e65ac1f2ba7c7e15))
* **core:** Uncover and fix side effect using new math operators ([09a2860](https://github.com/sile-typesetter/sile/commit/09a28601fe21d7d07b64b474708ab1110c61871a))
* **core:** Use local variable scope ([142caad](https://github.com/sile-typesetter/sile/commit/142caad6c45069f866a86e16b8d9f0ed3d03a797))
* **counters:** Restore variable passing to refactored counter code ([18d5b00](https://github.com/sile-typesetter/sile/commit/18d5b00bd28c5504ae5816d5759a2b5464630692))
* **debug:** Correct usage of SILE debug functions ([3889f35](https://github.com/sile-typesetter/sile/commit/3889f35598379888828e9839dd4a0ea9034c41d3))
* **debug:** Correctly check location before printing "after" part ([a527ea8](https://github.com/sile-typesetter/sile/commit/a527ea894b1cfb8b95665d65cda17f369b3b3b92))
* **debug:** Handle case where content is function ([97ae8d4](https://github.com/sile-typesetter/sile/commit/97ae8d4f676a899615620a26125984ab7d270c3b))
* **debug:** Output debug messages on STDERR ([c2e4ad5](https://github.com/sile-typesetter/sile/commit/c2e4ad5164ff727000aa668009615b5956e0bf64))
* **debug:** Properly place stack push/pop so nested includes work ([8d0318f](https://github.com/sile-typesetter/sile/commit/8d0318f2c5910710cb2b17978bb09c3c71877480))
* **languages:** Calmly note Lua comments are not hyphenation patterns ([e826063](https://github.com/sile-typesetter/sile/commit/e826063bf96ee105f84851070697a5946f96e3c3))
* **languages:** Catch a bug in Turkish number expressions ([003a93b](https://github.com/sile-typesetter/sile/commit/003a93b816a5e39020bdb83deffbe0a5bbcc0712))
* **languages:** Fix bogus Lua syntax in Finish hyphenation code ([dd44c51](https://github.com/sile-typesetter/sile/commit/dd44c512d51c77b1c9673c548c964257e7dea182))
* **languages:** Fix bogus Lua syntax in Greek hyphenation code ([21ac9e7](https://github.com/sile-typesetter/sile/commit/21ac9e7f63b45b2bd22c05636bf742de4f72128b))
* **languages:** Fix punctuation in French by escaping character set ([a8c8dd1](https://github.com/sile-typesetter/sile/commit/a8c8dd1fd7a4adc448ae1499ed1b25043d661c70))
* **languages:** Fixes and tests for letterspacing ([c8edfd1](https://github.com/sile-typesetter/sile/commit/c8edfd1eb7e81b8c7daa36fae04b87e36220dd12))
* **languages:** Make sure hyphenator doesn't ever think language is nil ([81d33d3](https://github.com/sile-typesetter/sile/commit/81d33d33bb519dcbcbfde92e851c2786f6233dbc))
* **languages:** Place Danish hyphenation rules under Danish code ([#629](https://github.com/sile-typesetter/sile/issues/629)) ([e05976c](https://github.com/sile-typesetter/sile/commit/e05976c5adade4d3484bf9ec4d8b282a048359af))
* **package:** Fix boustrophedon bugs unearthed writing documentation ([a382b93](https://github.com/sile-typesetter/sile/commit/a382b93e48863aa373db93cdc8fcb825f0104d2f))
* **package:** Replace obsolete Linux Libertine with Libertinus Serif ([8f3b9c4](https://github.com/sile-typesetter/sile/commit/8f3b9c40f7cf3d208aff9fc1acb630a78e24e1f2))
* **packages:** Fix typos and bad namespacing ([922cddf](https://github.com/sile-typesetter/sile/commit/922cddf1cdaaed38ee401e6d1f097d6d793b7738))
* **packages:** Refactor grid with new measurements ([c9a862a](https://github.com/sile-typesetter/sile/commit/c9a862a474f0983c325621cc4f038c5751e155ab))
* **packages:** Unbreak marks, 0 ≠ o as in previous refactor ([5c4c671](https://github.com/sile-typesetter/sile/commit/5c4c671337d482ae5820c9a605e573faad1a0bf2))
* **repl:** Enable UTF-8 input by default ([e203d4d](https://github.com/sile-typesetter/sile/commit/e203d4df34d147e261917cf52d3ae1bc531700a5))
* **repl:** Use Luarocks to get linenoise REPL plugin ([e6155c3](https://github.com/sile-typesetter/sile/commit/e6155c39ff2fc3874c0b60ae2ef1348c205d9ccc))
* **shaper:** Prevent rare crash when font is specified by filename ([235f931](https://github.com/sile-typesetter/sile/commit/235f931c6178fc2ed1f9a8efa963e5835e3391b4)), closes [#604](https://github.com/sile-typesetter/sile/issues/604)
* **shaper:** Use non-reserved word in REPL function variable ([73f631b](https://github.com/sile-typesetter/sile/commit/73f631b2e360772827270d1025dbdef5ebe244d1))
* **tests:** Drop expected files that are clearly not what we expect yet ([e7c547a](https://github.com/sile-typesetter/sile/commit/e7c547a5bc8b14fe2f44f72131b4d11ea61583a6))
* **tests:** Ignore LuaRocks when reporting on coverage ([3619a8c](https://github.com/sile-typesetter/sile/commit/3619a8c1bd0a84381199b4f747e9f9408ee70e28))
* **tests:** Mimic SILE's internal Lua path in Busted test runs ([9e67e7d](https://github.com/sile-typesetter/sile/commit/9e67e7d6c5fd85dcc334d1610a27f93ec8f4b9be))
* **tests:** Patch up Lua Busted testing framework ([527ca4e](https://github.com/sile-typesetter/sile/commit/527ca4ee4eadee0f61a8a04a27bfa02e928f9945))
* **tests:** Rename source file based on content type ([3886ceb](https://github.com/sile-typesetter/sile/commit/3886cebfbe92546e7da77247f18822b9b66ed645))
* **tooling:** Allow tests to run from xml or sil sources ([5e6ab5c](https://github.com/sile-typesetter/sile/commit/5e6ab5cfc04ff970fd0fab3f6667901901f43482))
* **tooling:** Bundle rockspec file in source tarballs ([cc6fb85](https://github.com/sile-typesetter/sile/commit/cc6fb85127f459100f4a4579832a4475106a7c28))
* **tooling:** Configure luarocks on Mac (assume homebrew installed libs) ([ba1d4d0](https://github.com/sile-typesetter/sile/commit/ba1d4d0e5a95472746e177bfc2f8ea7714567b92))
* **tooling:** Fix lists of expected vs. actual files ([10506ed](https://github.com/sile-typesetter/sile/commit/10506ed3243b244a599fa43af9cbdb5e2f5b4e02))
* **tooling:** Fix Lua coverage tests ([ea6351c](https://github.com/sile-typesetter/sile/commit/ea6351c8bb2d8cf856d20612e47f2a5a19f73564))
* **tooling:** Have make make sure LuaRocks are actually current ([680d145](https://github.com/sile-typesetter/sile/commit/680d1459d4f96b4411263b395670b49438178ca0))
* **tooling:** Help autoconf tools find luajit ([da957dd](https://github.com/sile-typesetter/sile/commit/da957dd15a9767a932ca7e25163f7632eedc97a3))
* **tooling:** Remove bogus test expectation file ([4f79fe1](https://github.com/sile-typesetter/sile/commit/4f79fe1754c930d167c36932ebe62c85ee19ce32))
* **tooling:** Update Cassowary dependency to work on newer Penlight ([8b79ce9](https://github.com/sile-typesetter/sile/commit/8b79ce9b4d06c6c700659eba046a653e3274cc80))
* **tooling:** Work around bugs in standard-version ([96aa81c](https://github.com/sile-typesetter/sile/commit/96aa81c7e9c79e2c7d4512657eb0e990d98e8919))
* **travis:** Don't die if links exist as happens when caches restored ([d47a12a](https://github.com/sile-typesetter/sile/commit/d47a12afdea7d0525546afe4c1d25d3b3d223d31))
* **typesetter:** Always handle margins as glues, never as nulls ([90d0550](https://github.com/sile-typesetter/sile/commit/90d05501d0e606717ca60e3c40b5030e5cd5a761))
* **typesetter:** Don't loose original node dimensions during pagebuild ([8c38979](https://github.com/sile-typesetter/sile/commit/8c389791abb2291e1cbc01ab85de4cbe8fce0ac2))
* **typesetter:** Fix height of insertions as used in pagebuilder ([1ec6102](https://github.com/sile-typesetter/sile/commit/1ec6102b037a10de29c3e942aeafc04d483cc2c2))
* Add missing `local` to `content` variables in inputs-common ([8f8d4f0](https://github.com/sile-typesetter/sile/commit/8f8d4f085b17661bf9569e8dea729a78a2678fa4))


* refactor!(core): Use Lua's built in resolver instead of our monkey work ([f89bae4](https://github.com/sile-typesetter/sile/commit/f89bae4d1f0855247d0ae5593ff74fda37838802))


### Optimizations

* **core:** Add in-place arithmetic methods to lengths and measures ([caf2298](https://github.com/sile-typesetter/sile/commit/caf2298354762c23b858781fbc61b75e0f1e74da))
* **core:** Devise faster node type checking ([a322d07](https://github.com/sile-typesetter/sile/commit/a322d079db06bfc2839276d68a73b928b7605972))
* **core:** Disable debug mode in lua.stdlib ([6457a69](https://github.com/sile-typesetter/sile/commit/6457a691b4c88f7e457e93827c321c141a482e45))
* **core:** Don't waste time instantiating unused intermediaries ([6f3dba1](https://github.com/sile-typesetter/sile/commit/6f3dba17f69550790c0bbfb5291c77901d3a987b))
* **core:** Improve node shape caching ([deea10f](https://github.com/sile-typesetter/sile/commit/deea10f6d0e23c6330551b3a14374f3d4833ce57))
* **core:** Reduce length instantiations during break checks ([b24da47](https://github.com/sile-typesetter/sile/commit/b24da471c358f4d13145c154638811e353c6010f))
* **core:** Speed up comparisons with fewer instantiations ([7f47354](https://github.com/sile-typesetter/sile/commit/7f473542693101629565cadf10af279ceeb8c649))
* **core:** Use faster operations when appending nodes ([9d28568](https://github.com/sile-typesetter/sile/commit/9d285686d3439a5ba82001f7e16e64262f3c8db6))
* **core:** Use in-place arithmetic methods where sensible ([2f87641](https://github.com/sile-typesetter/sile/commit/2f876417d083af332d89c4f68b81556318f07a31))
* **utilities:** Allow passing lambda functions to SU.debug ([c8610df](https://github.com/sile-typesetter/sile/commit/c8610df7258739728c00e4c116620e7721430a9c))


### New Features

* **backends:** Add dummy output backend for dry runs ([ffd9ce3](https://github.com/sile-typesetter/sile/commit/ffd9ce36a4efdce2e141076d033d0ba4c0fdc549))
* **classes:** Add option to disable toc entry for book section ([#613](https://github.com/sile-typesetter/sile/issues/613)) ([2eedfa9](https://github.com/sile-typesetter/sile/commit/2eedfa9c1c15ae34b51f8a6e82c18cc6ab6efd09))
* **core:** Add CLI flag to force a specific font manager ([ebd8bb0](https://github.com/sile-typesetter/sile/commit/ebd8bb02b9199650ff4c8135080a553e2d5c0154))
* **core:** Add command stack system for better error output ([edafe1e](https://github.com/sile-typesetter/sile/commit/edafe1e9ea16ba743b1fde139a06d38546874ee0))
* **core:** Add directory of master file as preeminent search path ([9f0aff4](https://github.com/sile-typesetter/sile/commit/9f0aff4fdc6479053ac20a2d2064c7131ce30a70))
* **core:** Generalize determining if tag is a passthrough one or not ([f98471a](https://github.com/sile-typesetter/sile/commit/f98471a6e77c33ae7278a9a04d77e877b76e8c19))
* **core:** Track all files used and output make dependencies ([73e5e2d](https://github.com/sile-typesetter/sile/commit/73e5e2d723297045670fc4dce4274d6ac8ba253e))
* **languages:** Add English N'th number format ([227ff1a](https://github.com/sile-typesetter/sile/commit/227ff1a25b0e3b62b76a6fdf25c2e2e84610257b))
* **languages:** Add string and ordinal outputs to formatCounter() ([178218d](https://github.com/sile-typesetter/sile/commit/178218dacbd206215bb87ad1cbfbf1aaaa00f53c))
* **languages:** Add Turkish N'th number format ([16ea29f](https://github.com/sile-typesetter/sile/commit/16ea29fbb9766143f82f34f9e6f455d2a52880ce))
* **languages:** Add Turkish number-to-string functions ([aad9ed9](https://github.com/sile-typesetter/sile/commit/aad9ed9bbb88afa36975376b705f0bbee363443b))
* **packages:** Add Pandoc helper package for converted documents ([96090a5](https://github.com/sile-typesetter/sile/commit/96090a5e22d3714e83ed5891dde5ab5d8ac9b917))
* **packages:** Allow stretch and shrink heights on insertion vboxes ([adfd8de](https://github.com/sile-typesetter/sile/commit/adfd8ded3da132e2cb08fb855111b6910e7cafe1))
* **settings:** Allow settings to have boolean values ([07a3aba](https://github.com/sile-typesetter/sile/commit/07a3aba79656f3c48d48c098021c22fbddeb202d))
* **tooling:** Setup make rules for comparing worktrees ([b8ff48a](https://github.com/sile-typesetter/sile/commit/b8ff48a457ee04e74f3e83a1589342e3008c72ce))
* **utilities:** Add English number to string formatter ([82aada2](https://github.com/sile-typesetter/sile/commit/82aada291e43fc74099df826cfad58e652722335))
* **utilities:** Add type casting option to SU.required() ([56c6506](https://github.com/sile-typesetter/sile/commit/56c6506e96d20d9255ba85369304bec240ab9213))

<a name="0.9.5.1"></a>
## [0.9.5.1](https://github.com/sile-typesetter/sile/compare/v0.9.4...v0.9.5.1) (2019-01-13)

No code changes, but the previous release was broken due to extraneous
files in the tarball. Oh, the embarrassment.

<a name="0.9.5"></a>
## [0.9.5](https://github.com/sile-typesetter/sile/compare/v0.9.4...v0.9.5) (2019-01-07)

* Experimental package manager.

* The "smart" bare percent unit (where SILE guessed whether you meant height or width) has now moved from deprecated to error. Replace with `%pw` etc.

* Language support: variable spaces in Amharic (and other languages if enabled with the `shaper.variablespaces` setting), improvements to Japanese Ruby processing, Uyghur hyphenation revisited and improved, Armenian hyphenation added.

* You can now set the stretch and shrink values of a space using the `shaper.spaceenlargementfactor`, `shaper.spaceshrinkfactor` and `shaper.spacestretchfactor` settings.

* You can use `-` as input filename to pipe in from standard input, and `-` as output filename to pipe generated PDF to standard output.

* New `letter` class.

* New commands: `\neverindent` and `\cr`

* New units: `ps` (parskip) and `bs` (baselineskip)

* Links generated via the `url` package are hyperlinked in the PDF.

* You can now style folios (page numbers) by overriding the `\foliostyle` macro.

* Languages may define their own counting functions by providing a `counter` function; you may also lean on ICU's number formatting to format numbers.

* ICU is now required for correct Unicode processing.

* Experimental support for SVG graphics and fonts. (see `tests/simplesvg.sil`)

* Users may select the Harfbuzz subshaping system used (`coretext`, `graphite`, `fallback` etc.) by setting the `harfbuzz.subshapers` setting.

* Fix typos in documentation (Thanks to Sean Leather, David Rowe).

Most other changes in this release are internal and non-user-visible, including:

* Introduced vertical kern nodes.

* Various fixes to pushback (end of page) logic, bidi implementation. ICU is now used for bidi.

* Updated various examples to work with current internals.

* Many and varied internal fixes and speedups, and improved coding style.

<a name="0.9.4"></a>
## [0.9.4](https://github.com/sile-typesetter/sile/compare/v0.9.3...v0.9.4) (2016-08-31)

Nearly 600 changes, including:

* New packages include: letter spacing, multiple line spacing methods, Japanese Ruby, font specimen generator, crop marks, font fallback, set PDF background color.

* Fixed handling of font weight and style.

* Hyphenation: Correct hyphenation of Indic scripts, words with non-alphabetic characters in them, and allow setting hyphen character and defining hyphenation exceptions.

* Relative dimensions ("1.2em") are converted to absolute dimensions at point of use, not point of declaration. So you can set linespacing to 1.2em, change font size, and it'll still work.

* Default paper size to A4.

* Changes to semantics of percent-of-page and percent-of-frame length specifications. (`width=50%` etc.)

* Much improved handling of footnotes, especially in multicolumn layouts.

* Support for: the libthai line breaking library, color fonts, querying the system font library on OS X, multiple Amharic justification conventions.

* Added explicit kern nodes.

* Changed to using Harfbuzz for the text processing pipeline; much faster, and much more accurate text shaping.

* Rewritten and more accurate bidirectional handling.

* Removed dependency on FreeType; use Harfbuzz for font metrics.

* Fixed the definition of an em. (It's not the width of a letter "m".)

and much more besides.

<a name="0.9.3"></a>
## [0.9.3](https://github.com/sile-typesetter/sile/compare/v0.9.2...v0.9.3) (2015-10-09)

* Support for typesetting Japanese according to the JIS X 4051 standard, both horizontally and vertically.

* Unicode line-breaking support; scripts now line-break correctly even if they don't have specific language support. Optionally uses the ICU library if installed.

* Font designers rejoice: you can now say \font[filename=...] to use uninstalled fonts.

* Pango/Cairo support is now officially deprecated. Stop using it!

* Improvements to USX Bible processing.

* Experimental support for Structured PDF generation.

* Support for Opentype kerning.

* Support for custom frame direction (e.g. "TTB-LTR" for Mongolian).

* Support for many-way parallel texts across pages or spreads.

* Line breaking support for Myanmar, Javanese and Uyghur.

* Support for boustrophedon Greek. No, really.

* Various fixes to bidirectionality, discretionary hyphens, insertions, footnotes, grid typesetting, alignment.

* Under-the-hood advancements for Harfbuzz.

<a name="0.9.2"></a>
## [0.9.2](https://github.com/sile-typesetter/sile/compare/v0.9.1...v0.9.2) (2015-06-02)

* New packages for: rotated content, accessing OpenType features and ligatures, alternative input of Unicode characters, PDF bookmarks and links, input transformation.

* Packages to help with typesetting chord sheets and bibles.

* Experimental packages for bibliography management, typesetting URLs, Japanese vertical typesetting, balanced columns, and best-fit page breaking.

* Support for quoted strings in the parameters to TeX-like commands.

* Language support: Many fixes to Arabic; support for Tibetan and Kannada; hyphenation for many languages; much improved bidirectional typesetting.

* Warn when frames are overfull.

* Support for older versions of autotools, for Lua 5.3 and mingw32 environments.

* Continuous integration and testing framework

* Fixes to long-standing bugs in grid support, centering, ligatures, insertions and page breaking.

* Better font handling and substitution.

* Valid PDFs will still be generated on error/interruption.

* Improved error handling and error messages.

* Many miscellaneous bug fixes.

<a name="0.9.1"></a>
## [0.9.1](https://github.com/sile-typesetter/sile/compare/v0.9.0...v0.9.1) (2014-10-30)

* The main change in this release is a new shaper based on [Harfbuzz][]
  and a new PDF creation engine. This has greatly improved the output
  quality on Linux, as well as bringing support for multilingual
  typesetting and allowing future support of interesting PDF features.
  (It's also much faster.)

* The new PDF library also allows images to be embedded in many different
  formats, rather than just PNG.

* Documents can now be written in right-to-left languages such as Hebrew
  or Arabic, and it's possible to mix left-to-right and right-to-left
  text arbitrarily. (Using the Unicode Bidirectional Algorithm.)

* Initial support for languages such as Japanese which have different
  word/line breaking rules.

* Frames can be grouped into a set called a "master", and masters can
  be used to set the frame layout of a given page.

* Hopefully a much easier installation process, by bundling some of the
  required Lua modules and using the standard autoconf `./configure; make`
  strategy.

* Support for Lua 5.2.

<a name="0.9.0"></a>
# 0.9.0 (2014-08-29)

[Harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
