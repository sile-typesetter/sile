#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <unicode/ustring.h>
#include <unicode/ustdio.h>
#include <unicode/ubrk.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

typedef int32_t (*conversion_function_t)(UChar *dest, int32_t destCapacity, const UChar *src, int32_t srcLength, const char *locale, UErrorCode *pErrorCode);

int icu_case(lua_State *L) {
  size_t input_l;
  const char* input = luaL_checklstring(L, 1, &input_l);

  const char* locale = luaL_checkstring(L, 2);
  const char* recase = luaL_checkstring(L, 3);

  /* Convert input to ICU-friendly UChars */
  UChar *input_as_uchar;
  int32_t l = 0;
  UErrorCode err = U_ZERO_ERROR;
  u_strFromUTF8(NULL, 0, &l, input, input_l, &err);
  err = U_ZERO_ERROR;
  input_as_uchar = malloc(l * sizeof(UChar));
  u_strFromUTF8(input_as_uchar, l, &l, input, input_l, &err);

  /* Now do the conversion */
  conversion_function_t conversion;
  UChar *output;
  int32_t l2 = 0;

  if (strcmp(recase, "upper") == 0) {
    conversion = u_strToUpper;
  } else if (strcmp(recase, "lower") == 0) {
    conversion = u_strToLower;
  // } else if (strcmp(recase, "title") == 0) {
    // conversion = u_strToTitle;
  } else {
    free(input_as_uchar);
    return luaL_error(L, "Unknown case conversion type %s", recase);
  }
  l2 = conversion(NULL, 0, input_as_uchar, l, locale, &err);
  err = U_ZERO_ERROR;
  output = malloc(l2 * sizeof(UChar));
  conversion(output, l2, input_as_uchar, l, locale, &err);
  if (!U_SUCCESS(err)) {
    free(input_as_uchar);
    free(output);
    return luaL_error(L, "Error in case conversion %s", u_errorName(err));
  }

  int32_t l3 = 0;
  u_strToUTF8(NULL, 0, &l3, output, l2, &err);
  err = U_ZERO_ERROR;
  char* utf8output = malloc(l3);
  u_strToUTF8(utf8output, l3, NULL, output, l2, &err);
  utf8output[l3] = '\0';
  if (!U_SUCCESS(err)) {
    free(input_as_uchar);
    free(output);
    free(utf8output);
    return luaL_error(L, "Error in UTF8 conversion %s", u_errorName(err));
  }
  lua_pushstring(L, utf8output);
  free(input_as_uchar);
  free(output);
  free(utf8output);
  return 1;
}

int icu_breakpoints(lua_State *L) {
  const char* input = luaL_checkstring(L, 1);
  int input_l = strlen(input);
  UChar *buffer;
  int32_t l, breakcount = 0;
  UErrorCode err = U_ZERO_ERROR;
  u_strFromUTF8(NULL, 0, &l, input, input_l, &err);
  /* Above call returns an error every time. */
  err = U_ZERO_ERROR;
  buffer = malloc(l * sizeof(UChar));
  u_strFromUTF8(buffer, l, &l, input, input_l, &err);

  char* outputbuffer = malloc(input_l); /* To hold UTF8 */
  UBreakIterator* wordbreaks, *linebreaks;
  int32_t i, previous;
  wordbreaks = ubrk_open(UBRK_WORD, 0, buffer, l, &err);
  assert(!U_FAILURE(err));

  linebreaks = ubrk_open(UBRK_LINE, 0, buffer, l, &err);
  assert(!U_FAILURE(err));

  previous = 0;
  i = 0;
  while (i <= l) {
    int32_t out_l;
    int32_t type;
    if (!ubrk_isBoundary(linebreaks, i) && !ubrk_isBoundary(wordbreaks,i)) {
      i++; continue;
    }
    lua_checkstack(L, 3);
    /* At some kind of boundary */
    lua_newtable(L);
    lua_pushstring(L, "type");
    lua_pushstring(L, ubrk_isBoundary(linebreaks,i) ? "line" : "word");
    lua_settable(L, -3);

    int32_t utf8_index = 0;
    err = U_ZERO_ERROR;
    u_strToUTF8(NULL, 0, &utf8_index, buffer, i, &err);
    assert(U_SUCCESS(err) || err == U_BUFFER_OVERFLOW_ERROR);

    lua_pushstring(L, "index");
    lua_pushinteger(L, utf8_index);
    lua_settable(L, -3);

    if (ubrk_isBoundary(linebreaks, i)) {
      lua_pushstring(L, "subtype");
      type = ubrk_getRuleStatus(linebreaks);
      if (type >= UBRK_LINE_SOFT && type < UBRK_LINE_SOFT_LIMIT) {
        lua_pushstring(L, "soft");
      } else {
        lua_pushstring(L, "hard");
      }
      lua_settable(L, -3);
    }
    lua_pushstring(L, "token");
    err = U_ZERO_ERROR;
    u_strToUTF8(outputbuffer, input_l, &out_l, buffer+previous, i-previous, &err);
    lua_pushlstring(L, outputbuffer, out_l);

    lua_settable(L, -3);

    previous  = i;
    breakcount++;
    i++;
  }
  ubrk_close(wordbreaks);
  ubrk_close(linebreaks);
  return breakcount;
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
  {"breakpoints", icu_breakpoints},
  {"case", icu_case},
  {NULL, NULL}
};

int luaopen_justenoughicu (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
