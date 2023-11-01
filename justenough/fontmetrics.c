#include <hb.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "hb-utils.h"

#include "compat-5.2.c"


int fm_get_typographic_extents (lua_State *L) {
  double upem;
  double ascender;
  double descender;
  double x_height;

  hb_font_t* hbFont = get_hb_font(L, 1);
  hb_font_extents_t metrics = {0,0,0};
  upem = hb_face_get_upem(hb_font_get_face(hbFont));
  hb_font_get_h_extents(hbFont, &metrics);
  ascender = metrics.ascender / upem;
  descender = -metrics.descender / upem;

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


int fm_glyphwidth (lua_State* L) {
  size_t font_l;
  unsigned int gid = luaL_checknumber(L, 1);
  hb_font_t* hbFont = get_hb_font(L, 2);
  double upem = hb_face_get_upem(hb_font_get_face(hbFont));
  hb_position_t width = hb_font_get_glyph_h_advance(hbFont, gid);
  lua_pushnumber(L, width / upem);
  return 1;
}


static const struct luaL_Reg lib_table [] = {
  {"get_typographic_extents", fm_get_typographic_extents},
  {"glyphwidth", fm_glyphwidth},
  {NULL, NULL}
};


int luaopen_fontmetrics (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
