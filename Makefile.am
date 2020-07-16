ACLOCAL_AMFLAGS = -I m4
AUTOMAKE_OPTIONS = foreign

if SYSTEM_LIBTEXPDF
SUBDIRS = src
else
SUBDIRS = libtexpdf src
endif

SUPPORTED_LUAS = 5.3 5.2 5.1

MANUAL = documentation/sile.pdf

Makefile-distfiles: build-aux/list-dist-files.sh .version
	$< 2>/dev/null > $@

include Makefile-distfiles

dist_man_MANS = sile.1
dist_doc_DATA = README.md CHANGELOG.md
bin_SCRIPTS = sile
EXTRA_DIST = LICENSE spec tests examples documentation sile-dev-1.rockspec build-aux/git-version-gen .version fontconfig.conf Makefile-distfiles
EXTRA_DIST += $(extra_dist) $(MANUAL) $(EXAMPLES)

SHELL = bash
.ONESHELL:
.SECONDARY:
.SECONDEXPANSION:
.DELETE_ON_ERROR:
am__remove_distdir =

if !SYSTEM_LUAROCKS
LUAROCKS := luarocks --tree lua_modules --lua-version $(LUA_VERSION)
LUAMODLOCK := sile-dev-1.rockslock
LUAMODSPEC := sile-dev-1.rockspec
genrockslock := $(LUAROCKS) $(LUAROCKSARGS) list --porcelain | awk '{print $$1 " " $$2}'
rocksmatch := cmp -s $(LUAMODLOCK) <($(genrockslock))
else
LUAROCKS := luarocks --tree lua_modules_dist --lua-version $(LUA_VERSION)
endif

BUILT_SOURCES = .version

.version: $(shell test -e .git && awk '{print ".git/" $$2}' .git/HEAD)
	mv $@{,-prev} 2>/dev/null || touch $@-prev
	( test -e .git && ./build-aux/git-version-gen .tarball-version || echo $(VERSION) ) > $@
	cmp -s $@{,-prev} || autoreconf configure.ac --force -W none
	sed -i -e '/rm -f/s/ core / /' configure aclocal.m4 ||:

dist-hook: lua_modules_dist $(MANUAL) $(EXAMPLES)
	echo $(VERSION) > $(distdir)/.tarball-version
	sed -i -e '/rm -f/s/ core / /' configure aclocal.m4 ||:

if MANUAL
install-data-hook: $(MANUAL)
endif

if EXAMPLES
install-data-hook: $(EXAMPLES)
endif

install-data-hook:
	:
if MANUAL
	rm -f "$(DESTDIR)/$(datarootdir)/$<"
	install -Dm644 -t "$(DESTDIR)$(docdir)" $(MANUAL)
endif
if EXAMPLES
	install -Dm644 -t "$(DESTDIR)$(docdir)/examples" $(EXAMPLES)
endif

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
prerelease: all test busted examples docs update_libtexpdf

.PHONY: release-preview
release-preview:
	npm run release -- --dry-run $(and $(RELTYPE),--release-as $(RELTYPE))

.PHONY: release
release: tagrelease

dist: examples docs all lua_modules_dist sile-$(VERSION).pdf

sile-$(VERSION).pdf: $(MANUAL)
	cp $< $@

.PHONY: update_libtexpdf
update_libtexpdf:
	git diff-index --quiet --cached HEAD || exit 1 # die if anything already staged
	git submodule update --init --remote -- libtexpdf
	git add -- libtexpdf
	git diff-index --quiet --cached HEAD || git commit -m "chore(build): Pin latest libtexpdf library submodule"

gh-pages:
	git worktree add -f $@ $@

.PHONY: installrocks
if !SYSTEM_LUAROCKS
installrocks: $(LUAMODLOCK) $(shell $(rocksmatch) || echo lua_modules)

