#include <ft2build.h>
#include FT_FREETYPE_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


FT_Library library = NULL;

int get_typographic_extents (lua_State *L) {
  size_t font_l;
  const char * font_s = luaL_checklstring(L, 1, &font_l);
  unsigned int font_index = luaL_checknumber(L, 2);

  if (!library) FT_Init_FreeType (&library);
  FT_Face ft_face = NULL;
  FT_Error err = FT_New_Memory_Face (library,
    (const FT_Byte *) font_s, font_l, font_index, &ft_face);
  if(err) { luaL_error(L, "FT_New_Memory_Face failed"); }
  lua_newtable(L);
  lua_pushstring(L, "ascender");
  lua_pushnumber(L, (ft_face->ascender / (double)ft_face->units_per_EM));
  lua_settable(L, -3);
  lua_pushstring(L, "descender");
  lua_pushnumber(L, -ft_face->descender / (double)ft_face->units_per_EM);
  lua_settable(L, -3);
  FT_Done_Face(ft_face);
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
  {"get_typographic_extents", get_typographic_extents},
  {NULL, NULL}
};

int luaopen_fontmetrics (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
