if HARFBUZZLIBTEXPDF
coredir = $(pkgdatadir)/core
core_LTLIBRARIES = justenoughharfbuzz.la justenoughlibtexpdf.la
justenoughharfbuzz_la_SOURCES = justenoughharfbuzz.c
justenoughharfbuzz_la_LDFLAGS = -module -avoid-version -shared
justenoughharfbuzz_la_CFLAGS = $(HARFBUZZ_CFLAGS) $(FREETYPE_CFLAGS) $(FONTCONFIG_CFLAGS) $(LUA_INCLUDE)
justenoughharfbuzz_la_LIBADD = $(HARFBUZZ_LIBS) $(FREETYPE_LIBS) $(FONTCONFIG_LIBS)

justenoughlibtexpdf_la_SOURCES = justenoughlibtexpdf.c
justenoughlibtexpdf_la_LDFLAGS = -module -avoid-version -shared
justenoughlibtexpdf_la_CFLAGS = -I../libtexpdf $(LIBPNG_INCLUDES) $(ZLIB_INCLUDES) $(LIBPAPER_INCLUDES) $(LUA_INCLUDE)
justenoughlibtexpdf_la_LIBADD = ../libtexpdf/.libs/libtexpdf.a $(FREETYPE_LIBS) $(LIBPNG_LIBS) $(ZLIB_LIBS) $(LIBPAPER_LIBS)

all-local: $(core_LTLIBRARIES)
	cp .libs/justenoughharfbuzz.so .libs/justenoughlibtexpdf.so ../core
endif
