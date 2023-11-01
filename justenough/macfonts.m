@import AppKit;
#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <hb.h>
#include <hb-ot.h>


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

#define MAX_NAME_LEN 512

bool
getNameFromCTFont(CTFontRef ctFontRef, CFStringRef nameKey, char* nameStr)
{
    CFStringRef name = CTFontCopyName(ctFontRef, nameKey);
    if (CFStringGetCString(name, nameStr, MAX_NAME_LEN, kCFStringEncodingUTF8))
        return true;
    return false;
}

bool
getNameFromHBFace(hb_face_t *face, hb_ot_name_id_t name_id, char* name)
{
    unsigned int len = MAX_NAME_LEN;
    if (hb_ot_name_get_utf8(face, name_id, HB_LANGUAGE_INVALID, &len, name) <= MAX_NAME_LEN)
        return true;
    return false;
}

char*
getFileNameFromCTFont(CTFontRef ctFontRef, uint32_t *index)
{
    char *ret = NULL;
    CFURLRef url = NULL;

    url = (CFURLRef) CTFontCopyAttribute(ctFontRef, kCTFontURLAttribute);
    if (url) {
        UInt8 pathname[PATH_MAX];
        if (CFURLGetFileSystemRepresentation(url, true, pathname, PATH_MAX)) {
            hb_blob_t *blob = hb_blob_create_from_file((char*)pathname);
            hb_face_t* face = NULL;
            unsigned int num_faces;
            unsigned int num_instances;
            char name1[MAX_NAME_LEN];
            char name2[MAX_NAME_LEN];

            *index = 0;
            ret = strdup((char *) pathname);

            /* Find the face index of a font collection. */
            num_faces = hb_face_count(blob);
            if (num_faces > 1) {
                if (getNameFromCTFont(ctFontRef, kCTFontPostScriptNameKey, name1)) {
                    for (unsigned int i = 0; i < num_faces; i++) {
                        face = hb_face_create(blob, i);
                        if (getNameFromHBFace(face, HB_OT_NAME_ID_POSTSCRIPT_NAME, name2) &&
                            strcmp(name1, name2) == 0) {
                            *index = i;
                            break;
                        }
                        hb_face_destroy(face);
                        face = NULL;
                    }
                }
            }

            /* If we hit the break above, the face would have been destroyed,
             * otherwise it is the face we want so we don’t create it again. */
            if (!face)
              face = hb_face_create(blob, *index);

            /* Find the instance index of a variable font.
             * We use the upper bits of `index` for the instance index. */
            num_instances = hb_ot_var_get_named_instance_count(face);
            if (num_instances) {
                if (getNameFromCTFont(ctFontRef, kCTFontSubFamilyNameKey, name1)) {
                    for (unsigned int i = 0; i < num_instances; i++) {
                        hb_ot_name_id_t name_id = hb_ot_var_named_instance_get_subfamily_name_id(face, i);
                        if (getNameFromHBFace(face, name_id, name2) &&
                            strcmp(name1, name2) == 0) {
                            *index += (i + 1) << 16;
                            break;
                        }
                    }
                }
            }

            hb_face_destroy(face);
            hb_blob_destroy(blob);
        }
        CFRelease(url);
    }

    return ret;
}


int je_face_from_options(lua_State* L) {
  uint32_t index = 0;
  const char *family = "Gentium";
  char * font_path;
  const char *familyname;
  double pointSize = 12;
  int weight = 100;
  const char *style = "Regular";

  NSFontTraitMask ftm = 0;
  NSFontManager* fm = [NSFontManager sharedFontManager];

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

  lua_pushstring(L, "family");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { family = lua_tostring(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "weight");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) {
    int newWeight = lua_tointeger(L, -1);
    weight = newWeight / 66;
  }
  lua_pop(L,1);

  lua_pushstring(L, "style");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    style = lua_tostring(L, -1);
    if (strcasestr(style, "italic")) {
      ftm |= NSItalicFontMask;
    }
  }
  lua_pop(L,1);

  NSFont *f = [fm fontWithFamily:[NSString stringWithUTF8String:family]
                  traits:ftm
                  weight:weight
                    size:pointSize
              ];
  font_path = getFileNameFromCTFont((CTFontRef)f, &index);

  familyname = [[f familyName] UTF8String];
  lua_newtable(L);
  lua_pushstring(L, "filename");
  lua_pushstring(L, font_path);
  lua_settable(L, -3);

  lua_pushstring(L, "family");
  lua_pushstring(L, familyname);
  lua_settable(L, -3);

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


int luaopen_macfonts (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}

