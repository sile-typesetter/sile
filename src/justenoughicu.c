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
  int32_t l, breakcount = 0;
  UErrorCode err = U_ZERO_ERROR;
  u_strFromUTF8(NULL, 0, &l, input, input_l, &err);
  /* Above call returns an error every time. */
  err = U_ZERO_ERROR;
  buffer = malloc(l * sizeof(UChar));
  u_strFromUTF8(buffer, l, &l, input, input_l, &err);

  char* outputbuffer = malloc(input_l); /* To hold UTF8 */
  UBreakIterator* wordbreaks, *linebreaks;
  int32_t i, previous;
  wordbreaks = ubrk_open(UBRK_WORD, 0, buffer, l, &err);
  assert(!U_FAILURE(err));

  linebreaks = ubrk_open(UBRK_LINE, 0, buffer, l, &err);
  assert(!U_FAILURE(err));

  previous = 0;
  i = 0;
  while (i <= l) {
    int32_t out_l;
    int32_t type;
    if (!ubrk_isBoundary(linebreaks, i) && !ubrk_isBoundary(wordbreaks,i)) {
      i++; continue;
    }
    lua_checkstack(L, 3);
    /* At some kind of boundary */
    lua_newtable(L);
    lua_pushstring(L, "type");
    lua_pushstring(L, ubrk_isBoundary(linebreaks,i) ? "line" : "word");
    lua_settable(L, -3);

    if (ubrk_isBoundary(linebreaks, i)) {
      lua_pushstring(L, "subtype");
      type = ubrk_getRuleStatus(linebreaks);
      if (type >= UBRK_LINE_SOFT && type < UBRK_LINE_SOFT_LIMIT) {
        lua_pushstring(L, "soft");
      } else {
        lua_pushstring(L, "hard");
      }
      lua_settable(L, -3);
    }
    lua_pushstring(L, "token");
    u_strToUTF8(outputbuffer, input_l, &out_l, buffer+previous, i-previous, &err);
    lua_pushlstring(L, outputbuffer, out_l);

    lua_settable(L, -3);

    previous  = i;
    breakcount++;
    i++;
  }
  ubrk_close(wordbreaks);
  ubrk_close(linebreaks);
  return breakcount;
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
