# wux
Hm... Sometimes I just do not wanna deal with Powershell and stick with Linux. I like Windows, don't get me wrong... :)

**wux** is a PowerShell module that brings Linux-style commands to Windows PowerShell 5.1+. It reimplements common Unix tools as native PowerShell functions, including full pipeline support (`find ... | grep ... | wc -l`) and tab completion for flags and paths.

## Commands

| Command | Description |
|---------|-------------|
| `ls` | List directory contents with color (`-a` hidden, `-l` long, `-h` human sizes, `-r` reverse, `-t` by time, `-S` by size, `-1` one per line, `-d` dir itself, `-R` recursive) |
| `pwd` | Print the current working directory |
| `cat` | Concatenate files with `-n` (line numbers), `-b` (number non-blank), `-s` (squeeze blanks) |
| `echo` | Print text (`-e` interpret escape sequences like `\n`/`\t`, `-n` no trailing newline) |
| `less` | Paginated file/stdin viewer |
| `head` | First N lines of input (`-n`) |
| `tail` | Last N lines of input (`-n`) |
| `grep` | Search text with regex, `-i`, `-r`, `-n`, `-c`, `-v`, `-A`/`-B`/`-C` context, `--color` |
| `find` | Traverse directories with `-name`, `-type`, `-maxdepth`, `-mindepth`, `-mtime`, `-size`, `-delete`, `-exec` |
| `sed` | Stream editor — substitution (`s/old/new/flags`), deletion, `-i` in-place, `-E` extended regex |
| `awk` | Field-splitting and pattern/action processing with `BEGIN`/`END` blocks and `$1`…`$NF` |
| `sort` | Sort lines (`-r` reverse, `-u` unique, `-n` numeric, `-i` ignore case, `-k` key field, `-t` separator) |
| `uniq` | Filter duplicate adjacent lines (`-c` count, `-d` dupes only, `-u` unique only) |
| `wc` | Count lines (`-l`), words (`-w`), bytes (`-c`) |
| `diff` | Compare two files line by line (`-q` brief, `-i` ignore case) |
| `cmp` | Byte-level file comparison (`-s` silent, `-l` list all differing bytes) |
| `comm` | Compare two sorted files column by column (suppress columns with `-1`/`-2`/`-3`) |
| `tee` | Write stdin to a file and pass through (`-a` append) |
| `touch` | Create files or update timestamps (`-a`, `-m`, `-c`, `-t`, `-d`) |
| `ln` | Create hard or symbolic links (`-s` symbolic, `-f` force, `-v` verbose) |
| `cp` | Copy files/directories (`-r` recursive, `-f` force, `-n` no-clobber, `-p` preserve timestamps) |
| `mv` | Move/rename files (`-f` force, `-n` no-clobber, `-b` backup) |
| `rm` | Remove files or directories (`-r` recursive, `-f` force, `-i` interactive, `-v` verbose) |
| `mkdir` | Create directories (`-p` parents, no error if exists) |
| `chmod` | Change file permissions using octal or symbolic notation (`-R` recursive) |
| `chown` | Change file ownership via Windows ACL (`-R` recursive) |
| `tar` | Archive tool — delegates to the built-in `tar.exe` (Windows 10 build 17063+) |
| `zip` | Create zip archives (`-r` recurse, `-u` update, `-q` quiet) |
| `unzip` | Extract zip archives (`-l` list contents, `-o` overwrite, `-q` quiet) |
| `whoami` | Print current Windows user |
| `ps` | List running processes in Unix-style format |
| `kill` | Terminate a process by PID (`-Force` for hard kill) |
| `killall` | Kill all processes matching a name (`-Force`, `-u` filter by user) |
| `top` | Live process viewer, refreshes every N seconds (`-n` iterations, `-d` delay, `-p` watch PIDs) |
| `df` | Disk free space for all mounted drives (`-h` human-readable) |
| `du` | Disk usage of a directory tree (`-h`, `-s` summary, `-d` max depth) |
| `free` | Physical and virtual memory usage (`-h`, `-m`, `-g`) |
| `uptime` | System uptime and last boot time |
| `uname` | Print system information (`-a` all, `-s` kernel, `-n` hostname, `-r` release, `-v` version, `-m` arch, `-o` OS) |
| `ss` | Socket statistics — TCP/UDP connections (`-t`, `-u`, `-l`, `-a`) |
| `ifconfig` | Display network adapter info — IP, MAC, MTU, RX/TX stats |
| `traceroute` | Trace network path to a host (`-m` max hops, `-n` numeric, `-w` timeout) |
| `mount` | List mounted volumes or mount `.iso`/`.vhd`/`.vhdx` disk images |
| `wget` | Download files from a URL (`-O` output file, `-P` directory, `-q` quiet, `-c` resume) |
| `which` | Locate a command on the PATH |
| `whereis` | Locate a command binary and show its help entry |
| `whatis` | Print a one-line description of a command |
| `man` | Display full help for a command (`-k` keyword search / apropos) |
| `env` | Print or modify environment variables |
| `export` | Set environment variables (`NAME=VALUE`); `-p` prints all current exports |
| `alias` | List all aliases or define a new one (`alias ll='ls -l'`) |
| `nano` | Open a file in nano (falls back to VS Code, then Notepad) |
| `cal` | Display a calendar for the current or given month/year (`-3` shows prev/curr/next) |
| `sudo` | Run a command elevated; re-launches in a new admin PowerShell window if not already admin |
| `systemctl` | Manage Windows services with Linux-style start/stop/restart/status/enable/disable |
| `service` | Alternative service manager — `service <name> start\|stop\|restart\|status\|enable\|disable` |
| `useradd` | Create a local Windows user account (`-c` description, `-G` groups, `-p` password) |
| `usermod` | Modify a local user account (`-l` rename, `-c` description, `-G` groups, `-a` append groups) |
| `passwd` | Change a local user's password (prompts securely) |
| `apt` | Package management via `winget` — `install`, `remove`, `update`, `search`, `list`, `show` |

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

Once loaded, the built-in PowerShell aliases for `cat`, `cp`, `mv`, `ps`, `tee`, `rm`, `echo`, `diff`, `sort`, `alias`, `man`, `pwd`, `ls`, `kill`, `wget`, and `mount` are automatically redirected to the wux versions and restored when the module is removed.

## Combined short flags

Bundled Unix-style short flags work as expected, e.g. `ls -la`, `ss -tunap`, `rm -rf`. Each command resolves bundled flags against its own parameters, so only valid single-letter switches combine; anything else (file paths, values) is passed through untouched.

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
