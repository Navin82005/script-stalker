# CLI Tools: ftree & flutter-cleanup

Both installers are **dynamic**: they scan the `scripts/` folder, and install
every file that starts with a Bash shebang (`#!/bin/bash` or `#!/usr/bin/env bash`)
as a command, named after the file itself. Non-Bash files (like this README)
are skipped automatically. Drop a new Bash script into `scripts/` and re-run
the installer to pick it up — no editing the installer required.

## Folder contents

```
cli-tools/
├── scripts/
│   ├── ftree              # the actual tree-printing script
│   └── flutter-cleanup    # the actual Flutter cleanup script
├── install-macos-linux.sh
├── install-windows.ps1
└── README.md
```

## macOS / Linux

```bash
cd cli-tools
chmod +x install-macos-linux.sh
./install-macos-linux.sh
```

This installs both tools to `~/.local/bin` (override with `INSTALL_DIR=/usr/local/bin ./install-macos-linux.sh`,
which may need `sudo` to write to `install-macos-linux.sh`'s target). It also offers to add that
folder to your PATH automatically. Open a new terminal, then:

```bash
ftree .
flutter-cleanup ~/Projects
```

## Windows

These are Bash scripts, so Windows needs a Bash interpreter — either **Git for Windows**
(recommended: https://git-scm.com/download/win) or **WSL** (`wsl --install`). The installer
auto-detects whichever you have.

1. Right-click `install-windows.ps1` → **Run with PowerShell**
   (or in PowerShell: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` then `.\install-windows.ps1`)
2. It copies the scripts and creates `ftree.cmd` / `flutter-cleanup.cmd` shims in `%USERPROFILE%\bin`,
   and adds that folder to your user PATH.
3. Open a **new** terminal (cmd, PowerShell, or Windows Terminal), then:

```
ftree .
flutter-cleanup C:\Projects
```

## Notes

- `flutter-cleanup` is destructive (it deletes build artifacts) — it always asks for
  confirmation before touching anything.
- Re-running either installer overwrites the previously installed copies, so pulling
  updated scripts into this folder and re-running the installer is how you upgrade.
