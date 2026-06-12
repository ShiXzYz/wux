function ss {
    [CmdletBinding()]
    param(
        [Alias('t')][switch]$TCP,
        [Alias('u')][switch]$UDP,
        [Alias('l')][switch]$Listening,
        [Alias('a')][switch]$All,
        [Alias('n')][switch]$Numeric,
        [Alias('p')][switch]$Processes,
        [Alias('4')][switch]$IPv4,
        [Alias('6')][switch]$IPv6,
        [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs
    )

    $showTCP = $TCP -or (-not $UDP)
    $showUDP = $UDP

    function Format-Addr {
        param($ip, $port)
        if ($ip -eq '0.0.0.0' -or $ip -eq '::') { return "*:$port" }
        if ($ip -match ':') { return "[$ip]:$port" }
        return "${ip}:${port}"
    }

    function Get-ProcName([int]$pid) {
        $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($p) { return "$pid/$($p.ProcessName)" }
        return "$pid/-"
    }

    $rows = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($showTCP) {
        $conns = Get-NetTCPConnection -ErrorAction SilentlyContinue
        if ($Listening)              { $conns = $conns | Where-Object { $_.State -eq 'Listen' } }
        elseif (-not $All)           { $conns = $conns | Where-Object { $_.State -ne 'Listen' } }
        if ($IPv4) { $conns = $conns | Where-Object { $_.LocalAddress -notmatch ':' } }
        if ($IPv6) { $conns = $conns | Where-Object { $_.LocalAddress -match    ':' } }

        foreach ($c in $conns) {
            $rows.Add([PSCustomObject]@{
                Netid   = 'tcp'
                State   = $c.State
                Local   = Format-Addr $c.LocalAddress  $c.LocalPort
                Peer    = Format-Addr $c.RemoteAddress $c.RemotePort
                Process = if ($Processes -and $c.OwningProcess) { Get-ProcName $c.OwningProcess } else { '' }
            })
        }
    }

    if ($showUDP) {
        $udp = Get-NetUDPEndpoint -ErrorAction SilentlyContinue
        if ($IPv4) { $udp = $udp | Where-Object { $_.LocalAddress -notmatch ':' } }
        if ($IPv6) { $udp = $udp | Where-Object { $_.LocalAddress -match    ':' } }

        foreach ($c in $udp) {
            $rows.Add([PSCustomObject]@{
                Netid   = 'udp'
                State   = 'UNCONN'
                Local   = Format-Addr $c.LocalAddress $c.LocalPort
                Peer    = '*:*'
                Process = if ($Processes -and $c.OwningProcess) { Get-ProcName $c.OwningProcess } else { '' }
            })
        }
    }

    if ($Processes) {
        '{0,-6} {1,-13} {2,-28} {3,-28} {4}' -f 'Netid','State','Local Address:Port','Peer Address:Port','Process'
        foreach ($r in $rows) {
            '{0,-6} {1,-13} {2,-28} {3,-28} {4}' -f $r.Netid,$r.State,$r.Local,$r.Peer,$r.Process
        }
    } else {
        '{0,-6} {1,-13} {2,-28} {3}' -f 'Netid','State','Local Address:Port','Peer Address:Port'
        foreach ($r in $rows) {
            '{0,-6} {1,-13} {2,-28} {3}' -f $r.Netid,$r.State,$r.Local,$r.Peer
        }
    }
}
