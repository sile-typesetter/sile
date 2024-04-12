ACLOCAL_AMFLAGS = -I build-aux

.ONESHELL:
.SECONDARY:
.SECONDEXPANSION:
.DELETE_ON_ERROR:

SUBDIRS =
if !SYSTEM_LIBTEXPDF
SUBDIRS += libtexpdf
endif
SUBDIRS += justenough .

docdir = $(datarootdir)/doc/$(TRANSFORMED_PACKAGE_NAME)
licensedir = $(datarootdir)/licenses/$(TRANSFORMED_PACKAGE_NAME)
datadir = $(datarootdir)/$(TRANSFORMED_PACKAGE_NAME)
pkgdatadir = $(datadir)

# Rules for installing LuaRocks locally as pkgdata_DATA
include Makefile-luarocks

# Actual rules for downloading test fonts are in a separate file
include Makefile-fonts

# Our regression test suite includes test for all features. Anything that is
# only expected to work with code behind a feature flag needs to be filtered
# out if we are configured with the feature disabled.
_DISABLEDSRCS =
if !FONT_VARIATIONS
_DISABLEDSRCS += tests/variations-%
endif
export DISABLEDSRCS ?= $(filter $(_DISABLEDSRCS),$(_TESTSRCS))
TESTSRCS ?= $(filter-out $(DISABLEDSRCS),$(_TESTSRCS))
TESTPREVIEWS ?= $(addsuffix .pdf,$(basename $(filter-out $(_DISABLEDSRCS),$(_TESTPREVIEWS))))

# Since we can't use $(wildcard ...) in automake file lists, we generate a file
# with a script that builds our dynamic file lists instead. This is tricky,
# because if we just include the file automake will flatten this include. By
# using $(wildcard ...) to include it (the very function we couldn't use because
# of the race condition it creates) we actually keep it from being flattened and
# hence evaluated when we want it to be. Since the file always exists (see
# BUILT_SOURCES and EXTRA_DIST) this doesn't induce a race.
include $(wildcard Makefile-distfiles)

FIGURES = documentation/fig-input-to-output.pdf

MANUAL := documentation/sile.pdf
SILELUA := $(PACKAGE_NAME)-lua

if MANUAL
_MANUAL = $(MANUAL)

endif

$(MANUAL): $(FIGURES)

BUILT_LUA_SOURCES = core/features.lua core/pathsetup.lua core/version.lua

bin_PROGRAMS = sile
bin_SCRIPTS = sile-lua
dist_man_MANS = sile-lua.1
sile_SOURCES = src/bin/sile.rs src/lib.rs src/cli.rs
EXTRA_sile_SOURCES =
if !EMBEDDED_RESOURCES
nobase_dist_pkgdata_DATA = $(SILEDATA) $(LUALIBRARIES)
nobase_nodist_pkgdata_DATA = $(BUILT_LUA_SOURCES) $(LUAMODULES)
endif
dist_doc_DATA = README.md CHANGELOG.md
dist_pdf_DATA = $(_MANUAL)
dist_license_DATA = LICENSE.md
EXTRA_DIST = spec tests documentation sile-dev-1.rockspec fontconfig.conf
EXTRA_DIST += Makefile-distfiles
EXTRA_DIST += build-aux/action-updater.js build-aux/cargo-updater.js build-aux/config.ld build-aux/decore-automake.sh build-aux/git-version-gen build-aux/list-dist-files.sh
EXTRA_DIST += Dockerfile build-aux/docker-bootstrap.sh build-aux/docker-fontconfig.conf hooks/build
EXTRA_DIST += default.nix flake.nix flake.lock shell.nix build-aux/pkg.nix
EXTRA_DIST += package.json # imported by both Nix and Docker
EXTRA_DIST += $(MANUAL) $(FIGURES)
EXTRA_DIST += src/embed.rs.in
EXTRA_DIST += sil.abnf

BUILT_SOURCES = $(BUILT_LUA_SOURCES) Makefile-distfiles

CLEANFILES = $(MANUAL)

include $(top_srcdir)/build-aux/rust_boilerplate.mk

Makefile-distfiles: $(wildcard .version .tarball-version) | $(LUAMODLOCK)
	$(SHELL) build-aux/list-dist-files.sh > $@