lua_modules: $(LUAMODSPEC) $(shell $(rocksmatch) || echo force)
	if test -e .git; then
		$(LUAROCKS) $(LUAROCKSARGS) install --only-deps $<
	else
		rm -rf lua_modules
		cp -a lua_modules_dist lua_modules
		$(foreach LUA,$(filter-out $(LUA_VERSION),$(SUPPORTED_LUAS)),
		find lua_modules -maxdepth 3 -type d -name "*$(LUA)" -execdir rm -rf {} \;)
	fi

$(LUAMODLOCK): lua_modules $(LUAMODSPEC)
	$(genrockslock) > $@

sile: installrocks
endif

.PHONY: lua_modules_dist
lua_modules_dist: $(LUAMODSPEC) force
	$(foreach LUA,$(SUPPORTED_LUAS),
	$(LUAROCKS) $(LUAROCKSARGS) --lua-version $(LUA) install --only-deps $<)

DEPDIR := .deps
REGRESSIONSCRIPT := ./tests/regressions.pl
LOCALTESTFONTS := FONTCONFIG_FILE=$(PWD)/fontconfig.conf
SILEFLAGS ?= -m $(DEPDIR)/$(basename $@).d -d versions -f fontconfig

TESTPDFS   = $(addsuffix      .pdf,$(basename $(TESTSRCS)))
EXPECTEDS ?= $(filter $(addsuffix .expected,$(basename $(TESTSRCS))),$(TESTEXPECTS))
ACTUALS    = $(addsuffix   .actual,$(basename $(EXPECTEDS)))

check: selfcheck

.PHONY: selfcheck
selfcheck: all
	output=$$(mktemp --suffix=.pdf)
	trap 'rm -f $$output' EXIT SIGHUP SIGTERM
	./sile -o $$output - <<< "<sile>foo</sile>"
	pdfinfo $$output | grep SILE

.PHONY: test
test: $(TESTSRCS) $(ACTUALS)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

.PHONY: lint
lint: luacheck luarocks-lint

.PHONY: luarocks-lint
luarocks-lint: $(LUAMODSPEC)
	luarocks lint $<

.PHONY: luacheck
luacheck:
	luacheck -j$(shell nproc) -q .

.PHONY: busted
busted: | $(_INSTALL) all
	set -f; IFS=';'
if SYSTEM_LUAROCKS
	packagecpath=(./{,core/}?.$(SHARED_LIB_EXT))
	packagepath=(./{,lua-libraries/}?{,/init}.lua)
else
	packagecpath=(./{,core/,lua_modules/lib/lua/$(LUA_VERSION)/}?.$(SHARED_LIB_EXT))
	packagepath=(./{,lua_modules/share/lua/$(LUA_VERSION)/,lua-libraries/}?{,/init}.lua)
endif
	busted --cpath="$${packagecpath[*]};;" --lpath="$${packagepath[*]};;" spec

.PHONY: docs
docs: $(MANUAL)

EXAMPLES = $(addsuffix .pdf,$(basename $(EXAMPLESSRCS)))

.PHONY: examples
examples: $(EXAMPLES)

