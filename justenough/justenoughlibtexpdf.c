#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <libtexpdf.h>

#include "compat-5.2.c"

pdf_doc *p = NULL;
double height = 0.0;
double precision = 65536.0;
char* producer = "SILE";

#define ASSERT_PDF_OPENED(p) \
  if (!p) { \
    luaL_error(L, "PDF object not initialized!"); \
    return 0; \
  }

int je_pdf_init (lua_State *L) {
  pdf_rect mediabox;
  const char*  fn = luaL_checkstring(L, 1);
  double w = luaL_checknumber(L, 2);
  height = luaL_checknumber(L, 3);
  producer = luaL_checkstring(L, 4);

  p = texpdf_open_document(fn, 0, w, height, 0,0,0);
  texpdf_init_device(p, 1/precision, 2, 0);

  mediabox.llx = 0.0;
  mediabox.lly = 0.0;
  mediabox.urx = w;
  mediabox.ury = height;
  texpdf_files_init();
  texpdf_init_fontmaps();
  texpdf_tt_aux_set_always_embed();
  texpdf_doc_set_mediabox(p, 0, &mediabox);
  texpdf_add_dict(p->info,
               texpdf_new_name("Producer"),
               texpdf_new_string(producer, strlen(producer)));
  return 0;
}

int je_pdf_endpage(lua_State *L) {
  ASSERT_PDF_OPENED(p);
  texpdf_doc_end_page(p);
  return 0;
};

int je_pdf_beginpage(lua_State *L) {
  ASSERT_PDF_OPENED(p);
  texpdf_doc_begin_page(p, 1,0,height);
  return 0;
}

int je_pdf_changepagesize(lua_State *L) {
  pdf_rect mediabox;

  double pageno = luaL_checknumber(L, 1);
  mediabox.llx = luaL_checknumber(L, 2);
  mediabox.lly = luaL_checknumber(L, 3);
  mediabox.urx = luaL_checknumber(L, 4);
  mediabox.ury = luaL_checknumber(L, 5);

  ASSERT_PDF_OPENED(p);

  texpdf_doc_set_mediabox(p, pageno, &mediabox);
  return 0;
}

int je_pdf_finish(lua_State *L) {
  ASSERT_PDF_OPENED(p);
  texpdf_files_close();
  texpdf_close_device  ();
  texpdf_close_document(p);
  texpdf_close_fontmaps();
  return 0;
}

int je_pdf_loadfont(lua_State *L) {
  const char * filename;
  int index = 0;
  double ptsize;
  int layout_dir = 0;
  int extend = 65536;
  int slant = 0;
  int embolden = 0;
  int font_id;

  if (!lua_istable(L, 1)) return 0;

  lua_pushstring(L, "tempfilename");
  lua_gettable(L, -2);
  if (lua_isstring(L, -1)) { filename = lua_tostring(L, -1); }
  else { luaL_error(L, "No font filename supplied to loadfont"); }
  lua_pop(L,1);

  lua_pushstring(L, "index");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { index = lua_tointeger(L, -1); }
  lua_pop(L,1);

  /* FontConfig uses the upper bits of the face index for named instance index,
   * but libtexpdf knows nothing about this. */
  index &= 0xFFFFu;

  lua_pushstring(L, "pointsize");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { ptsize = lua_tonumber(L, -1); }
  else { luaL_error(L, "No pointsize supplied to loadfont"); }
  lua_pop(L,1);

  /* The following parameters are not currently passed by SILE,
     and it will work without them, but if SILE extensions put them
     into the font cache then they should magically work. */

  lua_pushstring(L, "extend");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { extend = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "embolden");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { embolden = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "slant");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { slant = lua_tointeger(L, -1); }
  lua_pop(L,1);

  lua_pushstring(L, "layout_dir");
  lua_gettable(L, -2);
  if (lua_isnumber(L, -1)) { layout_dir = lua_tointeger(L, -1); }
  lua_pop(L,1);

  font_id = texpdf_dev_load_native_font(filename, index, precision * ptsize, layout_dir, extend, slant, embolden);
  lua_pushinteger(L, font_id);
  return 1;
}

int je_pdf_setdirmode(lua_State *L) {
  int layout_dir = luaL_checkinteger(L,1);
  texpdf_dev_set_dirmode(layout_dir);
  return 0;
}

int je_pdf_setstring(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  double y = luaL_checknumber(L, 2);
  const char*  s = luaL_checkstring(L, 3);
  int    chrlen  = luaL_checkinteger(L, 4);
  int    font_id = luaL_checkinteger(L, 5);
  double w = luaL_checknumber(L,6);
  ASSERT_PDF_OPENED(p);
  texpdf_dev_set_string(p, precision * x, precision * (-height+y), s, chrlen, w * precision, font_id, -1);
  return 0;
}

