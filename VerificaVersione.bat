echo off
set "ROOT=%~dp0"
echo %ROOT%CivilizationV.exe
powershell -Command "(Get-Item 'CivilizationV.exe').VersionInfo.FileVersion"
pause