# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

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
