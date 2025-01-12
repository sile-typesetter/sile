cmake_minimum_required(VERSION 3.0)

project(sile LANGUAGES C CXX)

add_subdirectory(libtexpdf)

if (WIN32)
  include(ExternalProject)

  set(TMP_INSTALL_DIR "${CMAKE_BINARY_DIR}/tmp_install")
  set(TMP_LUA_DIR "${CMAKE_BINARY_DIR}/lua")
  set(TMP_LUAROCKS_DIR "${CMAKE_BINARY_DIR}/luarocks")
  set(LUAROCKS_COMMAND "${TMP_LUAROCKS_DIR}/luarocks.bat")

  ExternalProject_Add(expat
    GIT_REPOSITORY https://github.com/libexpat/libexpat
    GIT_TAG R_2_2_6
    SOURCE_SUBDIR expat
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" -DBUILD_tools=OFF -DBUILD_tests=OFF -DBUILD_shared=OFF -DBUILD_doc=OFF -DMSVC_USE_STATIC_CRT=OFF
    INSTALL_DIR "${TMP_INSTALL_DIR}")

  ExternalProject_Add(icu
    GIT_REPOSITORY https://github.com/hunter-packages/icu
    GIT_TAG v63.1-p5
    PATCH_COMMAND git reset --hard HEAD
    COMMAND git apply "${CMAKE_CURRENT_SOURCE_DIR}/cmake/icu.diff"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" -DICU_BUILD_IO=ON
    INSTALL_DIR "${TMP_INSTALL_DIR}")

  ExternalProject_Add(harfbuzz
    GIT_REPOSITORY https://github.com/harfbuzz/harfbuzz
    GIT_TAG 6.0.0
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" -DHB_BUILD_TESTS=OFF "-DCMAKE_PREFIX_PATH=${CMAKE_BINARY_DIR}/bootstrap"
    INSTALL_DIR "${TMP_INSTALL_DIR}")

  ExternalProject_Add(freetype2
    DEPENDS libpng zlib
    GIT_REPOSITORY https://gitlab.freedesktop.org/freetype/freetype.git
    GIT_TAG VER-2-12-1
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" -DFT_DISABLE_HARFBUZZ=ON -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON
    INSTALL_DIR "${TMP_INSTALL_DIR}")

  ExternalProject_Add(libiconv
    GIT_REPOSITORY https://github.com/win-iconv/win-iconv/
    GIT_TAG v0.0.8
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" -DBUILD_STATIC=ON -DBUILD_SHARED=OFF
    INSTALL_DIR "${TMP_INSTALL_DIR}")

  ExternalProject_Add(fontconfig
    DEPENDS libiconv expat freetype2
    GIT_REPOSITORY https://github.com/freedesktop/fontconfig
    GIT_TAG 2.13.1
    PATCH_COMMAND git reset --hard HEAD
    COMMAND git clean -dfx
    COMMAND git apply "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fontconfig.diff"
    LIST_SEPARATOR ::
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" -DCMAKE_C_FLAGS=/DXML_STATIC=1 -DBUILD_SHARED=OFF -DBUILD_STATIC=ON "-DEXPAT_LIBRARIES=<INSTALL_DIR>/lib/expat.lib" "-DFREETYPE_LIBRARIES=<INSTALL_DIR>/lib/freetype.lib" "-DLIBRARIES_TO_LINK=<INSTALL_DIR>/lib/libpng16_static.lib::<INSTALL_DIR>/lib/zlibstatic.lib"
    INSTALL_DIR "${TMP_INSTALL_DIR}")
  ExternalProject_Add_Step(fontconfig genconf
    COMMAND "${CMAKE_COMMAND}" "-DCMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}" -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fonts_conf.cmake"
    DEPENDEES build)

  ExternalProject_Add(perl
    URL http://strawberryperl.com/download/5.28.1.1/strawberry-perl-5.28.1.1-64bit-portable.zip
    URL_HASH SHA1=51dbc993d93069190606e2534bd64b9c9bf1b9e3
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND "<SOURCE_DIR>/perl/bin/cpan.bat" Text::Template)

  ExternalProject_Add(openssl
    DEPENDS perl zlib
    GIT_REPOSITORY https://github.com/openssl/openssl
    GIT_TAG OpenSSL_1_1_1b
    INSTALL_DIR "${TMP_INSTALL_DIR}"
    CONFIGURE_COMMAND "${CMAKE_BINARY_DIR}/perl-prefix/src/perl/perl/bin/perl.exe" "<SOURCE_DIR>/Configure" VC-WIN64A-masm "--prefix=<INSTALL_DIR>" "--openssldir=<INSTALL_DIR>/ssl" "--with-zlib-include=<INSTALL_DIR>/include" "--with-zlib-lib=<INSTALL_DIR>/lib/zlibstatic.lib" --release zlib no-shared no-tests "CFLAGS=/W3 /wd4090 /nologo /O2 /MD"
    BUILD_COMMAND nmake
    INSTALL_COMMAND nmake install
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${TMP_INSTALL_DIR}/lib/libssl.lib" "${TMP_INSTALL_DIR}/lib/libssl32MD.lib"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${TMP_INSTALL_DIR}/lib/libcrypto.lib" "${TMP_INSTALL_DIR}/lib/libcrypto32MD.lib")

  ExternalProject_Add(lua
    GIT_REPOSITORY https://github.com/LuaJIT/LuaJIT
    GIT_TAG v2.1.0-beta3
    PATCH_COMMAND git clean -dfx
    COMMAND git apply "${CMAKE_CURRENT_SOURCE_DIR}/cmake/lua.diff"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>"
    INSTALL_DIR "${TMP_LUA_DIR}")

  ExternalProject_Add(luarocks
    DEPENDS lua
    GIT_REPOSITORY https://github.com/luarocks/luarocks
    GIT_TAG v3.0.4
    CONFIGURE_COMMAND ""
    BUILD_COMMAND install.bat /P "<INSTALL_DIR>" /SELFCONTAINED /LUA "${TMP_LUA_DIR}" /LIB "${TMP_LUA_DIR}" /BIN  "${TMP_LUA_DIR}" /NOREG /NOADMIN /Q /F
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ""
    INSTALL_DIR "${TMP_LUAROCKS_DIR}")

  ExternalProject_Add_Step(luarocks install_lpeg
    COMMAND "${LUAROCKS_COMMAND}" install lpeg 1.0.2-1
    DEPENDEES build)

  ExternalProject_Add_Step(luarocks install_luaexpat
    COMMAND "${LUAROCKS_COMMAND}" install luaexpat 1.3.3-1 "EXPAT_INCDIR=${TMP_INSTALL_DIR}/include" "EXPAT_LIBDIR=${TMP_INSTALL_DIR}/lib" "CFLAGS=/DXML_STATIC=1 /MD /O2"
    DEPENDEES build)
  ExternalProject_Add_StepDependencies(luarocks install_luaexpat expat)

  ExternalProject_Add_Step(luarocks install_luazip
    COMMAND "${LUAROCKS_COMMAND}" install lua-zlib 1.2-0 "ZLIB_INCDIR=${TMP_INSTALL_DIR}/include" "ZLIB_LIBDIR=${TMP_INSTALL_DIR}/lib"
    DEPENDEES build)
  ExternalProject_Add_StepDependencies(luarocks install_luazip zlib)

  ExternalProject_Add_Step(luarocks install_luafilesystem
    COMMAND "${LUAROCKS_COMMAND}" install luafilesystem 1.7.0-2
    DEPENDEES build)

  ExternalProject_Add_Step(luarocks install_luasocket
    COMMAND "${LUAROCKS_COMMAND}" install luasocket 3.0rc1-2
    DEPENDEES build)

  ExternalProject_Add_Step(luarocks install_luasec
    COMMAND "${LUAROCKS_COMMAND}" install luasec 0.7-1 "OPENSSL_DIR=${TMP_INSTALL_DIR}" "LD=link -libpath:${TMP_INSTALL_DIR}/lib zlibstatic.lib Advapi32.lib User32.lib Crypt32.lib"
    DEPENDEES build)
  ExternalProject_Add_StepDependencies(luarocks install_luasec openssl)

  ExternalProject_Add_Step(luarocks install_penlight
    COMMAND "${LUAROCKS_COMMAND}" install penlight 1.5.4-1
    DEPENDEES build)

  ExternalProject_Add(font_gentium
    URL https://software.sil.org/downloads/r/gentium/GentiumPlus-5.000.zip
    URL_MD5 acedcd2696ea14d1a9296ba6d3075288
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND "")

