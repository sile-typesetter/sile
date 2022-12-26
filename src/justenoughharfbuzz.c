#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <hb.h>
#include <hb-ot.h>
#include <hb-ft.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "silewin32.h"

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
      if (param == 0)
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

static char** scan_shaper_list(char* cp1) {
  char** res = NULL;
  char* cp2;
  int n_elems = 0;
  int i;
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
    if (*cp2 == 0) {
      res = realloc (res, sizeof (char*) * ++n_elems);
      res[n_elems-1] = cp1;
      break;
    } else {
      *cp2 = '\0';
      res = realloc (res, sizeof (char*) * ++n_elems);
      res[n_elems-1] = cp1;
    }
    cp1 = cp2+1;
  }
  res = realloc (res, sizeof (char*) * (n_elems+1));
  res[n_elems] = 0;
  return res;
}

int can_use_ot_funcs (hb_face_t* face) {
  if (hb_version_atleast(2,3,0)) return 1;
  hb_blob_t *cff = hb_face_reference_table(face, hb_tag_from_string("CFF ", 4));
  return hb_blob_get_length(cff) == 0;
}

int shape (lua_State *L) {
    size_t font_l;
    const char * text = luaL_checkstring(L, 1);
    const char * font_s = luaL_checklstring(L, 2, &font_l);
    unsigned int font_index = luaL_checknumber(L, 3);
    const char * script = luaL_checkstring(L, 4);
    const char * direction_s = luaL_checkstring(L, 5);
    const char * lang = luaL_checkstring(L, 6);
    double point_size = luaL_checknumber(L, 7);
    const char * featurestring = luaL_checkstring(L, 8);
    char * shaper_list_string = luaL_checkstring(L, 9);
    char ** shaper_list = NULL;
    if (strlen(shaper_list_string) > 0) {
      shaper_list = scan_shaper_list(shaper_list_string);
    }

    hb_direction_t direction;
    hb_feature_t* features;
    int nFeatures = 0;
    unsigned int glyph_count = 0;
    hb_font_t *hbFont;
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

    hb_blob_t* blob = hb_blob_create (font_s, font_l, HB_MEMORY_MODE_WRITABLE, (void*)font_s, NULL);
    hb_face_t* hbFace = hb_face_create (blob, font_index);
    hbFont = hb_font_create (hbFace);
    unsigned int upem = hb_face_get_upem(hbFace);
    hb_font_set_scale(hbFont, upem, upem);

    hb_variation_t opsz = { HB_TAG('o', 'p', 's', 'z'), point_size };
    hb_font_set_variations(hbFont, &opsz, 1);

    if (can_use_ot_funcs(hbFace)) {
      hb_ot_font_set_funcs(hbFont);
    } else {
      /*
        Note that using FT may cause differing vertical metrics for CFF fonts.
        SILE will give a one-time warning if this is the case.
      */
      hb_ft_font_set_funcs(hbFont);
    }

    buf = hb_buffer_create();
    hb_buffer_add_utf8(buf, text, strlen(text), 0, strlen(text));

    hb_buffer_set_script(buf, hb_tag_from_string(script, strlen(script)));
    hb_buffer_set_direction(buf, direction);
    hb_buffer_set_language(buf, hb_language_from_string(lang,strlen(lang)));

    hb_buffer_guess_segment_properties(buf);
    int res = hb_shape_full (hbFont, buf, features, nFeatures, shaper_list);

    if (direction == HB_DIRECTION_RTL) {
      hb_buffer_reverse(buf); /* URGH */
    }
    glyph_info   = hb_buffer_get_glyph_infos(buf, &glyph_count);
    glyph_pos    = hb_buffer_get_glyph_positions(buf, &glyph_count);
    lua_checkstack(L, glyph_count);
    for (j = 0; j < glyph_count; ++j) {
      char namebuf[255];
      hb_glyph_extents_t extents = {0,0,0,0};
      hb_font_get_glyph_extents(hbFont, glyph_info[j].codepoint, &extents);

      lua_newtable(L);
      lua_pushstring(L, "name");
      hb_font_get_glyph_name( hbFont, glyph_info[j].codepoint, namebuf, 255 );
      lua_pushstring(L, namebuf);
      lua_settable(L, -3);

      /* We don't apply x-offset and y-offsets for TTB, which
      is arguably a bug. We should. The reason we don't is that
      Harfbuzz assumes that you want to shift the character from a
      top-center baseline to a bottom-left baseline, and gives you
      offsets which do that. We don't want to do that so we ignore the
      offsets. I'm told there is a way of configuring HB's idea of the
      baseline, and we should use that and take out this condition. */
      if (direction != HB_DIRECTION_TTB) {
        if (glyph_pos[j].x_offset) {
          lua_pushstring(L, "x_offset");
          lua_pushnumber(L, glyph_pos[j].x_offset * point_size / upem);
          lua_settable(L, -3);
        }

        if (glyph_pos[j].y_offset) {
          lua_pushstring(L, "y_offset");
          lua_pushnumber(L, glyph_pos[j].y_offset * point_size / upem);
          lua_settable(L, -3);
        }
      }

      lua_pushstring(L, "gid");
      lua_pushinteger(L, glyph_info[j].codepoint);
      lua_settable(L, -3);
      lua_pushstring(L, "index");
      lua_pushinteger(L, glyph_info[j].cluster);
      lua_settable(L, -3);

      double height = extents.y_bearing * point_size / upem;
      double tHeight = extents.height * point_size / upem;
      double width = glyph_pos[j].x_advance * point_size / upem;

      /* The PDF model expects us to make positioning adjustments
      after a glyph is painted. For this we need to know the natural
      glyph advance. libtexpdf will use this to compute the adjustment. */
      double glyphAdvance = hb_font_get_glyph_h_advance(hbFont, glyph_info[j].codepoint) * point_size / upem;

      if (direction == HB_DIRECTION_TTB) {
        height = -glyph_pos[j].y_advance * point_size / upem;
        tHeight = -height; /* Set depth to 0 - depth has no meaning for TTB */
        width = glyphAdvance;
        glyphAdvance = height;
      }
      lua_pushstring(L, "glyphAdvance");
      lua_pushnumber(L, glyphAdvance);
      lua_settable(L, -3);

      lua_pushstring(L, "width");
      lua_pushnumber(L, width);
      lua_settable(L, -3);

      lua_pushstring(L, "height");
      lua_pushnumber(L, height);
      lua_settable(L, -3);
      lua_pushstring(L, "depth");
      lua_pushnumber(L, -tHeight - height);
      lua_settable(L, -3);
    }
    /* Cleanup */
    hb_buffer_destroy(buf);
    hb_font_destroy(hbFont);
    hb_face_destroy(hbFace);
    hb_blob_destroy(blob);

    free(features);
    return glyph_count;
}

