#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OUTLINE_H
#include FT_ADVANCES_H

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

FT_Library ft_library;

int face_from_options(lua_State* L) {
  FT_Face face;
  FcChar8 * font_path, * fullname, * familyname;
  FcPattern* p;
  FcPattern* matched;
  FcResult result;
  int index = 0;

  const char *family = "Gentium";
  double pointSize = 12;
  int slant = FC_SLANT_ROMAN;
  int weight = 100;
  const char *script = "latin";
  const char *language = "eng";
  int direction = HB_DIRECTION_LTR;

  if (!lua_istable(L, 1)) return 0;

  lua_pushstring(L, "size");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { pointSize = lua_tonumber(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "filename");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    font_path = lua_tostring(L, -1);
    lua_pop(L,1);
    lua_newtable(L);
    lua_pushstring(L, "filename");
    lua_pushstring(L, (char*)font_path);
    lua_settable(L, -3);
    goto done_match;
  }
  lua_pop(L,1);

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
  
  FcPatternGetInteger(matched, FC_INDEX, 0, &index);
  font_path = (FcChar8 *)strdup((char*)font_path); /* XXX signedness problems? */
  if (!font_path) {
    printf("Finding font path failed\n");
    return 0;
  }
  /* Push back slant and weight, we need to pass them to libpdftex */
  FcPatternGetInteger(matched, FC_SLANT, 0, &slant);
  FcPatternGetInteger(matched, FC_WEIGHT, 0, &weight);

  /* Find out which family we did actually pick up */
  if (FcPatternGetString (matched, FC_FAMILY, 0, &familyname) != FcResultMatch)
    return 0;

  lua_newtable(L);
  lua_pushstring(L, "filename");
  lua_pushstring(L, (char*)font_path);
  lua_settable(L, -3);

  lua_pushstring(L, "family");
  lua_pushstring(L, (char*)(familyname));
  lua_settable(L, -3);

  if (FcPatternGetString (matched, FC_FULLNAME, 0, &fullname) == FcResultMatch) {
    lua_pushstring(L, "fullname");
    lua_pushstring(L, (char*)(fullname));
    lua_settable(L, -3);
  }

  FcPatternDestroy (matched);
  FcPatternDestroy (p);

  done_match:
  face = (FT_Face)malloc(sizeof(FT_Face));
  if (FT_New_Face(ft_library, (char*)font_path, index, &face))
    return 0;

  if (FT_Set_Char_Size(face,pointSize * 64.0, 0, 0, 0))
    return 0;

  lua_pushstring(L, "index");
  lua_pushinteger(L, index);
  lua_settable(L, -3);

  lua_pushstring(L, "pointsize");
  lua_pushnumber(L, pointSize);
  lua_settable(L, -3);

  lua_pushstring(L, "face");
  lua_pushlightuserdata(L, face);
  lua_settable(L, -3);

  return 1;
}

/* The following function stolen from XeTeX_ext.c */
static hb_tag_t
read_tag_with_param(const char* cp, int* param)
{
  const char* cp2;
  hb_tag_t tag;
  int i;

  cp2 = cp;
  while (*cp2 && (*cp2 != ':') && (*cp2 != ';') && (*cp2 != ',') && (*cp2 != '='))
    ++cp2;

  tag = hb_tag_from_string(cp, cp2 - cp);

  cp = cp2;
  if (*cp == '=') {
    int neg = 0;
    ++cp;
    if (*cp == '-') {
      ++neg;
      ++cp;
    }
    while (*cp >= '0' && *cp <= '9') {
      *param = *param * 10 + *cp - '0';
      ++cp;
    }
    if (neg)
      *param = -(*param);
  }

  return tag;
}

static hb_feature_t* scan_feature_string(const char* cp1, int* ret) {
  hb_feature_t* features = NULL;
  hb_tag_t  tag;  
  int nFeatures = 0;
  const char* cp2;
  const char* cp3;
  while (*cp1) {
    if ((*cp1 == ':') || (*cp1 == ';') || (*cp1 == ','))
      ++cp1;
    while ((*cp1 == ' ') || (*cp1 == '\t')) /* skip leading whitespace */
      ++cp1;
    if (*cp1 == 0)  /* break if end of string */
      break;

    cp2 = cp1;
    while (*cp2 && (*cp2 != ':') && (*cp2 != ';') && (*cp2 != ','))
      ++cp2;
    
    if (*cp1 == '+') {
      int param = 0;
      tag = read_tag_with_param(cp1 + 1, &param);
      features = realloc(features, (nFeatures + 1) * sizeof(hb_feature_t));
      features[nFeatures].tag = tag;
      features[nFeatures].start = 0;
      features[nFeatures].end = (unsigned int) -1;
      if (param >= 0)
        param++;
      features[nFeatures].value = param;
      nFeatures++;
      goto next_option;
    }
    
    if (*cp1 == '-') {
      ++cp1;
      tag = hb_tag_from_string(cp1, cp2 - cp1);
      features = realloc(features, (nFeatures + 1) * sizeof(hb_feature_t));
      features[nFeatures].tag = tag;
      features[nFeatures].start = 0;
      features[nFeatures].end = (unsigned int) -1;
      features[nFeatures].value = 0;
      nFeatures++;
      goto next_option;
    }
    
  bad_option:
    //fontfeaturewarning(cp1, cp2 - cp1, 0, 0);
  
  next_option:
    cp1 = cp2;
  }
  *ret = nFeatures;
  return features;
}

