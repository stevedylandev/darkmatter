#!/bin/bash

# Darkmatter Terminal Setup - Linux installer
# Downloads and installs terminal configuration and tools
# Supports: apt (Ubuntu/Debian), pacman (Arch), dnf (Fedora), zypper (openSUSE)

set -euo pipefail  # Exit on any error, undefined variables, and pipe failures

#==============================================================================
# CONFIGURATION
#==============================================================================

GITHUB_RAW_BASE="https://raw.githubusercontent.com/stevedylandev/darkmatter/main"
TEMP_DIR="/tmp/darkmatter_install"
DEBUG_MODE="${DEBUG:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# Enhanced error handler
error_handler() {
    local line_number="$1"
    local error_code="$2"
    local command="$BASH_COMMAND"

    print_error "Script failed at line $line_number with exit code $error_code"
    print_error "Failed command: $command"
    print_error "Current function: ${FUNCNAME[1]:-main}"

    # Show some context
    if [ -f "$0" ]; then
        print_error "Context around line $line_number:"
        sed -n "$((line_number-2)),$((line_number+2))p" "$0" | nl -ba
    fi

    cleanup
    exit $error_code
}

# Set up error trap
trap 'error_handler ${LINENO} $?' ERR

#==============================================================================
# SYSTEM DETECTION AND SETUP
#==============================================================================

# Detect Linux distribution and package manager
detect_distro() {
    print_status "Detecting Linux distribution..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        print_success "Detected distribution: $PRETTY_NAME"
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi

    # Detect package manager
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt install -y"
        PKG_UPDATE="apt update"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf check-update || true"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_UPDATE="zypper refresh"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum check-update || true"
    else
        print_error "No supported package manager found (apt, pacman, dnf, zypper, yum)"
        exit 1
    fi

    print_success "Using package manager: $PKG_MANAGER"
}

# Check if required tools are available
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_status "Installing missing dependencies: ${missing_deps[*]}"
        sudo $PKG_UPDATE
        sudo $PKG_INSTALL "${missing_deps[@]}"
    fi
    
    print_success "All dependencies are available"
}

# Create temporary directory for downloads
setup_temp_dir() {
    print_status "Setting up temporary directory..."
    print_debug "Removing existing temp dir: $TEMP_DIR"

    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" || {
            print_error "Failed to remove existing temp directory: $TEMP_DIR"
            exit 1
        }
    fi

    print_debug "Creating temp dir: $TEMP_DIR"
    mkdir -p "$TEMP_DIR" || {
        print_error "Failed to create temporary directory: $TEMP_DIR"
        exit 1
    }

    print_success "Temporary directory created: $TEMP_DIR"
    print_debug "Temp directory permissions: $(ls -ld "$TEMP_DIR")"
}

#==============================================================================
# NETWORK AND DOWNLOAD FUNCTIONS
#==============================================================================

# Test GitHub connectivity
test_github_connection() {
    print_status "Testing GitHub connectivity..."
    print_debug "Testing connection to: $GITHUB_RAW_BASE"

    # Test with a simple HEAD request
    if curl -I -f -s --connect-timeout 10 --max-time 30 "$GITHUB_RAW_BASE/.zshrc-linux" > /dev/null; then
        print_success "Successfully connected to GitHub repository"
    else
        local exit_code=$?
        print_error "Failed to connect to GitHub repository"
        print_error "URL tested: $GITHUB_RAW_BASE/.zshrc-linux"
        print_error "curl exit code: $exit_code"

        # Try to give more specific error information
        case $exit_code in
            6) print_error "Could not resolve host - check your internet connection" ;;
            7) print_error "Failed to connect to host - check the repository URL" ;;
            22) print_error "HTTP error - the file might not exist or repository might be private" ;;
            28) print_error "Timeout - check your internet connection" ;;
            *) print_error "Unknown curl error - check the repository URL and your internet connection" ;;
        esac

        exit 1
    fi
}

