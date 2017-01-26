CC		?= cc
RM		?= rm -rf
INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)
INSTALL_DATA	?= $(INSTALL) -m 644
LUA_V		?= 5.1
LUA_LDIR	?= /usr/share/lua/$(LUA_V)
LUA_CDIR	?= /usr/lib/lua/$(LUA_V)
T		= lxp
LIBNAME		= $(T).so

COMMON_CFLAGS	 = -g -pedantic -Wall -O2 -fPIC -DPIC -ansi
LUA_INC		?= -I/usr/include/lua$(LUA_V)
EXPAT_INC	?= -I/usr/include
CF		 = $(LUA_INC) $(EXPAT_INC) $(COMMON_CFLAGS) $(CFLAGS)

EXPAT_LIB	 = -lexpat
COMMON_LDFLAGS	 = -shared
LF		 = $(COMMON_LDFLAGS) $(EXPAT_LIB) $(LDFLAGS)

OBJS		 = src/lxplib.o

lib: src/$(LIBNAME)

src/$(LIBNAME):
	export MACOSX_DEPLOYMENT_TARGET="10.3";
	$(CC) $(CF) -o $@ src/$(T)lib.c $(LF)

install:
	$(INSTALL_PROGRAM) -D src/$(LIBNAME) $(DESTDIR)$(LUA_CDIR)/$(LIBNAME)
	$(INSTALL_PROGRAM) -D src/$T/lom.lua $(DESTDIR)$(LUA_LDIR)/$T/lom.lua

clean:
	$(RM) src/$(LIBNAME) $(OBJS)
