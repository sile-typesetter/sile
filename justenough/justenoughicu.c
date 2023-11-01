#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <unicode/ustring.h>
#include <unicode/ustdio.h>
#include <unicode/unum.h>
#include <unicode/ubrk.h>
#include <unicode/ubidi.h>
#include <unicode/ucol.h>
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

int je_icu_case(lua_State *L) {
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

int je_icu_breakpoints(lua_State *L) {
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

int je_icu_canonicalize_language(lua_State *L) {
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

#define MAX_ICU_FORMATTED_NUMBER_STRING 512

int je_icu_format_number(lua_State *L) {
  double a = luaL_checknumber(L, 1);
  const char* locale = luaL_checkstring(L, 2);
  UNumberFormatStyle numFormatStyle = luaL_checkinteger(L, 3);

  UChar buf[MAX_ICU_FORMATTED_NUMBER_STRING];
  char utf8[MAX_ICU_FORMATTED_NUMBER_STRING];
  int32_t needed;
  UErrorCode status = U_ZERO_ERROR;

  UNumberFormat* fmt = unum_open(numFormatStyle, 0, 0, locale, 0, &status);
  if(U_FAILURE(status)) {
    return luaL_error(L, "Locale %s unavailable: %s", locale, u_errorName(status));
  }
  needed = unum_formatDouble(fmt, a, buf, MAX_ICU_FORMATTED_NUMBER_STRING, NULL, &status);
  if(U_FAILURE(status)) {
    return luaL_error(L, "Locale %s formatting error: %s", locale, u_errorName(status));
  }
  u_austrncpy(utf8, buf, MAX_ICU_FORMATTED_NUMBER_STRING);
  lua_pushstring(L, utf8);
  return 1;
}

int je_icu_bidi_runs(lua_State *L) {
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

int je_icu_collation_create(lua_State *L) {
  int nargs = lua_gettop(L);
  const char* locale = luaL_checkstring(L, 1);

  if (nargs > 2) {
    return luaL_error(L, "Collation creation takes at most two arguments (locale and options)");
  }

  // Options https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/ucol_8h.html#a583fbe7fc4a850e2fcc692e766d2826c
  // Also a useful reading https://www.mongodb.com/docs/manual/reference/collation/
  // I took some of the names from this documentation, they are more 'friendly'
  // (IMHO) than some of the ICU names.
  // The default ICU values do not aways make sense in usual dictionary sorting
  // so we may set them a bit more logically.
  int strength = UCOL_TERTIARY; // N.B.default is UCOL_TERTIARY
  int alternate = UCOL_SHIFTED; // N.B. default is UCOL_NON_IGNORABLE
  int numericOrdering = UCOL_ON; // N.B. default is UCOL_OFF
  int backwards = UCOL_OFF; // So-called 'french collation', default is UCOL_OFF
  // NOT IMPLEMENTED: maxVariable punct / maxVariable space
  //     This affects 'alternate handling' with expect to spaces and/or punctuations
  //     I never used it and I'm lazy - assume default is ok...
  int caseFirst = UCOL_OFF; // n.B. default is UCOL_OFF
  int caseLevel = UCOL_OFF; // n.B. default is UCOL_OFF

  if (nargs == 2) {
    char *err = NULL;

    // Begin options table processing
    if (!lua_istable(L, 2)) {
      return luaL_error(L, "Collation options must be a table");
    }

    lua_pushstring(L, "strength");
    lua_gettable(L, -2);
    if (lua_isnumber(L, -1)) { // Lua < 5.3 doesn't have lua_isinteger(L, -1)
      int i = lua_tointeger(L, -1);
      // Doh, ICU strength constants (U_PRIMARY...U_QUATERNARY) are 0-based :)
      if (i > 0 && i <= 4) {
        strength = i - 1;
      } else {
        err = "Collation strength must be between 1 and 4";
      }
    }
    lua_pop(L, 1);

    lua_pushstring(L, "ignorePunctuation");
    lua_gettable(L, -2);
    if (lua_isboolean(L, -1)) {
      alternate = lua_toboolean(L, -1) ? UCOL_SHIFTED : UCOL_NON_IGNORABLE;
    }
    lua_pop(L, 1);

    lua_pushstring(L, "numericOrdering");
    lua_gettable(L, -2);
    if (lua_isboolean(L, -1)) {
      numericOrdering = lua_toboolean(L, -1) ? UCOL_ON : UCOL_OFF;
    }
    lua_pop(L, 1);

    lua_pushstring(L, "backwards");
    lua_gettable(L, -2);
    if (lua_isboolean(L, -1)) {
      backwards = lua_toboolean(L, -1) ? UCOL_ON : UCOL_OFF;
    }
    lua_pop(L, 1);

    lua_pushstring(L, "caseFirst");
    lua_gettable(L, -2);
    if (lua_isstring(L, -1)) {
      const char *casestr = lua_tostring(L, - 1);
      if (strcmp(casestr, "off") == 0) {
        caseFirst = UCOL_OFF;
      } else if (strcmp(casestr, "upper") == 0) {
        caseFirst = UCOL_UPPER_FIRST;
      } else if (strcmp(casestr, "lower") == 0) {
        caseFirst = UCOL_LOWER_FIRST;
      } else {
        err = "Collation caseFirst option is not valid (off, upper, lower)";
      }
    }
    lua_pop(L, 1);

    lua_pushstring(L, "caseLevel");
    lua_gettable(L, -2);
    if (lua_isboolean(L, -1)) {
      caseLevel = lua_toboolean(L, -1) ? UCOL_ON : UCOL_OFF;
    }
    lua_pop(L, 1);

    if (err) {
      return luaL_error(L, err);
    }
    // End option table processing
  }

  UErrorCode status = U_ZERO_ERROR;
  UCollator *collator = ucol_open(locale, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to open collator for locale '%s'", locale);
  }

  // Always enable normalization
  ucol_setAttribute(collator, UCOL_NORMALIZATION_MODE, UCOL_ON, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set collation normalization for locale '%s'", locale);
  }

  // strength defines the level of comparison to perform.
  // Most language would need UCOL_TERTIARY for real sorting
  // Japanese may need UCOL_QUATERNARY
  ucol_setAttribute(collator, UCOL_STRENGTH, strength, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set collation strength for locale '%s'", locale);
  }

  // alternate (= ignorePunctuation) determines whether collation should consider whitespace and
  // punctuation as base characters for purposes of comparison.
  // If true, they are NOT considered as base characters and are only distinguished at strength
  // levels greater than 3.
  ucol_setAttribute(collator, UCOL_ALTERNATE_HANDLING, alternate, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set collation handling for locale '%s'", locale);
  }

  // numericOrdering determines whether to compare numeric strings as numbers or as strings.
  // If true, compare as numbers. For example, "10" is greater than "2".
  ucol_setAttribute(collator, UCOL_NUMERIC_COLLATION, numericOrdering, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set numeric collation for locale '%s'", locale);
  }

  // backwards (= 'french collation') determines whether strings with diacritics sort
  // from back of the string, such as with some French dictionary ordering (esp. Canada)
  ucol_setAttribute(collator, UCOL_FRENCH_COLLATION, backwards, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set french collation for locale '%s'", locale);
  }

  // caseFirst determines sort order of case differences during tertiary level comparisons
  // i.e. controls the ordering of upper and lower case letters.
  //   off = order upper and lower case letters in accordance to their tertiary weights
  //   upper = forces upper case letters to sort before lower case letters,
  //   lower = does the oppposite.
  ucol_setAttribute(collator, UCOL_CASE_FIRST, caseFirst, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set case-first collation for locale '%s'", locale);
  }

  // caseLevel controls whether an extra case level (positioned before the third level)
  // is generated or not.
  // It determines whether to include case comparison at strength level 1 or 2.
  ucol_setAttribute(collator, UCOL_CASE_LEVEL, caseLevel, &status);
  if (U_FAILURE(status)) {
    return luaL_error(L, "Failure to set case-level collation for locale '%s'", locale);
  }

  lua_pushlightuserdata(L, collator);
  return 1;
}

int je_icu_collation_destroy(lua_State *L) {
  UCollator *collator = (UCollator *)lua_touserdata(L, 1);
  if (!collator) {
    return luaL_error(L, "Collation cleanup called with invalid input");
  }
  ucol_close(collator);
  return 0;
}

int je_icu_compare(lua_State *L) {
  UCollator *collator = (UCollator *)lua_touserdata(L, 1);
  if (!collator) {
    return luaL_error(L, "Comparison called with invalid first argument (collator)");
  }

  size_t s1_l, s2_l;
  const char* s1 = luaL_checklstring(L, 2, &s1_l);
  const char* s2 = luaL_checklstring(L, 3, &s2_l);

  UErrorCode status = U_ZERO_ERROR;
  UCollationResult result = ucol_strcollUTF8(collator, s1, s1_l, s2, s2_l, &status);
  if (U_FAILURE(status)) {
    // Probably badly encoded UTF8 inputs...
    return luaL_error(L, "Internal failure to perform comparison");
  }

  lua_pushboolean(L, result == UCOL_LESS);
  return 1;
  // IMPLEMENTATION NOTE FOR PORTABILITY
  // Good news, ucol_strcollUTF8 was introduced in ICU 50.
  // Otherwise we would probably have needed something such as (untested):
  // (Using iterators avoid converting the full UTF8 strings to UChars)
  //     UCharIterator s1iter, s2iter;
  //     uiter_setUTF8(&s1iter, s1, s1_l);
  //     uiter_setUTF8(&s2iter, s2, s2_l);
  //     UCollationResult result = ucol_strcollIter(collation, &s1iter, &s2iter, &status);
}

int je_icu_version(lua_State *L) {
  lua_pushstring(L, U_ICU_VERSION);
  return 1;
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
  {"breakpoints", je_icu_breakpoints},
  {"case", je_icu_case},
  {"bidi_runs", je_icu_bidi_runs},
  {"canonicalize_language", je_icu_canonicalize_language},
  {"format_number", je_icu_format_number},
  {"collation_create", je_icu_collation_create},
  {"collation_destroy", je_icu_collation_destroy},
  {"compare", je_icu_compare},
  {"version", je_icu_version},
  {NULL, NULL}
};

int luaopen_justenoughicu (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
