function Wux_traceroute {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$Destination,
        [Alias('m')][int]$MaxHops = 30,
        [Alias('n')][switch]$Numeric,
        [Alias('w')][int]$Wait = 4
    )

    $args = [System.Collections.Generic.List[string]]@('-h', $MaxHops, '-w', ($Wait * 1000))
    if ($Numeric) { $args.Add('-d') }
    $args.Add($Destination)
    & tracert.exe @args
}
