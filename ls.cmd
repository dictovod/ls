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
set "LS_TREE="

if /i "%~1"=="/?" goto :help
if /i "%~1"=="-h" goto :help

:parse_args
if "%~1"=="" goto :run
if /i "%~1"=="/s" set "LS_RECURSE=1" & shift & goto :parse_args
if /i "%~1"=="/d" set "LS_SHOWPATHS=1" & set "LS_RECURSE=1" & set "LS_SHOWFILES=1" & shift & goto :parse_args
if /i "%~1"=="/f" set "LS_SHOWFILES=1" & shift & goto :parse_args
if /i "%~1"=="/l" set "LS_LONG=1" & shift & goto :parse_args
if /i "%~1"=="/v" set "LS_SHOWSIZE=1" & shift & goto :parse_args
if /i "%~1"=="/t" set "LS_SHOWCONTENT=1" & shift & goto :parse_args
if /i "%~1"=="/tree" set "LS_TREE=1" & shift & goto :parse_args
if /i "%~1"=="/x" (
    set "LS_EXCLUDE=%~2"
    shift & shift
    goto :parse_args
)
set "LS_MASK=%~1"
shift
goto :parse_args

:run
if defined LS_TREE (
    echo [Дерево каталогов]
    call :printTreeRecursive "." "" "1"
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
            call :shouldSkip "%%~xF"
            if "!LS_SKIP!"=="1" (
                rem пропускаем файл
            ) else (
                echo === Содержимое файла: %%~fF ===
                type "%%~fF"
                echo.
            )
        )
    ) else (
        echo [Содержимое файлов в текущей папке]
        for %%F in (%LS_MASK%) do if not exist "%%F\" (
            call :shouldSkip "%%~xF"
            if "!LS_SKIP!"=="1" (
                rem пропускаем файл
            ) else (
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

:shouldSkip
set "LS_SKIP=0"
set "EXT=%~1"
if defined LS_EXCLUDE (
    for %%E in (%LS_EXCLUDE%) do (
        if /i "!EXT!"=="%%~E" set "LS_SKIP=1"
    )
)
exit /b

:printTreeRecursive
setlocal EnableDelayedExpansion
set "CURRENT_DIR=%~1"
set "PREFIX=%~2"
set "IS_ROOT=%~3"

pushd "%CURRENT_DIR%" >nul 2>&1 || exit /b

:: Если это корневой вызов, покажем имя папки (без кавычек)
if "!IS_ROOT!"=="1" (
    echo ┌ %CD%\
    set "PREFIX="
)

:: Собираем файлы
set "FILE_COUNT=0"
for /f "delims=" %%F in ('dir /b /a-d 2^>nul') do (
    set /a FILE_COUNT+=1
    set "FILE[!FILE_COUNT!]=%%F"
)

:: Собираем папки
set "DIR_COUNT=0"
for /f "delims=" %%D in ('dir /b /ad 2^>nul') do (
    set /a DIR_COUNT+=1
    set "DIR[!DIR_COUNT!]=%%D"
)

:: Выводим файлы
for /l %%I in (1,1,!FILE_COUNT!) do (
    :: Определяем, является ли этот элемент последним
    if %%I==!FILE_COUNT! (
        if !DIR_COUNT!==0 (
            echo !PREFIX!└── !FILE[%%I]!
        ) else (
            echo !PREFIX!├── !FILE[%%I]!
        )
    ) else (
        echo !PREFIX!├── !FILE[%%I]!
    )
)

:: Выводим папки и рекурсивно обрабатываем их
for /l %%I in (1,1,!DIR_COUNT!) do (
    :: Определяем, является ли эта папка последним элементом
    if %%I==!DIR_COUNT! (
        echo !PREFIX!└── !DIR[%%I]!\
        set "NEW_PREFIX=!PREFIX!    "
    ) else (
        echo !PREFIX!├── !DIR[%%I]!\
        set "NEW_PREFIX=!PREFIX!│   "
    )
    call :printTreeRecursive "!DIR[%%I]!" "!NEW_PREFIX!" "0"
)

popd >nul
endlocal
exit /b

:help
echo.
echo Использование: ls [опции] [маска]
echo /s     рекурсивный список
echo /d     выводить полные пути до всех файлов рекурсивно
echo /f     только файлы
echo /l     подробный режим (дата, время, размер)
echo /v     показывать вес папок и файлов (медленнее для папок)
echo /t     выводить содержимое файлов, как команда type
echo /x     "расширения через запятую", которые нужно исключить при /t
echo /tree  вывод дерева каталогов в стиле tree
echo маска  напр. *.exe
echo.
echo Примеры:
echo ls
echo ls /v
echo ls /l /v
echo ls /s /l /v *.dll
echo ls /t
echo ls /t /x ".exe,.dll,.jpg"
echo ls /d /t /x ".log,.tmp"
echo ls /tree
echo.
exit /b
