@echo off
setlocal

:: Definisci la directory di origine (root) e destinazione (release)
set "SOURCE=%~dp0"
set "DESTINATION=%SOURCE%beta"

:: Crea la cartella di destinazione se non esiste
if not exist "%DESTINATION%" (
    mkdir "%DESTINATION%"
)

:: Copia la cartella UPDATE
xcopy "%SOURCE%UPDATE" "%DESTINATION%\Beta" /E /I /Y
xcopy "%SOURCE%ProblemSolver" "%DESTINATION%\ProblemSolver" /E /I /Y
copy "%SOURCE%log.txt" "%DESTINATION%" /Y
:: Copia i file specificati
copy "%SOURCE%Disintallazione beta.bat" "%DESTINATION%" /Y
echo Operazione completata con successo.
pause