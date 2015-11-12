@import AppKit;
#include <stdio.h>
#include <ft2build.h>
#include FT_FREETYPE_H
FT_Library gFreeTypeLibrary;


#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


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

/* Stolen from XeTeX */

char*
getNameFromCTFont(CTFontRef ctFontRef, CFStringRef nameKey)
{
    char *buf;
    CFStringRef name = CTFontCopyName(ctFontRef, nameKey);
    CFIndex len = CFStringGetLength(name);
    len = len * 6 + 1;
    buf = malloc(len);
    if (CFStringGetCString(name, buf, len, kCFStringEncodingUTF8))
        return buf;
    free(buf);
    return NULL;
}


char*
getFileNameFromCTFont(CTFontRef ctFontRef, uint32_t *index)
{
    char *ret = NULL;
    CFURLRef url = NULL;

#if !defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6
    /* kCTFontURLAttribute was not avialable before 10.6 */
    ATSFontRef atsFont;
    FSRef fsref;
    OSStatus status;
    atsFont = CTFontGetPlatformFont(ctFontRef, NULL);
    status = ATSFontGetFileReference(atsFont, &fsref);
    if (status == noErr)
        url = CFURLCreateFromFSRef(NULL, &fsref);
#else
    url = (CFURLRef) CTFontCopyAttribute(ctFontRef, kCTFontURLAttribute);
#endif
    if (url) {
        UInt8 pathname[PATH_MAX];
        if (CFURLGetFileSystemRepresentation(url, true, pathname, PATH_MAX)) {
            FT_Error error;
            FT_Face face;

            *index = 0;

            if (!gFreeTypeLibrary) {
                error = FT_Init_FreeType(&gFreeTypeLibrary);
                if (error) {
                    fprintf(stderr, "FreeType initialization failed! (%d)\n", error);
                    exit(1);
                }
            }

            error = FT_New_Face(gFreeTypeLibrary, (char *) pathname, 0, &face);
            if (!error) {
                if (face->num_faces > 1) {
                    int num_faces = face->num_faces;
                    char *ps_name1 = getNameFromCTFont(ctFontRef, kCTFontPostScriptNameKey);
                    int i;
                    *index = -1;
                    FT_Done_Face (face);
                    for (i = 0; i < num_faces; i++) {
                        error = FT_New_Face (gFreeTypeLibrary, (char *) pathname, i, &face);
                        if (!error) {
                            const char *ps_name2 = FT_Get_Postscript_Name(face);
                            if (strcmp(ps_name1, ps_name2) == 0) {
                                *index = i;
                                break;
                            }
                            FT_Done_Face (face);
                        }
                    }
                    free(ps_name1);
                }
            }

            if (*index != -1)
                ret = strdup((char *) pathname);
        }
        CFRelease(url);
    }

    return ret;
}


int face_from_options(lua_State* L) {
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

  lua_pushstring(L, "font");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { family = lua_tostring(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "weight");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) {
    int newWeight = lua_tointeger(L, -1);
    weight = newWeight / 50;
  }
  lua_pop(L,1);

  lua_pushstring(L, "style");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    style = lua_tostring(L, -1);
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
  {"_face", face_from_options},
  {NULL, NULL}
};


int luaopen_macfonts (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}