endif()

add_library(justenoughlibtexpdf SHARED justenough/justenoughlibtexpdf.c justenough/imagebbox.c)
add_dependencies(justenoughlibtexpdf libtexpdf lua)
target_include_directories(justenoughlibtexpdf PUBLIC
  "${CMAKE_SOURCE_DIR}"
  "${TMP_INSTALL_DIR}/include"
  "${TMP_LUA_DIR}/include")
target_link_directories(justenoughlibtexpdf PUBLIC
  "${TMP_INSTALL_DIR}/lib"
  "${TMP_LUA_DIR}")
target_link_libraries(justenoughlibtexpdf PUBLIC libtexpdf lua51.lib)
target_link_options(justenoughlibtexpdf PUBLIC /EXPORT:luaopen_justenoughlibtexpdf)


add_library(justenoughharfbuzz SHARED justenough/justenoughharfbuzz.c justenough/hb-utils.c justenough/hb-utils.h)
add_dependencies(justenoughharfbuzz harfbuzz lua)
target_include_directories(justenoughharfbuzz PUBLIC
  "${TMP_INSTALL_DIR}/include"
  "${TMP_INSTALL_DIR}/include/harfbuzz"
  "${TMP_LUA_DIR}/include")
target_link_directories(justenoughharfbuzz PUBLIC
  "${TMP_INSTALL_DIR}/lib"
  "${TMP_LUA_DIR}")
