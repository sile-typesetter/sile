ACLOCAL_AMFLAGS = -I m4

if SYSTEM_LIBTEXPDF
SUBDIRS = src
else
SUBDIRS = libtexpdf src
endif

dist_bin_SCRIPTS = sile
subdir_files = $(shell find core classes languages packages lua-libraries lua_modules -type f -print)
nobase_dist_pkgdata_DATA = $(subdir_files)
EXTRA_DIST=CHANGELOG.md README.md LICENSE tests examples documentation

# Hack around autoconf's overly opinionated ideas of what projects layouts should be
AUTOCONF = ${SHELL} /home/caleb/projects/sile/missing autoconf && sed -i -e '/^rm -f/s/ core / /' configure

SHELL = bash
.ONESHELL:
.SECONDEXPANSION:
.DELETE_ON_ERROR:

LUAROCKS := luarocks --tree lua_modules
LUAROCKSARGS ?=
LUAMODLOCK := sile-dev-1.rockslock
LUAMODSPEC := sile-dev-1.rockspec
LUAVERSION := $(shell lua <<< 'print(_VERSION:match("%d+%.%d+"))')
genrockslock := $(LUAROCKS) list --porcelain | awk '{print $$1 " " $$2}'
rocksmatch := cmp -s $(LUAMODLOCK) <($(genrockslock))

# Make sure the embeded version number iterates with every commit
configure.ac: .lastcommit

.PHONY: .lastcommit
.lastcommit:
	@touch -d "$$(git log -n1 --pretty=format:%cI)" -- $@

.PHONY: tagrelease
tagrelease: prerelease
	test -z $$(git tag --points-at HEAD) || exit 0 # end if we are already on a release tag
	git diff-index --quiet --cached HEAD || exit 1 # die if anything staged but not committed
	git diff-files --quiet || exit 1 # die if any tracked files have unstagged changes
	npm run release

.PHONY: prerelease
prerelease: sile test busted examples docs update_libtexpdf

.PHONY: release
release: tagrelease postrelease

.PHONY: postrelease
postrelease:
	@echo "- [ ] Ping packagers: https://repology.org/project/sile/versions"

.PHONY: update_libtexpdf
update_libtexpdf:
	git diff-index --quiet --cached HEAD || exit 1 # die if anything already staged
	git submodule update --init --remote -- libtexpdf
	git add -- libtexpdf
	git diff-index --quiet --cached HEAD || git commit -m "chore(build): Pin latest libtexpdf library submodule"

gh-pages:
	git worktree add -f $@ $@

.PHONY: installrocks
installrocks: $(LUAMODLOCK) $(shell $(rocksmatch) || echo lua_modules)

lua_modules: $(LUAMODSPEC) $(shell $(rocksmatch) || echo force)
	$(LUAROCKS) $(LUAROCKSARGS) install --only-deps $<

$(LUAMODLOCK): lua_modules $(LUAMODSPEC)
	$(genrockslock) > $@

sile: installrocks

DEPDIR := .deps
REGRESSIONSCRIPT := ./tests/regressions.pl
LOCALTESTFONTS := FONTCONFIG_FILE=$(PWD)/fontconfig.conf
SILEFLAGS ?= -m $(DEPDIR)/$(basename $@).d -d versions -f fontconfig

