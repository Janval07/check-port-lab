<#
.SYNOPSIS
    Verifica si un puerto TCP está abierto en un host.
.PARAMETER Puerto
    Puerto a comprobar (1-65535).
.PARAMETER Destino
    Host destino (por defecto 127.0.0.1).
.EXAMPLE
    .\Check-Port.ps1 -Puerto 80
    .\Check-Port.ps1 -Puerto 3389 -Destino 192.168.1.10
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateRange(1, 65535)]
    [int]$Puerto,

    [Parameter(Position = 1)]
    [string]$Destino = "127.0.0.1",

    [int]$TimeoutMs = 3000
)

Write-Host "Verificando ${Destino}:${Puerto} ..."

$client = New-Object System.Net.Sockets.TcpClient
try {
    $async = $client.BeginConnect($Destino, $Puerto, $null, $null)
    $ok    = $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

    if ($ok -and $client.Connected) {
        $client.EndConnect($async)
        Write-Host "Puerto $Puerto en ${Destino}: ABIERTO" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "Puerto $Puerto en ${Destino}: CERRADO (o filtrado)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Puerto $Puerto en ${Destino}: CERRADO (error: $($_.Exception.Message))" -ForegroundColor Red
    exit 1
}
finally {
    $client.Close()
}