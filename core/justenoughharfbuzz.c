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

void calculate_extents(box* b, hb_glyph_info_t glyph_info, hb_glyph_position_t glyph_pos, FT_Face ft_face) {
  const FT_Error error = FT_Load_Glyph(ft_face, glyph_info.codepoint, FT_LOAD_DEFAULT);
  if (error) return;

  const FT_Glyph_Metrics *ftmetrics = &ft_face->glyph->metrics;
  b->width = glyph_pos.x_advance /64.0;
  b->height = ftmetrics->horiBearingY / 64.0;
  b->depth = (ftmetrics->height - ftmetrics->horiBearingY) / 64.0;
}

int populate_options(fontOptions* f, lua_State* L) {
  int changed = 0;
  if (!lua_istable(L, 2)) return 0;

  lua_pushstring(L, "font");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    const char* newFamily = lua_tostring(L, -1);
    if (strcmp(newFamily, f->family)) changed = 1;
    f->family = (char*)newFamily;
  }
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
    if (newWeight != f->weight) changed = 1;
    f->weight = newWeight;
  }
  lua_pop(L,1);

  lua_pushstring(L, "size");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) {
    double newSize = lua_tonumber(L, -1);
    if (newSize != f->pointSize) changed = 1;
    f->pointSize = newSize;
  }
  lua_pop(L,1);

  // language
  // style
  // variant
  return changed;
}

typedef struct {
  FT_Library ft_library;
  FT_Face ft_face;
} userdata_state;

int shape (lua_State *L) {    
    const char * text = lua_tostring(L, 1);
    static fontOptions* f = NULL;
    unsigned int glyph_count = 0;
    int error;
    hb_font_t *hb_ft_font;
    hb_buffer_t *buf;
    hb_glyph_info_t *glyph_info;
    hb_glyph_position_t *glyph_pos;
    userdata_state *uds;

    unsigned int j;
    int changed = 0;
    if (!f) {
      f = malloc(sizeof(fontOptions));
      f->pointSize = 12;
      f->lang = strdup("eng");
      f->family = strdup("Gentium");
      f->direction = HB_DIRECTION_LTR;
      f->slant = FC_SLANT_ROMAN;
      f->weight = 100;
      f->script = strdup("latin");
      changed = 1;
    }
    changed = populate_options(f, L) | changed;
    // /* Grab state */
    lua_pushstring(L, "hb_uds");
    lua_gettable(L, LUA_REGISTRYINDEX);

    if (lua_isuserdata(L,-1)) {
      uds = (userdata_state*)lua_touserdata(L, -1);
    } else {
      lua_pushstring(L, "hb_uds");            
      uds = lua_newuserdata(L, sizeof(userdata_state));
      lua_settable(L, LUA_REGISTRYINDEX);
      uds->ft_library = malloc(sizeof(FT_Library));
      FT_Init_FreeType(&(uds->ft_library));
      uds->ft_face = NULL;
      luaL_getmetatable(L, "JEHB.state");
      lua_setmetatable(L, -2);
    }
    lua_pop(L,1);
    /* Load our fonts */
    if (changed) {
      FcChar8 * font_path;
      FcPattern* p;
      FcPattern* matched;
      FcResult result;
      p = FcPatternCreate();
      assert(f->family);
      FcPatternAddString (p, FC_FAMILY, (FcChar8*)(f->family));
      FcPatternAddDouble (p, FC_SIZE, f->pointSize);
      if (f->slant)
        FcPatternAddInteger(p, FC_SLANT, f->slant);
      if (f->weight)
        FcPatternAddInteger(p, FC_WEIGHT, f->weight);

      // /* Add fallback fonts here. Some of the standard 14 should be fine. */
      FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Times-Roman");
      FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Times");
      FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Helvetica");
      matched = FcFontMatch (0, p, &result);
      
      if (FcPatternGetString (matched, FC_FILE, 0, &font_path) != FcResultMatch)
        return 0;

      if (uds->ft_face) { FT_Done_Face(uds->ft_face); }
      uds->ft_face = malloc(sizeof(FT_Face));
      if (!font_path) {
        printf("Finding font path failed\n");
        return 0;
      }
      if (FT_New_Face(uds->ft_library, (char*)font_path, 0, &(uds->ft_face)))
        return 0;
      if (FT_Set_Char_Size(uds->ft_face,f->pointSize * 64.0, 0, 0, 0))
        return 0;
      FcPatternDestroy (matched);
      FcPatternDestroy (p);
      // free(font_path);
    }

    /* Get our harfbuzz font structs */
    hb_ft_font = hb_ft_font_create(uds->ft_face, NULL);
    hb_font_set_ppem(hb_ft_font, 0, 0);
    buf = hb_buffer_create();
    if (f->script)
      hb_buffer_set_script(buf, hb_tag_from_string(f->script, strlen(f->script)));
    if (f->direction)
      hb_buffer_set_direction(buf, f->direction);
    if (f->lang)
      hb_buffer_set_language(buf, hb_language_from_string(f->lang,strlen(f->lang)));

    /* Layout the text */
    hb_buffer_add_utf8(buf, text, strlen(text), 0, strlen(text));
    hb_shape(hb_ft_font, buf, NULL, 0);

    glyph_info   = hb_buffer_get_glyph_infos(buf, &glyph_count);
    glyph_pos    = hb_buffer_get_glyph_positions(buf, &glyph_count);
    for (j = 0; j < glyph_count; ++j) {
      char buf[255];
      box glyph_extents  = { 0.0, 0.0, 0.0 };
      calculate_extents(&glyph_extents, glyph_info[j], glyph_pos[j], uds->ft_face);
      glyph_extents.width += glyph_pos[j].x_offset / 64.0;
      //assert(!glyph_pos[j].x_offset);
      /* Add kerning? */
      if (j < glyph_count) {
        hb_position_t kern = hb_font_get_glyph_h_kerning(hb_ft_font, glyph_info[j].codepoint, glyph_info[j+1].codepoint);
        glyph_extents.width += kern;
      }
      lua_newtable(L);
      lua_pushstring(L, "name");
      FT_Get_Glyph_Name( uds->ft_face, glyph_info[j].codepoint, buf, 255 );      
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


static const struct luaL_reg lib_table [] = {
  {"_shape", shape},
  {NULL, NULL}
};
    
int jehb_gc(lua_State *L) {
  userdata_state *uds = lua_touserdata(L, 1);
  printf("Destructor called\n");
  FT_Done_Face(uds->ft_face);
  FT_Done_FreeType(uds->ft_library);
  return 0;
}

int luaopen_justenoughharfbuzz (lua_State *L) {
  // luaL_newmetatable(L, "JEHB.state");
  // lua_pushstring(L, "__gc");
  // lua_pushcfunction(L, jehb_gc);  
  // lua_settable(L, -3);

  luaL_openlib(L, "justenoughharfbuzz", lib_table, 0);
  return 1;
}

