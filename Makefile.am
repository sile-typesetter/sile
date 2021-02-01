ACLOCAL_AMFLAGS = -I m4
AUTOMAKE_OPTIONS = foreign

SHELL = bash
.ONESHELL:
.SECONDARY:
.SECONDEXPANSION:
.DELETE_ON_ERROR:

if SYSTEM_LIBTEXPDF
SUBDIRS = src
else
SUBDIRS = libtexpdf src
endif

# Rules for installing LuaRocks locally as pkgdata_DATA
include Makefile-luarocks

# Actual rules for downloading test fonts are in a separate file
include Makefile-fonts

# Since we can't use $(wildcard ...) in automake file lists, we generate a file
# with a script that builds our dynamic file lists instead. This is tricky,
# because if we just include the file automake will flatten this include. By
# using $(wildcard ...) to include it (the very function we couldn't use because
# of the race condition it creates) we actually keep it from being flattened and
# hence evaluated when we want it to be. Since the file always exists (see
# BUILT_SOURCES and EXTRA_DIST) this doesn't induce a race.
include $(wildcard Makefile-distfiles)

MANUAL = documentation/sile.pdf
EXAMPLES = $(addsuffix .pdf,$(basename $(EXAMPLESSRCS)))

if MANUAL
_MANUAL = $(MANUAL)
endif

if EXAMPLES
_EXAMPLES = $(EXAMPLES)
endif

licensedir = $(datarootdir)/licenses/sile

nobase_dist_pkgdata_DATA = $(SILEDATA) $(LUALIBRARIES)
nobase_nodist_pkgdata_DATA = $(LUAMODULES)
dist_man_MANS = sile.1
dist_doc_DATA = README.md CHANGELOG.md
dist_pdf_DATA = $(_MANUAL)
dist_license_DATA = LICENSE
nobase_dist_pdf_DATA = $(_EXAMPLES)
bin_SCRIPTS = sile
EXTRA_DIST = spec tests examples documentation sile-dev-1.rockspec fontconfig.conf
EXTRA_DIST += .version Makefile-distfiles
EXTRA_DIST += build-aux/decore-automake.sh build-aux/git-version-gen build-aux/list-dist-files.sh
EXTRA_DIST += $(MANUAL) $(EXAMPLES)

Makefile-distfiles: build-aux/list-dist-files.sh $(wildcard .version .tarball-version) | $(LUAMODLOCK)
	$< 2>/dev/null > $@

BUILT_SOURCES = .version Makefile-distfiles

.version: $(shell test -e .git && awk '{print ".git/" $$2}' .git/HEAD)
	mv $@{,-prev} 2>/dev/null || touch $@-prev
	( test -e .git && ./build-aux/git-version-gen .tarball-version || echo $(VERSION) ) > $@
	cmp -s $@{,-prev} || autoreconf configure.ac --force -W none
	build-aux/decore-automake.sh

dist-hook: $(MANUAL) $(EXAMPLES)
	cd $(distdir)
	sed -i -e '/^LUAMODULES =/s/=.*/=/' Makefile-distfiles
	echo $(VERSION) > .tarball-version
	build-aux/decore-automake.sh
	sed -i -e '/^LUAMODULES/d;/^\tlua_modules/d' Makefile.in

# Whether to force tests to run from scratch
CLEAN ?=

RELTYPE ?=

.PHONY: tagrelease
tagrelease:
	test -z $$(git tag --points-at HEAD) || exit 0 # end if we are already on a release tag
	git diff-index --quiet --cached HEAD || exit 1 # die if anything staged but not committed
	git diff-files --quiet || exit 1 # die if any tracked files have unstagged changes
	npm run release -- $(and $(RELTYPE),--release-as $(RELTYPE))

.PHONY: prerelease
prerelease: test examples docs update_libtexpdf

.PHONY: release-preview
release-preview:
	npm run release -- --dry-run $(and $(RELTYPE),--release-as $(RELTYPE))

.PHONY: release
release: tagrelease

dist: sile-$(VERSION).pdf sile-$(VERSION).md

sile-$(VERSION).pdf: $(MANUAL)
	cp $< $@

sile-%.md: CHANGELOG.md
	sed -e '/\.\.\.v$*/,/\.\.\.v/!d' $< |
		sed -e '1,3d;N;$$!P;$$!D;$$d' > $@

.PHONY: update_libtexpdf
update_libtexpdf:
	git diff-index --quiet --cached HEAD || exit 1 # die if anything already staged
	git submodule update --init --remote -- libtexpdf
	git add -- libtexpdf
	git diff-index --quiet --cached HEAD || git commit -m "chore(build): Pin latest libtexpdf library submodule"

gh-pages:
	git worktree add -f $@ $@

DEPDIR := .deps
REGRESSIONSCRIPT := ./tests/regressions.pl
LOCALTESTFONTS := FONTCONFIG_FILE=$(PWD)/fontconfig.conf
SILEFLAGS ?= -m $(DEPDIR)/$(basename $@).d -d versions -f fontconfig

