ACLOCAL_AMFLAGS = -I m4

if HARFBUZZLIBTEXPDF
SUBDIRS = libtexpdf src
else
SUBDIRS = src
endif

dist_bin_SCRIPTS = sile
-include subfiles.mk
nobase_dist_pkgdata_DATA = $(subdir_files)
