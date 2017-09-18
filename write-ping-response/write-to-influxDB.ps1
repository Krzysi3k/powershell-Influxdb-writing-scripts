# get ping response from host
function get-response 
{
    $measurement = 'ping_request'
    $pinghost = 'hostname'
    $command = 'ping {0} -n 1 | findstr "Reply from"' -f $pinghost
    try
    {
        $ping = Invoke-Expression -Command $command -ErrorAction Stop
        $ms = (($ping.Split("=") | select -Last 2) | select -First 1).replace("ms TTL","")
        [int]$ms = $ms
    }
    catch
    {
        # ustaw minusowa wartosc (grafana mappings)
        [int]$ms = -1
    }

    $ms
    write-influxDB -ms $ms -servername $pinghost -measurement $measurement
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
    #$currtime = [int][double]::Parse((Get-Date -UFormat %s))
    $url="http://localhost:8086/write?db=$db"
    Invoke-WebRequest -UseBasicParsing -Uri $url -Body $body -method Post | Out-Null
}

function run-main
{
    # run endless loop
    while($true) 
    {
        get-response
        Start-Sleep -Seconds 10
    }
}

