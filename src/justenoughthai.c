#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <unicode/ustring.h>
#include <unicode/ustdio.h>
#include <thai/thailib.h>
#include <thai/thbrk.h>
#include <stdlib.h>
#include <assert.h>

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

int thai_breakpoints(lua_State *L) {
  size_t text_l;
  const char * text = luaL_checklstring(L, 1, &text_l);
  int i, l;
  UErrorCode err = U_ZERO_ERROR;
  char* buffer = calloc(1, text_l);
  l = ucnv_convert("TIS-620","UTF-8", buffer, text_l, text, text_l, &err);
  int* pos = malloc(l * sizeof(int));
  int n_pos = th_brk((const thchar_t*)buffer, pos, l);
  lua_checkstack(L, n_pos);
  for (i=0; i < n_pos; i++) {
    int err = U_ZERO_ERROR;
    int utf8_index;
    utf8_index = ucnv_convert("UTF-8","TIS-620", NULL, 0, buffer, pos[i], &err);
    assert(U_SUCCESS(err) || err == U_BUFFER_OVERFLOW_ERROR);
    lua_pushinteger(L, utf8_index);
  }
  free(pos);
  free(buffer);
  return n_pos;
}

static const struct luaL_Reg lib_table [] = {
  {"breakpoints", thai_breakpoints},
  {NULL, NULL}
};


int luaopen_justenoughthai (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
