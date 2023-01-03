#include "hb-utils.h"

#include <stdlib.h>
#include <hb-ot.h>

static hb_variation_t* scan_variation_string(const char* cp1, unsigned int* ret) {
  hb_variation_t* variations = NULL;
  hb_variation_t variation;
  unsigned int nVariations = 0;
  const char* cp2;

  if (!cp1)
    return NULL;

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

    if (hb_variation_from_string(cp1, cp2 - cp1, &variation)) {
      variations = realloc(variations, (nVariations + 1) * sizeof(hb_variation_t));
      variations[nVariations++] = variation;
    }

    cp1 = cp2;
  }
  *ret = nVariations;
  return variations;
}

hb_font_t* get_hb_font(lua_State *L, int index) {
  const char * filename;
  int face_index = 0;
  hb_blob_t* blob;
  hb_face_t* face;
  hb_font_t* font;
  unsigned int upem;

  luaL_checktype(L, index, LUA_TTABLE);

  lua_getfield(L, index, "hbFont");
  if (lua_islightuserdata(L, -1)) { return lua_touserdata(L, -1); }

  lua_getfield(L, index, "filename");
  filename = luaL_checkstring(L, -1);

  lua_getfield(L, index, "index");
  if (lua_isnumber(L, -1)) { face_index = lua_tointeger(L, -1); }

  blob = hb_blob_create_from_file(filename);
  face = hb_face_create(blob, face_index);
  font = hb_font_create(face);
  upem = hb_face_get_upem(face);
  hb_font_set_scale(font, upem, upem);

  hb_ot_font_set_funcs(font);

#if HB_VERSION_ATLEAST(3, 3, 0)
  if (hb_ot_var_has_data(face)) {
    hb_ot_var_axis_info_t* axes;
    unsigned int nAxes;
    unsigned int nCoords;
    const float* coords;
    float* newCoords;

    /* Get font axes */
    nAxes = hb_ot_var_get_axis_infos(face, 0, NULL, NULL);
    axes = malloc(nAxes * sizeof(hb_ot_var_axis_info_t));
    hb_ot_var_get_axis_infos(face, 0, &nAxes, axes);

    /* Get existing variation coords, e.g. from named instance */
    coords = hb_font_get_var_coords_design(font, &nCoords);

    /* Set up new variation coords */

    /* First copy existing coords (e.g. from named instance) or use axis
     * default value. */
    newCoords = malloc(nAxes * sizeof(float));
    for (unsigned i = 0; i < nAxes; i++) {
      if (i < nCoords)
        newCoords[i] = coords[i];
      else
        newCoords[i] = axes[i].default_value;
    }

    /* Then we set variation axes that have corresponding font options. */
    for (unsigned i = 0; i < nAxes; i++) {
      switch (axes[i].tag) {
        case HB_TAG('o', 'p', 's', 'z'):
          lua_getfield(L, index, "pointsize");
          if (lua_isnumber(L, -1)) { newCoords[i] = lua_tonumber(L, -1); }
          break;
        case HB_TAG('w', 'g', 'h', 't'):
          lua_getfield(L, index, "weight");
          if (lua_isnumber(L, -1)) { newCoords[i] = lua_tonumber(L, -1); }
          break;
        default: break;
      }
    }

    /* Finally use any explicitly set variations */
    lua_getfield(L, index, "variations");
    if (lua_isstring(L, -1)) {
      const char* variationstring = lua_tostring(L, -1);
      unsigned int nVariations = 0;
      hb_variation_t* variations = scan_variation_string(variationstring, &nVariations);
      if (variations) {
        for (unsigned nVariation = 0; nVariation < nVariations; nVariation++) {
          for (unsigned nAxis = 0; nAxis < nAxes; nAxis++) {
            if (variations[nVariation].tag == axes[nAxis].tag)
              newCoords[nAxis] = variations[nVariation].value;
          }
        }
        free(variations);
      }
    }

    hb_font_set_var_coords_design(font, newCoords, nAxes);

    free(axes);
    free(newCoords);
  }
#endif

  hb_face_destroy(face);
  hb_blob_destroy(blob);

  lua_pushlightuserdata(L, font);
  lua_setfield(L, index, "hbFont");

  return font;
}