int get_glyph_dimensions(lua_State *L) {
  size_t font_l;
  const char * font_s = luaL_checklstring(L, 1, &font_l);
  unsigned int font_index = (unsigned int)luaL_checknumber(L, 2);
  double point_size = (unsigned int)luaL_checknumber(L, 3);
  hb_codepoint_t glyphId = (hb_codepoint_t)luaL_checknumber(L, 4);

  hb_blob_t* blob = hb_blob_create(font_s, font_l, HB_MEMORY_MODE_WRITABLE,
      (void*)font_s, NULL);
  hb_face_t* hbFace = hb_face_create(blob, font_index);
  hb_font_t* hbFont = hb_font_create(hbFace);
  unsigned int upem = hb_face_get_upem(hbFace);
  hb_font_set_scale(hbFont, upem, upem);

  hb_variation_t opsz = { HB_TAG('o', 'p', 's', 'z'), point_size };
  hb_font_set_variations(hbFont, &opsz, 1);

  if (can_use_ot_funcs(hbFace)) {
    hb_ot_font_set_funcs(hbFont);
  } else {
    /*
      Note that using FT may cause differing vertical metrics for CFF fonts.
      SILE will give a one-time warning if this is the case.
    */
    hb_ft_font_set_funcs(hbFont);
  }

  hb_glyph_extents_t extents = {0,0,0,0};
  hb_font_get_glyph_extents(hbFont, glyphId, &extents);

  double height = extents.y_bearing * point_size / upem;
  double tHeight = extents.height * point_size / upem;
  double width = extents.width * point_size / upem;
  /* The PDF model expects us to make positioning adjustments
  after a glyph is painted. For this we need to know the natural
  glyph advance. libtexpdf will use this to compute the adjustment. */
  double glyphAdvance = hb_font_get_glyph_h_advance(hbFont,
    glyphId) * point_size / upem;

  lua_newtable(L);
  lua_pushstring(L, "glyphAdvance");
  lua_pushnumber(L, glyphAdvance);
  lua_settable(L, -3);
  lua_pushstring(L, "width");
  lua_pushnumber(L, width);
  lua_settable(L, -3);
  lua_pushstring(L, "height");
  lua_pushnumber(L, height);
  lua_settable(L, -3);
  lua_pushstring(L, "depth");
  lua_pushnumber(L, -tHeight - height);
  lua_settable(L, -3);

  /* Cleanup */
  hb_font_destroy(hbFont);

  return 1;
}

int get_harfbuzz_version (lua_State *L) {
  unsigned int major;
  unsigned int minor;
  unsigned int micro;
  char version[256];
  hb_version(&major, &minor, &micro);
  sprintf(version, "%i.%i.%i", major, minor, micro);
  lua_pushstring(L, version);
  return 1;
}

int version_lessthan (lua_State *L) {
  unsigned int major = luaL_checknumber(L, 1);
  unsigned int minor = luaL_checknumber(L, 2);
  unsigned int micro = luaL_checknumber(L, 3);
  lua_pushboolean(L, !hb_version_atleast(major,minor,micro));
  return 1;
}

int list_shapers (lua_State *L) {
  const char **shaper_list = hb_shape_list_shapers ();
  int i = 0;

  for (; *shaper_list; shaper_list++) {
    i++;
    lua_pushstring(L, *shaper_list);
  }
  return i;
}

int get_table (lua_State *L) {
  size_t font_l, tag_l;
  const char * font_s = luaL_checklstring(L, 1, &font_l);
  unsigned int font_index = luaL_checknumber(L, 2);
  const char * tag_s = luaL_checklstring(L, 3, &tag_l);

  hb_blob_t * blob = hb_blob_create (font_s, font_l, HB_MEMORY_MODE_WRITABLE, (void*)font_s, NULL);
  hb_face_t * face = hb_face_create (blob, font_index);
  hb_blob_t * table = hb_face_reference_table(face, hb_tag_from_string(tag_s, tag_l));

  unsigned int table_l;
  const char * table_s = hb_blob_get_data(table, &table_l);

  lua_pushlstring(L, table_s, table_l);

  hb_blob_destroy(table);
  hb_face_destroy(face);
  hb_blob_destroy(blob);

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
  {"_shape", shape},
  {"get_glyph_dimensions", get_glyph_dimensions},
  {"version", get_harfbuzz_version},
  {"shapers", list_shapers},
  {"get_table", get_table},
  {"version_lessthan", version_lessthan},
  {NULL, NULL}
};

int luaopen_justenoughharfbuzz (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  //lua_setglobal(L, "harfbuzz");
  return 1;
}

