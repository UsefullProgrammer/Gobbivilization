@echo off
setlocal

REM Imposta la cartella sorgente e destinazione
set "SOURCE=Update\Assets"
set "DEST=UPDATEMAC\CivilizationV.app\Assets"

REM Crea la cartella di destinazione se non esiste
if not exist "%DEST%" (
    mkdir "%DEST%"
)

REM Copia tutto da Update\Assets a Assets\Assets
xcopy "%SOURCE%\*" "%DEST%\" /E /I /Y

echo Copia completata da %SOURCE% a %DEST%
pause
