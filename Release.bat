@echo off
setlocal

:: Definisci la directory di origine (root) e destinazione (release)
set "SOURCE=%~dp0"
set "DESTINATION=%SOURCE%release"

:: Crea la cartella di destinazione se non esiste
if not exist "%DESTINATION%" (
    mkdir "%DESTINATION%"
)

:: Copia la cartella UPDATE
xcopy "%SOURCE%UPDATE" "%DESTINATION%\UPDATE" /E /I /Y
xcopy "%SOURCE%ProblemSolver" "%DESTINATION%\ProblemSolver" /E /I /Y
:: Copia i file specificati
copy "%SOURCE%Installazione.bat" "%DESTINATION%" /Y
copy "%SOURCE%Disintallazione.bat" "%DESTINATION%" /Y
copy "%SOURCE%SOLOBACKUP.bat" "%DESTINATION%" /Y
copy "%SOURCE%Leggimi.txt" "%DESTINATION%" /Y
copy "%SOURCE%log.txt" "%DESTINATION%" /Y
copy "%SOURCE%_setpatchServer.bat" "%DESTINATION%" /Y
copy "%SOURCE%VerificaVersione.bat" "%DESTINATION%" /Y
move /Y "%DESTINATION%\UPDATE\rcedit-x64.exe" "%DESTINATION%\rcedit-x64.exe"
move /Y "%DESTINATION%\UPDATE\setpatch.bat" "%DESTINATION%\setpatch.bat"
echo Operazione completata con successo.
pause