TESTPDFS   = $(addsuffix      .pdf,$(basename $(TESTSRCS)))
EXPECTEDS ?= $(filter $(addsuffix .expected,$(basename $(TESTSRCS))),$(TESTEXPECTS))
ACTUALS    = $(addsuffix   .actual,$(basename $(EXPECTEDS)))

check: selfcheck

.PHONY: selfcheck
selfcheck: | $(_BUILT_SUBDIRS)
	output=$$(mktemp --suffix=.pdf)
	trap 'rm -f $$output' EXIT SIGHUP SIGTERM
	./sile -o $$output - <<< "<sile>foo</sile>"
	pdfinfo $$output | grep "SILE v@VERSION@"

.PHONY: regressions
regressions: $(TESTSRCS) $(ACTUALS)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

.PHONY: test
test: regressions busted

.PHONY: lint
lint: luacheck luarocks-lint

.PHONY: luarocks-lint
luarocks-lint: $(LUAMODSPEC)
	luarocks lint $<

.PHONY: luacheck
luacheck:
	luacheck -j$(shell nproc) -q .

.PHONY: busted
busted: sile $(addprefix .fonts/,$(TESTFONTFILES))
	set -f; IFS=';'
if SYSTEM_LUAROCKS
	packagecpath=(./{,core/}?.$(SHARED_LIB_EXT))
	packagepath=(./{,lua-libraries/}?{,/init}.lua)
else
	packagecpath=(./{,core/,lua_modules/lib/lua/$(LUA_VERSION)/}?.$(SHARED_LIB_EXT))
	packagepath=(./{,lua_modules/share/lua/$(LUA_VERSION)/,lua-libraries/}?{,/init}.lua)
endif
	$(LOCALTESTFONTS) busted --cpath="$${packagecpath[*]};;" --lpath="$${packagepath[*]};;" spec

.PHONY: docs
docs: $(MANUAL)

.PHONY: examples
examples: $(EXAMPLES)

