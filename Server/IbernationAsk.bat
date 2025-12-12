@echo off
setlocal enabledelayedexpansion

:: Chiedi le ore
set /p ore=Inserisci tra quante ore vuoi spegnere il PC: 
for /f "tokens=* usebackq" %%a in (`powershell -command "(Get-Date).AddHours(%ore%).AddMinutes(10).ToString('dd/MM/yyyy HH:mm')"`) do set DateTimeOff=%%a

echo Il PC si spegnera' alle %DateTimeOff%

:: Sostituisci spazio con %20 per URL
set "DateTimeOffURL=%DateTimeOff: =-%"
echo urldate %DateTimeOffURL%
:: Invio al tuo ESP32
curl "http://192.168.1.32:22113/setdatetime?datetimeoff=%DateTimeOffURL%"
echo Il PC si spegnera' tra %ore% ore e 10 minuti (in %secondi% secondi).
for /L %%i in (%ore%,-1,1) do (
  setlocal enabledelayedexpansion
  echo Ibernazione tra %%i ore...
  timeout /t 3600 /nobreak >nul
)


echo Iibernazione imminente...
timeout /t 60 /nobreak >nul
shutdown /h