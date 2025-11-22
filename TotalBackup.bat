@echo off
setlocal

:: Percorso di destinazione
set "PATH_E=E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V\Assets"
set "PATH_C=C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets"
set "ROOT=%~dp0"

robocopy "%PATH_E%" "%ROOT%AssCivBackup" *.lua *.xml /E /IF /XC /XN /XO