# Download file from GitHub with detailed error reporting
download_file() {
    local filename="$1"
    local dest="$TEMP_DIR/$filename"

    # If local file exists in current directory, use it instead of downloading
    if [ -f "$PWD/$filename" ]; then
        print_status "Copying local $filename"
        mkdir -p "$(dirname "$dest")"
        if cp "$PWD/$filename" "$dest"; then
            print_success "Copied local $filename"
            return 0
        else
            print_error "Failed to copy local $filename"
            return 1
        fi
    fi

    local url="$GITHUB_RAW_BASE/$filename"
    local dest_dir
    local curl_output

    print_status "Downloading $filename..."
    print_debug "From: $url"
    print_debug "To: $dest"

    # Create directory if needed
    dest_dir=$(dirname "$dest")
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir" || {
            print_error "Failed to create directory: $dest_dir"
            return 1
        }
    fi

    # Download with verbose error reporting
    curl_output=$(curl -L -f -s -w "HTTP_CODE:%{http_code};SIZE:%{size_download};TIME:%{time_total}" -o "$dest" "$url" 2>&1) || {
        local exit_code=$?
        print_error "Failed to download $filename"
        print_error "URL: $url"
        print_error "curl exit code: $exit_code"
        print_error "curl output: $curl_output"
        return 1
    }

    print_debug "curl response: $curl_output"

    # Verify file was downloaded and has content
    if [ ! -f "$dest" ]; then
        print_error "File was not created: $dest"
        return 1
    fi

    local file_size=$(wc -c < "$dest" 2>/dev/null || echo "0")
    if [ "$file_size" -eq 0 ]; then
        print_error "Downloaded file is empty: $filename"
        return 1
    fi

    print_success "Downloaded $filename (${file_size} bytes)"
    print_debug "File content preview:"
    if [ "$DEBUG_MODE" = "true" ]; then
        head -3 "$dest" || true
    fi

    return 0
}

