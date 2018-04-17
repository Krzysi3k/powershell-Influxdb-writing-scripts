- send ping request
- collect output (ms and hostname)
- send to InfluxDB (Invoke-WebRequest)

executing script:
```batch
powershell.exe -file .\ping-request-asJob.ps1
```