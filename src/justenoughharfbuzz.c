#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OUTLINE_H

#include <hb.h>
#include <hb-ft.h>

#include <fontconfig/fontconfig.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

typedef struct {
  char* family;
  char* lang;
  double pointSize;
  int weight;
  int direction;
  int slant;
  char* style;
  char* script;
} fontOptions;

typedef struct {
  double width;
  double height;
  double depth;
} box;

FT_Library ft_library;

void calculate_extents(box* b, hb_glyph_info_t glyph_info, hb_glyph_position_t glyph_pos, FT_Face ft_face) {
  const FT_Error error = FT_Load_Glyph(ft_face, glyph_info.codepoint, FT_LOAD_DEFAULT);
  if (error) return;

  const FT_Glyph_Metrics *ftmetrics = &ft_face->glyph->metrics;
  b->width = glyph_pos.x_advance /64.0;
  b->height = ftmetrics->horiBearingY / 64.0;
  b->depth = (ftmetrics->height - ftmetrics->horiBearingY) / 64.0;
}

int face_from_options(lua_State* L) {
  FT_Face face;
  FcChar8 * font_path;
  FcPattern* p;
  FcPattern* matched;
  FcResult result;

  const char *family = "Gentium";
  double pointSize = 12;
  int slant = FC_SLANT_ROMAN;
  int weight = 100;
  const char *script = "latin";
  const char *language = "eng";
  int direction = HB_DIRECTION_LTR;

  if (!lua_istable(L, 1)) return 0;

  lua_pushstring(L, "font");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { family = lua_tostring(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "weight");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) {
    int newWeight = lua_tointeger(L, -1);
    if      (newWeight <= 100) newWeight = FC_WEIGHT_THIN;
    else if (newWeight <= 200) newWeight = FC_WEIGHT_ULTRALIGHT;
    else if (newWeight <= 300) newWeight = FC_WEIGHT_LIGHT;
    else if (newWeight <= 400) newWeight = FC_WEIGHT_NORMAL;
    else if (newWeight <= 500) newWeight = FC_WEIGHT_MEDIUM;
    else if (newWeight <= 600) newWeight = FC_WEIGHT_DEMIBOLD;
    else if (newWeight <= 700) newWeight = FC_WEIGHT_BOLD;
    else if (newWeight <= 800) newWeight = FC_WEIGHT_ULTRABOLD;
    else                       newWeight = FC_WEIGHT_HEAVY;
    weight = newWeight;
  }
  lua_pop(L,1);

  lua_pushstring(L, "size");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { pointSize = lua_tonumber(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "language");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { language = lua_tostring(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "style");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    const char* newStyleAsText = lua_tostring(L, -1);
    if (!strcmp(newStyleAsText, "italic"))
      slant = FC_SLANT_ITALIC;
  }
  lua_pop(L,1);

  p = FcPatternCreate();

  FcPatternAddString (p, FC_FAMILY, (FcChar8*)(family));
  FcPatternAddDouble (p, FC_SIZE, pointSize);
  FcPatternAddInteger(p, FC_SLANT, slant);
  FcPatternAddInteger(p, FC_WEIGHT, weight);

  // /* Add fallback fonts here. Some of the standard 14 should be fine. */
  FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Times-Roman");
  FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Times");
  FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Helvetica");
  matched = FcFontMatch (0, p, &result);
  
  if (FcPatternGetString (matched, FC_FILE, 0, &font_path) != FcResultMatch)
    return 0;
  
  font_path = strdup(font_path);
  if (!font_path) {
    printf("Finding font path failed\n");
    return 0;
  }

  FcPatternDestroy (matched);
  FcPatternDestroy (p);
  lua_newtable(L);
  lua_pushstring(L, "filename");
  lua_pushstring(L, font_path);
  lua_settable(L, -3);
  face = (FT_Face)malloc(sizeof(FT_Face));
  if (FT_New_Face(ft_library, (char*)font_path, 0, &face))
    return 0;

  if (FT_Set_Char_Size(face,pointSize * 64.0, 0, 0, 0))
    return 0;

  lua_pushstring(L, "face");
  lua_pushlightuserdata(L, face);
  lua_settable(L, -3);

  return 1;
}

int shape (lua_State *L) {    
    const char * text = luaL_checkstring(L, 1);
    FT_Face face = lua_touserdata(L, 2);
    const char * script = luaL_checkstring(L, 3);
    hb_direction_t direction = luaL_checkinteger(L, 4);
    const char * lang = luaL_checkstring(L, 5);
    unsigned int glyph_count = 0;
    hb_font_t *hb_ft_font;
    hb_face_t *hb_ft_face;
    hb_buffer_t *buf;
    hb_glyph_info_t *glyph_info;
    hb_glyph_position_t *glyph_pos;
    unsigned int j;

    hb_ft_font = hb_ft_font_create(face, NULL);
    buf = hb_buffer_create();
    hb_buffer_set_script(buf, hb_tag_from_string(script, strlen(script)));
    hb_buffer_set_direction(buf, direction);
    hb_buffer_set_language(buf, hb_language_from_string(lang,strlen(lang)));

    /* Layout the text */
    hb_buffer_add_utf8(buf, text, strlen(text), 0, strlen(text));
    hb_shape(hb_ft_font, buf, NULL, 0);

    glyph_info   = hb_buffer_get_glyph_infos(buf, &glyph_count);
    glyph_pos    = hb_buffer_get_glyph_positions(buf, &glyph_count);
    for (j = 0; j < glyph_count; ++j) {
      char buf[255];
      box glyph_extents  = { 0.0, 0.0, 0.0 };
      calculate_extents(&glyph_extents, glyph_info[j], glyph_pos[j], face);
      // glyph_extents.width += glyph_pos[j].x_offset / 64.0;

      lua_newtable(L);
      lua_pushstring(L, "name");
      FT_Get_Glyph_Name( face, glyph_info[j].codepoint, buf, 255 );      
      lua_pushstring(L, buf);
      lua_settable(L, -3);
      lua_pushstring(L, "codepoint");
      lua_pushinteger(L, glyph_info[j].codepoint);
      lua_settable(L, -3);
      lua_pushstring(L, "width");
      lua_pushnumber(L, glyph_extents.width);
      lua_settable(L, -3);
      lua_pushstring(L, "height");
      lua_pushnumber(L, glyph_extents.height);
      lua_settable(L, -3);
      lua_pushstring(L, "depth");
      lua_pushnumber(L, glyph_extents.depth);
      lua_settable(L, -3);
    }
    /* Cleanup */
    hb_buffer_destroy(buf);
    hb_font_destroy(hb_ft_font);
    return glyph_count;
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
  {"_shape", shape},
  {"_face", face_from_options},
  {NULL, NULL}
};

int luaopen_justenoughharfbuzz (lua_State *L) {
  ft_library = malloc(sizeof(FT_Library));
  FT_Init_FreeType(&ft_library);
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  //lua_setglobal(L, "harfbuzz");
  return 1;
}