if EMBEDDED_RESOURCES
_EMBEDDED_SOURCES = src/embed.rs src/embed-includes.rs
nodist_sile_SOURCES = $(_EMBEDDED_SOURCES)
BUILT_SOURCES += $(_EMBEDDED_SOURCES)
CLEANFILES += $(_EMBEDDED_SOURCES)
$(CARGO_BIN): justenough/.libs/fontmetrics.a
$(CARGO_BIN): justenough/.libs/justenoughfontconfig.a
$(CARGO_BIN): justenough/.libs/justenoughharfbuzz.a
$(CARGO_BIN): justenough/.libs/justenoughicu.a
$(CARGO_BIN): justenough/.libs/justenoughlibtexpdf.a
$(CARGO_BIN): justenough/.libs/svg.a
$(CARGO_BIN): libtexpdf/.libs/libtexpdf.a

src/embed-includes.rs: Makefile-distfiles
	{
		echo $(BUILT_LUA_SOURCES)
		$(GREP) -E '^(SILEDATA|LUALIBRARIES|LUAMODULES) = ' $<
	} |
		$(SED) -E -e 's/^.* = //;s/ /\n/g' |
		while read file; do
			echo "#[include = \"$${file}\"]"
		done > $@

src/embed.rs: src/embed.rs.in src/embed-includes.rs
	$(SED) \
		-e '/@INCLUDE_EMDED_INCLUDES@/r $(word 2,$^)' \
		-e '/@INCLUDE_EMDED_INCLUDES@/d' \
		$< > $@
endif EMBEDDED_RESOURCES

if LUAJIT
MLUAVER = luajit
else
MLUAVER = lua$(LUA_SHORT_VERSION)
endif
CARGO_FEATURE_ARGS = --features $(MLUAVER)

if !SYSTEM_LUA_SOURCES
CARGO_FEATURE_ARGS += --features vendored
endif

if EMBEDDED_RESOURCES
CARGO_FEATURE_ARGS += --features static
endif

if FONT_VARIATIONS
CARGO_FEATURE_ARGS += --features variations
endif

DEPDIR := .deps
LOCALFONTS := FONTCONFIG_FILE=$(PWD)/fontconfig.conf
LOCALPATHS := SILE_PATH="$(PWD);libtexpdf/.libs;justenough/.libs"
SILEFLAGS ?= -m $(DEPDIR)/$(basename $@).d -d versions -f fontconfig
DRAFT ?= false

dist-hook: $(MANUAL) dist-hook-distfiles

.PHONY: dist-hook-distfiles
dist-hook-distfiles:
	cd $(distdir)
	$(SED) -i -e '/^LUAMODULES =/s/=.*/=/' Makefile-distfiles
	$(top_srcdir)/build-aux/decore-automake.sh
	$(SED) -i -e '/^LUAMODULES/d;/^\tlua_modules/d' Makefile.in

# Whether to force tests to run from scratch
CLEAN ?=

dist: sile-$(VERSION).pdf sile-$(VERSION).md

sile-$(VERSION).pdf: $(MANUAL)
	$(INSTALL) $(MANUAL) $@

sile-%.md: CHANGELOG.md
	$(SED) -e '/\.\.\.v$*/,/\.\.\.v/!d' CHANGELOG.md | \
		$(SED) -e '1,3d;N;$$!P;$$!D;$$d' > $@

check: selfcheck

.PHONY: selfcheck
selfcheck: | $(bin_PROGRAMS) $(_BUILT_SUBDIRS)
	output=$$(mktemp -t selfcheck-XXXXXX.pdf)
	trap '$(RM) $$output' EXIT HUP TERM
	echo "<sile>foo</sile>" | $(LOCALPATHS) ./$(bin_PROGRAMS) -o $$output -
	$(PDFINFO) $$output | $(GREP) "SILE v$(VERSION)"

.PHONY: docs
docs: $(_MANUAL) lua-api-docs

.PHONY: lua-api-docs
lua-api-docs: lua-api-docs/index.html documentation/lsp.html

