#!/bin/bash

# Darkmatter Terminal Setup - Remote configuration installer
# Downloads and installs terminal configuration from GitHub
# Requires: Homebrew (https://brew.sh)

set -euo pipefail  # Exit on any error, undefined variables, and pipe failures

# Configuration - Update these URLs to match your GitHub repo
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

# Check if required tools are available
check_dependencies() {
    print_status "Checking dependencies..."
    print_debug "Checking for brew command..."

    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed. Please install it first:"
        print_error "https://brew.sh"
        exit 1
    fi
    print_success "Homebrew found at: $(which brew)"

    print_debug "Checking for curl command..."
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install it first."
        exit 1
    fi
    print_success "curl found at: $(which curl)"

    print_debug "Checking curl version..."
    curl --version | head -1
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

# Test GitHub connectivity
test_github_connection() {
    print_status "Testing GitHub connectivity..."
    print_debug "Testing connection to: $GITHUB_RAW_BASE"

    # Test with a simple HEAD request
    if curl -I -f -s --connect-timeout 10 --max-time 30 "$GITHUB_RAW_BASE/.zshrc" > /dev/null; then
        print_success "Successfully connected to GitHub repository"
    else
        local exit_code=$?
        print_error "Failed to connect to GitHub repository"
        print_error "URL tested: $GITHUB_RAW_BASE/.zshrc"
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
    local url="$GITHUB_RAW_BASE/$filename"
    local dest="$TEMP_DIR/$filename"

    print_status "Downloading $filename..."
    print_debug "From: $url"
    print_debug "To: $dest"

    # Create directory if needed
    local dest_dir=$(dirname "$dest")
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir" || {
            print_error "Failed to create directory: $dest_dir"
            return 1
        }
    fi

    # Download with verbose error reporting
    local curl_output
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
        ".zshrc"
        "config"
        "starship.toml"
    )

    local success_count=0
    local total_files=${#files[@]}

    print_debug "Starting download loop for ${total_files} files"

    for file in "${files[@]}"; do
        print_debug "=== Processing file $((success_count + 1))/$total_files: $file ==="
        print_status "Attempting to download: $file"

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

# Download and install font
download_and_install_font() {
    print_status "Downloading CommitMono Nerd Font..."

    local font_filename="CommitMonoNerdFont-Regular.otf"
    local font_url="$GITHUB_RAW_BASE/assets/$font_filename"
    local font_dest="$TEMP_DIR/$font_filename"

    print_debug "Font download URL: $font_url"

    # Create assets subdirectory in temp
    mkdir -p "$TEMP_DIR/assets"
    font_dest="$TEMP_DIR/assets/$font_filename"

    if curl -L -f -s -w "HTTP_CODE:%{http_code};SIZE:%{size_download}" -o "$font_dest" "$font_url" 2>/dev/null; then
        local file_size=$(wc -c < "$font_dest" 2>/dev/null || echo "0")
        print_success "Downloaded CommitMono Nerd Font (${file_size} bytes)"

        # Verify it's actually a font file (should be reasonably large)
        if [ "$file_size" -lt 10000 ]; then
            print_warning "Font file seems too small, might be an error page"
            print_debug "Font file content preview:"
            if [ "$DEBUG_MODE" = "true" ]; then
                head -3 "$font_dest" || true
            fi
        fi
    else
        print_warning "Failed to download font from $font_url"
        print_warning "Continuing without font installation..."
        return 1
    fi

    # Install the font
    print_status "Installing CommitMono Nerd Font..."

    local user_fonts_dir="$HOME/Library/Fonts"
    print_debug "Font installation directory: $user_fonts_dir"

    if [ ! -d "$user_fonts_dir" ]; then
        mkdir -p "$user_fonts_dir" || {
            print_error "Failed to create fonts directory: $user_fonts_dir"
            return 1
        }
    fi

    local dest_file="$user_fonts_dir/$font_filename"

    if [ -f "$dest_file" ]; then
        print_warning "Font $font_filename already installed, skipping"
    else
        cp "$font_dest" "$dest_file" || {
            print_error "Failed to copy font to $dest_file"
            return 1
        }
        print_success "Installed font: $font_filename"

        # Clear font cache on macOS
        print_status "Refreshing font cache..."
        if command -v atsutil &> /dev/null; then
            sudo atsutil databases -remove 2>/dev/null || print_debug "atsutil databases -remove failed"
            atsutil server -shutdown 2>/dev/null || print_debug "atsutil server -shutdown failed"
            atsutil server -ping 2>/dev/null || print_debug "atsutil server -ping failed"
        else
            print_debug "atsutil not found, skipping font cache refresh"
        fi

        print_success "Font installation complete!"
        print_status "You may need to restart applications to see the new font"
    fi
}

# Install packages via Homebrew with better error handling
install_packages() {
    print_status "Installing packages via Homebrew..."

    local packages=(
        "zsh"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "starship"
        "eza"
        "zoxide"
    )

    local cask_packages=(
        "ghostty"
    )

    # Update Homebrew first
    print_status "Updating Homebrew..."
    brew update || print_warning "Homebrew update failed, continuing anyway..."

    # Install regular packages
    for package in "${packages[@]}"; do
        print_status "Installing $package..."
        print_debug "Checking if $package is already installed..."

        if brew list "$package" &>/dev/null; then
            print_warning "$package is already installed"
        else
            print_debug "Installing $package with brew..."
            if brew install "$package"; then
                print_success "Installed $package"
            else
                print_error "Failed to install $package"
                # Don't exit, try to continue with other packages
            fi
        fi
    done

    # Install cask packages
    for package in "${cask_packages[@]}"; do
        print_status "Installing $package (cask)..."
        print_debug "Checking if cask $package is already installed..."

        if brew list --cask "$package" &>/dev/null; then
            print_warning "$package is already installed"
        else
            print_debug "Installing cask $package with brew..."
            if brew install --cask "$package"; then
                print_success "Installed $package"
            else
                print_warning "Failed to install $package (cask) - this might not be critical"
                # Ghostty might not be available, but don't fail the whole script
            fi
        fi
    done
}

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

    if [ -f "$HOME/.config/ghostty/config" ]; then
        mkdir -p "$backup_dir/.config/ghostty"
        cp "$HOME/.config/ghostty/config" "$backup_dir/.config/ghostty/" && {
            print_success "Backed up ghostty config to $backup_dir"
            backed_up=true
        } || print_warning "Failed to backup ghostty config"
    fi

    if [ -f "$HOME/.config/starship.toml" ]; then
        mkdir -p "$backup_dir/.config"
        cp "$HOME/.config/starship.toml" "$backup_dir/.config/" && {
            print_success "Backed up starship.toml to $backup_dir"
            backed_up=true
        } || print_warning "Failed to backup starship.toml"
    fi

    if [ "$backed_up" = false ]; then
        print_status "No existing configuration files to backup"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Copy downloaded configuration files to their destinations
install_configs() {
    print_status "Installing configuration files..."

    local install_errors=0

    # Install .zshrc
    if [ -f "$TEMP_DIR/.zshrc" ]; then
        print_debug "Installing .zshrc to $HOME/"
        if cp "$TEMP_DIR/.zshrc" "$HOME/"; then
            print_success "Installed .zshrc"
        else
            print_error "Failed to install .zshrc"
            ((install_errors++))
        fi
    else
        print_error ".zshrc not found in downloaded files: $TEMP_DIR/.zshrc"
        ((install_errors++))
    fi

    # Install ghostty config
    if [ -f "$TEMP_DIR/config" ]; then
        print_debug "Installing ghostty config to $HOME/.config/ghostty/"
        mkdir -p "$HOME/.config/ghostty"
        if cp "$TEMP_DIR/config" "$HOME/.config/ghostty/"; then
            print_success "Installed Ghostty config"
        else
            print_error "Failed to install Ghostty config"
            ((install_errors++))
        fi
    else
        print_error "Ghostty config not found in downloaded files: $TEMP_DIR/config"
        ((install_errors++))
    fi

    # Install starship config
    if [ -f "$TEMP_DIR/starship.toml" ]; then
        print_debug "Installing starship config to $HOME/.config/"
        mkdir -p "$HOME/.config"
        if cp "$TEMP_DIR/starship.toml" "$HOME/.config/"; then
            print_success "Installed starship.toml"
        else
            print_error "Failed to install starship.toml"
            ((install_errors++))
        fi
    else
        print_error "starship.toml not found in downloaded files: $TEMP_DIR/starship.toml"
        ((install_errors++))
    fi

    if [ $install_errors -gt 0 ]; then
        print_error "$install_errors configuration files failed to install"
        exit 1
    fi
}

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
        print_debug "GitHub base URL: $GITHUB_RAW_BASE"
        print_debug "Temp directory: $TEMP_DIR"
        print_debug "========================="
    fi
}

# Main installation function
main() {
    echo "🌑 Darkmatter Setup Installer (Remote)"
    echo "======================================"
    echo

    # Enable debug mode if requested
    if [ "${1:-}" = "--debug" ] || [ "${1:-}" = "-d" ]; then
        DEBUG_MODE="true"
        print_status "Debug mode enabled"
    fi

    show_debug_info

    # Check if GITHUB_RAW_BASE needs to be updated
    if [[ "$GITHUB_RAW_BASE" == *"your-username/your-repo"* ]]; then
        print_error "Please update the GITHUB_RAW_BASE variable in this script"
        print_error "Set it to your actual GitHub repository URL"
        print_error "Example: https://raw.githubusercontent.com/username/repo-name/main"
        exit 1
    fi

    print_status "Starting installation process..."

    check_dependencies
    setup_temp_dir
    test_github_connection
    download_configs
    download_and_install_font
    install_packages
    backup_configs
    install_configs
    set_default_shell
    cleanup

    echo
    print_success "Installation complete! 🌌"
    echo
    print_status "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open Ghostty to use your new terminal setup"
    echo "  3. Enjoy your Darkmatter terminal experience!"
    echo
}

# Handle script interruption
trap cleanup EXIT

# Run main function with all arguments
main "$@"
