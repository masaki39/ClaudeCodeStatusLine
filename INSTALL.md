# Installation

This document is the authoritative install guide. It is written to be executed step-by-step by Claude Code when a user asks to install or update this status line.

## 1. Detect the operating system

- **macOS or Linux** → use `statusline.sh`
- **Windows** (PowerShell, CMD, Git Bash, or WSL) → use `statusline.ps1`

## 2. Clone the repo

Clone to `~/.claude/statusline/` on Unix, or `%USERPROFILE%\.claude\statusline\` on Windows. If that directory already exists and is a git clone of this repo, run `git pull` in it instead of re-cloning.

**macOS / Linux**

```bash
git clone https://github.com/daniel3303/ClaudeCodeStatusLine ~/.claude/statusline
chmod +x ~/.claude/statusline/statusline.sh
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/daniel3303/ClaudeCodeStatusLine "$env:USERPROFILE\.claude\statusline"
```

## 3. Configure `settings.json`

Add (or update) the `statusLine` key in `~/.claude/settings.json` (Unix) or `%USERPROFILE%\.claude\settings.json` (Windows). If the file already contains other keys, merge — do not overwrite.

**macOS / Linux**

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline/statusline.sh"
  }
}
```

**Windows (PowerShell / CMD)**

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\statusline\\statusline.ps1\""
  }
}
```

**Windows (Git Bash / WSL bash shells)**

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File \"$USERPROFILE\\.claude\\statusline\\statusline.ps1\""
  }
}
```

> `%VAR%` expands only in CMD/PowerShell; `$VAR` expands only in bash shells. Pick the one that matches the shell Claude Code launches the command in.

## 4. Restart Claude Code

The status line is loaded at startup. After saving `settings.json`, tell the user to restart Claude Code (or start a new session) for the change to take effect.

## Updating

Pull the latest release:

```bash
git -C ~/.claude/statusline pull
```

No `settings.json` changes are needed — the command path is stable across versions.

## Uninstalling

1. Remove the `statusLine` block from `settings.json`.
2. Delete the clone: `rm -rf ~/.claude/statusline` (or the Windows equivalent).

## Requirements

- Claude Code (Pro/Max subscription for rate-limit and extra-usage display)
- `git` in `PATH`
- macOS / Linux: `jq` and `curl`
- Windows: PowerShell 5.1+ (default on Windows 10/11)

If `jq` is missing on macOS/Linux, install it with the system package manager (`brew install jq`, `apt install jq`, etc.).
