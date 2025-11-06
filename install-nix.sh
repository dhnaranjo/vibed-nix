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
    NIX_BIN=$(find /nix/store -type f -name "nix" | grep "/bin/nix$" | grep "nix-[0-9]" | sort -r | head -1)
    if [ -n "$NIX_BIN" ]; then
        NIX_DIR=$(dirname "$NIX_BIN")
        export PATH="$NIX_DIR:$PATH"
        echo "Added $NIX_DIR to PATH"
        nix --version

        # Enable flakes and nix-command experimental features
        mkdir -p ~/.config/nix
        cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
sandbox = false
build-users-group =
EOF
        echo "Nix environment configured!"
        exit 0
    fi
fi

# Create /nix directory if it doesn't exist (as root)
if [ ! -d /nix ]; then
    echo "Creating /nix directory..."
    mkdir -m 0755 /nix
    chown root:root /nix
fi

# Install Nix using the official installer
# Note: The installer may show errors but still install successfully
echo "Downloading and installing Nix..."
sh <(curl -L https://nixos.org/nix/install) --no-daemon 2>&1 || true

# Find and add Nix to PATH
NIX_BIN=$(find /nix/store -type f -name "nix" | grep "/bin/nix$" | grep "nix-[0-9]" | sort -r | head -1)
if [ -z "$NIX_BIN" ]; then
    echo "Error: Nix installation failed"
    exit 1
fi

NIX_DIR=$(dirname "$NIX_BIN")
export PATH="$NIX_DIR:$PATH"

# Enable flakes and nix-command experimental features
# Also disable sandbox since we're in a container
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
sandbox = false
build-users-group =
EOF

# Source the nix profile if it exists
if [ -f ~/.nix-profile/etc/profile.d/nix.sh ]; then
    source ~/.nix-profile/etc/profile.d/nix.sh
fi

echo "Nix installation complete!"
nix --version
