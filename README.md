# wux
Hm... Sometimes I just do not wanna deal with Powershell and stick with Linux. I like Windows, don't get me wrong... :)

**wux** is a PowerShell module that brings Linux-style commands to Windows PowerShell 5.1+. It reimplements common Unix tools as native PowerShell functions, including full pipeline support (`find ... | grep ... | wc -l`) and tab completion for flags and paths.

## Commands

| Command | Description |
|---------|-------------|
| `grep` | Search text with regex, `-i`, `-r`, `-n`, `-c`, `-v`, `-A`/`-B`/`-C` context, `--color` |
| `find` | Traverse directories with `-name`, `-type`, `-maxdepth`, `-mindepth`, `-mtime`, `-size`, `-delete`, `-exec` |
| `sed` | Stream editor — substitution (`s/old/new/flags`), deletion, `-i` in-place, `-E` extended regex |
| `awk` | Field-splitting and pattern/action processing with `BEGIN`/`END` blocks and `$1`…`$NF` |
| `head` | First N lines of input (`-n`) |
| `tail` | Last N lines of input (`-n`) |
| `cat` | Concatenate files with `-n` (line numbers), `-b` (number non-blank), `-s` (squeeze blanks) |
| `wc` | Count lines (`-l`), words (`-w`), bytes (`-c`) |
| `tee` | Write stdin to a file and pass through (`-a` append) |
| `uniq` | Filter duplicate adjacent lines (`-c` count, `-d` dupes only, `-u` unique only) |
| `touch` | Create files or update timestamps (`-a`, `-m`, `-c`, `-t`, `-d`) |
| `chmod` | Change file permissions using octal or symbolic notation (`-R` recursive) |
| `cp` | Copy files/directories (`-r` recursive, `-f` force, `-n` no-clobber, `-p` preserve timestamps) |
| `mv` | Move/rename files (`-f` force, `-n` no-clobber, `-b` backup) |
| `mkdir` | Create directories (`-p` parents, no error if exists) |
| `chown` | Change file ownership via Windows ACL (`-R` recursive) |
| `whoami` | Print current Windows user |
| `ps` | List running processes in Unix-style format |
| `kill` | Terminate a process by PID (`-Force` for hard kill) |
| `df` | Disk free space for all mounted drives (`-h` human-readable) |
| `du` | Disk usage of a directory tree (`-h`, `-s` summary, `-d` max depth) |
| `free` | Physical and virtual memory usage (`-h`, `-m`, `-g`) |
| `uptime` | System uptime and last boot time |
| `ss` | Socket statistics — TCP/UDP connections (`-t`, `-u`, `-l`, `-a`) |
| `which` | Locate a command on the PATH |
| `env` | Print or modify environment variables |
| `nano` | Open a file in nano (falls back to VS Code, then Notepad) |
| `systemctl` | Manage Windows services with Linux-style start/stop/status/enable/disable |

## Usage

```powershell
# Load the module
Import-Module C:\path\to\wux\wux.psd1

# Or add to your PowerShell profile for permanent access
# Add this line to $PROFILE:
Import-Module C:\path\to\wux\wux.psd1

# Unload
Remove-Module wux
```

Once loaded, the built-in PowerShell aliases for `cat`, `cp`, `mv`, `ps`, and `tee` are automatically redirected to the wux versions and restored when the module is removed.

## Pipeline support

All commands that read from stdin support PowerShell pipelines:

```powershell
find . -name "*.log" | grep "ERROR" | wc -l
cat access.log | grep -i "404" | tail -n 20
ps | grep chrome | awk '{print $1}'
find . -name "*.txt" | head -n 5 | cat -n
```

## Tab completion

All commands have tab completion for flags and file paths. Press `Tab` after a command name or partial flag to see suggestions.
