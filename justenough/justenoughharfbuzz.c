#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <hb.h>
#include <hb-ot.h>
#ifdef HAVE_HARFBUZZ_SUBSET
#include <hb-subset.h>
#endif
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "hb-utils.h"
#include "silewin32.h"

#include "compat-5.2.c"

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

int je_hb_shape (lua_State *L) {
    size_t font_l;
    const char * text = luaL_checkstring(L, 1);
    hb_font_t * hbFont = get_hb_font(L, 2);
    const char * script = luaL_checkstring(L, 3);
    const char * direction_s = luaL_checkstring(L, 4);
    const char * lang = luaL_checkstring(L, 5);
    double point_size = luaL_checknumber(L, 6);
    const char * featurestring = luaL_checkstring(L, 7);
    char * shaper_list_string = (char *)luaL_checkstring(L, 8);
    const char * const* shaper_list = NULL;
    if (strlen(shaper_list_string) > 0) {
      shaper_list = (const char * const*)scan_shaper_list(shaper_list_string);
    }

    hb_direction_t direction;
    hb_feature_t* features;
    int nFeatures = 0;
    unsigned int glyph_count = 0;
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

    unsigned int upem = hb_face_get_upem(hb_font_get_face(hbFont));

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
    for (j = 0; j < glyph_count; ++j) {
      char namebuf[255];
      hb_glyph_extents_t extents = {0,0,0,0};
      hb_font_get_glyph_extents(hbFont, glyph_info[j].codepoint, &extents);

      lua_checkstack(L, 3);
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
          lua_checkstack(L, 2);
          lua_pushstring(L, "x_offset");
          lua_pushnumber(L, glyph_pos[j].x_offset * point_size / upem);
          lua_settable(L, -3);
        }

        if (glyph_pos[j].y_offset) {
          lua_checkstack(L, 2);
          lua_pushstring(L, "y_offset");
          lua_pushnumber(L, glyph_pos[j].y_offset * point_size / upem);
          lua_settable(L, -3);
        }
      }

      lua_checkstack(L, 2);
      lua_pushstring(L, "gid");
      lua_pushinteger(L, glyph_info[j].codepoint);
      lua_settable(L, -3);
      lua_checkstack(L, 2);
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
      lua_checkstack(L, 2);
      lua_pushstring(L, "glyphAdvance");
      lua_pushnumber(L, glyphAdvance);
      lua_settable(L, -3);

      lua_checkstack(L, 2);
      lua_pushstring(L, "width");
      lua_pushnumber(L, width);
      lua_settable(L, -3);

      lua_checkstack(L, 2);
      lua_pushstring(L, "height");
      lua_pushnumber(L, height);
      lua_settable(L, -3);
      lua_checkstack(L, 2);
      lua_pushstring(L, "depth");
      lua_pushnumber(L, -tHeight - height);
      lua_settable(L, -3);
    }
    /* Cleanup */
    hb_buffer_destroy(buf);

    free(features);
    return glyph_count;
}

static int has_table(hb_face_t* face, hb_tag_t tag) {
  hb_blob_t *blob = hb_face_reference_table(face, tag);
  int ret = hb_blob_get_length(blob) != 0;
  hb_blob_destroy(blob);
  return ret;
}