documentation/lsp.html:
	$(LSP) --doc $(top_srcdir) |
		$(GREP) ': ' |
		$(AWK) -F'[][]' '{ print $$2 }' |
		while read resource; do
			case $$resource in
				*.json) cp $$resource $(@D) ;;
				*.md)
					$(PANDOC) $$resource --wrap none -o $(basename $(@F)).md
					$(PANDOC) $$resource -s -o $@
					;;
			esac
		done

lua-api-docs/index.html: build-aux/config.ld
	$(LDOC) -c build-aux/config.ld .

.PHONY: docs-figures
docs-figures: $(FIGURES)

# This is a monkey patch to figure out how many passes we have to to to
# garantee the TOC is up to date, simplify when #230 is fixed.
hastoc = [ -f $(subst .pdf,.toc,$@) ] && echo true || echo false
pages = $(PDFINFO) $@ | $(AWK) '$$1 == "Pages:" {print $$2}' || echo 0
localsile = $(LOCALFONTS) $(LOCALPATHS) ./$(bin_PROGRAMS) $(SILEFLAGS)
silepass = $(localsile) $< -o $@ && pg0=$${pg} pg=$$($(pages)) || false
define runsile =
	set -e
	pg=$$($(pages)) hadtoc=$$($(hastoc))
	$(MKDIR_P) $(DEPDIR)/$$(dirname $@)
	$(silepass)
	export -n SILE_COVERAGE
	if $$($(hastoc)) && ! $(DRAFT); then
		$${hadtoc} || $(silepass)
		[ "$${pg}" = "$${pg0}" ] || $(silepass)
	fi
endef

_FORCED = $(and $(SILE_COVERAGE)$(CLEAN),force)
_TEST_DEPS = $(and $$(filter tests/%,$@),$(addprefix .fonts/,$(TESTFONTFILES)))
_DOCS_DEPS = $(and $$(filter documentation/%,$@),$(addprefix .fonts/,$(DOCSFONTFILES)))

# TODO: remove _BUILT_SUBDIRS hack and replace it with something sensible when
# these subdirs don't do crazy things like copying files outside of their own trees!
_BUILT_SUBDIRS = .built-subdirs
_SUBDIR_TELLS =

if SHARED
_SUBDIR_TELLS += justenough/.libs/fontmetrics.$(SHARED_LIB_EXT) \
				justenough/.libs/justenoughfontconfig.$(SHARED_LIB_EXT) \
				justenough/.libs/justenoughharfbuzz.$(SHARED_LIB_EXT) \
				justenough/.libs/justenoughicu.$(SHARED_LIB_EXT) \
				justenough/.libs/justenoughlibtexpdf.$(SHARED_LIB_EXT) \
				justenough/.libs/svg.$(SHARED_LIB_EXT) \
				libtexpdf/.libs/libtexpdf.$(SHARED_LIB_EXT).0.0.0
endif

if STATIC
_SUBDIR_TELLS += justenough/.libs/fontmetrics.a \
				justenough/.libs/justenoughfontconfig.a \
				justenough/.libs/justenoughharfbuzz.a \
				justenough/.libs/justenoughicu.a \
				justenough/.libs/justenoughlibtexpdf.a \
				justenough/.libs/svg.a \
				libtexpdf/.libs/libtexpdf.a
endif

$(_BUILT_SUBDIRS): $(_SUBDIR_TELLS)
	touch $@

CLEANFILES += $(_BUILT_SUBDIRS)

$(_SUBDIR_TELLS):
	$(MAKE) $(AM_MAKEFLAGS) all-recursive

patterndeps = $(_FORCED) $(_TEST_DEPS) $(_DOCS_DEPS) | $(bin_PROGRAMS) $(DEPDIRS) $(LUAMODLOCK) $(_BUILT_SUBDIRS)

%.pdf: %.sil $$(patterndeps)
	$(runsile)

%.pdf: %.xml $$(patterndeps)
	$(runsile)

%.pdf: %.nil $$(patterndeps)
	$(runsile)

%.pdf: %.dot
	$(DOT) -Tpdf $< -o $@.gs
	$(GS) -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -o $@ $@.gs

.PHONY: force
force: ;

PHONY_DEVELOPER_TARGETS = busted compare coverage docker docker-build-push \
	docker-dep-check docker-ghcr-to-hub gource.webm lint luacheck luarocks-lint \
	prerelease regression_previews regressions release release-preview tagrelease \
	test update_expecteds update_libtexpdf
