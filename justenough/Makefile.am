ACLOCAL_AMFLAGS = -I ../build-aux

if LINKLUA
MY_LUA_LIB = $(LUA_LIB)
UNDEFINED = -no-undefined
else
MY_LUA_LIB =
UNDEFINED =
endif

if SYSTEM_LIBTEXPDF
LIBTEXPDF_LIB = -ltexpdf
else
LIBTEXPDF_LIB = ../libtexpdf/libtexpdf.la
endif

AM_CFLAGS = $(WARNING_CFLAGS) -I../libtexpdf -I./justenough/
AM_LDFLAGS = -module -avoid-version $(UNDEFINED)

pkglib_LTLIBRARIES = justenoughharfbuzz.la
justenoughharfbuzz_la_SOURCES = justenoughharfbuzz.c hb-utils.c hb-utils.h compat-5.3.h
justenoughharfbuzz_la_LDFLAGS = $(AM_LDFLAGS)
justenoughharfbuzz_la_CFLAGS = $(AM_CFLAGS) $(HARFBUZZ_CFLAGS) $(HARFBUZZ_SUBSET_CFLAGS) $(LUA_INCLUDE) $(COMPAT53_CFLAGS)
justenoughharfbuzz_la_LIBADD = $(HARFBUZZ_LIBS) $(HARFBUZZ_SUBSET_LIBS) $(MY_LUA_LIB)

pkglib_LTLIBRARIES += justenoughfontconfig.la
justenoughfontconfig_la_SOURCES = justenoughfontconfig.c silewin32.h compat-5.3.h
justenoughfontconfig_la_LDFLAGS = $(AM_LDFLAGS)
justenoughfontconfig_la_CFLAGS = $(AM_CFLAGS) $(FONTCONFIG_CFLAGS) $(LUA_INCLUDE) $(COMPAT53_CFLAGS)
justenoughfontconfig_la_LIBADD = $(FONTCONFIG_LIBS) $(MY_LUA_LIB)

if APPKIT
pkglib_LTLIBRARIES += macfonts.la
macfonts_la_SOURCES = macfonts.m compat-5.3.h
macfonts_la_LDFLAGS = $(AM_LDFLAGS)
macfonts_la_OBJCFLAGS = -U VERSION $(HARFBUZZ_CFLAGS) $(LUA_INCLUDE) -fmodules $(COMPAT53_CFLAGS)
macfonts_la_LIBADD = $(HARFBUZZ_LIBS) $(MY_LUA_LIB)
endif

pkglib_LTLIBRARIES += justenoughlibtexpdf.la
justenoughlibtexpdf_la_SOURCES = justenoughlibtexpdf.c imagebbox.c compat-5.3.h
justenoughlibtexpdf_la_LDFLAGS = $(AM_LDFLAGS)
justenoughlibtexpdf_la_CFLAGS = $(AM_CFLAGS) $(LIBPNG_INCLUDES) $(ZLIB_INCLUDES) $(LIBPAPER_INCLUDES) $(LUA_INCLUDE) $(COMPAT53_CFLAGS)
justenoughlibtexpdf_la_LIBADD = $(LIBTEXPDF_LIB) $(LIBPNG_LIBS) $(ZLIB_LIBS) $(LIBPAPER_LIBS) $(MY_LUA_LIB)

pkglib_LTLIBRARIES += fontmetrics.la
fontmetrics_la_SOURCES = fontmetrics.c hb-utils.c hb-utils.h compat-5.3.h
fontmetrics_la_LDFLAGS = $(AM_LDFLAGS)
fontmetrics_la_CFLAGS = $(AM_CFLAGS) $(LUA_INCLUDE) $(HARFBUZZ_CFLAGS) $(COMPAT53_CFLAGS)
fontmetrics_la_LIBADD = $(MY_LUA_LIB) $(HARFBUZZ_LIBS)

pkglib_LTLIBRARIES += svg.la
svg_la_SOURCES = svg.c nanosvg.h compat-5.3.h
svg_la_LDFLAGS = $(AM_LDFLAGS)
svg_la_CFLAGS = $(AM_CFLAGS) $(LUA_INCLUDE) $(COMPAT53_CFLAGS)
svg_la_LIBADD = $(MY_LUA_LIB)

if ICU
pkglib_LTLIBRARIES += justenoughicu.la
justenoughicu_la_SOURCES = justenoughicu.c compat-5.3.h
justenoughicu_la_LDFLAGS = $(AM_LDFLAGS)
justenoughicu_la_CFLAGS = $(AM_CFLAGS) $(ICU_CFLAGS) $(LUA_INCLUDE) $(COMPAT53_CFLAGS)
justenoughicu_la_LIBADD = $(ICU_LIBS) $(MY_LUA_LIB)
endif
