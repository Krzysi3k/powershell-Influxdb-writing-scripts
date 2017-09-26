cd /d "%~dp0"
powershell.exe -command "Import-Module .\write-to-influxDB.ps1;run-main"
exit