int je_pdf_setrule(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  double y = luaL_checknumber(L, 2);
  double w = luaL_checknumber(L, 3);
  double h = luaL_checknumber(L, 4);
  ASSERT_PDF_OPENED(p);
  texpdf_dev_set_rule(p, precision * x, precision * (-height+y), precision * w, precision * h);
  return 0;
}

/* Colors */

int je_pdf_colorpush_rgb(lua_State *L) {
  double r = luaL_checknumber(L, 1);
  double g = luaL_checknumber(L, 2);
  double b = luaL_checknumber(L, 3);
  pdf_color color;

  ASSERT_PDF_OPENED(p);
  texpdf_color_rgbcolor(&color, r, g, b);
  texpdf_color_push(p, &color, &color);
  return 0;
    }

int je_pdf_colorpush_cmyk(lua_State *L) {
  double c = luaL_checknumber(L, 1);
  double m = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double k = luaL_checknumber(L, 4);

  ASSERT_PDF_OPENED(p);

  pdf_color color;
  texpdf_color_cmykcolor(&color, c, m, y, k);
  texpdf_color_push(p, &color, &color);
  return 0;
    }

int je_pdf_colorpush_gray(lua_State *L) {
  double l = luaL_checknumber(L, 1);
  pdf_color color;

  ASSERT_PDF_OPENED(p);

  texpdf_color_graycolor(&color, l);
  texpdf_color_push(p, &color, &color);
  return 0;
    }

int je_pdf_setcolor_rgb(lua_State *L) {
  double r = luaL_checknumber(L, 1);
  double g = luaL_checknumber(L, 2);
  double b = luaL_checknumber(L, 3);
  pdf_color color;

  ASSERT_PDF_OPENED(p);

  texpdf_color_rgbcolor(&color, r, g, b);
  texpdf_color_set(p, &color, &color);
  return 0;
}

int je_pdf_setcolor_cmyk(lua_State *L) {
  double c = luaL_checknumber(L, 1);
  double m = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double k = luaL_checknumber(L, 4);
  pdf_color color;

  ASSERT_PDF_OPENED(p);

  texpdf_color_cmykcolor(&color, c, m, y, k);
  texpdf_color_set(p, &color, &color);
  return 0;
}

int je_pdf_setcolor_gray(lua_State *L) {
  double l = luaL_checknumber(L, 1);
  pdf_color color;

  ASSERT_PDF_OPENED(p);

  texpdf_color_graycolor(&color, l);
  texpdf_color_set(p, &color, &color);
  return 0;
}

int je_pdf_colorpop(lua_State *L) {
  ASSERT_PDF_OPENED(p);
  texpdf_color_pop(p);
  return 0;
}

/* PDF "specials" */

int je_pdf_destination(lua_State *L) {
  pdf_obj* array = texpdf_new_array();
  const char* name = luaL_checkstring(L, 1);
  double x = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);

  ASSERT_PDF_OPENED(p);

  texpdf_add_array(array, texpdf_doc_this_page_ref(p));
  texpdf_add_array(array, texpdf_new_name("XYZ"));
  texpdf_add_array(array, texpdf_new_number(x));
  texpdf_add_array(array, texpdf_new_number(y));
  texpdf_add_array(array, texpdf_new_null());
  texpdf_doc_add_names(p, "Dests",
                    name,
                    strlen(name),
                    array);
  return 0;
}

int je_pdf_bookmark(lua_State *L) {
  const char* dictionary = luaL_checkstring(L, 1);
  int level = luaL_checknumber(L, 2);
  pdf_obj* dict = texpdf_parse_pdf_dict(&dictionary, dictionary + strlen(dictionary), NULL);
  int current_depth;
  if (!dict) {
    luaL_error(L, "Unparsable bookmark dictionary");
    return 0;
  }
  ASSERT_PDF_OPENED(p);
  current_depth = texpdf_doc_bookmarks_depth(p);
  if (current_depth > level) {
    while (current_depth-- > level)
      texpdf_doc_bookmarks_up(p);
  } else if (current_depth < level) {
    while (current_depth++ < level)
      texpdf_doc_bookmarks_down(p);
  }
  texpdf_doc_bookmarks_add(p, dict, 0);
  return 0;
}

int je_pdf_begin_annotation(lua_State *L) {
  // In theory we should track boxes and breaking state and etc.
  return 0;
}

int je_pdf_end_annotation(lua_State *L) {
  const char* dictionary = luaL_checkstring(L, 1);
  pdf_rect rect;
  pdf_obj* dict;

  rect.llx = luaL_checknumber(L, 2);
  rect.lly = luaL_checknumber(L, 3);
  rect.urx = luaL_checknumber(L, 4);
  rect.ury = luaL_checknumber(L, 5);

  dict = texpdf_parse_pdf_dict(&dictionary, dictionary + strlen(dictionary), NULL);
  if (!dict) {
    luaL_error(L, "Unparsable annotation dictionary");
    return 0;
  }
  ASSERT_PDF_OPENED(p);
  texpdf_doc_add_annot(p, texpdf_doc_current_page_number(p), &rect, dict, 1);
  texpdf_release_obj(dict);
  return 0;
}

