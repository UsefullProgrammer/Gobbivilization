@echo off
setlocal

:: Percorso di destinazione
set "PATH_E=E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V"
set "PATH_C=C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V"
:: Percorso della root (dove si trova lo script)
set "ROOT=%~dp0"

:: Controlla se l'eseguibile esiste nella stessa cartella
if exist "%ROOT%CivilizationV.exe" (
    echo Eseguibile trovato nella stessa cartella dello script.
    ::set "DEST=%ROOT%"
        :: Rimuove l'ultima barra se presente
    
    for %%Q in ("%~dp0\.") DO set "DEST=%%~fQ"

) else (
  echo Eseguibile non trovato nella stessa cartella dello script procedo a controllare percorsi standard.
:: Controllo esistenza
if exist "%PATH_E%" (
    set "DEST=%PATH_E%"
    echo Trovata cartella in E:
) else if exist "%PATH_C%" (
    set "DEST=%PATH_C%"
    echo Trovata cartella in C:
) else (
    echo.
    echo La cartella Civilization V non è stata trovata in E: o C:
    echo Aprire il path e modificare il path "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V" con il vostro
    pause
    exit /b
)
)
echo.
echo Cartella selezionata: %DEST%



:: Percorso di backup nella root
set "BACKUP=%ROOT%backup"
set "UPDATE=%ROOT%UPDATE"
:: Crea la cartella di backup se non esiste
::V2

for /R "%UPDATE%" %%F in (*) do (
    set /a COUNT+=1
)

set "TOTAL=%COUNT%"

set "CURRENT=0"

for /R "%UPDATE%" %%F in (*) do (
    setlocal enabledelayedexpansion
    
    set "REL_PATH=%%F"
    
    set "REL_PATH=!REL_PATH:%UPDATE%=!"
    set "SOURCE_FILE=%DEST%!REL_PATH!"
    set "TARGET_FILE=%BACKUP%!REL_PATH!"
    if exist "!SOURCE_FILE!" (
        if not exist "!TARGET_FILE!" (
            mkdir "!TARGET_FILE!\.." >nul 2>&1
            copy /Y "!SOURCE_FILE!" "!TARGET_FILE!" >nul
        ) else (
            echo Gia' presente: !TARGET_FILE!
        )
    ) else (
        echo Non trovato in DEST: !SOURCE_FILE!
    )
    endlocal
)

echo.
echo Backup completato.
echo === Copia i nuovi file per l'aggiornamneto gobbico (escludendo la cartella backup) ===

:: Copia tutti i file dalla root alla destinazione, escludendo la cartella "backup"
echo Filedaggiornamento = [%UPDATE%]
echo DEST = [%DEST%]
echo BACKUP = [%BACKUP%]
robocopy "%UPDATE%" "%DEST%" /E /NFL /NDL /NJH /NJS

echo Installazione completata.
echo.
echo Avviare civ V (S/N)?
set /p "RISPOSTA=> "

if /I "%RISPOSTA%"=="S" (
    echo [+] Avvio Civilization V...
    start "" "%DEST%\CivilizationV.exe"
) else (
    echo [-] Avvio annullato.
)

pause