# This is a monkey patch to figure out how many passes we have to to to
# garantee the TOC is up to date, simplify when #230 is fixed.
hastoc = [[ -f $(subst .pdf,.toc,$@) ]] && echo true || echo false
pages = pdfinfo $@ | awk '$$1 == "Pages:" {print $$2}' || echo 0
silepass = $(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@ && pg0=$${pg} pg=$$($(pages))
define runsile =
	pg0=$$($(pages)) hadtoc=$$($(hastoc))
	mkdir -p $(DEPDIR)
	$(silepass)
	export -n SILE_COVERAGE
	if $(hastoc); then
		$${hadtoc} || $(silepass)
		[[ $${pg} -gt $${pg0} ]] && $(silepass) ||:
	fi
endef


if !SYSTEM_LUAROCKS
_INSTALL = installrocks
endif
_FORCED = $(and $(SILE_COVERAGE)$(CLEAN),force)
_MAKE_DEPS = $(wildcard $(DEPDIR)/$*.d)
_TEST_DEPS = $(and $(filter tests/%,$@),$(addprefix .fonts/,$(TESTFONTFILES)))
_DOCS_DEPS = $(and $(filter docs/%,$@),$(addprefix .fonts/,$(DOCSFONTFILES)))
_EXAM_DEPS = $(and $(filter examples/%,$@),$(addprefix .fonts/,$(EXAMFONTFILES)))
patterndeps = $(_FORCED) $(_TEST_DEPS) $(_EXAM_DEPS) $(_DOCS_DEPS) | $(DEPDIRS) $(_MAKE_DEPS) $(_INSTALL) all

%.pdf: %.sil $$(patterndeps)
	$(runsile)

%.pdf: %.xml $$(patterndeps)
	$(runsile)

examples/docbook/article-template.pdf: SILEFLAGS += -I docbook.sil

.PHONY: coverage
coverage: export SILE_COVERAGE=1
coverage: test_previews

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

define time_action =
	export TIMEFORMAT=$$'{ "real": "%R", "user": "%U", "sys": "%S" }'
	{ time (./sile documentation/sile.sil > /dev/null 2>&1) } 2> time.json
endef

make_worktree_rules = $(eval $(foreach SHA,$(_HEADSHA) $(_BASESHA),$(call worktree_sha,$(1),$(shell git rev-parse --short=7 $(SHA)))))

define worktree_sha =

.PRECIOUS: $(1)-$(2)
$(1)-$(2):
	[[ -d $$@ ]] || git worktree add --detach $$@ $(2)
	cd $$@
	[[ -d libtexpdf ]] && rmdir libtexpdf
	[[ -h libtexpdf ]] || ln -s ../libtexpdf
	[[ -h lua_modules ]] || ln -s ../lua_modules
	[[ -h lua_modules_dist ]] || ln -s ../lua_modules_dist
	[[ -h node_modules ]] || ln -s ../node_modules
	[[ -h .fonts ]] || ln -s ../.fonts
	./bootstrap.sh
	./configure
	make

.PRECIOUS: $(1)-$(2)/%
$(1)-$(2)/%: $(1)-$(2)
	cd $$<
	make $$*

.PRECIOUS: $(1)-$(2)/time.json
$(1)-$(2)/time.json: $(1)-$(2) $(1)-$(2)/sile
	cd $$<
	$$(time_action)

endef

$(call make_worktree_rules,benchmark)

.PHONY: benchmark
benchmark: time-$(_HEADSHA).json time-$(_BASESHA).json
	cat $^

.PRECIOUS: time-%.json
time-%.json: benchmark-%/time.json
	cp $< $@

.PRECIOUS: time.json
time.json: sile
	$(time_action)

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

.PHONY: test_previews
test_previews: $(TESTPDFS)

tests/%.actual: tests/%.sil $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.actual: tests/%.xml $$(patterndeps)
	-$(if $(CLEAN),rm -f $@,:)
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

DEPFILES = $(addsuffix .d,$(addprefix $(DEPDIR)/,$(basename $(TESTSRCS) $(MANUAL) $(EXAMPLES))))
DEPDIRS = $(sort $(dir $(DEPFILES)))

$(DEPDIRS):
	mkdir -p $@

$(DEPFILES): | $(DEPDIRS)

include $(wildcard $(DEPFILES))

.fonts: fontconfig.conf
	[[ -h .fonts ]] || mkdir -p $@

.sources:
	[[ -h .sources ]] || mkdir -p $@

# Actual rules for downloading test fonts are in a separate file
include Makefile-fonts

CLEANFILES = $(bin_SCRIPTS) $(dist_man_MANS) $(DEPFILES) $(ACTUALS) $(TESTPDFS) $(MANUAL) Makefile-distfiles

.PHONY: docker
docker: Dockerfile build-aux/docker-entrypoint.sh
	docker build --tag siletypesetter/sile:HEAD ./

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
