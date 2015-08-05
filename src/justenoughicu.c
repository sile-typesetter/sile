#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unicode/ustring.h>
#include <unicode/ustdio.h>
#include <unicode/ubrk.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int icu_breakpoints(lua_State *L) {
    // UBreakIterator* bi;
    // int32_t p;
    // u_printf("-> %S <-\n", s);
    // UErrorCode err = U_ZERO_ERROR;

    // bi = ubrk_open(UBRK_LINE, 0, s, len, &err);
    // if (U_FAILURE(err)) return;
    // p = ubrk_first(bi);
    // while (p != UBRK_DONE) {
    //     printf("Boundary at position %d\n", p);
    //     p = ubrk_next(bi);
    // }
    // ubrk_close(bi);
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
