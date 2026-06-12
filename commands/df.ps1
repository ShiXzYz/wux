function df {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Paths,

        [Alias('h')][switch]$HumanReadable,
        [Alias('k')][switch]$Kilobytes,
        [Alias('m')][switch]$Megabytes,
        [Alias('T')][switch]$PrintType,
        [Alias('i')][switch]$Inodes   # accepted for compat; no-op on Windows
    )

    function Format-Size([long]$bytes) {
        if ($HumanReadable) {
            $u = 'B','K','M','G','T'; $i = 0; $v = [double]$bytes
            while ($v -ge 1024 -and $i -lt 4) { $v /= 1024; $i++ }
            return '{0:0.#}{1}' -f $v, $u[$i]
        }
        if ($Megabytes) { return [Math]::Ceiling($bytes / 1MB) }
        return [Math]::Ceiling($bytes / 1KB)
    }

    $label = if ($HumanReadable) { 'Size' } elseif ($Megabytes) { 'MB-blocks' } else { '1K-blocks' }

    if ($PrintType) {
        '{0,-22} {1,-8} {2,12} {3,12} {4,12} {5,5}% {6}' -f 'Filesystem','Type',$label,'Used','Available','Use','Mounted on'
    } else {
        '{0,-22} {1,12} {2,12} {3,12} {4,5}% {5}' -f 'Filesystem',$label,'Used','Available','Use','Mounted on'
    }

    Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Used } | ForEach-Object {
        $total  = $_.Used + $_.Free
        $usePct = if ($total -gt 0) { [int]([Math]::Round(100 * $_.Used / $total)) } else { 0 }
        $mount  = if ($_.Root) { $_.Root } else { "$($_.Name):\" }
        $fs     = ''
        if ($PrintType) {
            try { $fs = (Get-Volume -DriveLetter $_.Name -ErrorAction SilentlyContinue).FileSystemType } catch {}
        }

        if ($PrintType) {
            '{0,-22} {1,-8} {2,12} {3,12} {4,12} {5,5}% {6}' -f $mount,$fs,(Format-Size $total),(Format-Size $_.Used),(Format-Size $_.Free),$usePct,$mount
        } else {
            '{0,-22} {1,12} {2,12} {3,12} {4,5}% {5}' -f $mount,(Format-Size $total),(Format-Size $_.Used),(Format-Size $_.Free),$usePct,$mount
        }
    }
}
