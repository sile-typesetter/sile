ACLOCAL_AMFLAGS = -I build-aux

.ONESHELL:
.SECONDARY:
.SECONDEXPANSION:
.DELETE_ON_ERROR:

if SYSTEM_LIBTEXPDF
SUBDIRS = src
else
SUBDIRS = libtexpdf src
endif

licensedir = $(datarootdir)/licenses/$(TRANSFORMED_PACKAGE_NAME)
docdir = $(datarootdir)/doc/$(TRANSFORMED_PACKAGE_NAME)
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

MANUAL := documentation/sile.pdf
SILELUA := $(PACKAGE_NAME)-lua

if MANUAL
_MANUAL = $(MANUAL)
endif

nobase_dist_pkgdata_DATA = $(SILEDATA) $(LUALIBRARIES)
nobase_nodist_pkgdata_DATA = core/features.lua core/version.lua $(LUAMODULES)
dist_man_MANS = sile.1 sile-lua.1
dist_doc_DATA = README.md CHANGELOG.md
dist_pdf_DATA = $(_MANUAL)
dist_license_DATA = LICENSE lua-libraries/LICENSE-lunamark
bin_SCRIPTS = sile-lua
bin_PROGRAMS = sile
sile_SOURCES = Cargo.toml build-aux/build.rs src/bin/sile.rs src/lib.rs src/cli.rs
EXTRA_sile_SOURCES = Cargo.lock .version
EXTRA_DIST = spec tests documentation sile-dev-1.rockspec fontconfig.conf
EXTRA_DIST += Makefile-distfiles
EXTRA_DIST += build-aux/action-updater.js build-aux/decore-automake.sh build-aux/git-version-gen build-aux/list-dist-files.sh
EXTRA_DIST += Dockerfile build-aux/docker-bootstrap.sh build-aux/docker-fontconfig.conf hooks/build
EXTRA_DIST += default.nix flake.nix flake.lock libtexpdf.git-rev shell.nix
EXTRA_DIST += package.json # imported by both Nix and Docker
EXTRA_DIST += $(MANUAL)

BUILT_SOURCES = .version core/features.lua core/pathsetup.lua core/version.lua Makefile-distfiles

CLEANFILES = $(bin_SCRIPTS) $(dist_man_MANS) $(BUILT_SOURCES) $(DEPFILES) $(ACTUALS) $(TESTPDFS) $(MANUAL) $(_BUILT_SUBDIRS) .version-prev

Makefile-distfiles: $(wildcard .version .tarball-version) | $(LUAMODLOCK)
	$(SHELL) build-aux/list-dist-files.sh > $@

if DEBUG_RELEASE
CARGO_RELEASE_ARGS =
else
CARGO_RELEASE_ARGS = --release --locked
endif

if LUAJIT
MLUAVER = luajit
else
MLUAVER = lua$(LUA_SHORT_VERSION)
endif
CARGO_FEATURE_ARGS = --features $(MLUAVER)

CARGO_ENV = CARGO_TARGET_DIR=@abs_top_builddir@/target
RUST_BIN = @abs_top_builddir@/target/@RUST_TARGET_SUBDIR@/$(PACKAGE_NAME)
_RUST_OUT = @abs_top_builddir@/target/@RUST_TARGET_SUBDIR@/.cargo_out_dir
COMPLETIONS_OUT_DIR = completions

if ENABLE_BASH_COMPLETION
bashcompletiondir = $(BASH_COMPLETION_DIR)
nodist_bashcompletion_DATA = $(COMPLETIONS_OUT_DIR)/$(TRANSFORMED_PACKAGE_NAME)
CLEANFILES += $(nodist_bashcompletion_DATA)
endif

if ENABLE_FISH_COMPLETION
fishcompletiondir = $(FISH_COMPLETION_DIR)
nodist_fishcompletion_DATA = $(COMPLETIONS_OUT_DIR)/$(TRANSFORMED_PACKAGE_NAME).fish
CLEANFILES += $(nodist_fishcompletion_DATA)
endif

