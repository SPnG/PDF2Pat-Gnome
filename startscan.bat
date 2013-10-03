@echo off

rem Start eines Batch Scanners
rem
rem Speedpoint GmbH (FW), Stand: Oktober 2013, Version 1

rem --------------------------------------------------------------------
rem Bitte anpassen:
set job="PDF2Pat"
set prog="C:\Programme\fiScanner\ScandAll PRO\ScandAllPro.exe"
set task="ScandAllPro.exe"
rem --------------------------------------------------------------------

tasklist | find /I %task% && taskkill /IM %task% /F
call %prog% /exit /batch:%job%

exit