target_compile_definitions(justenoughharfbuzz PUBLIC HAVE_HARFBUZZ_SUBSET)
target_link_libraries(justenoughharfbuzz PUBLIC harfbuzz.lib harfbuzz-subset.lib lua51.lib)
target_link_options(justenoughharfbuzz PUBLIC /EXPORT:luaopen_justenoughharfbuzz)

add_library(justenoughicu SHARED justenough/justenoughicu.c)
add_dependencies(justenoughicu icu lua)
target_include_directories(justenoughicu PUBLIC
  "${TMP_INSTALL_DIR}/include"
  "${TMP_LUA_DIR}/include")
target_link_directories(justenoughicu PUBLIC
  "${TMP_INSTALL_DIR}/lib"
  "${TMP_LUA_DIR}")
target_link_libraries(justenoughicu PUBLIC icuio.lib icuin.lib icuuc.lib icudt.lib lua51.lib)
target_link_options(justenoughicu PUBLIC /EXPORT:luaopen_justenoughicu)

add_library(justenoughfontconfig SHARED justenough/justenoughfontconfig.c)
add_dependencies(justenoughfontconfig fontconfig)
target_include_directories(justenoughfontconfig PUBLIC
  "${TMP_INSTALL_DIR}/include"
  "${TMP_LUA_DIR}/include")
target_link_directories(justenoughfontconfig PUBLIC
  "${TMP_INSTALL_DIR}/lib"
  "${TMP_LUA_DIR}")
target_link_libraries(justenoughfontconfig PUBLIC fontconfig-static.lib lua51.lib expat.lib freetype.lib libpng16_static.lib zlibstatic.lib)
target_link_options(justenoughfontconfig PUBLIC /EXPORT:luaopen_justenoughfontconfig)