if ENABLE_ZSH_COMPLETION
zshcompletiondir = $(ZSH_COMPLETION_DIR)
nodist_zshcompletion_DATA = $(COMPLETIONS_OUT_DIR)/_$(TRANSFORMED_PACKAGE_NAME)
CLEANFILES += $(nodist_zshcompletion_DATA)
endif

export SILE_VERSION = v$(VERSION)
SILE := $(PACKAGE_NAME)$(EXEEXT)

# Leave some tips for cargo to use so CLI knows where it is
export CONFIGURE_PREFIX = $(prefix)/
export CONFIGURE_DATADIR = $(datadir)/
export CONFIGURE_BINDIR = $(bindir)/

CARGO_VERBOSE = $(cargo_verbose_$(V))
cargo_verbose_ = $(cargo_verbose_$(AM_DEFAULT_VERBOSITY))
cargo_verbose_0 =
cargo_verbose_1 = --verbose

$(COMPLETIONS_OUT_DIR):
	$(MKDIR_P) $@

$(SILE): $(RUST_BIN)
	$(INSTALL) $(RUST_BIN) $@

$(PACKAGE_NAME).1: $(RUST_BIN)
	$(INSTALL) -D $$(cat $(_RUST_OUT))/$@ $@

$(COMPLETIONS_OUT_DIR)/$(TRANSFORMED_PACKAGE_NAME): $(RUST_BIN) | $(COMPLETIONS_OUT_DIR)
	$(INSTALL) -D $$(cat $(_RUST_OUT))/$(COMPLETIONS_OUT_DIR)/$(PACKAGE_NAME).bash $@

$(COMPLETIONS_OUT_DIR)/$(TRANSFORMED_PACKAGE_NAME).elv: $(RUST_BIN) | $(COMPLETIONS_OUT_DIR)
	$(INSTALL) -D $$(cat $(_RUST_OUT))/$(COMPLETIONS_OUT_DIR)/$(PACKAGE_NAME).elv $@

$(COMPLETIONS_OUT_DIR)/$(TRANSFORMED_PACKAGE_NAME).fish: $(RUST_BIN) | $(COMPLETIONS_OUT_DIR)
	$(INSTALL) -D $$(cat $(_RUST_OUT))/$(COMPLETIONS_OUT_DIR)/$(PACKAGE_NAME).fish $@

$(COMPLETIONS_OUT_DIR)/_$(TRANSFORMED_PACKAGE_NAME).ps1: $(RUST_BIN) | $(COMPLETIONS_OUT_DIR)
	$(INSTALL) -D $$(cat $(_RUST_OUT))/$(COMPLETIONS_OUT_DIR)/_$(PACKAGE_NAME).ps1 $@

$(COMPLETIONS_OUT_DIR)/_$(TRANSFORMED_PACKAGE_NAME): $(RUST_BIN) | $(COMPLETIONS_OUT_DIR)
	$(INSTALL) -D $$(cat $(_RUST_OUT))/$(COMPLETIONS_OUT_DIR)/_$(PACKAGE_NAME) $@

$(_RUST_OUT) $(RUST_BIN): $(sile_SOURCES) $(EXTRA_sile_SOURCES)
	cd $(top_srcdir)
	$(CARGO_ENV) $(CARGO) build $(CARGO_VERBOSE) $(CARGO_FEATURE_ARGS) $(CARGO_RELEASE_ARGS)
	$(CARGO_ENV) $(CARGO) build --quiet --message-format=json $(CARGO_FEATURE_ARGS) $(CARGO_RELEASE_ARGS) |
		$(JQ) -sr 'map(select(.reason == "build-script-executed")) | last | .out_dir' > $(_RUST_OUT)

_BRANCH_REF != $(AWK) '{print ".git/" $$2}' .git/HEAD 2>/dev/null ||:

.version: $(_BRANCH_REF)
	@if [ -e "$(srcdir)/.tarball-version" ]; then \
		printf "$(VERSION)" > $@; \
	else \
		touch "$@-prev"; \
		if [ -e "$@" ]; then \
			cp "$@" "$@-prev"; \
		fi; \
		./build-aux/git-version-gen "$(srcdir)/.tarball-version" > $@; \
		cmp -s "$@" "$@-prev" || ( autoreconf configure.ac --force && build-aux/decore-automake.sh ); \
	fi

libtexpdf.git-rev: $(_BRANCH_REF)
	$(GIT) submodule status -- libtexpdf | $(AWK) '{ print $$1 }' > $@

dist-hook: $(MANUAL)
	cd $(distdir)
	printf "$(VERSION)" > .tarball-version
	$(SED) -i -e '/^LUAMODULES =/s/=.*/=/' Makefile-distfiles
	$(top_srcdir)/build-aux/decore-automake.sh
	$(SED) -i -e '/^LUAMODULES/d;/^\tlua_modules/d' Makefile.in

# Whether to force tests to run from scratch
CLEAN ?=

RELTYPE ?=

.PHONY: tagrelease
tagrelease:
	test -z $$($(GIT) tag --points-at HEAD) || exit 0 # end if we are already on a release tag
	$(GIT) diff-index --quiet --cached HEAD || exit 1 # die if anything staged but not committed
	$(GIT) diff-files --quiet || exit 1 # die if any tracked files have unstagged changes
	npm run release -- $(and $(RELTYPE),--release-as $(RELTYPE))

.PHONY: prerelease
prerelease: test docs update_libtexpdf

.PHONY: release-preview
release-preview:
	npm run release -- --dry-run $(and $(RELTYPE),--release-as $(RELTYPE))

.PHONY: release
release: tagrelease

dist: sile-$(VERSION).pdf sile-$(VERSION).md

sile-$(VERSION).pdf: $(MANUAL)
	cp $(MANUAL) $@

sile-%.md: CHANGELOG.md
	$(SED) -e '/\.\.\.v$*/,/\.\.\.v/!d' CHANGELOG.md | \
		$(SED) -e '1,3d;N;$$!P;$$!D;$$d' > $@

.PHONY: update_libtexpdf
update_libtexpdf:
	$(GIT) diff-index --quiet --cached HEAD || exit 1 # die if anything already staged
	$(GIT) submodule update --init --remote -- libtexpdf
	$(GIT) submodule status -- libtexpdf | $(AWK) '{ print $$1 }' > libtexpdf.git-rev
	$(GIT) add -- libtexpdf libtexpdf.git-rev
	$(GIT) diff-index --quiet --cached HEAD || $(GIT) commit -m "chore(build): Pin latest libtexpdf library submodule"

DEPDIR := .deps
REGRESSIONSCRIPT := ./tests/regressions.pl
LOCALTESTFONTS := FONTCONFIG_FILE=$(PWD)/fontconfig.conf
SILEFLAGS ?= -m $(DEPDIR)/$(basename $@).d -d versions -f fontconfig
BUSTEDFLAGS ?= $(and $(SILE_COVERAGE),-c)

TESTPDFS   = $(addsuffix      .pdf,$(basename $(TESTSRCS)))
EXPECTEDS ?= $(filter $(addsuffix .expected,$(basename $(TESTSRCS))),$(TESTEXPECTS))
ACTUALS    = $(addsuffix   .actual,$(basename $(EXPECTEDS)))

check: selfcheck

.PHONY: selfcheck
selfcheck: | $(_BUILT_SUBDIRS)
	output=$$(mktemp -t selfcheck-XXXXXX.pdf)
	trap 'rm -f $$output' EXIT HUP TERM
	echo "<sile>foo</sile>" | ./$(SILE) -o $$output -
	$(PDFINFO) $$output | $(GREP) "SILE v$(VERSION)"

.PHONY: docs
docs: $(MANUAL)