int je_hb_instanciate(lua_State *L) {
  unsigned int data_l = 0;
  const char * data_s = NULL;
#ifdef HAVE_HARFBUZZ_SUBSET

  hb_font_t* font = get_hb_font(L, 1);
  hb_face_t* face = hb_font_get_face(font);

  if (hb_ot_var_has_data(face) &&
      /* hb-subset does not support instanciating CFF2 table yet */
      !has_table(face, HB_TAG('C','F','F','2'))) {
    hb_subset_input_t * input;

    input = hb_subset_input_create_or_fail();
    if (input) {
      hb_ot_var_axis_info_t* axes;
      unsigned int nAxes;
      unsigned int nCoords;
      const float* coords;
      hb_face_t* subset;
      hb_set_t* glyphs;
      hb_set_t* tables;

      hb_subset_input_set_flags(input,
                                HB_SUBSET_FLAGS_RETAIN_GIDS |
                                HB_SUBSET_FLAGS_NAME_LEGACY |
                                HB_SUBSET_FLAGS_GLYPH_NAMES |
                                HB_SUBSET_FLAGS_NO_PRUNE_UNICODE_RANGES);

      /* Keep all glyphs */
      glyphs = hb_subset_input_set(input, HB_SUBSET_SETS_GLYPH_INDEX);
      hb_set_invert(glyphs);

      /* Keep only tables required for PDF */
      tables = hb_subset_input_set(input, HB_SUBSET_SETS_DROP_TABLE_TAG);
      hb_set_add(tables, HB_TAG('O','S','/','2'));
      hb_set_add(tables, HB_TAG('c','m','a','p'));
      hb_set_add(tables, HB_TAG('c','v','t',' '));
      hb_set_add(tables, HB_TAG('f','p','g','m'));
      hb_set_add(tables, HB_TAG('g','l','y','f'));
      hb_set_add(tables, HB_TAG('h','e','a','d'));
      hb_set_add(tables, HB_TAG('h','h','e','a'));
      hb_set_add(tables, HB_TAG('h','m','t','x'));
      hb_set_add(tables, HB_TAG('l','o','c','a'));
      hb_set_add(tables, HB_TAG('m','a','x','p'));
      hb_set_add(tables, HB_TAG('n','a','m','e'));
      hb_set_add(tables, HB_TAG('p','o','s','t'));
      hb_set_add(tables, HB_TAG('p','r','e','p'));
      hb_set_invert(tables);

      /* Get font axes */
      nAxes = hb_ot_var_get_axis_infos(face, 0, NULL, NULL);
      axes = malloc(nAxes * sizeof(hb_ot_var_axis_info_t));
      hb_ot_var_get_axis_infos(face, 0, &nAxes, axes);

      /* Get set variation coords */
      coords = hb_font_get_var_coords_design(font, &nCoords);

      /* Pin all axes */
      for (unsigned i = 0; i < nAxes; i++) {
        if (i < nCoords)
          hb_subset_input_pin_axis_location(input, face, axes[i].tag, coords[i]);
        else
          hb_subset_input_pin_axis_to_default(input, face, axes[i].tag);
      }

      subset = hb_subset_or_fail(face, input);
      if (subset) {
        hb_blob_t *data;

        data = hb_face_reference_blob(subset);
        data_s = hb_blob_get_data(data, &data_l);
        if (data_s && data_l)
          lua_pushlstring(L, data_s, data_l);
        hb_face_destroy(subset);
        hb_blob_destroy(data);
      }

      hb_subset_input_destroy(input);
      free(axes);
    }
  }
#endif

  if (!data_s || !data_l)
    lua_pushnil(L);

  return 1;
}

int je_hb_get_glyph_dimensions(lua_State *L) {
  hb_font_t* hbFont = get_hb_font(L, 1);
  double point_size = (unsigned int)luaL_checknumber(L, 2);
  hb_codepoint_t glyphId = (hb_codepoint_t)luaL_checknumber(L, 3);

  hb_glyph_extents_t extents = {0,0,0,0};
  hb_font_get_glyph_extents(hbFont, glyphId, &extents);

  unsigned int upem = hb_face_get_upem(hb_font_get_face(hbFont));
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

  return 1;
}

int je_hb_get_harfbuzz_version (lua_State *L) {
  unsigned int major;
  unsigned int minor;
  unsigned int micro;
  char version[256];
  hb_version(&major, &minor, &micro);
  sprintf(version, "%i.%i.%i", major, minor, micro);
  lua_pushstring(L, version);
  return 1;
}

int je_hb_version_lessthan (lua_State *L) {
  unsigned int major = luaL_checknumber(L, 1);
  unsigned int minor = luaL_checknumber(L, 2);
  unsigned int micro = luaL_checknumber(L, 3);
  lua_pushboolean(L, !hb_version_atleast(major,minor,micro));
  return 1;
}

int je_hb_list_shapers (lua_State *L) {
  const char **shaper_list = hb_shape_list_shapers ();
  int i = 0;

  for (; *shaper_list; shaper_list++) {
    i++;
    lua_pushstring(L, *shaper_list);
  }
  return i;
}

int je_hb_get_table (lua_State *L) {
  size_t tag_l;
  hb_face_t * face = hb_font_get_face(get_hb_font(L, 1));
  const char * tag_s = luaL_checklstring(L, 2, &tag_l);
  hb_blob_t * table = hb_face_reference_table(face, hb_tag_from_string(tag_s, tag_l));

  unsigned int table_l;
  const char * table_s = hb_blob_get_data(table, &table_l);

  lua_pushlstring(L, table_s, table_l);

  hb_blob_destroy(table);

  return 1;
}

static const struct luaL_Reg lib_table [] = {
  {"_shape", je_hb_shape},
  {"get_glyph_dimensions", je_hb_get_glyph_dimensions},
  {"version", je_hb_get_harfbuzz_version},
  {"shapers", je_hb_list_shapers},
  {"get_table", je_hb_get_table},
  {"instanciate", je_hb_instanciate},
  {"version_lessthan", je_hb_version_lessthan},
  {NULL, NULL}
};

int luaopen_justenoughharfbuzz (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
