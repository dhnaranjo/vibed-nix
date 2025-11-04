#!/bin/bash
set -euo pipefail

echo "Installing Nix..."

# Check if Nix is already installed and in PATH
if command -v nix &> /dev/null; then
    echo "Nix is already installed"
    nix --version
    exit 0
fi

# Check if Nix store exists but not in PATH
if [ -d /nix/store ]; then
    echo "Nix store found, setting up environment..."
    NIX_BIN=$(find /nix/store -path "*/nix-*/bin/nix" -type f -executable | sort -r | head -1)
    if [ -n "$NIX_BIN" ]; then
        NIX_DIR=$(dirname "$NIX_BIN")
        export PATH="$NIX_DIR:$PATH"
        echo "Added $NIX_DIR to PATH"
        nix --version

        # Enable flakes and nix-command experimental features
        mkdir -p ~/.config/nix
        cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF
        echo "Nix environment configured!"
        exit 0
    fi
fi

# Install Nix using the official installer
# Ignore errors as the binaries are often installed despite error messages
echo "Downloading and installing Nix..."
sh <(curl -L https://nixos.org/nix/install) --no-daemon 2>&1 || true

# Find and add Nix to PATH
NIX_BIN=$(find /nix/store -path "*/nix-*/bin/nix" -type f -executable | sort -r | head -1)
if [ -z "$NIX_BIN" ]; then
    echo "Error: Nix installation failed"
    exit 1
fi

NIX_DIR=$(dirname "$NIX_BIN")
export PATH="$NIX_DIR:$PATH"

# Enable flakes and nix-command experimental features
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF

echo "Nix installation complete!"
nix --version