TESTSRCS  ?= $(wildcard tests/*.sil tests/*.xml)
TESTPDFS   = $(addsuffix      .pdf,$(basename $(TESTSRCS)))
EXPECTEDS ?= $(wildcard tests/*.expected)
ACTUALS    = $(addsuffix   .actual,$(basename $(EXPECTEDS)))

.PHONY: test
test: $(TESTSRCS) $(ACTUALS) sile testprep
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

busted: $(wildcard tests/*_spec.lua) sile testprep
	set -f; IFS=';'
	packagecpath=(./{,core/,lua_modules/lib/lua/$(LUAVERSION)/}?.so)
	packagepath=(./{,lua_modules/share/lua/$(LUAVERSION)/,lua-libraries/}?{,/init}.lua)
	busted --cpath="$${packagecpath[*]}" --lpath="$${packagepath[*]}" tests

DOCSSRCS = $(basename $(wildcard documentation/*.sil))
DOCS = $(addsuffix .pdf,$(basename $(DOCSSRCS)))

.PHONY: docs
docs: $(DOCS)

EXAMPLESSRCS = $(basename $(wildcard examples/*.sil))
EXAMPLES = $(addsuffix .pdf,$(DOCSSRCS))

.PHONY: examples
examples: $(EXAMPLES)

# Use system wide fonts for docs and examples
documentation/%.pdf: LOCALTESTFONTS=
examples/%.pdf: LOCALTESTFONTS=

# This is a monkey patch to figure out how many passes we have to to to
# garantee the TOC is up to date, simplify when #230 is fixed.
hastoc = [[ -f $(subst .pdf,.toc,$@) ]] && echo true || echo false
pages = pdfinfo $@ | awk '$$1 == "Pages:" {print $$2}' || echo 0
silepass = $(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@ && pg0=$${pg} pg=$$($(pages))
define runsile =
	pg0=$$($(pages)) hadtoc=$$($(hastoc))
	$(silepass)
	if $(hastoc); then
		$${hadtoc} || $(silepass)
		[[ $${pg} -gt $${pg0} ]] && $(silepass) ||:
	fi
endef

%.pdf: %.sil $(and $(SILE_COVERAGE),force)
	$(runsile)

%.pdf: %.xml $(and $(SILE_COVERAGE),force)
	$(runsile)

.PHONY: coverage
coverage: export SILE_COVERAGE=1
coverage: test_previews

HEADSHA ?= $(shell git rev-parse --short HEAD)
BASESHA ?= $(shell git rev-parse --short $(HEADSHA)^)

.PHONY: benchmark
benchmark: time-$(HEADSHA).json time-$(BASESHA).json
	cat $^

clean-recursive: clean-benchmarks

.PHONY: clean-benchmarks
clean-benchmarks:
	rm -rf benchmark-*
	git worktree prune
	git branch --list | grep benchmark- | xargs git branch -D ||:

time-%.json: benchmark-%/time.json
	cp $< $@

.PRECIOUS: benchmark-%/time.json
benchmark-%/time.json: benchmark-%/sile
	cd benchmark-$*
	export TIMEFORMAT=$$'{ "real": "%R", "user": "%U", "sys": "%S" }'
	{ time (./sile documentation/sile.sil > /dev/null 2>&1) } 2> time.json

.PRECIOUS: benchmark-%/sile
benchmark-%/sile:
	[[ -d benchmark-$* ]] || git worktree add --detach benchmark-$* $(HEADSHA)
	cd benchmark-$*
	[[ -d libtexpdf ]] && rmdir libtexpdf
	[[ -h libtexpdf ]] || ln -s ../libtexpdf
	[[ -h lua_modules ]] || ln -s ../lua_modules
	[[ -h node_modules ]] || ln -s ../node_modules
	./bootstrap.sh
	./configure
	make

.PHONY: force
force: ;

.PHONY: update_expecteds
update_expecteds: $(EXPECTEDS)

tests/%.expected: tests/%.sil
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.expected: tests/%.xml
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

.PHONY: update_actuals
update_actuals: $(ACTUALS)

.PHONY: test_previews
test_previews: $(TESTPDFS)

tests/%.actual: tests/%.sil
	-$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.actual: tests/%.xml
	-$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

DEPFILES = $(addsuffix .d,$(addprefix $(DEPDIR)/,$(basename $(TESTSRCS) $(DOCS) $(EXAMPLES))))
DEPDIRS = $(sort $(dir $(DEPFILES)))

$(DEPDIRS):
	mkdir -p $@

%.pdf: $(DEPDIR)/%.d
%.expected: $(DEPDIR)/%.d
%.actual: $(DEPDIR)/%.d

$(DEPFILES): | $(DEPDIRS)

include $(wildcard $(DEPFILES))

# Make sure we have a local font directory before putting anything there
.fonts/%: Makefile-fonts | .fonts

.fonts: fontconfig.conf
	mkdir -p $@

# Actual rules for downloading test fonts are in a separate file
include Makefile-fonts

# Make sure we have font files before running tests (ignoring timestamp of font files)
.PHONY: testprep
testprep: installrocks | $(DEPDIRS) $(addprefix .fonts/,$(TESTFONTFILES))

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
