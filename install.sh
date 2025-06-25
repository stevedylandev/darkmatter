#!/bin/bash

# Terminal Setup - Opinionated terminal configuration installer
# Requires: Homebrew (https://brew.sh)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed. Please install it first:"
        print_error "https://brew.sh"
        exit 1
    fi
    print_success "Homebrew found"
}

# Install packages via Homebrew
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
    
    # Install regular packages
    for package in "${packages[@]}"; do
        print_status "Installing $package..."
        if brew list "$package" &>/dev/null; then
            print_warning "$package is already installed"
        else
            brew install "$package"
            print_success "Installed $package"
        fi
    done
    
    # Install cask packages
    for package in "${cask_packages[@]}"; do
        print_status "Installing $package (cask)..."
        if brew list --cask "$package" &>/dev/null; then
            print_warning "$package is already installed"
        else
            brew install --cask "$package"
            print_success "Installed $package"
        fi
    done
}

# Backup existing config files
backup_configs() {
    print_status "Backing up existing configuration files..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.config_backup_$timestamp"
    
    mkdir -p "$backup_dir"
    
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$backup_dir/"
        print_success "Backed up .zshrc to $backup_dir"
    fi
    
    if [ -f "$HOME/.config/ghostty/config" ]; then
        cp "$HOME/.config/ghostty/config" "$backup_dir/"
        print_success "Backed up ghotty config to $backup_dir"
    fi
    
    if [ -f "$HOME/.config/starship.toml" ]; then
        mkdir -p "$backup_dir/.config"
        cp "$HOME/.config/starship.toml" "$backup_dir/.config/"
        print_success "Backed up starship.toml to $backup_dir"
    fi
}

# Copy configuration files from the repo
copy_configs() {
    print_status "Copying configuration files..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy .zshrc
    if [ -f "$script_dir/.zshrc" ]; then
        cp "$script_dir/.zshrc" "$HOME/"
        print_success "Copied .zshrc"
    else
        print_warning ".zshrc not found in repo"
    fi
    
    # Copy ghostty config
    if [ -f "$script_dir/config" ]; then
        mkdir -p "$HOME/.config/ghostty"
        cp "$script_dir/config" "$HOME/.config/ghostty/"
        print_success "Copied ghostty config"
    else
        print_warning "Ghostty config not found in repo"
    fi
    
    # Copy starship config
    if [ -f "$script_dir/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        cp "$script_dir/starship.toml" "$HOME/.config/"
        print_success "Copied starship.toml"
    else
        print_warning "starship.toml not found in repo"
    fi
}

# Set zsh as default shell
set_default_shell() {
    local current_shell=$(echo $SHELL)
    local zsh_path=$(which zsh)
    
    if [ "$current_shell" != "$zsh_path" ]; then
        print_status "Setting zsh as default shell..."
        
        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        
        # Change default shell
        chsh -s "$zsh_path"
        print_success "Default shell set to zsh"
        print_warning "Please restart your terminal or run 'exec zsh' to use the new shell"
    else
        print_success "zsh is already the default shell"
    fi
}

# Main installation function
main() {
    echo "🌑 Darkmatter Setup Installer"
    echo "=========================="
    echo
    
    check_homebrew
    install_packages
    backup_configs
    copy_configs
    set_default_shell
    
    echo
    print_success "Installation complete! 🌌"
    echo
    print_status "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open Ghostty to use your new terminal setup"
    echo "  3. Enjoy your opinionated terminal experience!"
}

# Run main function
main "$@"
