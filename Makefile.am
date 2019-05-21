ACLOCAL_AMFLAGS = -I m4

if SYSTEM_LIBTEXPDF
SUBDIRS = src
else
SUBDIRS = libtexpdf src
endif

dist_bin_SCRIPTS = sile
-include subfiles.mk
nobase_dist_pkgdata_DATA = $(subdir_files)
EXTRA_DIST=NEWS.md README.md LICENSE ROADMAP tests examples documentation

REGRESSIONSCRIPT := ./tests/regressions.pl
LOCALTESTFONTS := FONTCONFIG_FILE=$(PWD)/fontconfig.conf
SILEFLAGS ?=

TESTSRCS  ?= $(wildcard tests/*.sil tests/*.xml)
TESTPDFS   = $(addsuffix      .pdf,$(basename $(TESTSRCS)))
EXPECTEDS  = $(addsuffix .expected,$(basename $(TESTSRCS)))
ACTUALS    = $(addsuffix   .actual,$(basename $(TESTSRCS)))

.PHONY: test
test: REGRESSIONMODE ?= true
test: $(TESTSRCS) $(ACTUALS) | sile testprep
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) $(TESTSRCS)

DOCS = $(addsuffix .pdf,$(basename $(wildcard documentation/*.sil)))

.PHONY: docs
docs: $(DOCS) | sile

EXAMPLES = $(addsuffix .pdf,$(basename $(wildcard examples/*.sil)))

.PHONY: examples
examples: $(EXAMPLES) | sile

%.pdf: %.sil | sile
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@

%.pdf: %.xml | sile
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) $< -o $@

.PHONY: coverage
coverage: $(REGRESSIONSCRIPT)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) --coverage

.PHONY: update_expecteds
update_expecteds: $(EXPECTEDS)

tests/%.expected: tests/%.sil | sile testprep
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.expected: tests/%.xml | sile testprep
	$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

.PHONY: update_actuals
update_actuals: REGRESSIONMODE = true
update_actuals: $(ACTUALS)

.PHONY: test_previews
test_previews: $(TESTPDFS)

tests/%.actual: tests/%.sil $(and $(REGRESSIONMODE),force) | sile testprep
	-$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

tests/%.actual: tests/%.xml $(and $(REGRESSIONMODE),force) | sile testprep
	-$(LOCALTESTFONTS) ./sile $(SILEFLAGS) -b debug $< -o $@

.PHONY: force
force: ;

.PRECIOUS: .fonts/% %.zip %.xz

TESTFONTFILES  = NotoSansCJK-Regular.ttc
TESTFONTFILES += NotoSansMalayalam-Regular.ttf
TESTFONTFILES += NotoNaskhArabic-Regular.ttf
TESTFONTFILES += LibertinusSerif-Regular.otf
TESTFONTFILES += LibertinusSans-Bold.otf
TESTFONTFILES += GentiumPlus-R.ttf GentiumPlus-I.ttf
TESTFONTFILES += Hack-Regular.ttf
TESTFONTFILES += Amiri-Regular.ttf AmiriQuran.ttf

.PHONY: testprep
testprep: | $(addprefix .fonts/,$(TESTFONTFILES))

.fonts: fontconfig.conf
	mkdir -p $@

.fonts/NotoSansCJK%: | .fonts
	curl -s -L https://github.com/googlefonts/noto-cjk/raw/NotoSansV2.001/$(notdir $@) -o $@

.fonts/Noto%: | .fonts
	curl -s -L https://github.com/googlefonts/noto-fonts/raw/v2017-09-19-phase3-second/hinted/$(notdir $@) -o $@

.fonts/Libertinus%: | .fonts
	curl -s -L https://github.com/alif-type/libertinus/raw/v6.9/$(notdir $@) -o $@

.fonts/Amiri%: | .fonts
	curl -s -L https://github.com/alif-type/amiri/raw/0.111/$(notdir $@) -o $@

.fonts/GentiumPlus%: GentiumPlus-5.000.zip | .fonts
	bsdtar -x -f $< -C $(dir $@) --strip-components 1 GentiumPlus-5.000/$(notdir $@)
	touch $@

.fonts/Hack%: Hack-v3.003-ttf.tar.xz | .fonts
	bsdtar -x -f $< -C $(dir $@) $(notdir $@)
	touch $@

GentiumPlus-5.000.zip:
	curl -s -L https://software.sil.org/downloads/r/gentium/$(notdir $@) -o $@

Hack-v3.003-ttf.tar.xz:
	curl -s -L https://github.com/source-foundry/Hack/releases/download/v3.003/$(notdir $@) -o $@

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