# Download all configuration files
download_configs() {
    print_status "Downloading configuration files from GitHub..."

    local files=(
        ".zshrc-linux"
        "dark.tmTheme"
    )

    local success_count=0
    local total_files=${#files[@]}

    print_debug "Starting download loop for ${total_files} files"

    for file in "${files[@]}"; do
        print_debug "=== Processing file $((success_count + 1))/$total_files: $file ==="

        # Disable error exit temporarily for this specific operation
        set +e
        download_file "$file"
        local download_result=$?
        set -e

        print_debug "Download result for $file: $download_result"

        if [ $download_result -eq 0 ]; then
            success_count=$((success_count + 1))
            print_success "Successfully downloaded: $file (count: $success_count)"
        else
            print_error "Failed to download $file (exit code: $download_result)"
            print_error "This will cause installation issues"
            # Continue with other files to see what we can get
        fi

        print_debug "Completed processing $file, moving to next file"
    done

    print_debug "Download loop completed"
    print_status "Downloaded $success_count/$total_files configuration files"

    if [ $success_count -eq $total_files ]; then
        print_success "All configuration files downloaded successfully"
    else
        print_error "Failed to download some configuration files ($success_count/$total_files succeeded)"
        print_error "Installation cannot continue without all config files"

        # Show what files we do have
        print_status "Files in temp directory:"
        ls -la "$TEMP_DIR" || true

        exit 1
    fi
}

#==============================================================================
# PACKAGE INSTALLATION
#==============================================================================

# Install or ensure Homebrew is available
ensure_homebrew() {
    if ! command -v brew &>/dev/null; then
        print_status "Homebrew not found; installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Initialize Homebrew environment
        if command -v brew &>/dev/null; then
            eval "$(brew shellenv)"
        else
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed and configured"
    else
        print_success "Homebrew is already available"
    fi
}

# Install packages via Homebrew exclusively
install_packages() {
    print_status "Installing packages via Homebrew..."
    
    ensure_homebrew
    
    local brew_pkgs=(
        "zsh"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "starship"
        "eza"
        "zoxide"
        "aichat"
        "btop"
        "fzf"
    )
    
    local failed_packages=()
    
    for pkg in "${brew_pkgs[@]}"; do
        print_status "Installing $pkg via Homebrew..."
        if brew list "$pkg" &>/dev/null; then
            print_warning "$pkg already installed"
        else
            if brew install "$pkg"; then
                print_success "Successfully installed $pkg"
            else
                print_warning "Failed to install $pkg via Homebrew"
                failed_packages+=("$pkg")
            fi
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_warning "Failed to install: ${failed_packages[*]}"
        print_warning "You may need to install these manually"
    else
        print_success "All packages installed successfully"
    fi
}

#==============================================================================
# FONT INSTALLATION
#==============================================================================

# Download and install CommitMono Nerd Font
download_and_install_font() {
    print_status "Downloading CommitMono Nerd Font..."

    local font_files=(
        "CommitMonoNerdFont-Regular.otf"
        "CommitMonoNerdFont-Bold.otf"
        "CommitMonoNerdFont-Italic.otf"
        "CommitMonoNerdFont-BoldItalic.otf"
    )

    # Create fonts directory
    local user_fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$user_fonts_dir"

    local installed_count=0

    for font_file in "${font_files[@]}"; do
        # Check if local font file exists
        if [ -f "$PWD/assets/$font_file" ]; then
            print_status "Using local font file: $font_file"
            local dest_file="$user_fonts_dir/$font_file"
            
            if [ -f "$dest_file" ]; then
                print_warning "Font $font_file already installed, skipping"
            else
                if cp "$PWD/assets/$font_file" "$dest_file"; then
                    print_success "Installed font: $font_file"
                    ((installed_count++))
                else
                    print_warning "Failed to install font: $font_file"
                fi
            fi
            continue
        fi

        # Download font from GitHub
        local font_url="$GITHUB_RAW_BASE/assets/$font_file"
        local font_dest="$TEMP_DIR/$font_file"

        print_status "Downloading $font_file..."
        
        if curl -L -f -s -o "$font_dest" "$font_url" 2>/dev/null; then
            local file_size=$(wc -c < "$font_dest" 2>/dev/null || echo "0")
            
            if [ "$file_size" -gt 10000 ]; then
                # Install the font
                local dest_file="$user_fonts_dir/$font_file"
                
                if [ -f "$dest_file" ]; then
                    print_warning "Font $font_file already installed, skipping"
                else
                    if cp "$font_dest" "$dest_file"; then
                        print_success "Installed font: $font_file"
                        ((installed_count++))
                    else
                        print_warning "Failed to install font: $font_file"
                    fi
                fi
            else
                print_warning "Font file $font_file seems too small, might be an error"
            fi
        else
            print_warning "Failed to download font: $font_file"
        fi
    done

    if [ $installed_count -gt 0 ]; then
        # Refresh font cache
        print_status "Refreshing font cache..."
        if command -v fc-cache &> /dev/null; then
            fc-cache -fv "$user_fonts_dir" &> /dev/null
            print_success "Font cache refreshed"
        fi
        print_success "Installed $installed_count font files"
    else
        print_warning "No fonts were installed"
    fi
}

#==============================================================================
# CONFIGURATION MANAGEMENT
#==============================================================================

# Backup existing config files
backup_configs() {
    print_status "Backing up existing configuration files..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.config_backup_$timestamp"

    print_debug "Backup directory: $backup_dir"

    mkdir -p "$backup_dir" || {
        print_error "Failed to create backup directory: $backup_dir"
        exit 1
    }

    local backed_up=false

    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$backup_dir/" && {
            print_success "Backed up .zshrc to $backup_dir"
            backed_up=true
        } || print_warning "Failed to backup .zshrc"
    fi

    if [ -f "$HOME/.config/aichat/dark.tmTheme" ]; then
        mkdir -p "$backup_dir/.config/aichat"
        cp "$HOME/.config/aichat/dark.tmTheme" "$backup_dir/.config/aichat/" && {
            print_success "Backed up aichat theme to $backup_dir"
            backed_up=true
        } || print_warning "Failed to backup aichat theme"
    fi

    if [ "$backed_up" = false ]; then
        print_status "No existing configuration files to backup"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Check if Darkmatter configuration exists in zshrc
check_darkmatter_in_zshrc() {
    local zshrc_file="$1"

    if [ ! -f "$zshrc_file" ]; then
        return 1  # File doesn't exist
    fi

    # Look for our marker comment
    if grep -q "# Darkmatter Terminal Configuration" "$zshrc_file" 2>/dev/null; then
        return 0  # Already present
    else
        return 1  # Not present
    fi
}

# SHELL CONFIGURATION HELPERS (zshrc management)
DARKMATTER_START="# >>> DARKMATTER START >>>"
DARKMATTER_END="# <<< DARKMATTER END <<<"
BREW_SHELLENV_MARKER="# --- Darkmatter: Homebrew shellenv ---"

# Ensure the Homebrew shellenv line is present near the top of ~/.zshrc
ensure_brew_shellenv() {
    local zshrc_file="$HOME/.zshrc"
    local brew_path="/home/linuxbrew/.linuxbrew/bin/brew"

    # Bail if brew isn't installed yet (should not happen here)
    if ! command -v brew &>/dev/null; then
        return 0
    fi

    # If the marker already exists, do nothing
    if grep -q "$BREW_SHELLENV_MARKER" "$zshrc_file" 2>/dev/null; then
        return 0
    fi

    print_status "Inserting Homebrew shellenv into .zshrc"
    local shellenv_line="if [ -x $brew_path ]; then\n  eval \"$($brew_path shellenv)\"\nfi"

    # Prepend the lines to the file
    {
        echo "$BREW_SHELLENV_MARKER"
        echo "$shellenv_line"
        echo
        cat "$zshrc_file"
    } > "${zshrc_file}.tmp" && mv "${zshrc_file}.tmp" "$zshrc_file"
}

# Remove any existing Darkmatter block from ~/.zshrc
remove_old_darkmatter_block() {
    local zshrc_file="$HOME/.zshrc"
    if [ ! -f "$zshrc_file" ]; then
        return 0
    fi

    local modified=false

    # Remove new-style marker block
    if grep -q "$DARKMATTER_START" "$zshrc_file"; then
        print_status "Removing previous Darkmatter block (marker) from .zshrc"
        awk "/$DARKMATTER_START/{flag=1;next}/$DARKMATTER_END/{flag=0;next}!flag" "$zshrc_file" > "${zshrc_file}.tmp" && mv "${zshrc_file}.tmp" "$zshrc_file"
        modified=true
    fi

    # Remove legacy header block if present
    if grep -q "# Darkmatter Terminal Configuration" "$zshrc_file"; then
        print_status "Removing legacy Darkmatter block from .zshrc"
        awk '/# Darkmatter Terminal Configuration/{flag=1;next}flag && /^# =============================================/{flag=0;next}!flag' "$zshrc_file" > "${zshrc_file}.tmp" && mv "${zshrc_file}.tmp" "$zshrc_file"
        modified=true
    fi

    if [ "$modified" = true ]; then
        print_success "Old Darkmatter configuration removed"
    fi
}

# Copy downloaded configuration files to their destinations
install_configs() {
    print_status "Installing configuration files..."

    local install_errors=0
    local zshrc_file="$HOME/.zshrc"

    # Prepare zshrc
    if [ -f "$TEMP_DIR/.zshrc-linux" ]; then
        if [ -f "$zshrc_file" ]; then
            print_status "Existing .zshrc found – refreshing Darkmatter configuration"
            # Ensure brew shellenv loader exists
            ensure_brew_shellenv
            # Remove previous block if present
            remove_old_darkmatter_block
            # Append new block wrapped with markers
            {
                echo "$DARKMATTER_START"
                cat "$TEMP_DIR/.zshrc-linux"
                echo "$DARKMATTER_END"
                echo
            } >> "$zshrc_file" && {
                print_success "Darkmatter configuration updated in .zshrc"
            } || {
                print_error "Failed to update .zshrc"
                ((install_errors++))
            }
        else
            print_status "No existing .zshrc found – creating fresh one"
            # Compose fresh file: brew shellenv + block
            {
                echo "$BREW_SHELLENV_MARKER"
                echo "if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then"
                echo "  eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
                echo "fi"
                echo
                echo "$DARKMATTER_START"
                cat "$TEMP_DIR/.zshrc-linux"
                echo "$DARKMATTER_END"
            } > "$zshrc_file" && {
                print_success "Installed new .zshrc"
            } || {
                print_error "Failed to create .zshrc"
                ((install_errors++))
            }
        fi
    else
        print_error ".zshrc-linux not found in downloaded files: $TEMP_DIR/.zshrc-linux"
        ((install_errors++))
    fi

    # Install aichat theme (Linux path)
    if [ -f "$TEMP_DIR/dark.tmTheme" ]; then
        print_debug "Installing aichat theme to $HOME/.config/aichat/"
        mkdir -p "$HOME/.config/aichat"

        if [ -f "$HOME/.config/aichat/dark.tmTheme" ]; then
            print_status "Existing aichat theme found, it will be replaced"
        fi

        if cp "$TEMP_DIR/dark.tmTheme" "$HOME/.config/aichat/"; then
            print_success "Installed aichat theme"
        else
            print_error "Failed to install aichat theme"
            ((install_errors++))
        fi
    else
        print_error "aichat theme not found in downloaded files: $TEMP_DIR/dark.tmTheme"
        ((install_errors++))
    fi

    if [ $install_errors -gt 0 ]; then
        print_error "$install_errors configuration files failed to install"
        exit 1
    fi
}

#==============================================================================
# SHELL CONFIGURATION
#==============================================================================

# Set zsh as default shell
set_default_shell() {
    print_status "Checking default shell..."

    local current_shell="${SHELL}"
    local zsh_path
    zsh_path=$(which zsh) || {
        print_error "zsh not found in PATH"
        exit 1
    }

    print_debug "Current shell: $current_shell"
    print_debug "zsh path: $zsh_path"

    if [ "$current_shell" != "$zsh_path" ]; then
        print_status "Setting zsh as default shell..."

        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            print_debug "Adding $zsh_path to /etc/shells"
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null || {
                print_error "Failed to add zsh to /etc/shells"
                exit 1
            }
        fi

        # Change default shell
        print_debug "Changing default shell to $zsh_path"
        if chsh -s "$zsh_path"; then
            print_success "Default shell set to zsh"
            print_warning "Please restart your terminal or run 'exec zsh' to use the new shell"
        else
            print_error "Failed to change default shell"
            exit 1
        fi
    else
        print_success "zsh is already the default shell"
    fi
}

#==============================================================================
# CLEANUP AND DEBUGGING
#==============================================================================

# Cleanup temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_debug "Cleaning up temporary files from: $TEMP_DIR"
        rm -rf "$TEMP_DIR" || print_warning "Failed to clean up temporary directory"
        print_success "Cleanup complete"
    fi
}