# This is a monkey patch to figure out how many passes we have to to to
# garantee the TOC is up to date, simplify when #230 is fixed.
hastoc = [ -f $(subst .pdf,.toc,$@) ] && echo true || echo false
pages = $(PDFINFO) $@ | $(AWK) '$$1 == "Pages:" {print $$2}' || echo 0
silepass = $(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) $< -o $@ && pg0=$${pg} pg=$$($(pages)) || false
define runsile =
	set -e
	pg=$$($(pages)) hadtoc=$$($(hastoc))
	mkdir -p $(DEPDIR)/$$(dirname $@)
	$(silepass)
	export -n SILE_COVERAGE
	if $(hastoc); then
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
_SUBDIR_TELLS = justenoughfontconfig.so justenoughharfbuzz.so justenoughicu.so justenoughlibtexpdf.so libtexpdf/.libs/libtexpdf.so.0.0.0
$(_BUILT_SUBDIRS): $(_SUBDIR_TELLS)
	touch $@

$(_SUBDIR_TELLS):
	$(MAKE) $(AM_MAKEFLAGS) all-recursive
#	$(error Running `make install`, `make dist`, or other end-game targets before `make all` unspported.)

patterndeps = $(_FORCED) $(_TEST_DEPS) $(_DOCS_DEPS) | $(DEPDIRS) $(LUAMODLOCK) $(_BUILT_SUBDIRS)

%.pdf: %.sil $$(patterndeps)
	$(runsile)

%.pdf: %.xml $$(patterndeps)
	$(runsile)

%.pdf: %.nil $$(patterndeps)
	$(runsile)

.PHONY: force
force: ;

PHONY_DEVELOPER_TARGETS = regressions test lint luarocks-lint luacheck rustfmt clippy cargo-test busted coverage benchmark compare update_expecteds regression_previews docker docker-dep-check docker-ghcr-to-hub docker-build-push gource.webm
.PHONY: $(PHONY_DEVELOPER_TARGETS)

if DEVELOPER

regressions: $(TESTSRCS) $(ACTUALS)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

test: regressions busted cargo-test

lint: luacheck luarocks-lint rustfmt clippy

luarocks-lint: $(LUAMODSPEC)
	$(LUAROCKS) lint $(LUAMODSPEC)

luacheck:
	$(LUACHECK) -j$(shell nproc) -q .

rustfmt:
	$(GIT) ls-files '*.rs' | $(XARGS) rustfmt --check

clippy:
	cd $(srcdir)
	$(CARGO_ENV) $(CARGO) $(CARGO_VERBOSE) clippy $(CARGO_FEATURE_ARGS) -- -D warnings

cargo-test: $(SILE)
	cd $(srcdir)
	$(CARGO_ENV) $(CARGO) $(CARGO_VERBOSE) test $(CARGO_FEATURE_ARGS) --locked

busted: $(SILELUA) $(addprefix .fonts/,$(TESTFONTFILES)) $(BUSTEDSPECS)
	set -f; IFS=';'
if SYSTEM_LUAROCKS
	packagecpath=(./{,core/}?.$(SHARED_LIB_EXT))
	packagepath=(./{,lua-libraries/}?{,/init}.lua)
else
	packagecpath=(./{,core/,lua_modules/lib/lua/$(LUA_VERSION)/}?.$(SHARED_LIB_EXT))
	packagepath=(./{,lua_modules/share/lua/$(LUA_VERSION)/,lua-libraries/}?{,/init}.lua)
endif
	$(LOCALTESTFONTS) $(BUSTED) --cpath="$${packagecpath[*]};;" --lpath="$${packagepath[*]};;" $(BUSTEDFLAGS) .

coverage: export SILE_COVERAGE=1
coverage: BUSTEDFLAGS = -c
coverage: regression_previews busted

