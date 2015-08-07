#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <unicode/ustring.h>
#include <unicode/ustdio.h>
#include <unicode/ubrk.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int icu_breakpoints(lua_State *L) {
  const char* input = luaL_checkstring(L, 1);
  int input_l = strlen(input);
  UChar *buffer;
  int32_t l;
  UErrorCode err = U_ZERO_ERROR;
  u_strFromUTF8(NULL, 0, &l, input, input_l, &err);
  /* Above call returns an error every time. */
  err = U_ZERO_ERROR;
  buffer = malloc(l * sizeof(UChar));
  u_strFromUTF8(buffer, l, &l, input, input_l, &err);

  char* outputbuffer = malloc(input_l); /* To hold UTF8 */
  UBreakIterator* bi;
  int index = 1;
  int32_t p, previous;
  bi = ubrk_open(UBRK_LINE, 0, buffer, l, &err);
  assert(!U_FAILURE(err));
  p = ubrk_first(bi);
  previous = 0;
  lua_newtable(L);
  while (p != UBRK_DONE) {
    int32_t out_l;
    u_strToUTF8(outputbuffer, input_l, &out_l, buffer+previous, p-previous, &err);
    lua_pushinteger(L, index++);
    lua_pushstring(L, outputbuffer);
    lua_settable(L, -3);
    assert(!U_FAILURE(err));
    previous = p;
    p = ubrk_next(bi);
  }
  ubrk_close(bi);
  return 1;
}


#if !defined LUA_VERSION_NUM
/* Lua 5.0 */
#define luaL_Reg luaL_reg
#endif

#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501
/*
** Adapted from Lua 5.2.0
*/
static void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
  luaL_checkstack(L, nup+1, "too many upvalues");
  for (; l->name != NULL; l++) {  /* fill the table with given functions */
    int i;
    lua_pushstring(L, l->name);
    for (i = 0; i < nup; i++)  /* copy upvalues to the top */
      lua_pushvalue(L, -(nup+1));
    lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
    lua_settable(L, -(nup + 3));
  }
  lua_pop(L, nup);  /* remove upvalues */
}
#endif

static const struct luaL_Reg lib_table [] = {
  {"breakpoints", icu_breakpoints},
  {NULL, NULL}
};

int luaopen_justenoughicu (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
