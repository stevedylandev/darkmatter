# DARKMATTER Linux Installation

This document provides detailed information about the Linux installation script for DARKMATTER.

## Quick Installation

```bash
curl -sSL https://raw.githubusercontent.com/stevedylandev/darkmatter/main/install-linux.sh | bash
```

## Supported Distributions

The Linux installer supports the following distributions and package managers:

- **Ubuntu/Debian** - Uses `apt` package manager
- **Arch Linux** - Uses `pacman` package manager
- **Fedora** - Uses `dnf` package manager  
- **CentOS/RHEL** - Uses `yum` package manager
- **openSUSE** - Uses `zypper` package manager

## What Gets Installed

### Core Packages (via Homebrew)
The script uses Homebrew for consistent package management across distributions **and purposely does not attempt to install a terminal emulator**.

> **Note:** Ghostty is *not* installed automatically on Linux. If you wish to use it, follow the upstream installation instructions (package manager, Snap, or source build).

Installed packages:

- `zsh` - Z shell
- `zsh-autosuggestions` - Command autosuggestions
- `zsh-syntax-highlighting` - Syntax highlighting
- `starship` - Cross-shell prompt
- `eza` - Modern `ls` replacement
- `zoxide` - Smart `cd` replacement
- `aichat` - AI chat tool
- `btop` - System monitor
- `fzf` - Fuzzy finder

### System Dependencies
Automatically installed if missing:
- `curl` - HTTP client
- `git` - Version control
- `unzip` - Archive utility

### Fonts
- **CommitMono Nerd Font** - Downloaded to `~/.local/share/fonts`
  - Regular, Bold, Italic, and Bold Italic variants

## Configuration Files

The installer downloads and installs:

- `.zshrc-linux` → `~/.zshrc` (appended if existing)
- `dark.tmTheme` → `~/.config/aichat/dark.tmTheme`

## Script Structure

The improved script is organized into logical sections:

### System Detection and Setup
- **`detect_distro()`** - Identifies Linux distribution and package manager
- **`check_dependencies()`** - Ensures required tools are available
- **`setup_temp_dir()`** - Creates temporary workspace

### Network and Download Functions
- **`test_github_connection()`** - Verifies repository accessibility
- **`download_file()`** - Robust file downloading with error handling
- **`download_configs()`** - Downloads all configuration files

### Package Installation
- **`ensure_homebrew()`** - Installs Homebrew if not present
- **`install_packages()`** - Installs all packages via Homebrew

### Font Installation
- **`download_and_install_font()`** - Handles font installation with local fallback

### Configuration Management
- **`backup_configs()`** - Creates timestamped backups
- **`ensure_brew_shellenv()`** - Prepends Linuxbrew Homebrew environment loader to `~/.zshrc` if missing
- **`remove_old_darkmatter_block()`** - Deletes previous Darkmatter blocks (legacy or marker based) to avoid duplication
- **`install_configs()`** - Writes a single, wrapped Darkmatter block using markers:
  ```zsh
  # >>> DARKMATTER START >>>
  # … Darkmatter zsh config …
  # <<< DARKMATTER END <<<
  ```

### Shell Configuration
- **`set_default_shell()`** - Sets zsh as default shell

### Cleanup and Debugging
- **`cleanup()`** - Removes temporary files
- **`show_debug_info()`** - Provides diagnostic information

## Key Features

### Error Handling
- Comprehensive error trapping with context
- Detailed error reporting with line numbers
- Graceful failure handling for non-critical components

### Smart Configuration
- Detects existing Darkmatter installations
- Appends to existing `.zshrc` without duplication
- Creates timestamped backups of existing configs

### Local File Support
- Uses local files if available (for offline installation)
- Falls back to GitHub downloads automatically
- Supports development/testing scenarios

### Debug Mode
Run with debug mode for detailed logging:
```bash
bash install-linux.sh --debug
```

## Homebrew on Linux

