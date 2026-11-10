# kitty-dev-harness 🚀

A zero-bloat, language-agnostic development workspace orchestrator for [Kitty](https://sw.kovidgoyal.net/kitty/). 

Spins up a complete, tabbed terminal IDE environment in milliseconds—complete with an **adaptive SHA-256 file watcher**, **live syntax-highlighted log stream**, and your favorite terminal editor.

---

## Features

* **Instant Multi-Tab Orchestration:** One command launches your Shell, Auto-Compiler, Live Log Viewer, and Editor into organized, named Kitty tabs.
* **Adaptive SHA-256 File Watching:** Watches source trees for changes using cryptographically accurate checksums.
  * Currently is hardcoded to scan for ./src/ ./Source/ and ./Resource
  * Automatically backs off from 2s to 5s when idle to save CPU cycles.
  * Avoids `inotify` buffer overflow, pipe deadlocks, and false triggers caused by atomic swap-file writes in Neovim/VS Code.
  * Plus my Compile Script needed gum to work so I had to manually concoc this mess
* **Live Cool Logs:** Used With bat, it automatically clears the screen on Log Tab whenever changes occur without locking file descriptors.
* **Editor & Language Agnostic:** Works with **Neovim, Helix, Vim, Micro, or Nano**, and any language that can run a build script (`dotnet`, `cargo`, `make`, `gcc`, `zig`, `go`).
* **Defensive Shell Design:** Full POSIX flag parsing (`-r`, `-c`, `-l`, `-e`, `-n`), executable bit validation (`-x`), path checks, and clean exit codes.

---

## Workspace Layout

When launched, your Kitty window is organized into 4 dedicated tabs:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │ 
│                                                                          │
│                                $EDITOR .                                 │
│                        (Neovim / Helix / etc.)                           │
│                                                                          │  
├──────────────────────────────────────────────────────────────────────────┤
│ [Project | Editor] [Project | TERM] [Project | Compiler] [Project | Log] │
└──────────────────────────────────────────────────────────────────────────┘
```

* **Editor Tab:** Automatically sets the Kitty window title and opens your editor inside the project root.
* **Compiler Tab:** Runs `Watch_Build.sh`—watches `src/`, `Source/`, and `Resources/`, triggering your compile script upon file change.
* **Log Tab:** Runs `Watch_Log.sh`—tails your log file and displays updates cleanly using `bat`.
* **Terminal Tab:** A clean shell ready for ad-hoc commands, Git, or running tests.

---

## Prerequisites

Ensure you have the following installed on your system:

* **Kitty Terminal**
* **bat** (for syntax-highlighted log streaming):
  ```bash
  # Arch / EndeavourOS
  sudo pacman -S bat
  # Ubuntu / Debian
  sudo apt install bat
  # Fedora
  sudo dnf install bat
  ```
* **Coreutils** (`sha256sum`, `find`, `sort`, `cut` — standard on all Linux distros)

* **NOTE** CompileScript provided requires GUM as MY compile script uses it, youre a big boy now, you can edit it out.

> [!NOTE]  
> Kitty must allow remote control. Ensure this line is present in `~/.config/kitty/kitty.conf`:  
> ```conf
> allow_remote_control yes
> ```

---

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Jussstrollin/Kitty-Dev-Env.git
   cd Kitty-Dev-Env
   ```

2. ** READ THE SOURCE FILE, you should learn to read for malicious things. **

3. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

4. *(Optional)* Add to your `$PATH` or create a convenient alias:
   ```bash
   ln -s "$(pwd)/Dev_DWT.sh" ~/.local/bin/dev-harness
   ```

---

## Usage

```bash
./Dev_DWT.sh -r <PROJECT_ROOT> -c <COMPILE_SCRIPT> -l <LOG_FILE> -e <EDITOR> [-n <NAME>]
```

### Options

| Flag | Argument | Description | Required? |
| :--- | :--- | :--- | :---: |
| `-r`, `--Root` | `/path/to/project` | Absolute path to your project root | **Yes** |
| `-c`, `--CompileScript` | `/path/to/build.sh` | Absolute path to your executable compile script | **Yes** |
| `-l`, `--LogFile` | `/path/to/Latest.log`| Absolute path to your application's output log | **Yes** |
| `-e`, `--Editor` | `nvim` / `hx` / `vim` | Terminal editor command (must be in `$PATH`) | **Yes** |
| `-n`, `--Name` | `"MyProject"` | Custom prefix for Kitty tab titles (Default: `Project`) | No |
| `-h`, `--help` | — | Display the help menu and exit | No |

---

### Example

How i Use mine (its shoved in an alias in zsh):

```bash
./Dev_DWT.sh \
  -r /home/user/Projects/DefenseWithTowers \
  -c /home/user/Projects/DefenseWithTowers/Compile.sh \
  -l /home/user/Projects/DefenseWithTowers/Latest.log \
  -e nvim \
  -n "DWT"
```

---

## How It Works (Behind the Scenes)

```mermaid
flowchart TD
    Launch["./Dev_DWT.sh"] --> Check{"Validate Paths & Executable Bits"}
    Check -->|Valid| Tabs["Kitty IPC: Spawn 3 Background Tabs"]
    
    Tabs --> T1["Tab 1: Interactive Shell"]
    Tabs --> T2["Tab 2: Watch_Build.sh"]
    Tabs --> T3["Tab 3: Watch_Log.sh"]
    
    Launch --> Ed["Tab 0: Open $EDITOR in Root"]
    
    subgraph Watch_Build Loop
        T2 --> HashB["Calculate Source SHA-256"]
        HashB --> CompB{"Hash Changed?"}
        CompB -->|Yes| RunBuild["Execute CompileScript & Reset to 2s"]
        CompB -->|No| BackoffB["Adaptive Backoff (up to 5s)"]
    end

    subgraph Watch_Log Loop
        T3 --> HashL["Calculate Log SHA-256"]
        HashL --> CompL{"Log Changed?"}
        CompL -->|Yes| PrintLog["bat --pager=none LogFile"]
        CompL -->|No| BackoffL["Sleep & Poll"]
    end
```

---

## License

This project is open-source and available under the [MIT License](LICENSE).
