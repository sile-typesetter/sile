#include <dwrite.h>
#include <wchar.h>
#include <memory>
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
  for (; l->name != nullptr; l++) {  /* fill the table with given functions */
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

std::unique_ptr<WCHAR[]> toW(const char* c) {
  const size_t l = mbsrtowcs(nullptr, &c, 0, nullptr) + 1;
  std::unique_ptr<WCHAR[]> w(new WCHAR[l]);
  mbsrtowcs(w.get(), &c, l, nullptr);
  return w;
}

std::unique_ptr<char[]> toC(const WCHAR* w) {
  const size_t l = wcsrtombs(nullptr, &w, 0, nullptr) + 1;
  std::unique_ptr<char[]> c(new char[l]);
  wcsrtombs(c.get(), &w, l, nullptr);
  return c;
}

std::unique_ptr<char[]> getNameFromHBFace(hb_face_t *face, hb_ot_name_id_t name_id)
{
    unsigned int l = hb_ot_name_get_utf8(face, name_id, HB_LANGUAGE_INVALID, nullptr, nullptr) + 1;
    std::unique_ptr<char[]> n(new char[l]);
    hb_ot_name_get_utf8(face, name_id, HB_LANGUAGE_INVALID, &l, n.get());
    return n;
}

int face_from_options(lua_State* L) {
  int index = 0;
  const char* filename = nullptr;
  double pointsize = 12;
  const char* family = "Gentium";
  int weight = 400;
  const char* style = "regular";

  if (!lua_istable(L, 1)) return 0;

  lua_pushstring(L, "size");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { pointsize = lua_tonumber(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "filename");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) {
    filename = lua_tostring(L, -1);
    lua_pop(L,1);
    lua_newtable(L);
    lua_pushstring(L, "filename");
    lua_pushstring(L, (char*)filename);
    lua_settable(L, -3);
  }
  lua_pop(L,1);

  if (filename == NULL) {
    lua_pushstring(L, "family");
    lua_gettable(L, -2);
    if (lua_isstring(L, -1)) { family = lua_tostring(L, -1); }
    lua_pop(L,1);

    lua_pushstring(L, "weight");
    lua_gettable(L, -2);
    if (lua_isnumber(L, -1)) { weight = lua_tointeger(L, -1); }
    lua_pop(L,1);

    lua_pushstring(L, "style");
    lua_gettable(L, -2);
    if (lua_isstring(L, -1)) { style = lua_tostring(L, -1); }
    lua_pop(L,1);

    DWRITE_FONT_WEIGHT dwWeight;
    if      (weight <= 100) dwWeight = DWRITE_FONT_WEIGHT_THIN;
    else if (weight <= 200) dwWeight = DWRITE_FONT_WEIGHT_ULTRA_LIGHT;
    else if (weight <= 300) dwWeight = DWRITE_FONT_WEIGHT_LIGHT;
    else if (weight <= 350) dwWeight = DWRITE_FONT_WEIGHT_SEMI_LIGHT;
    else if (weight <= 400) dwWeight = DWRITE_FONT_WEIGHT_NORMAL;
    else if (weight <= 500) dwWeight = DWRITE_FONT_WEIGHT_MEDIUM;
    else if (weight <= 600) dwWeight = DWRITE_FONT_WEIGHT_SEMI_BOLD;
    else if (weight <= 700) dwWeight = DWRITE_FONT_WEIGHT_BOLD;
    else if (weight <= 800) dwWeight = DWRITE_FONT_WEIGHT_ULTRA_BOLD;
    else if (weight <= 900) dwWeight = DWRITE_FONT_WEIGHT_BLACK;
    else                    dwWeight = DWRITE_FONT_WEIGHT_ULTRA_BLACK;

    DWRITE_FONT_STRETCH dwStretch = DWRITE_FONT_STRETCH_NORMAL;

    // TODO: what are the other possible styles?
    DWRITE_FONT_STYLE dwStyle;
    if (strcasecmp(style, "italic") == 0)
      dwStyle = DWRITE_FONT_STYLE_ITALIC;
    else if (strcasecmp(style, "oblique") == 0)
      dwStyle = DWRITE_FONT_STYLE_OBLIQUE;
    else
      dwStyle = DWRITE_FONT_STYLE_NORMAL;

    IDWriteFactory* pDWriteFactory = nullptr;
    HRESULT hr = DWriteCreateFactory(
              DWRITE_FACTORY_TYPE_SHARED,
              __uuidof(IDWriteFactory),
              reinterpret_cast<IUnknown**>(&pDWriteFactory)
              );

    IDWriteFontCollection* pFontCollection = nullptr;
    if (SUCCEEDED(hr))
      hr = pDWriteFactory->GetSystemFontCollection(&pFontCollection);

    auto dwFamily = toW(family);
    UINT32 dwIndex = 0;
    BOOL dwExists = FALSE;
    if (SUCCEEDED(hr))
      pFontCollection->FindFamilyName(dwFamily.get(), &dwIndex, &dwExists);

    IDWriteFontFamily* pFontFamily = nullptr;
    if (SUCCEEDED(hr) && dwExists)
      hr = pFontCollection->GetFontFamily(dwIndex, &pFontFamily);

    IDWriteFont* pFont = nullptr;
    if (SUCCEEDED(hr))
      hr = pFontFamily->GetFirstMatchingFont(dwWeight, dwStretch, dwStyle, &pFont);

    IDWriteFontFace* pFontFace = nullptr;
    if (SUCCEEDED(hr))
      hr = pFont->CreateFontFace(&pFontFace);

    if (SUCCEEDED(hr))
      index = pFontFace->GetIndex();

    UINT32 numberOfFiles = 0;
    if (SUCCEEDED(hr))
      hr = pFontFace->GetFiles(&numberOfFiles, nullptr);

    IDWriteFontFile* pFontFile = nullptr;
    if (SUCCEEDED(hr) && numberOfFiles == 1)
      hr = pFontFace->GetFiles(&numberOfFiles, &pFontFile);

    void const* pFontFileReferenceKey = nullptr;
    UINT32 nFontFileReferenceKey = 0;
    if (SUCCEEDED(hr))
      hr = pFontFile->GetReferenceKey(&pFontFileReferenceKey, &nFontFileReferenceKey);

    IDWriteFontFileLoader* pFontFileLoader = nullptr;
    if (SUCCEEDED(hr))
      hr = pFontFile->GetLoader(&pFontFileLoader);

    IDWriteLocalFontFileLoader* pLocalFontFileLoader = nullptr;
    if (SUCCEEDED(hr))
      hr = pFontFileLoader->QueryInterface(__uuidof(IDWriteLocalFontFileLoader),
                                           reinterpret_cast<void**>(&pLocalFontFileLoader));

    UINT32 nFilePath = 0;
    if (SUCCEEDED(hr))
      hr = pLocalFontFileLoader->GetFilePathLengthFromKey(pFontFileReferenceKey,
                                                          nFontFileReferenceKey,
                                                          &nFilePath);

    std::unique_ptr<char[]> filepath = nullptr;
    if (SUCCEEDED(hr)) {
      std::unique_ptr<WCHAR[]> pFilePath(new WCHAR[nFilePath + 1]);
      hr = pLocalFontFileLoader->GetFilePathFromKey(pFontFileReferenceKey,
                                                    nFontFileReferenceKey,
                                                    pFilePath.get(), nFilePath);
      if (SUCCEEDED(hr))
        filepath = toC(pFilePath.get());
    }

    IDWriteLocalizedStrings* pFaceNames = nullptr;
    if (SUCCEEDED(hr))
      hr = pFont->GetFaceNames(&pFaceNames);

    wchar_t pSubfamilyName[LOCALE_NAME_MAX_LENGTH];
    if (SUCCEEDED(hr)) {
      hb_blob_t* blob = hb_blob_create_from_file(filepath.get());
      hb_face_t* face = hb_face_create(blob, index);
      unsigned int num_instances = hb_ot_var_get_named_instance_count(face);

      for (unsigned int i = 0; i < num_instances; i++) {
        hb_ot_name_id_t name_id = hb_ot_var_named_instance_get_subfamily_name_id(face, i);
        auto name1 = getNameFromHBFace(face, name_id);
        for (UINT32 j = 0; j < pFaceNames->GetCount(); j++) {
          UINT32 nName = 0;
          hr = pFaceNames->GetStringLength(j, &nName);
          if (SUCCEEDED(hr)) {
            std::unique_ptr<WCHAR[]> pName(new WCHAR[nName]);
            hr = pFaceNames->GetString(j, pName.get(), nName);
            if (SUCCEEDED(hr)) {
              auto name2 = toC(pName.get());
              if (strcmp(name1.get(), name2.get()) == 0) {
                index += (i + 1) << 16;
                break;
              }
            }
          }
        }
        if (index >> 16)
          break;
      }
    }

    lua_newtable(L);
    lua_pushstring(L, "filename");
    lua_pushstring(L, filepath.get());
    lua_settable(L, -3);

    lua_pushstring(L, "family");
    lua_pushstring(L, family);
    lua_settable(L, -3);
  }

  lua_pushstring(L, "index");
  lua_pushinteger(L, index);
  lua_settable(L, -3);

  lua_pushstring(L, "pointsize");
  lua_pushnumber(L, pointsize);
  lua_settable(L, -3);

  return 1;
}


static const struct luaL_Reg lib_table [] = {
  {"_face", face_from_options},
  {nullptr, nullptr}
};


int luaopen_winfonts (lua_State* L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}

