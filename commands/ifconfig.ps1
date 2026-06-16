function Wux_ifconfig {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$Interface
    )

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
    if ($Interface) {
        $adapters = $adapters | Where-Object { $_.Name -like "*$Interface*" -or $_.InterfaceDescription -like "*$Interface*" }
    }

    foreach ($a in $adapters) {
        $status = if ($a.Status -eq 'Up') { 'UP' } else { 'DOWN' }
        $flags  = "flags=<$status,BROADCAST,MULTICAST>"
        Write-Host "$($a.Name): $flags  mtu $($a.MtuSize)" -ForegroundColor Cyan
        Write-Host "    ether $($a.MacAddress)"

        $ips = Get-NetIPAddress -InterfaceIndex $a.InterfaceIndex -ErrorAction SilentlyContinue
        foreach ($ip in $ips) {
            if ($ip.AddressFamily -eq 'IPv4') {
                Write-Host "    inet $($ip.IPAddress)/$($ip.PrefixLength)"
            } elseif ($ip.AddressFamily -eq 'IPv6') {
                Write-Host "    inet6 $($ip.IPAddress)/$($ip.PrefixLength)"
            }
        }

        $stats = Get-NetAdapterStatistics -Name $a.Name -ErrorAction SilentlyContinue
        if ($stats) {
            Write-Host "    RX packets:$($stats.ReceivedUnicastPackets) bytes:$($stats.ReceivedBytes)"
            Write-Host "    TX packets:$($stats.SentUnicastPackets) bytes:$($stats.SentBytes)"
        }
        Write-Host ''
    }
}