add_library(fontmetrics SHARED justenough/fontmetrics.c justenough/hb-utils.c justenough/hb-utils.h)
add_dependencies(fontmetrics harfbuzz lua)
target_include_directories(fontmetrics PUBLIC
  "${TMP_INSTALL_DIR}/include"
  "${TMP_INSTALL_DIR}/include/harfbuzz"
  "${TMP_LUA_DIR}/include")
target_link_directories(fontmetrics PUBLIC
  "${TMP_INSTALL_DIR}/lib"
  "${TMP_LUA_DIR}")
target_link_libraries(fontmetrics PUBLIC harfbuzz.lib lua51.lib)
target_link_options(fontmetrics PUBLIC /EXPORT:luaopen_fontmetrics)

add_library(svg SHARED justenough/svg.c)
add_dependencies(svg lua)
target_include_directories(svg PUBLIC
  "${TMP_INSTALL_DIR}/include"
  "${TMP_LUA_DIR}/include")
target_link_directories(svg PUBLIC
  "${TMP_INSTALL_DIR}/lib"
  "${TMP_LUA_DIR}")
target_link_libraries(svg PUBLIC lua51.lib)
target_link_options(svg PUBLIC /EXPORT:luaopen_svg)

set(LUA "luajit.exe")
set(SILE_PATH "debug.getinfo(1, 'S').source:match('@?.*[/\\\\]') or '.'")
set(SILE_LIB_PATH "debug.getinfo(1, 'S').source:match('@?.*[/\\\\]') or '.'")
set(LIBEXT "dll")
configure_file(sile.in sile.lua)

if (WIN32)
  ExternalProject_Add(srlua
    GIT_REPOSITORY https://github.com/LuaDist/srlua
    GIT_TAG 5.2
    PATCH_COMMAND git reset --hard HEAD
    COMMAND git apply "${CMAKE_CURRENT_SOURCE_DIR}/cmake/srlua.diff"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>" "-DLUA_INCLUDE_DIR=${TMP_LUA_DIR}/include" "-DLUA_LIBRARIES=${TMP_LUA_DIR}/lua51.lib"
    INSTALL_DIR "${TMP_INSTALL_DIR}")
  ExternalProject_Add_Step(srlua create_sile
    COMMAND "<INSTALL_DIR>/bin/glue.exe" "<INSTALL_DIR>/bin/srlua.exe" "${CMAKE_CURRENT_BINARY_DIR}/sile.lua" "${CMAKE_CURRENT_BINARY_DIR}/sile.exe"
    DEPENDEES install)
endif()

install(DIRECTORY core classes languages packages DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY "${TMP_LUA_DIR}/" DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/sile.exe" DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY "${TMP_LUAROCKS_DIR}/systree/lib/lua/5.1/" DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY "${TMP_LUAROCKS_DIR}/systree/share/lua/5.1/" DESTINATION lua)
install(DIRECTORY lua-libraries/ DESTINATION lua)
install(TARGETS justenoughlibtexpdf justenoughharfbuzz justenoughicu justenoughfontconfig fontmetrics svg
  RUNTIME DESTINATION core)
file(GLOB FONTCONFIG_BINARIES "${TMP_INSTALL_DIR}/bin/fc-*.exe")
install(DIRECTORY "${TMP_INSTALL_DIR}/bin/" DESTINATION ${CMAKE_INSTALL_PREFIX} FILES_MATCHING PATTERN "fc-*.exe")
install(FILES "${CMAKE_BINARY_DIR}/fonts.conf" DESTINATION fonts)
install(DIRECTORY "${CMAKE_BINARY_DIR}/font_gentium-prefix/src/font_gentium/" DESTINATION fonts FILES_MATCHING PATTERN  "*.ttf" PATTERN "documentation/*" EXCLUDE)
