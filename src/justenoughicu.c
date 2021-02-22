#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <unicode/ustring.h>
#include <unicode/ustdio.h>
#include <unicode/unum.h>
#include <unicode/ubrk.h>
#include <unicode/ubidi.h>
#include <unicode/utf16.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "silewin32.h"

typedef int32_t (*conversion_function_t)(UChar *dest, int32_t destCapacity, const UChar *src, int32_t srcLength, const char *locale, UErrorCode *pErrorCode);

#define utf8_to_uchar(in, in_l, out, out_l)   { \
  UErrorCode err; \
  out_l = 0; \
  err = U_ZERO_ERROR; \
  u_strFromUTF8(NULL, 0, &out_l, in, in_l, &err); \
  err = U_ZERO_ERROR; \
  out = malloc(out_l * sizeof(UChar)); \
  u_strFromUTF8(out, out_l, &out_l, in, in_l, &err); \
}

int icu_case(lua_State *L) {
  size_t input_l;
  const char* input = luaL_checklstring(L, 1, &input_l);

  const char* locale = luaL_checkstring(L, 2);
  const char* recase = luaL_checkstring(L, 3);

  /* Convert input to ICU-friendly UChars */
  UChar *input_as_uchar;
  int32_t l;
  utf8_to_uchar(input, input_l, input_as_uchar, l);

  /* Now do the conversion */
  UChar *output;
  int32_t l2 = 0;

  UErrorCode err = U_ZERO_ERROR;

  if (strcmp(recase, "title") == 0) {
    l2 = u_strToTitle(NULL, 0, input_as_uchar, l, NULL, locale, &err);
    err = U_ZERO_ERROR;
    output = malloc(l2 * sizeof(UChar));
    u_strToTitle(output, l2, input_as_uchar, l, NULL, locale, &err);
  } else {
    conversion_function_t conversion;
    if (strcmp(recase, "upper") == 0) {
      conversion = u_strToUpper;
    } else if (strcmp(recase, "lower") == 0) {
      conversion = u_strToLower;
    } else {
      free(input_as_uchar);
      return luaL_error(L, "Unknown case conversion type %s", recase);
    }
    l2 = conversion(NULL, 0, input_as_uchar, l, locale, &err);
    err = U_ZERO_ERROR;
    output = malloc(l2 * sizeof(UChar));
    conversion(output, l2, input_as_uchar, l, locale, &err);
  }
  if (!U_SUCCESS(err)) {
    free(input_as_uchar);
    free(output);
    return luaL_error(L, "Error in case conversion %s", u_errorName(err));
  }

  int32_t l3 = 0;
  char possibleOutbuf[4096];
  u_strToUTF8(possibleOutbuf, 4096, &l3, output, l2, &err);
  if (U_SUCCESS(err)) {
    lua_pushstring(L, possibleOutbuf);
    free(input_as_uchar);
    free(output);
    return 1;
  }
  char *utf8output;
  if (err == U_BUFFER_OVERFLOW_ERROR) {
    utf8output = malloc(l3);
    u_strToUTF8(utf8output, l3, NULL, output, l2, &err);
    if (!U_SUCCESS(err)) goto fail;
    utf8output[l3] = '\0';
    lua_pushstring(L, utf8output);
    free(input_as_uchar);
    free(output);
    free(utf8output);
    return 1;
  }
  fail:
    return luaL_error(L, "Error in UTF8 conversion %s", u_errorName(err));
}

int icu_breakpoints(lua_State *L) {
  const char* input = luaL_checkstring(L, 1);
  int input_l = strlen(input);
  const char* locale = luaL_checkstring(L, 2);
  UChar *buffer;
  int32_t l, breakcount = 0;
  UErrorCode err = U_ZERO_ERROR;
  u_strFromUTF8(NULL, 0, &l, input, input_l, &err);
  /* Above call returns an error every time. */
  err = U_ZERO_ERROR;
  buffer = malloc(l * sizeof(UChar));
  u_strFromUTF8(buffer, l, &l, input, input_l, &err);

  UBreakIterator* wordbreaks, *linebreaks;
  int32_t i, previous;
  wordbreaks = ubrk_open(UBRK_WORD, locale, buffer, l, &err);
  if(U_FAILURE(err)) {
    luaL_error(L, "Word break parser failure: %s", u_errorName(err));
  }

  linebreaks = ubrk_open(UBRK_LINE, locale, buffer, l, &err);
  if(U_FAILURE(err)) {
    luaL_error(L, "Line break parser failure: %s", u_errorName(err));
  }

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
    lua_pushlstring(L, input+previous, utf8_index-previous);

    lua_settable(L, -3);

    previous = utf8_index;
    breakcount++;
    i++;
  }
  ubrk_close(wordbreaks);
  ubrk_close(linebreaks);
  return breakcount;
}

