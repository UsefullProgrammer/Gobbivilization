@echo off
setlocal
::per gestire più versioni
REM Cartelle di origine e destinazione
set SRC="Assets - Main"
set DEST="assets"

REM 1. Sincronizza i file: copia quelli nuovi/diversi e elimina quelli extra
robocopy %SRC% %DEST% /MIR /R:1 /W:1 /LOG:sync.log

REM Spiegazione parametri:
REM /MIR   -> Mirror: rende DEST identico a SRC (copia + elimina)
REM /R:1   -> Tentativi di retry = 1 (default è infinito)
REM /W:1   -> Attesa tra retry = 1 secondo
REM /NFL   -> Non mostra lista file
REM /NDL   -> Non mostra lista directory
REM /NP    -> Non mostra progressi
REM /LOG   -> Scrive log in sync.log

echo Sincronizzazione completata!
pause