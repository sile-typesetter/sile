#define _GNU_SOURCE
#include <string.h>

#include <fontconfig/fontconfig.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "silewin32.h"

// #define COMPAT53_PREFIX compat53
#include "compat-5.3.h"

int je_face_from_options(lua_State* L) {
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
  const char *style = "";

  if (!lua_istable(L, 1)) return 0;

  lua_pushstring(L, "size");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { pointSize = lua_tonumber(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "filename");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    font_path = (char*)lua_tostring(L, -1);
    lua_pop(L,1);
    lua_newtable(L);
    lua_pushstring(L, "filename");
    lua_pushstring(L, (char*)font_path);
    lua_settable(L, -3);
    goto done_match;
  }
  lua_pop(L,1);

  lua_pushstring(L, "family");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { family = lua_tostring(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "weight");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) {
    int newWeight = lua_tointeger(L, -1);
#if FC_VERSION >= 21191
    newWeight = FcWeightFromOpenType(newWeight);
#else
    if      (newWeight <= 100) newWeight = FC_WEIGHT_THIN;
    else if (newWeight <= 200) newWeight = FC_WEIGHT_ULTRALIGHT;
    else if (newWeight <= 300) newWeight = FC_WEIGHT_LIGHT;
    else if (newWeight <= 400) newWeight = FC_WEIGHT_NORMAL;
    else if (newWeight <= 500) newWeight = FC_WEIGHT_MEDIUM;
    else if (newWeight <= 600) newWeight = FC_WEIGHT_DEMIBOLD;
    else if (newWeight <= 700) newWeight = FC_WEIGHT_BOLD;
    else if (newWeight <= 800) newWeight = FC_WEIGHT_ULTRABOLD;
    else                       newWeight = FC_WEIGHT_HEAVY;
#endif
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
    style = lua_tostring(L, -1);
    if (strcasestr(style,"italic")) {
      slant = FC_SLANT_ITALIC;
      style = "\0";
    } else if (strcasestr(style, "oblique")) {
      slant = FC_SLANT_OBLIQUE;
      style = "\0";
    }
  }
  lua_pop(L,1);

  p = FcPatternCreate();

  FcPatternAddString (p, FC_FAMILY, (FcChar8*)(family));
  FcPatternAddDouble (p, FC_SIZE, pointSize);
  if (strlen(style) > 0) {
    FcPatternAddString (p, FC_STYLE, style);
  } else {
    FcPatternAddInteger(p, FC_SLANT, slant);
  }
  FcPatternAddInteger(p, FC_WEIGHT, weight);

  // /* Add fallback fonts here. Some of the standard 14 should be fine. */
  FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Times-Roman");
  FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Times");
  FcPatternAddString (p, FC_FAMILY,(FcChar8*) "Helvetica");

  FcConfigSubstitute (NULL, p, FcMatchFont);
  FcDefaultSubstitute (p);
  matched = FcFontMatch (0, p, &result);

  if (FcPatternGetString (matched, FC_FILE, 0, &font_path) != FcResultMatch)
    return 0;

  FcPatternGetInteger(matched, FC_INDEX, 0, &index);
  font_path = (FcChar8 *)strdup((char*)font_path);
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
  lua_pushstring(L, "index");
  lua_pushinteger(L, index);
  lua_settable(L, -3);

  lua_pushstring(L, "pointsize");
  lua_pushnumber(L, pointSize);
  lua_settable(L, -3);

  return 1;
}

static const struct luaL_Reg lib_table [] = {
  {"_face", je_face_from_options},
  {NULL, NULL}
};

int luaopen_justenoughfontconfig (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
