function Wux_chown {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Owner,

        [Parameter(Position = 1, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Paths,

        [Alias('R')][switch]$Recursive,
        [Alias('v')][switch]$ShowChanges
    )

    # Parse owner[:group] — group is accepted for compat but ignored on Windows ACL model
    $ownerName = $Owner -split ':' | Select-Object -First 1

    # Resolve to NTAccount
    try {
        $account = [System.Security.Principal.NTAccount]$ownerName
        $account.Translate([System.Security.Principal.SecurityIdentifier]) | Out-Null
    } catch {
        Write-Error "chown: invalid user: '$ownerName'"; return
    }

    function Set-Owner([string]$path) {
        try {
            $acl = Get-Acl $path
            $acl.SetOwner($account)
            if ($PSCmdlet.ShouldProcess($path, "chown to $ownerName")) {
                Set-Acl $path $acl
                if ($ShowChanges) { Write-Host "changed ownership of '$path' to '$ownerName'" }
            }
        } catch {
            Write-Warning "chown: changing ownership of '${path}': $($_.Exception.Message)"
        }
    }

    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) { Write-Error "chown: cannot access '${p}': No such file or directory"; continue }
        if ($Recursive) {
            Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { Set-Owner $_.FullName }
        }
        Set-Owner $p
    }
}