int shape (lua_State *L) {    
    const char * text = luaL_checkstring(L, 1);
    FT_Face face = lua_touserdata(L, 2);
    const char * script = luaL_checkstring(L, 3);
    const char * direction_s = luaL_checkstring(L, 4);
    const char * lang = luaL_checkstring(L, 5);
    double point_size = luaL_checknumber(L, 6);
    const char * featurestring = luaL_checkstring(L, 7);

    hb_segment_properties_t segment_props;
    hb_shape_plan_t *shape_plan;

    hb_direction_t direction;
    hb_feature_t* features;
    int nFeatures = 0;
    unsigned int glyph_count = 0;
    hb_font_t *hb_ft_font;
    hb_face_t *hb_ft_face;
    hb_buffer_t *buf;
    hb_glyph_info_t *glyph_info;
    hb_glyph_position_t *glyph_pos;
    unsigned int j;

    features = scan_feature_string(featurestring, &nFeatures);

    if (!strcasecmp(direction_s,"RTL"))
      direction = HB_DIRECTION_RTL;
    else if (!strcasecmp(direction_s,"TTB"))
      direction = HB_DIRECTION_TTB;
    else
      direction = HB_DIRECTION_LTR;

    hb_face_t* hbFace = hb_ft_face_create_cached(face);
    hb_ft_font = hb_font_create (hbFace);
    unsigned int upem = hb_face_get_upem(hbFace);
    hb_font_set_scale(hb_ft_font, upem, upem);
    hb_ft_font_set_funcs(hb_ft_font);

    buf = hb_buffer_create();
    hb_buffer_add_utf8(buf, text, strlen(text), 0, strlen(text));

    hb_buffer_set_script(buf, hb_tag_from_string(script, strlen(script)));
    hb_buffer_set_direction(buf, direction);
    hb_buffer_set_language(buf, hb_language_from_string(lang,strlen(lang)));

    hb_buffer_guess_segment_properties(buf);
    hb_buffer_get_segment_properties(buf, &segment_props);
    shape_plan = hb_shape_plan_create_cached(hbFace, &segment_props, features, nFeatures, NULL);
    int res = hb_shape_plan_execute(shape_plan, hb_ft_font, buf, features, nFeatures);

    glyph_info   = hb_buffer_get_glyph_infos(buf, &glyph_count);
    glyph_pos    = hb_buffer_get_glyph_positions(buf, &glyph_count);
    lua_checkstack(L, glyph_count);
    for (j = 0; j < glyph_count; ++j) {
      char namebuf[255];
      hb_glyph_extents_t extents = {0,0,0,0};
      hb_font_get_glyph_extents(hb_ft_font, glyph_info[j].codepoint, &extents);

      lua_newtable(L);
      lua_pushstring(L, "name");
      hb_font_get_glyph_name( hb_ft_font, glyph_info[j].codepoint, namebuf, 255 );
      lua_pushstring(L, namebuf);
      lua_settable(L, -3);

      if (direction != HB_DIRECTION_TTB) { /* XXX */
        if (glyph_pos[j].x_offset) {
          lua_pushstring(L, "x_offset");
          lua_pushnumber(L, glyph_pos[j].x_offset / 64.0);
          lua_settable(L, -3);
        }

        if (glyph_pos[j].y_offset) {
          lua_pushstring(L, "y_offset");
          lua_pushnumber(L, glyph_pos[j].y_offset / 64.0);
          lua_settable(L, -3);
        }
      }

      lua_pushstring(L, "codepoint");
      lua_pushinteger(L, glyph_info[j].codepoint);
      lua_settable(L, -3);
      lua_pushstring(L, "index");
      lua_pushinteger(L, glyph_info[j].cluster);
      lua_settable(L, -3);
      lua_pushstring(L, "width");
      lua_pushnumber(L, glyph_pos[j].x_advance * point_size / upem);
      lua_settable(L, -3);

      double height = extents.y_bearing * point_size / upem;
      double tHeight = extents.height * point_size / upem;
      if (direction == HB_DIRECTION_TTB) { /* XXX */
        height = -glyph_pos[j].y_advance * point_size / upem;
        tHeight = 0;
      }
      lua_pushstring(L, "height");
      lua_pushnumber(L, height);
      lua_settable(L, -3);
      lua_pushstring(L, "depth");
      lua_pushnumber(L, tHeight + height);
      lua_settable(L, -3);
    }
    /* Cleanup */
    hb_buffer_destroy(buf);
    hb_font_destroy(hb_ft_font);
    hb_shape_plan_destroy(shape_plan);

    free(features);
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

