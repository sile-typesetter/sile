enable_testing()

set(FONT_DIR "${PROJECT_SOURCE_DIR}/.fonts")
# file(MAKE_DIRECTORY ${FONT_DIR})

file(DOWNLOAD https://software.sil.org/downloads/r/gentium/GentiumPlus-5.000.zip "${FONT_DIR}/GentiumPlus-5.000.zip" SHOW_PROGRESS EXPECTED_MD5 acedcd2696ea14d1a9296ba6d3075288)
file(DOWNLOAD https://github.com/alif-type/amiri/raw/0.111/Amiri-Regular.ttf "${FONT_DIR}/Amiri-Regular.ttf" SHOW_PROGRESS EXPECTED_MD5 677a9e68f175605481649cdda4f937d2)
file(DOWNLOAD https://github.com/alif-type/amiri/raw/0.111/AmiriQuran.ttf "${FONT_DIR}/AmiriQuran.ttf" SHOW_PROGRESS EXPECTED_MD5 f3728c6e5c0d2585586b1fb42aa5bba9)
file(DOWNLOAD https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.xz "${FONT_DIR}/Hack-v3.003-ttf.tar.xz" SHOW_PROGRESS EXPECTED_MD5 cf274d8c32045a350e6d6a116fe463d7)
file(DOWNLOAD https://software.sil.org/downloads/r/lateef/Hack-v3.003-ttf.tar.xz "${FONT_DIR}/LateefGR-1.200.zip" SHOW_PROGRESS EXPECTED_MD5 d41d8cd98f00b204e9800998ecf8427e)
file(DOWNLOAD https://github.com/alif-type/libertinus/raw/v6.9/LibertinusSans-Bold.otf "${FONT_DIR}/LibertinusSans-Bold.otf" SHOW_PROGRESS EXPECTED_MD5 eb4659f927b729e0f0236704f4cccaac)
file(DOWNLOAD https://github.com/alif-type/libertinus/raw/v6.9/LibertinusSerif-Regular.otf "${FONT_DIR}/LibertinusSerif-Regular.otf" SHOW_PROGRESS EXPECTED_MD5 3409bacd6d3a6a75087494c4b8e26b6d)
file(DOWNLOAD https://github.com/googlefonts/noto-fonts/raw/v2017-09-19-phase3-second/hinted/NotoNaskhArabic-Regular.ttf "${FONT_DIR}/NotoNaskhArabic-Regular.ttf" SHOW_PROGRESS EXPECTED_MD5 c9ea4fcb9b1761acdcc43e2078d51b19)
file(DOWNLOAD https://github.com/googlefonts/noto-cjk/raw/NotoSansV2.001/NotoSansCJK-Regular.ttc "${FONT_DIR}/NotoSansCJK-Regular.ttc" SHOW_PROGRESS EXPECTED_MD5 6f79bd2b639660b292042bd210ff90a7)
file(DOWNLOAD https://github.com/googlefonts/noto-fonts/raw/v2017-09-19-phase3-second/hinted/NotoSansKannada-Regular.ttf "${FONT_DIR}/NotoSansKannada-Regular.ttf" SHOW_PROGRESS EXPECTED_MD5 455c8452c925d5b900715919b2f5623e)
file(DOWNLOAD https://github.com/googlefonts/noto-fonts/raw/v2017-09-19-phase3-second/hinted/NotoSansEthiopic-Regular.ttf "${FONT_DIR}/NotoSansEthiopic-Regular.ttf" SHOW_PROGRESS EXPECTED_MD5 fe438922eeed3374cb58b90ef2bc1d75)
file(DOWNLOAD https://github.com/googlefonts/noto-fonts/raw/v2017-09-19-phase3-second/hinted/NotoSansMalayalam-Regular.ttf "${FONT_DIR}/NotoSansMalayalam-Regular.ttf" SHOW_PROGRESS EXPECTED_MD5 10749ea1f748cfaa131e4f6a48125735)
file(DOWNLOAD https://www.sbl-site.org/Fonts/SBL_Hbrw.ttf "${FONT_DIR}/SBL_Hbrw.ttf" SHOW_PROGRESS EXPECTED_MD5 dbf49ba8a07d2e0e73b9b76aabd694f0)
file(DOWNLOAD https://web.archive.org/web/20190608100449/http://users.teilar.gr/~g1951d/Symbola.zip "${FONT_DIR}/Symbola.zip" SHOW_PROGRESS EXPECTED_MD5 be7b84a1e5ba3fce6bf73338aa7013cc)

execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz "${FONT_DIR}/GentiumPlus-5.000.zip" WORKING_DIRECTORY ${FONT_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz "${FONT_DIR}/Hack-v3.003-ttf.tar.xz" WORKING_DIRECTORY ${FONT_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz "${FONT_DIR}/LateefGR-1.200.zip" WORKING_DIRECTORY ${FONT_DIR})
execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz "${FONT_DIR}/Symbola.zip" WORKING_DIRECTORY ${FONT_DIR})

execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/TestCLR-Regular.ttf" "${FONT_DIR}")

set(env_vars
  "FONTCONFIG_FILE=${PROJECT_SOURCE_DIR}/fontconfig.conf"
  "PATH=${PROJECT_BINARY_DIR}/lua"
  "LUA_PATH=${PROJECT_SOURCE_DIR}/?.lua\\;${PROJECT_SOURCE_DIR}/lua-libraries/?.lua\\;${PROJECT_SOURCE_DIR}/lua-libraries/?/init.lua\\;${TMP_LUAROCKS_DIR}/systree/share/lua/5.1/?.lua"
  "LUA_CPATH=$<TARGET_FILE_DIR:justenoughicu>/?.dll\\;${TMP_LUAROCKS_DIR}/systree/lib/lua/5.1/?.dll"
)

set(known_bad_tests
  "process-commands"
  "color-fonts"
  "balanced"
  "bug-307"
  "footnotes-twocols"
  "space-after-command"
  "sura-2")

function(add_sile_test file_path)
  get_filename_component(basename "${file_path}" NAME_WE)
  set(expect_file "${CMAKE_CURRENT_SOURCE_DIR}/${basename}.expected")
  set(actual_file "${CMAKE_CURRENT_BINARY_DIR}/${basename}.actual")

  add_test(
    NAME ${basename}
    COMMAND "${PROJECT_BINARY_DIR}/sile.exe" "${file_path}" -b debug -o "${actual_file}"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
  set_tests_properties(${basename} PROPERTIES ENVIRONMENT "${env_vars}")

  add_test(
    NAME ${basename}_parity
    COMMAND "${CMAKE_COMMAND}" -E compare_files "${expect_file}" "${actual_file}")
  set_tests_properties(${basename}_parity PROPERTIES DEPENDS ${basename})

  if (NOT EXISTS "${expect_file}")
    message("Skip the running of test ${basename} because the expect file is missing.")
    set_tests_properties(${basename} PROPERTIES DISABLED True)
    set_tests_properties(${basename}_parity PROPERTIES DISABLED True)
  elseif (basename IN_LIST known_bad_tests)
    message("Skip the parity test of test ${basename} because it's a known bad test")
    set_tests_properties(${basename}_parity PROPERTIES DISABLED True)
  endif()
endfunction()

file(GLOB TEST_FILES
  "${CMAKE_CURRENT_SOURCE_DIR}/*.sil"
  "${CMAKE_CURRENT_SOURCE_DIR}/*.xml")
foreach(TEST_FILE ${TEST_FILES})
  add_sile_test(${TEST_FILE})
endforeach()