HEADSHA ?= HEAD
_HEADSHA ?= $(shell test -e .git && $(GIT) rev-parse --short=7 $(HEADSHA))
BASESHA ?= $(HEADSHA)^
_BASESHA ?= $(shell test -e .git && $(GIT) rev-parse --short=7 $(BASESHA))

clean-recursive: clean-tests

clean-tests:
	rm -rf tests/*.actual
	rm -rf $(DEPDIR)/tests/*

clean-recursive: clean-deps

clean-deps:
	rm -rf $(DEPDIR)

time-%.json: benchmark-%/time.json
	cp $< $@

update_expecteds: $(EXPECTEDS)

tests/%.expected: tests/%.sil $$(patterndeps)
	$(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) -b debug $< -o $@

tests/%.expected: tests/%.xml $$(patterndeps)
	$(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) -b debug $< -o $@

tests/%.expected: tests/%.nil $$(patterndeps)
	$(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) -b debug $< -o $@

regression_previews: $(TESTPREVIEWS)

tests/%.actual: tests/%.sil $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) -b debug $< -o $@

tests/%.actual: tests/%.xml $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) -b debug $< -o $@

tests/%.actual: tests/%.nil $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./$(SILE) $(SILEFLAGS) -b debug $< -o $@

DEPFILES = $(addsuffix .d,$(addprefix $(DEPDIR)/,$(basename $(TESTSRCS) $(MANUAL))))
DEPDIRS = $(sort $(dir $(DEPFILES)))

$(DEPDIRS): | Makefile-distfiles
	mkdir -p $@

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
	diff -u $^

CLEANFILES += .docker_deps
.docker_deps: hooks/build
	$(SHELL) -c 'source <($(SED) -nE "/^(RUN|'"'"')/{s/.*=/echo /;p}" $<)' | \
		tr ' ' '\n' | \
		sort > $@

CLEANFILES += .aur_deps
.aur_deps:
	curl -Ls 'https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=sile-git' | \
		$(SED) -nE '/\bdepends =/{s/.*= //;p}' | \
		$(GREP) -vxE '(lua-.*|.*\.so|git|glibc)' | \
		sort > $@

define docker_push =
	test -z "$(DOCKER_PAT)" || \
		docker login https://$(DOCKER_REGISTRY) -u $(DOCKER_USERNAME) -p $(DOCKER_PAT)
	docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)
	if [[ "$(DOCKER_TAG)" == v*.*.* ]]; then \
		tag=$(DOCKER_TAG) ; \
		docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):latest ; \
		docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):$${tag//.*} ; \
		docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO):latest ; \
		docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO):$${tag//.*} ; \
	fi
endef

docker-ghcr-to-hub:
	docker pull $(GHCR_REGISTRY)/$(GHCR_REPO):$(DOCKER_TAG)
	docker tag  $(GHCR_REGISTRY)/$(GHCR_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)
	$(docker_push)

docker-build-push: docker
	docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)
	$(docker_push)

gource.webm:
	mkdir -p /tmp/gravatars
	magick documentation/sile-logo.pdf[0] -density 300 -colorspace RGB -negate -resize 50% /tmp/sile-logo.jpg
	$(GIT) log --pretty=format:"%an—%ae" | \
		sort -u | \
		while IFS=— read name email; do \
			test -f "/tmp/gravatars/$$name.jpg" || \
				curl -S "https://www.gravatar.com/avatar/$$(echo -n $$email | md5sum | cut -d\  -f1)?d=identicon&s=256" -o "/tmp/gravatars/$$name.jpg" ; \
		done ;\
	gource -a 0.2 -s 0.2 -i 0 --logo /tmp/sile-logo.jpg -b 000000 --max-file-lag 5 --hide filenames --date-format '%Y-%m-%d' --user-image-dir /tmp/gravatars --user-filter simoncozens --key -1920x1080 -o - | \
		ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libvpx -b 10000K $@

else

$(PHONY_DEVELOPER_TARGETS):
	@: $(error "Please reconfigure using --enable-developer to use developer tooling")

endif
