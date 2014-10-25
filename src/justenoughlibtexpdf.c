#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <libtexpdf/libtexpdf.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

pdf_doc *p = NULL;
double height = 0.0;
double precision = 65536.0;

int pdf_init (lua_State *L) {
  pdf_rect mediabox;
  const char*  fn = luaL_checkstring(L, 1);
  double w = luaL_checknumber(L, 2);
  height = luaL_checknumber(L, 3);

  p = texpdf_open_document(fn, 0, w, height, 0,0,0);
  texpdf_init_device(p, 1/precision, 2, 0);

  mediabox.llx = 0.0;
  mediabox.lly = 0.0;
  mediabox.urx = w;
  mediabox.ury = height;
  texpdf_init_fontmaps();
  texpdf_doc_set_mediabox(p, 0, &mediabox);
  return 0;
}

int pdf_endpage(lua_State *L) {
  ASSERT(p);
  texpdf_doc_end_page(p);  
  return 0;
};

int pdf_beginpage(lua_State *L) {
  ASSERT(p);
  texpdf_doc_begin_page(p, 1,0,height);
  return 0;
}

int pdf_finish(lua_State *L) {
  ASSERT(p);
  texpdf_close_document(p);
  texpdf_close_device  ();
  texpdf_close_fontmaps();    
  return 0;
}

int pdf_loadfont(lua_State *L) {
  const char * filename;
  int index = 0;
  double ptsize;
  int layout_dir = 0;
  int extend = 65536;
  int slant = 0;
  int embolden = 0;  
  int font_id;

  if (!lua_istable(L, 1)) return 0;

  lua_pushstring(L, "filename");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { filename = lua_tostring(L, -1); }
  else { luaL_error(L, "No font filename supplied to loadfont"); }
  lua_pop(L,1);

  lua_pushstring(L, "index");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { index = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "pointsize");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { ptsize = lua_tonumber(L, -1); }
  else { luaL_error(L, "No pointsize supplied to loadfont"); }
  lua_pop(L,1);

  /* The following parameters are not currently passed by SILE,
     and it will work without them, but if SILE extensions put them
     into the font cache then they should magically work. */

  lua_pushstring(L, "extend");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { extend = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "embolden");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { embolden = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "slant");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { slant = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "layout_dir");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { layout_dir = lua_tointeger(L, -1); }  
  lua_pop(L,1);

  font_id = texpdf_dev_load_native_font(filename, index, precision * ptsize, layout_dir, extend, slant, embolden);
  lua_pushinteger(L, font_id);
  return 1;
}

int pdf_setstring(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  double y = luaL_checknumber(L, 2);
  const char*  s = luaL_checkstring(L, 3);
  int    chrlen  = luaL_checkinteger(L, 4);
  int    font_id = luaL_checkinteger(L, 5);
  double w = luaL_checknumber(L,6);

  texpdf_dev_set_string(p, precision * x, precision * (-height+y), s, chrlen, w * 65536 * precision, font_id, -1);
  return 0;
}

int pdf_setrule(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  double y = luaL_checknumber(L, 2);
  double w = luaL_checknumber(L, 3);
  double h = luaL_checknumber(L, 4);
  texpdf_dev_set_rule(p, precision * x, precision * (-height+y), precision * w, precision * h);
  return 0;
}

int pdf_setcolor(lua_State *L) {
  double r = luaL_checknumber(L, 1);
  double g = luaL_checknumber(L, 2);
  double b = luaL_checknumber(L, 3);

  pdf_color color;
  texpdf_color_rgbcolor(&color,r,g,b);
  texpdf_color_set(p, &color, &color);
  return 0;
}

int pdf_colorpush(lua_State *L) {
  double r = luaL_checknumber(L, 1);
  double g = luaL_checknumber(L, 2);
  double b = luaL_checknumber(L, 3);

  pdf_color color;
  texpdf_color_rgbcolor(&color,r,g,b);
  texpdf_color_push(p, &color, &color);
  return 0;
}

int pdf_colorpop(lua_State *L) {
  texpdf_color_pop(p);
  return 0;
}

int pdf_drawimage(lua_State *L) {
  const char* filename = luaL_checkstring(L, 1);
  transform_info ti;
  double x = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double w = luaL_checknumber(L, 4);
  double h = luaL_checknumber(L, 5);
  int form_id = texpdf_ximage_findresource(p, filename, 0, NULL);

  texpdf_transform_info_clear(&ti);
  ti.width = w;
  ti.height = h;
  ti.flags |= (INFO_HAS_WIDTH|INFO_HAS_HEIGHT);

  texpdf_dev_put_image(p, form_id, &ti, x, -h-y, 0);
  return 0;
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
  {"init", pdf_init},
  {"beginpage", pdf_beginpage},
  {"endpage", pdf_endpage},
  {"finish", pdf_finish},
  {"loadfont", pdf_loadfont},
  {"setstring", pdf_setstring},
  {"setrule", pdf_setrule},
  {"setcolor", pdf_setcolor},
  {"drawimage", pdf_drawimage},
  {"colorpop", pdf_colorpop},
  {"colorpush", pdf_colorpush},
  {NULL, NULL}
};

int luaopen_justenoughlibtexpdf (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}