The script exclusively uses Homebrew for package management because:

- **Consistency** - Same packages across all distributions
- **Up-to-date** - Latest versions of tools
- **Reliability** - Proven package management
- **Isolation** - Doesn't interfere with system packages

Homebrew is automatically installed if not present.

## File Locations

### Installed Files
- **Shell config**: `~/.zshrc` (appended or created)
- **AI chat theme**: `~/.config/aichat/dark.tmTheme`
- **Fonts**: `~/.local/share/fonts/CommitMonoNerdFont-*.otf`

### Backup Location
- **Backup directory**: `~/.config_backup_YYYYMMDD_HHMMSS/`
- Contains any existing configuration files before modification

### Temporary Files
- **Working directory**: `/tmp/darkmatter_install/`
- Automatically cleaned up on completion or error

## Troubleshooting

### Missing Packages
The script will:
- Continue installation if optional packages fail
- Provide warnings for missing components
- Use Homebrew to ensure consistent package availability

### Permission Issues
The script requires `sudo` for:
- Installing system dependencies (curl, git, unzip)
- Adding zsh to `/etc/shells`
- Changing default shell

### Network Issues
- Script tests GitHub connectivity before proceeding
- Provides specific error messages for connection failures
- Uses local files when available (offline mode)

### Homebrew Installation
If Homebrew installation fails:
1. Check internet connectivity
2. Ensure sufficient disk space
3. Verify system requirements
4. Run with `--debug` for detailed logs

## Manual Installation

If the automated script fails, you can install components manually:

1. **Install Homebrew**:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install packages**:
   ```bash
   brew install zsh zsh-autosuggestions zsh-syntax-highlighting starship eza zoxide aichat btop fzf
   ```

3. **Download configs**:
   ```bash
   curl -O https://raw.githubusercontent.com/stevedylandev/darkmatter/main/.zshrc-linux
   curl -O https://raw.githubusercontent.com/stevedylandev/darkmatter/main/dark.tmTheme
   ```

4. **Install configs**:
   ```bash
   cp .zshrc-linux ~/.zshrc
   mkdir -p ~/.config/aichat && cp dark.tmTheme ~/.config/aichat/
   ```

## Post-Installation

After installation:
1. **Restart terminal** or run `exec zsh`
2. **Configure aichat**: Run `aichat` for initial setup
3. **Verify installation**: Check that all tools are working
4. **Font verification**: Fonts should be available system-wide after cache refresh

## Uninstallation

To remove Darkmatter configuration:

1. **Restore from backup**:
   ```bash
   # Find your backup directory
   ls ~/.config_backup_*/
   
   # Restore .zshrc
   cp ~/.config_backup_YYYYMMDD_HHMMSS/.zshrc ~/.zshrc
   ```

2. **Remove added configs**:
   ```bash
   rm ~/.config/aichat/dark.tmTheme
   rm ~/.local/share/fonts/CommitMonoNerdFont-*.otf
   fc-cache -fv  # Refresh font cache
   ```

3. **Optional - Remove Homebrew packages** (if not needed):
   ```bash
   brew uninstall zsh-autosuggestions zsh-syntax-highlighting starship eza zoxide aichat btop fzf
   ```

## How ~/.zshrc is Handled

1. **Brew loader first** – If `eval "$($(brew --prefix) shellenv)"` (Linuxbrew path) isn't in your file, the script prepends it under a comment marker `# --- Darkmatter: Homebrew shellenv ---`.
2. **Old blocks removed** – Any earlier Darkmatter sections (both legacy headers and new-style markers) are stripped out automatically.
3. **One clean block** – A fresh Darkmatter block is appended, wrapped in the new markers shown above. Edit inside these markers if you wish, or rerun the installer to have it replaced cleanly.

This guarantees there's never more than one Darkmatter configuration and that `brew`, `zoxide`, `starship`, and plugin paths are always available when the shell starts.
