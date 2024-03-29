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

FIGURES = documentation/fig-input-to-output.pdf

MANUAL := documentation/sile.pdf
SILE := $(PACKAGE_NAME)

if MANUAL
_MANUAL = $(MANUAL)

endif

$(MANUAL): $(FIGURES)

nobase_dist_pkgdata_DATA = $(SILEDATA) $(LUALIBRARIES)
nobase_nodist_pkgdata_DATA = core/features.lua core/pathsetup.lua core/version.lua $(LUAMODULES)
dist_man_MANS = sile.1
dist_doc_DATA = README.md CHANGELOG.md
dist_pdf_DATA = $(_MANUAL)
dist_license_DATA = LICENSE lua-libraries/LICENSE-lunamark
bin_SCRIPTS = sile
EXTRA_DIST = spec tests documentation sile-dev-1.rockspec fontconfig.conf
EXTRA_DIST += Makefile-distfiles
EXTRA_DIST += build-aux/action-updater.js build-aux/decore-automake.sh build-aux/git-version-gen build-aux/list-dist-files.sh
EXTRA_DIST += Dockerfile build-aux/docker-bootstrap.sh build-aux/docker-fontconfig.conf hooks/build
EXTRA_DIST += default.nix flake.nix flake.lock shell.nix
EXTRA_DIST += package.json # imported by both Nix and Docker
EXTRA_DIST += $(MANUAL) $(FIGURES)

BUILT_SOURCES = .version core/features.lua core/pathsetup.lua core/version.lua Makefile-distfiles

CLEANFILES = $(bin_SCRIPTS) $(dist_man_MANS) $(BUILT_SOURCES) $(DEPFILES) $(ACTUALS) $(TESTPDFS) $(MANUAL) $(_BUILT_SUBDIRS) .version-prev

Makefile-distfiles: $(wildcard .version .tarball-version) | $(LUAMODLOCK)
	$(SHELL) build-aux/list-dist-files.sh > $@

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
	$(NIX) flake lock --override-input libtexpdf-src github:sile-typesetter/libtexpdf/$(shell $(GIT) submodule status -- libtexpdf | awk '{print $$1}')
	$(GIT) add -- libtexpdf flake.lock
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

%.pdf: %.dot
	$(DOT) -Tpdf $< -o $@.gs
	$(GS) -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -o $@ $@.gs

.PHONY: force
force: ;

PHONY_DEVELOPER_TARGETS = regressions test lint luarocks-lint luacheck busted coverage benchmark compare update_expecteds regression_previews docker docker-dep-check docker-ghcr-to-hub docker-build-push gource.webm
.PHONY: $(PHONY_DEVELOPER_TARGETS)

if DEVELOPER

regressions: $(TESTSRCS) $(ACTUALS)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

test: regressions busted

lint: luacheck luarocks-lint

luarocks-lint: $(LUAMODSPEC)
	$(LUAROCKS) lint $(LUAMODSPEC)

luacheck:
	$(LUACHECK) -j$(shell nproc) -q .

busted: $(SILE) $(addprefix .fonts/,$(TESTFONTFILES)) $(BUSTEDSPECS)
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
