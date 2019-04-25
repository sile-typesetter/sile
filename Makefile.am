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

.PHONY: test
test: $(REGRESSIONSCRIPT) | sile
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT)

DOCS = $(addsuffix .pdf,$(basename $(wildcard documentation/*.sil)))

.PHONY: docs
docs: $(DOCS) | sile

EXAMPLES = $(addsuffix .pdf,$(basename $(wildcard examples/*.sil)))

.PHONY: examples
examples: $(EXAMPLES) | sile

%.pdf: %.sil | sile
	$(LOCALTESTFONTS) ./sile $< -o $@

%.pdf: %.xml | sile
	$(LOCALTESTFONTS) ./sile $< -o $@

.PHONY: coverage
coverage: $(REGRESSIONSCRIPT)
	$(LOCALTESTFONTS) $(REGRESSIONSCRIPT) --coverage

EXPECTS = $(wildcard tests/*.expected)

.PHONY: update_expected
update_expected: $(EXPECTS)

tests/%.expected: tests/%.sil force | sile
	$(LOCALTESTFONTS) ./sile -b debug $< -o $@

ACTUALS = $(addsuffix .actual,$(basename $(wildcard tests/*.expected)))

.PHONY: update_actuals
update_actuals: $(ACTUALS)

tests/%.actual: tests/%.sil | sile
	$(LOCALTESTFONTS) ./sile -b debug $< -o $@

.PHONY: force
force: ;

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