int icu_canonicalize_language(lua_State *L) {
  const char* lang = luaL_checkstring(L, 1);
  char locale[200], minimized[200], result[200];
  UErrorCode error = 0;
  uloc_forLanguageTag(lang, locale, sizeof(locale), NULL, &error);
  if (!error) {
    uloc_minimizeSubtags(locale, minimized, sizeof(minimized), &error);
  }
  if (!error) {
    uloc_toLanguageTag(minimized, result, sizeof(result),
               /* strict */ 1, &error);
  }
  if (!error) {
    lua_pushstring(L, result);
  } else {
    lua_pushstring(L, "und");
  }
  return 1;
}


int icu_format_number(lua_State *L) {
  double a = luaL_checknumber(L, 1);
  /* See https://github.com/unicode-org/cldr/blob/master/common/bcp47/number.xml
     for valid system names */
  const char* system = luaL_checkstring(L, 2);
  char locale[18]; // "@numbers=12345678";
  UChar buf[256];
  char utf8[256];
  int32_t needed;
  UErrorCode status = U_ZERO_ERROR;

  snprintf(locale, 18, "@numbers=%s", system);
  UNumberFormat* fmt = unum_open(UNUM_DECIMAL, 0, 0, locale, 0, &status);
  if(U_FAILURE(status)) {
    luaL_error(L, "Locale %s unavailable: %s", locale, u_errorName(status));
  }
  needed = unum_formatDouble(fmt, a, buf, 256, NULL, &status);
  assert(!U_FAILURE(status));
  u_austrncpy(utf8, buf, 256);
  lua_pushstring(L, utf8);
  return 1;
}

int icu_bidi_runs(lua_State *L) {
  size_t input_l;
  const char* input = luaL_checklstring(L, 1, &input_l);
  const char* direction = luaL_checkstring(L, 2);

  UChar *input_as_uchar;
  int32_t l;
  utf8_to_uchar(input, input_l, input_as_uchar, l);

  UBiDiLevel paraLevel = 0;
  if (strncasecmp(direction, "RTL", 3) == 0) {
    paraLevel = 1;
  }
  /* Now let's bidi! */
  UBiDi* bidi = ubidi_open();
  UErrorCode err = U_ZERO_ERROR;
  ubidi_setPara(bidi, input_as_uchar, l, paraLevel, NULL, &err);
  if (!U_SUCCESS(err)) {
    free(input_as_uchar);
    ubidi_close(bidi);
    return luaL_error(L, "Error in bidi %s", u_errorName(err));
  }

  int count = ubidi_countRuns(bidi,&err);
  int start, length, codepointlength;

  lua_checkstack(L,count);
  for (int i=0; i < count; i++) {
    UBiDiDirection dir = ubidi_getVisualRun(bidi, i, &start, &length);
    lua_newtable(L);
    // Convert back to UTF8...
    int32_t l3 = 0;
    char* possibleOutbuf = malloc(4*length);
    if(!possibleOutbuf) {
      return luaL_error(L, "Couldn't malloc");
    }
    u_strToUTF8(possibleOutbuf, 4 * length, &l3, input_as_uchar+start, length, &err);
    if (!U_SUCCESS(err)) {
      free(possibleOutbuf);
      return luaL_error(L, "Bidi run too big? %s", u_errorName(err));
    }
    lua_pushstring(L, "run");
    lua_pushstring(L, possibleOutbuf);
    free(possibleOutbuf);
    lua_settable(L, -3);

    lua_pushstring(L, "start");
    int32_t new_start = start;
    // Length/start is given in terms of UTF16 codepoints.
    // But we want a count of Unicode characters. This means
    // surrogate pairs need to be counted as 1.
    for (int j=0; j< start; j++) {
      if (U_IS_TRAIL(*(input_as_uchar+j))) new_start--;
    }
    lua_pushinteger(L, new_start);
    lua_settable(L, -3);

    lua_pushstring(L, "length");
    codepointlength = length;
    for (int j=start; j< start+length; j++) {
      if (U_IS_TRAIL(*(input_as_uchar+j))) codepointlength--;
    }
    lua_pushinteger(L, codepointlength);
    lua_settable(L, -3);

    lua_pushstring(L, "dir");
    lua_pushstring(L, dir == UBIDI_RTL ? "RTL" : "LTR");
    lua_settable(L, -3);

    lua_pushstring(L, "level");
    lua_pushinteger(L, ubidi_getLevelAt(bidi, start));
    lua_settable(L, -3);
  }

  free(input_as_uchar);
  ubidi_close(bidi);
  return count;
}

#if !defined LUA_VERSION_NUM
/* Lua 5.0 */
#define luaL_Reg luaL_reg
#endif

#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501 && !LUAJIT
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
  {"breakpoints", icu_breakpoints},
  {"case", icu_case},
  {"bidi_runs", icu_bidi_runs},
  {"canonicalize_language", icu_canonicalize_language},
  {"format_number", icu_format_number},
  {NULL, NULL}
};

int luaopen_justenoughicu (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