.PHONY: $(PHONY_DEVELOPER_TARGETS)

if DEVELOPER

RELTYPE ?=

tagrelease:
	test -z $$($(GIT) tag --points-at HEAD) || exit 0 # end if we are already on a release tag
	$(GIT) diff-index --quiet --cached HEAD || exit 1 # die if anything staged but not committed
	$(GIT) diff-files --quiet || exit 1 # die if any tracked files have unstagged changes
	$(NPM) run release -- $(and $(RELTYPE),--release-as $(RELTYPE))

prerelease: test docs update_libtexpdf

release-preview:
	$(NPM) run release -- --dry-run $(and $(RELTYPE),--release-as $(RELTYPE))

release: tagrelease

update_libtexpdf:
	$(GIT) diff-index --quiet --cached HEAD || exit 1 # die if anything already staged
	$(GIT) submodule update --init --remote -- libtexpdf
	$(NIX) flake lock --override-input libtexpdf-src github:sile-typesetter/libtexpdf/$(shell $(GIT) submodule status -- libtexpdf | awk '{print $$1}')
	$(GIT) add -- libtexpdf flake.lock
	$(GIT) diff-index --quiet --cached HEAD || $(GIT) commit -m "chore(build): Pin latest libtexpdf library submodule"

TESTPDFS   = $(addsuffix      .pdf,$(basename $(TESTSRCS)))
EXPECTEDS ?= $(filter $(addsuffix .expected,$(basename $(TESTSRCS))),$(TESTEXPECTS))
ACTUALS    = $(addsuffix   .actual,$(basename $(EXPECTEDS)))
CLEANFILES += $(TESTPDFS) $(ACTUALS)

REGRESSIONSCRIPT := ./tests/regressions.pl
BUSTEDFLAGS ?=

