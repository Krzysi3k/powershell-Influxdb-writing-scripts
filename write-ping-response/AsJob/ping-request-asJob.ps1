$currpth = Split-Path $MyInvocation.MyCommand.Definition
Set-Location $currpth

function ping-machines
{
    #initial configuration:
    $json = Get-Content .\config.json | ConvertFrom-Json
    $database = $json.database
    $measurement = 'ping_request'


    # send metrics every 10 seconds:
    while($true)
    {
        $job = @()
        foreach($h in $json.machines)
        {
            $job += Test-Connection $h.ipaddress -Count 1 -AsJob
        }

        While($job.State -match 'Running')
        {
            Start-Sleep -Milliseconds 20
        }

        $table = Receive-Job $job

        for($i = 0; $i -le $table.Length -1; $i++)
        {
            if($table[$i].ResponseTime -eq $null)
            {
                # if there is no response - send metrics with value: -100 (grafana mappings)
                $ms = -100
                WriteTo-InfluxDB -database $database -measurement $measurement -ms $ms -alias $json.machines.alias[$i]
                Write-Host "$($json.machines.alias[$i]) $ms"
            }
            else
            {
                # send metrics
                WriteTo-InfluxDB -database $database -measurement $measurement -ms $table[$i].ResponseTime -alias $json.machines.alias[$i]
                Write-Host "$($json.machines.alias[$i]) $($table[$i].ResponseTime)"
            }
        }

        Start-Sleep -Seconds 10
    }
}


function WriteTo-InfluxDB
{
    Param(
        [parameter(Mandatory=$true)][string]$database,
        [parameter(Mandatory=$true)][string]$measurement,
        [parameter(Mandatory=$true)][int]$ms,
        [parameter(Mandatory=$true)][string]$alias
    )

    $body = "$measurement,servername=$alias ms=$ms"
    $url="http://10.24.69.6:8086/write?db=$database"
    Invoke-WebRequest -UseBasicParsing -Uri $url -Body $body -method Post | Out-Null
}


ping-machines
