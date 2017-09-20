# get ping response from host

function ping-request
{
    Param(
        [parameter(Mandatory=$true)][string]$hostname,
        [parameter(Mandatory=$true)][string]$alias
    )

    $measurement = 'ping_request'
    try
    {
        # get ping response (ms)
        [int]$ms = (Test-Connection $hostname -Count 1 -ErrorAction Stop).ResponseTime
    }
    catch
    {
        # ustaw minusowa wartosc (grafana mappings)
        [int]$ms = -1
    }

    #display output:
    #Write-Host "$alias : $ms`ms"
    write-influxDB -ms $ms -servername $alias -measurement $measurement
}

# write data into influxDB
function write-influxDB
{
    Param(
        [parameter(Mandatory=$true)][int]$ms,
        [parameter(Mandatory=$true)][string]$servername,
        [parameter(Mandatory=$true)][string]$measurement
    )

    $db = 'test_db'
    $body = "$measurement,servername=$servername ms=$ms"
    $url="http://localhost:8086/write?db=$db"
    Invoke-WebRequest -UseBasicParsing -Uri $url -Body $body -method Post | Out-Null
}

function run-main
{
    $json = Get-Content .\config.json | ConvertFrom-Json

    # run endless loop
    while($true) 
    {
        Clear-Host
        Write-Verbose "sending metrics..." -Verbose
        foreach($i in $json.machines)
        {
            ping-request -hostname $i.hostname -alias $i.alias
        }

        Start-Sleep -Seconds 10
    }
}

run-main
