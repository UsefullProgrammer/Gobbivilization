@echo off
setlocal

:: Percorso di destinazione
set "PATH_E=E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V"
set "PATH_C=C:\SteamLibrary\steamapps\common\Sid Meier's Civilization V"
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
if not exist "%BACKUP%" (
    

    echo.
    echo === Backup dei file esistenti ===

    :: Esegui backup solo dei file che esistono già nella destinazione
    if not exist "%BACKUP%" (
    mkdir "%BACKUP%"
    robocopy "%DEST%" "%BACKUP%" /E /XC /XD UPDATE backup /XN /XO /NFL /NDL /NJH /NJS /NP CivilizationV.exe *.xml *.lua *.Civ5Pkg
    echo Backup salvato in %BACKUP%
    echo.


    )
)
echo === Copia i nuovi file per l'aggiornamneto gobbico (escludendo la cartella backup) ===

:: Copia tutti i file dalla root alla destinazione, escludendo la cartella "backup"
echo Filedaggiornamento = [%UPDATE%]
echo DEST = [%DEST%]
echo BACKUP = [%BACKUP%]
robocopy "%UPDATE%" "%DEST%" /E /NFL /NDL /NJH /NJS /NP
echo Installazione completata.
echo.

pause