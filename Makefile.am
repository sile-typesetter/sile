ACLOCAL_AMFLAGS = -I m4

if SYSTEM_LIBTEXPDF
SUBDIRS = src
else
SUBDIRS = libtexpdf src
endif

dist_bin_SCRIPTS = sile
-include subfiles.mk
nobase_dist_pkgdata_DATA = $(subdir_files)
EXTRA_DIST=NEWS.md README.md LICENSE tests examples documentation

.SECONDEXPANSION:
.DELETE_ON_ERROR:

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

DOCSSRCS = $(basename $(wildcard documentation/*.sil))
DOCS = $(addsuffix .pdf,$(basename $(DOCSSRCS)))

.PHONY: docs
docs: $(DOCS)

EXAMPLESSRCS = $(basename $(wildcard examples/*.sil))
EXAMPLES = $(addsuffix .pdf,$(DOCSSRCS))

.PHONY: examples
examples: $(EXAMPLES)

%.pdf: %.sil
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@

%.pdf: %.xml
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@

.PHONY: coverage
coverage: $(REGRESSIONSCRIPT)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) --coverage

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
testprep: | $(DEPDIRS) $(addprefix .fonts/,$(TESTFONTFILES))

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