# This is a monkey patch to figure out how many passes we have to to to
# garantee the TOC is up to date, simplify when #230 is fixed.
hastoc = [[ -f $(subst .pdf,.toc,$@) ]] && echo true || echo false
pages = pdfinfo $@ | awk '$$1 == "Pages:" {print $$2}' || echo 0
silepass = $(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@ && pg0=$${pg} pg=$$($(pages))
define runsile =
	pg0=$$($(pages)) hadtoc=$$($(hastoc))
	mkdir -p $(DEPDIR)/$$(dirname $@)
	$(silepass)
	export -n SILE_COVERAGE
	if $(hastoc); then
		$${hadtoc} || $(silepass)
		[[ $${pg} -gt $${pg0} ]] && $(silepass) ||:
	fi
endef

_FORCED = $(and $(SILE_COVERAGE)$(CLEAN),force)
_TEST_DEPS = $(and $$(filter tests/%,$@),$(addprefix .fonts/,$(TESTFONTFILES)))
_DOCS_DEPS = $(and $$(filter documentation/%,$@),$(addprefix .fonts/,$(DOCSFONTFILES)))
_EXAM_DEPS = $(and $$(filter examples/%,$@),$(addprefix .fonts/,$(EXAMFONTFILES)))

# TODO: remove _BUILT_SUBDIRS hack and replace it with something sensible when
# these subdirs don't do crazy things like copying files outside of their own trees!
_BUILT_SUBDIRS = .built-subdirs
_SUBDIR_TELLS = core/justenoughharfbuzz.so libtexpdf/.libs/libtexpdf.so.0.0.0
$(_BUILT_SUBDIRS): $(_SUBDIR_TELLS)
	touch $@

$(_SUBDIR_TELLS):
	$(MAKE) $(AM_MAKEFLAGS) all-recursive
#	$(error Running `make install`, `make dist`, or other end-game targets before `make all` unspported.)

patterndeps = $(_FORCED) $(_TEST_DEPS) $(_EXAM_DEPS) $(_DOCS_DEPS) | $(DEPDIRS) $(LUAMODLOCK) $(_BUILT_SUBDIRS)

%.pdf: %.sil $$(patterndeps)
	$(runsile)

%.pdf: %.xml $$(patterndeps)
	$(runsile)

examples/docbook/article-template.pdf: SILEFLAGS += -I docbook.sil

.PHONY: coverage
coverage: export SILE_COVERAGE=1
coverage: regression_previews busted

HEADSHA ?= HEAD
_HEADSHA ?= $(shell test -e .git && git rev-parse --short=7 $(HEADSHA))
BASESHA ?= $(HEADSHA)^
_BASESHA ?= $(shell test -e .git && git rev-parse --short=7 $(BASESHA))

clean-recursive: clean-tests

.PHONY: clean-tests
clean-tests:
	rm -rf tests/*.actual
	rm -rf $(DEPDIR)/tests/*

clean-recursive: clean-deps

.PHONY: clean-deps
clean-deps:
	rm -rf $(DEPDIR)

time-%.json: benchmark-%/time.json
	cp $< $@

clean-recursive: clean-worktrees

.PHONY: clean-worktrees
clean-worktrees:
	if test -e .git; then
		git worktree list --porcelain |
			awk 'BEGIN { FS = "/" }; /^worktree .*-[0-9a-f]{7}/ { print $$(NF) }' |
			while read worktree; do
				git worktree remove --force $${worktree}
			done
	fi

time_action ?= ./sile documentation/sile.sil -o /dev/null
make_worktree_rules = $(eval $(foreach SHA,$(_HEADSHA) $(_BASESHA),$(call worktree_sha,$(1),$(shell git rev-parse --short=7 $(SHA)))))

define worktree_sha =

.PRECIOUS: $(1)-$(2)
$(1)-$(2):
	[[ -d $$@ ]] || git worktree add --detach $$@ $(2)
	cd $$@
	[[ -d libtexpdf ]] && rmdir libtexpdf
	[[ -h libtexpdf ]] || ln -s ../libtexpdf
	[[ -h lua_modules ]] || ln -s ../lua_modules
	[[ -h node_modules ]] || ln -s ../node_modules
	[[ -h .fonts ]] || ln -s ../.fonts
	[[ -h .sources ]] || ln -s ../.sources
	./bootstrap.sh
	cp ../config.status .
	./configure
	make

.PRECIOUS: $(1)-$(2)/%
$(1)-$(2)/%: $(1)-$(2)
	cd $$<
	make $$*

.PRECIOUS: $(1)-$(2)/time.json
$(1)-$(2)/time.json: $(1)-$(2) force
	cd $$<
	export TIMEFORMAT=$$$$'{ "real": "%R", "user": "%U", "sys": "%S" }'
	{ time ($$(time_action) > /dev/null 2>&1) } 2> time.json

endef

$(call make_worktree_rules,benchmark)

.PHONY: benchmark
benchmark: time-$(_HEADSHA).json time-$(_BASESHA).json
	head $^

.PRECIOUS: time-%.json
time-%.json: benchmark-%/time.json
	cp $< $@

.PRECIOUS: time.json
time.json: force | $(_BUILT_SUBDIRS)
	export TIMEFORMAT=$$'{ "real": "%R", "user": "%U", "sys": "%S" }'
	{ time ($(time_action) > /dev/null 2>&1) } 2> time.json

$(call make_worktree_rules,compare)

onetest = $(firstword $(ACTUALS)),$(firstword $(TESTPDFS))
compare_prerequisites = $(sort $(shell echo {compare-$(_BASESHA)/,}{$(onetest)}))

runapp ?= nohup $(1) > /dev/null &
compare: $(call compare_prerequisites)
	$(call runapp,diff-pdf --view $(filter %.pdf,$^))
	$(call runapp,zathura $(filter %.pdf,$^))
	diff -u $(filter %.actual,$^)

.PHONY: force
force: ;

.PHONY: update_expecteds
update_expecteds: $(EXPECTEDS)

tests/%.expected: tests/%.sil $$(patterndeps)
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.expected: tests/%.xml $$(patterndeps)
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

.PHONY: update_actuals
update_actuals: $(ACTUALS)

.PHONY: regression_previews
regression_previews: $(TESTPDFS)

tests/%.actual: tests/%.sil $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.actual: tests/%.xml $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

DEPFILES = $(addsuffix .d,$(addprefix $(DEPDIR)/,$(basename $(TESTSRCS) $(MANUAL) $(EXAMPLES))))
DEPDIRS = $(sort $(dir $(DEPFILES)))

$(DEPDIRS): | Makefile-distfiles
	mkdir -p $@

$(DEPFILES): | $(DEPDIRS)

include $(wildcard $(DEPFILES))

.fonts: fontconfig.conf
	[[ -h .fonts ]] || mkdir -p $@

.sources:
	[[ -h .sources ]] || mkdir -p $@

CLEANFILES = $(bin_SCRIPTS) $(dist_man_MANS) $(DEPFILES) $(ACTUALS) $(TESTPDFS) $(MANUAL) Makefile-distfiles $(_BUILT_SUBDIRS)

.PHONY: docker
docker: Dockerfile
	docker build \
		--build-arg VCS_REF="$(VERSION)" \
		--tag siletypesetter/sile:HEAD \
		./

gource.webm:
	mkdir -p /tmp/gravatars
	convert examples/images/sile-logo.jpg -negate -resize 50% /tmp/sile-logo.jpg
	git log --pretty=format:"%an—%ae" | \
		sort -u | \
		while IFS=— read name email; do \
			test -f "/tmp/gravatars/$$name.jpg" || curl -S "https://www.gravatar.com/avatar/$$(echo -n $$email | md5sum | cut -d\  -f1)?d=identicon&s=256" -o "/tmp/gravatars/$$name.jpg" ;\
		done
	gource -a 0.2 -s 0.2 -i 0 --logo /tmp/sile-logo.jpg -b 000000 --max-file-lag 5 --hide filenames --date-format '%Y-%m-%d' --user-image-dir /tmp/gravatars --user-filter simoncozens --key -1920x1080 -o - \
		| ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libvpx -b 10000K $@

# vim: ft=make
