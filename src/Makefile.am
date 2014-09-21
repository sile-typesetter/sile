if HARFBUZZPODOFO
coredir = $(pkgdatadir)/core
core_LTLIBRARIES = justenoughharfbuzz.la podofo.la
justenoughharfbuzz_la_SOURCES = justenoughharfbuzz.c
justenoughharfbuzz_la_LDFLAGS = -module -avoid-version -shared
justenoughharfbuzz_la_CFLAGS = $(HARFBUZZ_CFLAGS) $(FREETYPE_CFLAGS) $(FONTCONFIG_CFLAGS) $(LUA_INCLUDE)
justenoughharfbuzz_la_LIBADD = $(HARFBUZZ_LIBS) $(FREETYPE_LIBS) $(FONTCONFIG_LIBS)
podofo_la_SOURCES = podofo_wrap.cxx
podofo_la_LDFLAGS = -module -avoid-version -shared
podofo_la_CXXFLAGS = $(LUA_INCLUDE) $(FREETYPE_CFLAGS) $(FONTCONFIG_CFLAGS)
podofo_la_LIBADD = -lpodofo -lpthread -ltiff -ljpeg $(FREETYPE_LIBS) $(FONTCONFIG_LIBS)

all-local: $(core_LTLIBRARIES)
	cp .libs/justenoughharfbuzz.so .libs/podofo.so ../core
endif
