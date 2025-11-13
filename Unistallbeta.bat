@echo off
setlocal

:: Percorso di destinazione
set "PATH_E=E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V"
set "PATH_C=C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V"
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
    set /p DEST=Inserisci manualmente il percorso completo della cartella Civilization V:
    if not exist "%DEST%" (
        echo.
        echo Il percorso inserito non esiste. Uscita...
        pause
        exit /b
    )
)
ECHO %DEST%
:: Percorso della root (dove si trova lo script)
set "ROOT=%~dp0"
:: Percorso di backup nella root
set "BACKUP=%ROOT%backup"
set "UPDATE=%ROOT%Beta"
ECHO %ROOT%
ECHO %BACKUP%
ECHO %UPDATE%
echo.
echo === Cancellazione dei file in %DEST% che combacciano con quelli in UPDATE ===

:: Controlla se le cartelle esistono
if not exist "%UPDATE%" (
    echo La cartella UPDATE non esiste: %UPDATE%
    goto :EOF
)
if not exist "%DEST%" (
    echo La cartella DEST non esiste: %DEST%
    goto :EOF
)

:: Ciclo ricorsivo su tutti i file nella cartella UPDATE
for /R "%UPDATE%" %%F in (*) do (
    setlocal enabledelayedexpansion
    set "REL_PATH=%%F"
    set "REL_PATH=!REL_PATH:%UPDATE%=!"
    set "TARGET_FILE=%DEST%!REL_PATH!"
   echo Cerco di Eliminare: !REL_PATH! !REL_PATH! !TARGET_FILE!
    if exist "!TARGET_FILE!" (
        echo Eliminazione: !TARGET_FILE!
        del /F /Q "!TARGET_FILE!"
    ) else (
        echo File non trovato: !TARGET_FILE!
    )
    endlocal
)
echo.
echo Disinstallazione file unici completata. Premere per continuare la disisntellazione
echo === Reinstallo versione vecchia dei file esistenti ===

robocopy "%BACKUP%" "%DEST%" /E /XC /XN /XO /NFL /NDL /NJH /NJS

call Installazione.bat