int je_pdf_metadata(lua_State *L) {
  const char* key = luaL_checkstring(L, 1);
  const char* value = luaL_checkstring(L, 2);
  int len = lua_rawlen(L, 2);
  ASSERT(p);
  ASSERT(key);
  ASSERT(value);
  texpdf_add_dict(p->info,
               texpdf_new_name(key),
               texpdf_new_string(value, len));
  return 0;
}
/* Images */

int je_pdf_drawimage(lua_State *L) {
  const char* filename = luaL_checkstring(L, 1);
  transform_info ti;
  double x = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double w = luaL_checknumber(L, 4);
  double h = luaL_checknumber(L, 5);
  long page_no = (long)luaL_checkinteger(L, 6);
  int form_id = texpdf_ximage_findresource(p, filename, page_no, NULL);

  texpdf_transform_info_clear(&ti);
  ti.width = w;
  ti.height = h;
  ti.flags |= (INFO_HAS_WIDTH|INFO_HAS_HEIGHT);

  ASSERT_PDF_OPENED(p);
  texpdf_dev_put_image(p, form_id, &ti, x, -h-y, 0);
  return 0;
}

extern int get_image_bbox(FILE* f, long page_no, double* llx, double* lly, double* urx, double* ury, double* xresol, double* yresol);

int je_pdf_imagebbox(lua_State *L) {
  const char* filename = luaL_checkstring(L, 1);
  long page_no = (long)luaL_checkinteger(L, 2);
  double llx = 0;
  double lly = 0;
  double urx = 0;
  double ury = 0;
  double xresol = 0;
  double yresol = 0;

  FILE* f = MFOPEN(filename, FOPEN_RBIN_MODE);
  if (!f) {
    return luaL_error(L, "Image file not found %s", filename);
  }

  if ( get_image_bbox(f, page_no, &llx, &lly, &urx, &ury, &xresol, &yresol) < 0 ) {
    MFCLOSE(f);
    return luaL_error(L, "Invalid image file %s", filename);
  }

  MFCLOSE(f);

  lua_pushnumber(L, llx);
  lua_pushnumber(L, lly);
  lua_pushnumber(L, urx);
  lua_pushnumber(L, ury);
  if (xresol == 0) {
    lua_pushnil(L);
  } else {
    lua_pushnumber(L, xresol);
  }
  if (yresol == 0) {
    lua_pushnil(L);
  } else {
    lua_pushnumber(L, yresol);
  }
  return 6;
}

int je_pdf_transform(lua_State *L) {
  pdf_tmatrix matrix;
  double a = luaL_checknumber(L, 1);
  double b = luaL_checknumber(L, 2);
  double c = luaL_checknumber(L, 3);
  double d = luaL_checknumber(L, 4);
  double e = luaL_checknumber(L, 5);
  double f = luaL_checknumber(L, 6);
  ASSERT_PDF_OPENED(p);
  texpdf_graphics_mode(p);
  pdf_setmatrix(&matrix, a,b,c,d,e,f);
  texpdf_dev_concat(p, &matrix);
  return 0;
}

int je_pdf_gsave(lua_State *L)    {
  ASSERT_PDF_OPENED(p);
  texpdf_graphics_mode(p);
  texpdf_dev_gsave(p);
  return 0;
}

int je_pdf_grestore(lua_State *L) {
  ASSERT_PDF_OPENED(p);
  texpdf_graphics_mode(p);
  texpdf_dev_grestore(p);
  return 0;
}

int je_pdf_add_content(lua_State *L) {
  const char* input = luaL_checkstring(L, 1);
  int input_l = lua_rawlen(L, 1);
  ASSERT_PDF_OPENED(p);
  texpdf_graphics_mode(p); /* Don't be mid-string! */
  texpdf_doc_add_page_content(p, " ", 1);
  texpdf_doc_add_page_content(p, input, input_l);
  texpdf_doc_add_page_content(p, " ", 1);
  return 0;
}

int je_pdf_parse(lua_State *L) {
  const char* input = luaL_checkstring(L, 1);
  int input_l = lua_rawlen(L, 1);
  pdf_obj* o = texpdf_parse_pdf_object(&input, input+input_l, NULL);
  if (o) {
    lua_pushlightuserdata(L,o);
    return 1;
  } else {
    return 0;
  }
}

int je_pdf_add_dict(lua_State *L) {
  pdf_obj* dict  = lua_touserdata(L, 1);
  pdf_obj* key   = lua_touserdata(L, 2);
  pdf_obj* value = lua_touserdata(L, 3);
  texpdf_add_dict(dict, key, value);
  return 0;
}

