function Wux_free {
    [CmdletBinding()]
    param(
        [Alias('h')][switch]$HumanReadable,
        [Alias('m')][switch]$Megabytes,
        [Alias('g')][switch]$Gigabytes,
        [Alias('k')][switch]$Kilobytes,
        [switch]$Total
    )

    function Format-Mem([long]$bytes) {
        if ($HumanReadable) {
            $u = 'B','Ki','Mi','Gi','Ti'; $i = 0; $v = [double]$bytes
            while ($v -ge 1024 -and $i -lt 4) { $v /= 1024; $i++ }
            return '{0:0.#}{1}' -f $v, $u[$i]
        }
        if ($Gigabytes) { return [Math]::Round($bytes / 1GB, 1) }
        if ($Megabytes) { return [Math]::Round($bytes / 1MB) }
        return [Math]::Round($bytes / 1KB)
    }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

    $totalMem  = [long]$os.TotalVisibleMemorySize * 1KB
    $freeMem   = [long]$os.FreePhysicalMemory      * 1KB
    $usedMem   = $totalMem - $freeMem

    $totalSwap = [long]$os.TotalVirtualMemorySize * 1KB
    $freeSwap  = [long]$os.FreeVirtualMemory       * 1KB
    $usedSwap  = $totalSwap - $freeSwap

    '{0,-8} {1,12} {2,12} {3,12} {4,12}' -f '','total','used','free','available'
    '{0,-8} {1,12} {2,12} {3,12} {4,12}' -f 'Mem:',(Format-Mem $totalMem),(Format-Mem $usedMem),(Format-Mem $freeMem),(Format-Mem $freeMem)
    '{0,-8} {1,12} {2,12} {3,12}' -f 'Swap:',(Format-Mem $totalSwap),(Format-Mem $usedSwap),(Format-Mem $freeSwap)
}
