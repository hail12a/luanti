@echo off
rem ==========================================================================
rem  AkititoCraft launcher
rem  Double-click this file to start AkititoCraft on Windows.
rem  It searches the usual build/output locations for the game executable
rem  and launches the first one it finds.
rem ==========================================================================

setlocal enableextensions
title AkititoCraft

rem Always work from the directory this script lives in.
cd /d "%~dp0"

set "EXE_NAME=akititocraft.exe"
set "GAME_EXE="

rem Candidate locations, in priority order.
for %%P in (
    "bin\%EXE_NAME%"
    "%EXE_NAME%"
    "build\bin\%EXE_NAME%"
    "build\Release\%EXE_NAME%"
    "build\Debug\%EXE_NAME%"
) do (
    if exist "%%~P" (
        set "GAME_EXE=%%~fP"
        goto :found
    )
)

rem Fallback: search recursively for the executable.
for /r "%~dp0" %%F in (%EXE_NAME%) do (
    if exist "%%F" (
        set "GAME_EXE=%%F"
        goto :found
    )
)

echo.
echo   Could not find %EXE_NAME%.
echo.
echo   AkititoCraft has not been built yet, or the executable is in an
echo   unexpected location. Build the game first (see README.md, "Compiling")
echo   and make sure %EXE_NAME% ends up in the "bin" folder next to this file.
echo.
pause
exit /b 1

:found
echo Launching AkititoCraft...
echo   %GAME_EXE%
echo.

rem Pass along any command-line arguments given to this script.
start "" "%GAME_EXE%" %*

endlocal
exit /b 0
