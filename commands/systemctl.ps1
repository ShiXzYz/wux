function Wux_systemctl {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Action,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$ServiceArgs
    )

    $svcName = if ($ServiceArgs.Count -gt 0) { $ServiceArgs[0] } else { $null }

    function Require-Service {
        param([string]$name)
        $s = Get-Service $name -ErrorAction SilentlyContinue
        if (-not $s) { Write-Error "systemctl: Unit '$name' not found."; return $null }
        return $s
    }

    switch -Regex ($Action) {
        '^start$' {
            $s = Require-Service $svcName; if (-not $s) { return }
            Start-Service $svcName
            Write-Host "Started $svcName."
        }
        '^stop$' {
            $s = Require-Service $svcName; if (-not $s) { return }
            Stop-Service $svcName
            Write-Host "Stopped $svcName."
        }
        '^restart$' {
            $s = Require-Service $svcName; if (-not $s) { return }
            Restart-Service $svcName
            Write-Host "Restarted $svcName."
        }
        '^reload$' {
            $s = Require-Service $svcName; if (-not $s) { return }
            Restart-Service $svcName
            Write-Warning "reload: no reload mechanism on Windows; restarted $svcName instead."
        }
        '^status$' {
            if ($svcName) {
                $s = Require-Service $svcName; if (-not $s) { return }
                $active = if ($s.Status -eq 'Running') { 'active (running)' } else { "inactive ($($s.Status))" }
                $load   = try { (Get-Service $svcName).StartType } catch { 'unknown' }
                Write-Output "  $($s.DisplayName) ($svcName)"
                Write-Output "     Loaded: $load"
                Write-Output "     Active: $active"
            } else {
                Get-Service | Format-Table Name, Status, StartType, DisplayName -AutoSize
            }
        }
        '^enable$' {
            $s = Require-Service $svcName; if (-not $s) { return }
            Set-Service $svcName -StartupType Automatic
            Write-Host "Enabled $svcName (StartupType: Automatic)."
        }
        '^disable$' {
            $s = Require-Service $svcName; if (-not $s) { return }
            Set-Service $svcName -StartupType Disabled
            Write-Host "Disabled $svcName."
        }
        '^(list-units|list-unit-files)$' {
            Get-Service |
                Select-Object @{N='UNIT';E={$_.Name}},
                              @{N='LOAD';E={'loaded'}},
                              @{N='ACTIVE';E={if($_.Status-eq'Running'){'active'}else{'inactive'}}},
                              @{N='SUB';E={$_.Status.ToString().ToLower()}},
                              @{N='DESCRIPTION';E={$_.DisplayName}} |
                Format-Table -AutoSize
        }
        '^daemon-reload$' {
            Write-Host "daemon-reload: no-op on Windows (no systemd daemon)."
        }
        '^is-active$' {
            $s = Get-Service $svcName -ErrorAction SilentlyContinue
            Write-Output $(if ($s -and $s.Status -eq 'Running') { 'active' } else { 'inactive' })
        }
        '^is-enabled$' {
            $s = Get-Service $svcName -ErrorAction SilentlyContinue
            if (-not $s) { Write-Output 'not-found'; return }
            Write-Output $(if ($s.StartType -eq 'Automatic') { 'enabled' } else { 'disabled' })
        }
        default {
            Write-Error "systemctl: unknown operation '$Action'"
            Write-Host "Usage: systemctl start|stop|restart|status|enable|disable|is-active|is-enabled|list-units [unit]"
        }
    }
}