regressions: $(TESTSRCS) $(ACTUALS)
	$(LOCALFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

test: regressions busted

lint: luacheck luarocks-lint

luarocks-lint: $(LUAMODSPEC)
	$(LUAROCKS) lint $(LUAMODSPEC)

luacheck:
	$(LUACHECK) -j$(shell nproc) -q .

busted: $(SILELUA) $(addprefix .fonts/,$(TESTFONTFILES)) $(BUSTEDSPECS)
	set -f; IFS=';'
	packagepath=(./{,lua-libraries/}?{,/init}.lua)
	packagecpath=(./{,core/,{libtexpdf,justenough}/.libs/}?.$(SHARED_LIB_EXT))
if !SYSTEM_LUAROCKS
	packagepath+=(./lua_modules/share/lua/$(LUA_VERSION)/?{,/init}.lua)
	packagecpath+=(./lua_modules/lib/lua/$(LUA_VERSION)/?.$(SHARED_LIB_EXT))
endif
# Note: use of --lua causes this to be passed back through a shell loosing one layer of quoting. Drop single quotes if removing.
	$(LOCALFONTS) $(BUSTED) --lua=$(LUA) --lpath="'$${packagepath[*]};;'" --cpath="'$${packagecpath[*]};;'" $(BUSTEDFLAGS) .

coverage: export SILE_COVERAGE=1
coverage: BUSTEDFLAGS += -c
coverage: regression_previews busted

HEADSHA ?= HEAD
_HEADSHA ?= $(shell test -e .git && $(GIT) rev-parse --short=7 $(HEADSHA))
BASESHA ?= $(HEADSHA)^
_BASESHA ?= $(shell test -e .git && $(GIT) rev-parse --short=7 $(BASESHA))

clean-recursive: clean-tests

clean-tests:
	$(RM) -r tests/*.actual
	$(RM) -r $(DEPDIR)/tests/*

clean-recursive: clean-deps

clean-deps:
	$(RM) -r $(DEPDIR)

update_expecteds: $(EXPECTEDS)

tests/%.expected: tests/%.sil $$(patterndeps)
	$(localsile) -b debug $< -o $@

tests/%.expected: tests/%.xml $$(patterndeps)
	$(localsile) -b debug $< -o $@

tests/%.expected: tests/%.nil $$(patterndeps)
	$(localsile) -b debug $< -o $@

regression_previews: $(TESTPREVIEWS)

tests/%.actual: tests/%.sil $$(patterndeps)
	-$(if $(CLEAN),$(RM) $@,:)
	$(localsile) -b debug $< -o $@

tests/%.actual: tests/%.xml $$(patterndeps)
	-$(if $(CLEAN),$(RM) $@,:)
	$(localsile) -b debug $< -o $@

tests/%.actual: tests/%.nil $$(patterndeps)
	-$(if $(CLEAN),$(RM) $@,:)
	$(localsile) -b debug $< -o $@

DEPFILES = $(addsuffix .d,$(addprefix $(DEPDIR)/,$(basename $(TESTSRCS) $(MANUAL))))
DEPDIRS = $(sort $(dir $(DEPFILES)))
CLEANFILES += $(DEPFILES)

$(DEPDIRS): | Makefile-distfiles
	$(MKDIR_P) $@

$(DEPFILES): | $(DEPDIRS)

include $(wildcard $(DEPFILES))

export GHCR_REGISTRY ?= ghcr.io
export GHCR_REPO ?= sile-typesetter/$(TRANSFORMED_PACKAGE_NAME)

export DOCKER_REGISTRY ?= docker.io
export DOCKER_REPO ?= siletypesetter/$(TRANSFORMED_PACKAGE_NAME)
export DOCKER_TAG ?= HEAD

docker: Dockerfile hooks/build .version
	./hooks/build $(VERSION)

docker-dep-check: .docker_deps .aur_deps
	$(DIFF) -u $^

.docker_deps: hooks/build
	$(SHELL) -c 'source <($(SED) -nE "/^(RUN|'"'"')/{s/.*=/echo /;p}" $<)' | \
		$(TR) ' ' '\n' | \
		$(SORT) > $@

CLEANFILES += .docker_deps

.aur_deps:
	$(CURL) -Ls 'https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=sile-git' | \
		$(SED) -nE '/\bdepends =/{s/.*= //;p}' | \
		$(GREP) -vxE '(lua-.*|.*\.so|git|glibc)' | \
		$(SORT) > $@

CLEANFILES += .aur_deps

define docker_push =
	test -z "$(DOCKER_PAT)" || \
		$(DOCKER) login https://$(DOCKER_REGISTRY) -u $(DOCKER_USERNAME) -p $(DOCKER_PAT)
	$(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)
	if [[ "$(DOCKER_TAG)" == v*.*.* ]]; then \
		tag=$(DOCKER_TAG) ; \
		$(DOCKER) tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):latest ; \
		$(DOCKER) tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):$${tag//.*} ; \
		$(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_REPO):latest ; \
		$(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_REPO):$${tag//.*} ; \
	fi
endef

docker-ghcr-to-hub:
	$(DOCKER) pull $(GHCR_REGISTRY)/$(GHCR_REPO):$(DOCKER_TAG)
	$(DOCKER) tag  $(GHCR_REGISTRY)/$(GHCR_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)
	$(docker_push)

docker-build-push: docker
	$(DOCKER) tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)
	$(docker_push)

gource.webm:
	$(MKDIR_P) /tmp/gravatars
	magick documentation/sile-logo.pdf[0] -density 300 -colorspace RGB -negate -resize 50% /tmp/sile-logo.jpg
	$(GIT) log --pretty=format:"%an—%ae" | \
		$(SORT) -u | \
		while IFS=— read name email; do \
			test -f "/tmp/gravatars/$$name.jpg" || \
				$(CURL) -S "https://www.gravatar.com/avatar/$$(echo -n $$email | md5sum | cut -d\  -f1)?d=identicon&s=256" -o "/tmp/gravatars/$$name.jpg" ; \
		done ;\
	gource -a 0.2 -s 0.2 -i 0 --logo /tmp/sile-logo.jpg -b 000000 --max-file-lag 5 --hide filenames --date-format '%Y-%m-%d' --user-image-dir /tmp/gravatars --user-filter simoncozens --key -1920x1080 -o - | \
		ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libvpx -b 10000K $@

else !DEVELOPER

$(PHONY_DEVELOPER_TARGETS):
	@: $(error "Please reconfigure using --enable-developer to use developer tooling")

endif !DEVELOPER
