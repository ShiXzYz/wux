@{
    ModuleVersion     = '1.0.0'
    GUID              = 'a3f2d1e0-4b5c-6d7e-8f9a-0b1c2d3e4f50'
    Author            = 'ShiXzYz'
    Description       = 'Linux-style commands for PowerShell: grep, awk, sed, head, tail, find, touch, chmod, nano, ss, systemctl, df, du, ps, kill, which, wc, tee, free, uptime, uniq, env, cat, whoami, cp, mv, mkdir, chown'
    PowerShellVersion = '5.1'
    RootModule        = 'wux.psm1'
    FunctionsToExport = @('grep','head','tail','sed','awk','find','touch','chmod',
                          'nano','ss','systemctl','df','du','ps','kill','which',
                          'wc','tee','free','uptime','uniq','env',
                          'cat','whoami','cp','mv','mkdir','chown')
    PrivateData = @{
        PSData = @{
            Tags       = @('Linux','Unix','compat','grep','awk','sed','tools')
            ProjectUri = 'https://github.com/ShiXzYz/wux'
        }
    }
}
