#include <stdio.h>
#include <string.h>
#include <math.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#define NANOSVG_IMPLEMENTATION  // Expands implementation
#include "nanosvg.h"

/* #define COMPAT53_PREFIX compat53 */
#include "compat-5.3.h"

static char* safe_append(char* output, int* output_l, int* max_output, char* s2) {
  int append_len = strlen(s2) + 1; // strlen doesn't count \0
  if (*output_l + append_len > *max_output) {
    *max_output *= 2;
    output = realloc(output, *max_output);
  }
  strcat(output, s2);
  *output_l += (append_len - 1); // tracks w/o \0
  return output;
}

int svg_to_ps(lua_State *L) {
  const char* input = luaL_checkstring(L, 1);
  int em = 72;
  if (lua_gettop(L) == 2) {
    em = luaL_checkinteger(L, 2);
  }
  struct NSVGimage* image;
  image = nsvgParse((char*)input, "pt", em);
  int max_output = 256;
  int output_l = 0;
  char *output = malloc(max_output);
  output[0] = '\0';
  for (NSVGshape *shape = image->shapes; shape != NULL; shape = shape->next) {
    char* strokeFillOper = "s "; // Just stroke
    for (NSVGpath *path = shape->paths; path != NULL; path = path->next) {
      double lastx = -1;
      double lasty = -1;
      for (int i = 0; i < path->npts-1; i += 3) {
        float* p = &path->pts[i*2];
        char thisPath[256];
        // Some kind of precision here?
        if (lastx != p[0] || lasty != p[1]) {
          // Move needed
          snprintf(thisPath, 256, "%f %f m ", p[0], p[1]);
          output = safe_append(output, &output_l, &max_output, thisPath);
        }
        snprintf(thisPath, 256, "%f %f %f %f %f %f c ",
          p[2],p[3], p[4],p[5], p[6],p[7]);
        lastx = p[6];
        lasty = p[7];
        output = safe_append(output, &output_l, &max_output, thisPath);
      }
      if (!path->closed)
        strokeFillOper = "S ";
      if (shape->stroke.type == NSVG_PAINT_COLOR) {
        int r = shape->stroke.color        & 0xff;
        int g = (shape->stroke.color >> 8) & 0xff;
        int b = (shape->stroke.color >> 16)& 0xff;
        char color[256];
        snprintf(color, 256, "%f w %f %f %f RG ", shape->strokeWidth,
          r/256.0, g/256.0, b/256.0);
        output = safe_append(output, &output_l, &max_output, color);
      }

      if (shape->fill.type == NSVG_PAINT_COLOR) {
        int r = shape->fill.color        & 0xff;
        int g = (shape->fill.color >> 8) & 0xff;
        int b = (shape->fill.color >> 16)& 0xff;
        char color[256];
        snprintf(color, 256, "%f %f %f rg ", r/256.0, g/256.0, b/256.0);
        output = safe_append(output, &output_l, &max_output, color);

        switch (shape->fillRule) {
            case NSVG_FILLRULE_NONZERO:
                strokeFillOper = "f "; break;
            case NSVG_FILLRULE_EVENODD:
            default:
                strokeFillOper = "f* "; break;
        }

        if (shape->stroke.type == NSVG_PAINT_COLOR) {
          strokeFillOper = "B ";
        } else {
          static char appendme[3] = {'h', ' ', '\0'};
          output = safe_append(output, &output_l, &max_output, appendme);
        }
      }
    }
    output = safe_append(output, &output_l, &max_output, strokeFillOper);
  }
  lua_pushstring(L, output);
  lua_pushnumber(L, image->width);
  lua_pushnumber(L, image->height);
  free(output);
  // Delete
  nsvgDelete(image);
  return 3;
}

static const struct luaL_Reg lib_table [] = {
  {"svg_to_ps", svg_to_ps},
  {NULL, NULL}
};

int luaopen_svg (lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, lib_table, 0);
  return 1;
}
