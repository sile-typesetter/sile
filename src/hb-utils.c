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

  if (hb_ot_var_has_data(face)) {
    const char* variationstring = NULL;
    unsigned int nVariations = 0;

    lua_getfield(L, index, "pointsize");
    if (lua_isnumber(L, -1)) {
      double point_size = luaL_checknumber(L, -1);

      /* Set ‘opsz’ axis to point size, if set explicitly it will be overridden
       * below. */
      hb_variation_t opsz = { HB_TAG('o', 'p', 's', 'z'), point_size };
      hb_font_set_variations(font, &opsz, 1);
    }

    lua_getfield(L, index, "variations");
    if (lua_isstring(L, -1)) { variationstring = lua_tostring(L, -1); }

    hb_variation_t* variations = scan_variation_string(variationstring, &nVariations);
    if (variations) {
      hb_font_set_variations(font, variations, nVariations);
      free(variations);
    }
  }

  hb_face_destroy(face);
  hb_blob_destroy(blob);

  lua_pushlightuserdata(L, font);
  lua_setfield(L, index, "hbFont");

  return font;
}


