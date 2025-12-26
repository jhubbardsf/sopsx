#!/usr/bin/env bash

# sopsx installer
# Installs sopsx to ~/.local/bin
# Usage: curl -fsSL https://raw.githubusercontent.com/jhubbardsf/sopsx/main/install.sh | bash

set -e

INSTALL_DIR="${HOME}/.local/bin"
REPO_URL="https://raw.githubusercontent.com/jhubbardsf/sopsx/main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}==>${NC} $1"
}

success() {
    echo -e "${GREEN}==>${NC} $1"
}

warn() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

error() {
    echo -e "${RED}Error:${NC} $1"
    exit 1
}

# Check for required dependencies
check_dependencies() {
    info "Checking dependencies..."

    # Check bash version
    BASH_VERSION_MAJOR="${BASH_VERSION%%.*}"
    if [[ "$BASH_VERSION_MAJOR" -lt 4 ]]; then
        warn "bash 4.0+ is required (you have $BASH_VERSION)"
        echo "  Install with: brew install bash"
        echo "  Note: sopsx will use brew's bash, not the system one"
    fi

    # Check for sops
    if ! command -v sops &> /dev/null; then
        warn "sops is not installed"
        echo "  Install with: brew install sops"
    fi

    # Check for AWS CLI
    if ! command -v aws &> /dev/null; then
        warn "AWS CLI is not installed"
        echo "  Install with: brew install awscli"
    fi
}

# Create install directory if needed
create_install_dir() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        info "Creating $INSTALL_DIR..."
        mkdir -p "$INSTALL_DIR"
    fi
}

# Download and install sopsx
install_sopsx() {
    info "Downloading sopsx..."

    if command -v curl &> /dev/null; then
        curl -fsSL "${REPO_URL}/bin/sopsx" -o "${INSTALL_DIR}/sopsx"
    elif command -v wget &> /dev/null; then
        wget -q "${REPO_URL}/bin/sopsx" -O "${INSTALL_DIR}/sopsx"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi

    chmod +x "${INSTALL_DIR}/sopsx"
    success "Installed sopsx to ${INSTALL_DIR}/sopsx"
}

# Check if install dir is in PATH
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "$INSTALL_DIR is not in your PATH"
        echo ""
        echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

# Print success message
print_success() {
    echo ""
    success "sopsx installed successfully!"
    echo ""
    echo "Usage:"
    echo "  sopsx -d secrets.enc.yaml    # Decrypt (auto-detects AWS profile)"
    echo "  sopsx secrets.enc.yaml       # Edit encrypted file"
    echo "  sopsx help                   # Show help"
    echo ""
    echo "For git diff integration, add to ~/.gitconfig:"
    echo "  [diff \"sopsdiffer\"]"
    echo "      textconv = sopsx -d"
    echo ""
}

main() {
    echo ""
    echo "Installing sopsx..."
    echo ""

    check_dependencies
    create_install_dir
    install_sopsx
    check_path
    print_success
}

main
