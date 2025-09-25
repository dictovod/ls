@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: ==============================
:: ls.cmd - простой аналог ls
:: ==============================

set "LS_RECURSE="
set "LS_SHOWDIRS="
set "LS_SHOWFILES="
set "LS_LONG="
set "LS_SHOWSIZE="
set "LS_MASK=*"
set "LS_SHOWPATHS="

if /i "%~1"=="/?" goto :help
if /i "%~1"=="-h" goto :help

:parse_args
if "%~1"=="" goto :run
if /i "%~1"=="/s" set "LS_RECURSE=1" & shift & goto :parse_args
if /i "%~1"=="/d" set "LS_SHOWPATHS=1" & set "LS_RECURSE=1" & set "LS_SHOWFILES=1" & shift & goto :parse_args
if /i "%~1"=="/f" set "LS_SHOWFILES=1" & shift & goto :parse_args
if /i "%~1"=="/l" set "LS_LONG=1" & shift & goto :parse_args
if /i "%~1"=="/v" set "LS_SHOWSIZE=1" & shift & goto :parse_args
set "LS_MASK=%~1"
shift
goto :parse_args

:run
if defined LS_SHOWPATHS (
    echo [Список файлов с полными путями]
    for /r %%F in (%LS_MASK%) do if not exist "%%F\" echo %%~fF
    exit /b
)

if defined LS_RECURSE (
    echo [Рекурсивный список]
    for /r /d %%D in (*) do if not defined LS_SHOWFILES call :printEntry "%%~fD" dir
    for /r %%F in (%LS_MASK%) do if not exist "%%F\" if not defined LS_SHOWDIRS call :printEntry "%%~fF" file
) else (
    echo [Текущая папка]
    for /d %%D in (*) do if not defined LS_SHOWFILES call :printEntry "%%~fD" dir
    for %%F in (%LS_MASK%) do if not exist "%%F\" if not defined LS_SHOWDIRS call :printEntry "%%~fF" file
)
exit /b

:printEntry
set "LS_ENTRY=%~1"
set "LS_KIND=%~2"

for %%I in ("%LS_ENTRY%") do (
    set "LS_SIZE=%%~zI"
    set "LS_DATE=%%~tI"
    set "LS_NAME=%%~nxI"
)

if defined LS_LONG (
    if /i "%LS_KIND%"=="dir" (
        if defined LS_SHOWSIZE (
            call :getDirSize "%LS_ENTRY%"
            echo !LS_DATE!    [DIR] !LS_ENTRY! (!LS_DIRSIZE! bytes)
        ) else (
            echo !LS_DATE!    <DIR>    !LS_ENTRY!
        )
    ) else (
        if defined LS_SHOWSIZE (
            echo !LS_DATE!    !LS_SIZE! bytes   !LS_ENTRY!
        ) else (
            echo !LS_DATE!    !LS_SIZE! bytes   !LS_ENTRY!
        )
    )
) else (
    echo !LS_NAME!
)
exit /b

:getDirSize
set "LS_DIRSIZE="
for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command ^
  "(Get-ChildItem -LiteralPath '%~1' -Force -Recurse -File | Measure-Object -Sum Length).Sum"`) do set "LS_DIRSIZE=%%S"
if not defined LS_DIRSIZE set "LS_DIRSIZE=0"
exit /b

:help
echo.
echo Использование: ls [опции] [маска]
echo   /s  рекурсивный список
echo   /d  выводить полные пути до всех файлов рекурсивно
echo   /f  только файлы
echo   /l  подробный режим (дата, время, размер)
echo   /v  показывать вес папок и файлов (медленнее для папок)
echo   маска, напр. *.exe
echo Примеры:
echo   ls
echo   ls /v
echo   ls /l /v
echo   ls /s /l /v *.dll
echo.
exit /b