int je_pdf_reference(lua_State *L) {
  pdf_obj* o1 = lua_touserdata(L, 1);
  pdf_obj* o2 = texpdf_ref_obj(o1);
  lua_pushlightuserdata(L, o2);
  return 1;
}

int je_pdf_release(lua_State *L) {
  pdf_obj* o1 = lua_touserdata(L, 1);
  texpdf_release_obj(o1);
  return 0;
}

int je_pdf_get_dictionary(lua_State *L) {
  const char* dict = luaL_checkstring(L, 1);
  pdf_obj *o = texpdf_doc_get_dictionary(p, dict);
  if (o) {
    lua_pushlightuserdata(L,o);
    return 1;
  } else {
    return 0;
  }
}

int je_pdf_lookup_dictionary(lua_State *L) {
  pdf_obj* dict = lua_touserdata(L, 1);
  const char* key = luaL_checkstring(L, 2);
  pdf_obj *o = texpdf_lookup_dict(dict, key);
  if (o) {
    lua_pushlightuserdata(L,o);
    return 1;
  } else {
    return 0;
  }
}

int je_pdf_push_array(lua_State *L) {
  pdf_obj* array = lua_touserdata(L, 1);
  if (!PDF_OBJ_ARRAYTYPE(array)) {
    return luaL_error(L, "push_array called on non-array");
  }
  pdf_obj* val = lua_touserdata(L, 2);
  texpdf_add_array(array, val);
  return 0;
}

int je_pdf_get_array(lua_State *L) {
  pdf_obj* array = lua_touserdata(L, 1);
  if (!PDF_OBJ_ARRAYTYPE(array)) {
    return luaL_error(L, "push_array called on non-array");
  }
  long idx = lua_tonumber(L, 2);
  pdf_obj *o = texpdf_get_array(array,idx);
  if (o) {
    lua_pushlightuserdata(L,o);
    return 1;
  } else {
    return 0;
  }
}

int je_pdf_array_length(lua_State *L) {
  pdf_obj* array = lua_touserdata(L, 1);
  if (!PDF_OBJ_ARRAYTYPE(array)) {
    return luaL_error(L, "push_array called on non-array");
  }
  lua_pushinteger(L, texpdf_array_length(array));
  return 1;
}

int je_pdf_new_string(lua_State *L) {
  const char* s = luaL_checkstring(L, 1);
  int l = lua_rawlen(L, 1);
  lua_pushlightuserdata(L, texpdf_new_string(s, l));
  return 1;
}

int je_pdf_version(lua_State *L) {
  lua_pushstring(L, texpdf_library_version());
  return 1;
}

static const struct luaL_Reg lib_table [] = {
  {"init", je_pdf_init},
  {"beginpage", je_pdf_beginpage},
  {"change_page_size", je_pdf_changepagesize},
  {"endpage", je_pdf_endpage},
  {"finish", je_pdf_finish},
  {"loadfont", je_pdf_loadfont},
  {"setdirmode", je_pdf_setdirmode},
  {"setstring", je_pdf_setstring},
  {"setrule", je_pdf_setrule},
  {"setcolor_rgb", je_pdf_setcolor_rgb},
  {"setcolor_cmyk", je_pdf_setcolor_cmyk},
  {"setcolor_gray", je_pdf_setcolor_gray},
  {"drawimage", je_pdf_drawimage},
  {"imagebbox", je_pdf_imagebbox},
  {"colorpop", je_pdf_colorpop},
  {"colorpush_rgb", je_pdf_colorpush_rgb},
  {"colorpush_cmyk", je_pdf_colorpush_cmyk},
  {"colorpush_gray", je_pdf_colorpush_gray},
  {"setmatrix", je_pdf_transform},
  {"gsave", je_pdf_gsave},
  {"grestore", je_pdf_grestore},
  {"destination", je_pdf_destination},
  {"bookmark", je_pdf_bookmark},
  {"begin_annotation", je_pdf_begin_annotation},
  {"end_annotation", je_pdf_end_annotation},
  {"metadata", je_pdf_metadata},
  {"version", je_pdf_version},
  {"add_content", je_pdf_add_content},
  {"get_dictionary", je_pdf_get_dictionary},
  {"parse", je_pdf_parse},
  {"add_dict", je_pdf_add_dict},
  {"lookup_dictionary", je_pdf_lookup_dictionary},
  {"reference", je_pdf_reference},
  {"release", je_pdf_release},
  {"push_array", je_pdf_push_array},
  {"get_array", je_pdf_get_array},
  {"array_length", je_pdf_array_length},
  {"string", je_pdf_new_string},
  {NULL, NULL}
};

int luaopen_justenoughlibtexpdf (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
