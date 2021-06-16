@echo off
set SOURCE_DIR=%1
set STAGE_DIR=%2
set OUTPUT_DIR=%3

for /f %%i in ('git describe --tags') do set VERSION=%%i
for /f "tokens=1 delims=-" %%i in ("%VERSION%") do set VERSION=%%i
set VERSION=%VERSION:v=%
iscc /Dversion=%VERSION% "/Dsource_dir=%SOURCE_DIR%" "/Dstage_dir=%STAGE_DIR%" "/O%OUTPUT_DIR%" "%SOURCE_DIR%\.inno\sile.iss"