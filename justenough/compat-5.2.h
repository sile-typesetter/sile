#if LUA_VERSION_NUM==501

#define lua_rawlen lua_objlen

void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup);

#endif