# Show debug information
show_debug_info() {
    if [ "$DEBUG_MODE" = "true" ]; then
        print_debug "=== Debug Information ==="
        print_debug "Script: $0"
        print_debug "Working directory: $(pwd)"
        print_debug "User: $USER"
        print_debug "Home: $HOME"
        print_debug "Shell: $SHELL"
        print_debug "PATH: $PATH"
        print_debug "Distribution: $DISTRO"
        print_debug "Package Manager: $PKG_MANAGER"
        print_debug "GitHub base URL: $GITHUB_RAW_BASE"
        print_debug "Temp directory: $TEMP_DIR"
        print_debug "========================="
    fi
}

#==============================================================================
# MAIN FUNCTION
#==============================================================================

# Main installation function
main() {
    echo "🌑 Darkmatter Setup Installer for Linux"
    echo "========================================"
    echo

    # Enable debug mode if requested
    if [ "${1:-}" = "--debug" ] || [ "${1:-}" = "-d" ]; then
        DEBUG_MODE="true"
        print_status "Debug mode enabled"
    fi

    # Only test GitHub connectivity if local files are not present
    if [ ! -f "$PWD/.zshrc-linux" ]; then
        test_github_connection
    else
        print_status "Local config detected, skipping GitHub connectivity test"
    fi

    print_status "Starting installation process..."

    # System setup
    detect_distro
    show_debug_info
    check_dependencies
    setup_temp_dir

    # Package and font installation
    install_packages
    download_configs
    download_and_install_font

    # Configuration
    backup_configs
    install_configs
    set_default_shell
    
    # Cleanup
    cleanup

    echo
    print_success "Installation complete! 🌌"
    echo
    print_status "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Configure aichat by running: aichat"
    echo "  3. Enjoy your Darkmatter terminal experience!"
    echo
    print_status "Note: Some applications may need to be restarted to see the new font"
}

# Handle script interruption
trap cleanup EXIT

# Run main function with all arguments
main "$@"
