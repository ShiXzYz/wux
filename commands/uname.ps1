function Wux_uname {
    [CmdletBinding()]
    param(
        [Alias('a')][switch]$All,
        [Alias('s')][switch]$KernelName,
        [Alias('n')][switch]$NodeName,
        [Alias('r')][switch]$KernelRelease,
        [Alias('v')][switch]$KernelVersion,
        [Alias('m')][switch]$Machine,
        [Alias('o')][switch]$OperatingSystem
    )

    $os       = [System.Environment]::OSVersion
    $kName    = 'Windows_NT'
    $node     = $env:COMPUTERNAME
    $release  = $os.Version.ToString()
    $version  = $os.VersionString
    $machineArch = $env:PROCESSOR_ARCHITECTURE
    $osName   = 'Windows'

    $noneSet = -not ($All -or $KernelName -or $NodeName -or $KernelRelease -or $KernelVersion -or $Machine -or $OperatingSystem)
    if ($noneSet) { return $kName }

    $parts = @()
    if ($All -or $KernelName)       { $parts += $kName }
    if ($All -or $NodeName)         { $parts += $node }
    if ($All -or $KernelRelease)    { $parts += $release }
    if ($All -or $KernelVersion)    { $parts += $version }
    if ($All -or $Machine)          { $parts += $machineArch }
    if ($All -or $OperatingSystem)  { $parts += $osName }
    $parts -join ' '
}
