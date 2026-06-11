function find {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [string]$Name,
        [string]$IName,        # case-insensitive name
        [ValidateSet('f','d','l','b','c','p','s','')][string]$Type = '',
        [string]$Newer,
        [string]$OlderThan,
        [int]$MaxDepth = [int]::MaxValue,
        [int]$MinDepth = 0,
        [int]$Mtime,           # modified N days ago
        [string]$Size,         # +/-Nc/k/M/G
        [switch]$Empty,
        [switch]$Delete,
        [string]$Exec,         # e.g. "echo {}"
        [switch]$Print,        # default behavior
        [switch]$L,            # follow symlinks (no-op on Windows, accepted for compat)
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$ExtraArgs
    )

    $pattern     = if ($IName) { $IName } elseif ($Name) { $Name } else { '*' }
    $caseInsensitive = [bool]$IName

    $gciParams = @{
        Path    = $Path
        Recurse = $true
        Force   = $true
        ErrorAction = 'SilentlyContinue'
    }

    Get-ChildItem @gciParams | Where-Object {
        $item = $_
        $depth = ($item.FullName.Replace($Path, '').Split([IO.Path]::DirectorySeparatorChar) | Where-Object { $_ }).Count - 1

        if ($depth -lt $MinDepth -or $depth -gt $MaxDepth) { return $false }

        if ($Type) {
            $match = switch ($Type) {
                'f' { -not $item.PSIsContainer -and $item.LinkType -ne 'SymbolicLink' }
                'd' { $item.PSIsContainer }
                'l' { $item.LinkType -eq 'SymbolicLink' }
                default { $true }
            }
            if (-not $match) { return $false }
        }

        if ($Name -or $IName) {
            $nameMatch = if ($caseInsensitive) {
                $item.Name -ilike $pattern
            } else {
                $item.Name -like $pattern
            }
            if (-not $nameMatch) { return $false }
        }

        if ($Empty) {
            if ($item.PSIsContainer) {
                if ((Get-ChildItem $item.FullName -Force).Count -ne 0) { return $false }
            } else {
                if ($item.Length -ne 0) { return $false }
            }
        }

        if ($Mtime) {
            $cutoff = (Get-Date).AddDays(-$Mtime)
            if ($item.LastWriteTime -lt $cutoff) { return $false }
        }

        if ($Newer) {
            $ref = Get-Item $Newer -ErrorAction SilentlyContinue
            if ($ref -and $item.LastWriteTime -le $ref.LastWriteTime) { return $false }
        }

        if ($Size) {
            $sign = if ($Size[0] -in '+','-') { $Size[0] } else { '=' }
            $raw  = $Size.TrimStart('+','-')
            $unit = $raw[-1]
            $num  = [double]($raw.TrimEnd('cCkKmMgG'))
            $bytes = switch ($unit) {
                'k' { $num * 1KB }   'K' { $num * 1KB }
                'm' { $num * 1MB }   'M' { $num * 1MB }
                'g' { $num * 1GB }   'G' { $num * 1GB }
                'c' { $num }
                default { $num * 512 }  # blocks
            }
            $fileSize = $item.Length
            $pass = switch ($sign) {
                '+' { $fileSize -gt $bytes }
                '-' { $fileSize -lt $bytes }
                default { $fileSize -eq $bytes }
            }
            if (-not $pass) { return $false }
        }

        return $true
    } | ForEach-Object {
        if ($Delete) {
            Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
        } elseif ($Exec) {
            $cmd = $Exec -replace '\{\}', $_.FullName
            Invoke-Expression $cmd
        } else {
            $_.FullName
        }
    }
}
