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
set "LS_SHOWCONTENT="
set "LS_EXCLUDE="
set "LS_EXCLUDEDIRS="
set "LS_TREE="

if /i "%~1"=="/?" goto :help
if /i "%~1"=="-h" goto :help

:parse_args
if "%~1"=="" goto :run

if /i "%~1"=="/s"    set "LS_RECURSE=1"    & shift & goto :parse_args
if /i "%~1"=="/d"    set "LS_SHOWPATHS=1"  & set "LS_RECURSE=1" & set "LS_SHOWFILES=1" & shift & goto :parse_args
if /i "%~1"=="/f"    set "LS_SHOWFILES=1"  & shift & goto :parse_args
if /i "%~1"=="/l"    set "LS_LONG=1"       & shift & goto :parse_args
if /i "%~1"=="/v"    set "LS_SHOWSIZE=1"   & shift & goto :parse_args
if /i "%~1"=="/t"    set "LS_SHOWCONTENT=1"& shift & goto :parse_args
if /i "%~1"=="/tree" set "LS_TREE=1"       & shift & goto :parse_args

if /i "%~1"=="/x" (
    set "LS_EXCLUDE=%~2"
    shift & shift
    goto :parse_args
)

if /i "%~1"=="/xd" (
    set "LS_EXCLUDEDIRS=%~2"
    shift & shift
    goto :parse_args
)

set "LS_MASK=%~1"
shift
goto :parse_args

:run
if defined LS_TREE (
    echo [Дерево каталогов]
    call :printTree "."
    exit /b
)

if not defined LS_SHOWPATHS if not defined LS_RECURSE if not defined LS_SHOWFILES if not defined LS_SHOWDIRS if not defined LS_LONG if not defined LS_SHOWSIZE if not defined LS_SHOWCONTENT (
    echo [Список файлов с полными путями]
    for %%F in (%LS_MASK%) do if not exist "%%F\" echo %%~fF
    exit /b
)

if defined LS_SHOWCONTENT (
    if defined LS_SHOWPATHS (
        echo [Содержимое файлов с полными путями рекурсивно]
        for /r %%F in (%LS_MASK%) do if not exist "%%F\" (
            call :shouldSkipExt "%%~xF"
            if "!LS_SKIP!"=="0" (
                echo === Содержимое файла: %%~fF ===
                type "%%~fF"
                echo.
            )
        )
    ) else (
        echo [Содержимое файлов в текущей папке]
        for %%F in (%LS_MASK%) do if not exist "%%F\" (
            call :shouldSkipExt "%%~xF"
            if "!LS_SKIP!"=="0" (
                echo === Содержимое файла: %%~fF ===
                type "%%~fF"
                echo.
            )
        )
    )
    exit /b
)

if defined LS_SHOWPATHS (
    echo [Список файлов с полными путями]
    for /r %%F in (%LS_MASK%) do if not exist "%%F\" echo %%~fF
    exit /b
)

if defined LS_RECURSE (
    echo [Рекурсивный список]

    rem Директории
    for /r /d %%D in (*) do (
        call :isInExcludedDir "%%~fD"
        if "!LS_INEXCL!"=="0" (
            if not defined LS_SHOWFILES call :printEntry "%%~fD" dir
        )
    )

    rem Файлы
    for /r %%F in (%LS_MASK%) do if not exist "%%F\" (
        call :isInExcludedDir "%%~fF"
        if "!LS_INEXCL!"=="0" (
            if not defined LS_SHOWDIRS call :printEntry "%%~fF" file
        )
    )

) else (
    echo [Текущая папка]

    rem Директории
    for /d %%D in (*) do (
        call :isInExcludedDir "%%~fD"
        if "!LS_INEXCL!"=="0" (
            if not defined LS_SHOWFILES call :printEntry "%%~fD" dir
        )
    )

    rem Файлы
    for %%F in (%LS_MASK%) do if not exist "%%F\" (
        call :isInExcludedDir "%%~fF"
        if "!LS_INEXCL!"=="0" (
            if not defined LS_SHOWDIRS call :printEntry "%%~fF" file
        )
    )
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
            echo !LS_DATE! [DIR] !LS_ENTRY! (!LS_DIRSIZE! bytes)
        ) else (
            echo !LS_DATE! <DIR> !LS_ENTRY!
        )
    ) else (
        if defined LS_SHOWSIZE (
            echo !LS_DATE! !LS_SIZE! bytes !LS_ENTRY!
        ) else (
            echo !LS_DATE! !LS_SIZE! bytes !LS_ENTRY!
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

:shouldSkipExt
set "LS_SKIP=0"
set "EXT=%~1"
if defined LS_EXCLUDE (
    for %%E in (%LS_EXCLUDE%) do (
        if /i "!EXT!"=="%%~E" set "LS_SKIP=1"
    )
)
exit /b

:isInExcludedDir
set "LS_INEXCL=0"
if not defined LS_EXCLUDEDIRS exit /b

set "FULL=%~f1\"
set "LIST=%LS_EXCLUDEDIRS:,= %"

for %%E in (%LIST%) do (
    echo "!FULL!" | findstr /i "\\%%E\\">nul && set "LS_INEXCL=1"
)
exit /b

:printTree
setlocal EnableDelayedExpansion
set "BASE=%~1"
set "PREFIX=%~2"
pushd "%BASE%" >nul 2>&1 || exit /b

set i=0

rem Файлы
for /f "delims=" %%A in ('dir /b /a-d 2^>nul') do (
    set /a i+=1
    set "ITEM[!i!]=%%A"
)

rem Директории
for /f "delims=" %%A in ('dir /b /ad 2^>nul') do (
    call :isInExcludedDir "%CD%\%%A"
    if "!LS_INEXCL!"=="0" (
        set /a i+=1
        set "ITEM[!i!]=%%A\"
    )
)

for /l %%I in (1,1,!i!) do (
    set "NAME=!ITEM[%%I]!"
    if %%I==!i! (
        echo !PREFIX!└── !NAME!
        if "!NAME:~-1!"=="\" call :printTree "!BASE!\!NAME:~0,-1!" "!PREFIX!    "
    ) else (
        echo !PREFIX!├── !NAME!
        if "!NAME:~-1!"=="\" call :printTree "!BASE!\!NAME:~0,-1!" "!PREFIX!│   "
    )
)

popd >nul
endlocal
exit /b

:help
echo.
echo Использование: ls [опции] [маска]
echo /s       рекурсивный список
echo /d       выводить полные пути
echo /f       только файлы
echo /l       подробный режим
echo /v       показывать размер
echo /t       выводить содержимое файлов
echo /x       исключить расширения
echo /xd      исключить папки ("bin,obj")
echo /tree    дерево каталогов ls /tree /xd "bin,obj"
echo.
exit /b
