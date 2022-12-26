#ifndef HB_UTILS_H
#define HB_UTILS_H

#include <hb.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

hb_font_t* get_hb_font(lua_State *L, int index);

#endif /* HB_UTILS_H */
