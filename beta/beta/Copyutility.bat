@echo off
setlocal

:: Ottieni la cartella dove si trova lo script (senza barra finale)
for %%Q in ("%~dp0\.") DO set "TARGET=%%~fQ"

:: Chiedi il percorso da cui copiare
set "SOURCE=E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V\
set /p "RELATIVE=Inserisci il percorso relativo da copiare (es. UI\FrontEnd\OtherMenu.lua) "
if /I "%RELATIVE%"=="EXIT" goto END
:: Copia tutto da SOURCE a TARGET
::robocopy "%SOURCE%" "%TARGET%" CivilizationV.exe *.xml *.lua *.Civ5Pkg /E /XC /XD UPDATE backup /XN /XO /NFL /NDL /NJH /NJS /NP
::robocopy "%SOURCE%" "%TARGET%" "%RELATIVE%" /S /E /NFL /NDL /NJH /NJS /NP
:: Estrai la cartella relativa
for %%F in ("%SOURCE%%RELATIVE%") do set "RELATIVESource=%%~dpF"
for %%F in ("%TARGET%\%RELATIVE%") do set "RELATIVEFOLDERTarget=%%~dpF"
for %%F in ("%RELATIVE%") do set "RELATIVEexe=%%~nxF"
echo SR : %RELATIVESource%
echo TR : %RELATIVEFOLDERTarget%
robocopy "%RELATIVESource%\" "%RELATIVEFOLDERTarget%\" "%RELATIVEexe%" /NFL /NDL /NJH /NJS /NP
echo Copiato da: %SOURCE%
echo Incollato in: %TARGET%
:END