#include <hb.h>
#include <hb-ft.h>
#ifndef HB_VERSION_ATLEAST
#define HB_VERSION_ATLEAST(major,minor,micro) \
        ((major)*10000+(minor)*100+(micro) <= \
         HB_VERSION_MAJOR*10000+HB_VERSION_MINOR*100+HB_VERSION_MICRO)
#endif
#if HB_VERSION_ATLEAST(1,1,3)
#define USE_HARFBUZZ_METRICS
#include <hb-ot.h>
#else
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TRUETYPE_TABLES_H
#define USE_FREETYPE_METRICS

FT_Library library = NULL;

#endif

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


int get_typographic_extents (lua_State *L) {
  size_t font_l;
  const char * font_s = luaL_checklstring(L, 1, &font_l);
  unsigned int font_index = luaL_checknumber(L, 2);
  short upem;
  double ascender;
  double descender;
  double x_height;

#ifdef USE_FREETYPE_METRICS
  if (!library) FT_Init_FreeType (&library);
  FT_Face ft_face = NULL;
  FT_Error err = FT_New_Memory_Face (library,
    (const FT_Byte *) font_s, font_l, font_index, &ft_face);
  if(err) { luaL_error(L, "FT_New_Memory_Face failed"); }
  upem = ft_face->units_per_EM;
  ascender = ft_face->ascender / (double)upem;
  descender = -ft_face->descender / (double)upem;
  TT_OS2* os2 = (TT_OS2*) FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (os2) {
    x_height = os2->sxHeight / (double)upem;
  }
  FT_Done_Face(ft_face);
#else
  hb_blob_t* blob = hb_blob_create (font_s, font_l, HB_MEMORY_MODE_WRITABLE, (void*)font_s, NULL);
  hb_face_t* hbFace = hb_face_create (blob, font_index);
  hb_font_t* hbFont = hb_font_create (hbFace);
  hb_font_extents_t metrics = {0,0,0};
  upem = hb_face_get_upem(hbFace);
  hb_ot_font_set_funcs(hbFont);
  hb_font_get_h_extents(hbFont, &metrics);
  ascender = metrics.ascender / (double)upem;
  descender = -metrics.descender / (double)upem;
  hb_font_destroy(hbFont);
#endif

  lua_newtable(L);
  lua_pushstring(L, "ascender");
  lua_pushnumber(L, ascender);
  lua_settable(L, -3);
  lua_pushstring(L, "x_height");
  lua_pushnumber(L, x_height);
  lua_settable(L, -3);
  lua_pushstring(L, "descender");
  lua_pushnumber(L, descender);
  lua_settable(L, -3);

  return 1;
}


int glyphwidth (lua_State* L) {
  size_t font_l;
  unsigned int gid = luaL_checknumber(L, 1);
  const char * font_s = luaL_checklstring(L, 2, &font_l);
  unsigned int font_index = luaL_checknumber(L, 3);
  hb_blob_t* blob = hb_blob_create (font_s, font_l, HB_MEMORY_MODE_WRITABLE, (void*)font_s, NULL);
  hb_face_t* hbFace = hb_face_create (blob, font_index);
  hb_font_t* hbFont = hb_font_create (hbFace);
  short upem = hb_face_get_upem(hbFace);
  hb_ft_font_set_funcs(hbFont);
  hb_position_t width = hb_font_get_glyph_h_advance(hbFont, gid);
  lua_pushnumber(L, width / (double)upem);
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
void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
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
  {"glyphwidth", glyphwidth},
  {NULL, NULL}
};

int luaopen_fontmetrics (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
