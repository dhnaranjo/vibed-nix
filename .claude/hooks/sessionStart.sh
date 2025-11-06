#!/bin/bash
set -euo pipefail

echo "Setting up Nix environment for vibed-nix..."

cd /home/user/vibed-nix

# Check if Nix is already available in PATH
if ! command -v nix &> /dev/null; then
    # Find Nix binary if already installed
    if [ -d /nix/store ]; then
        echo "Nix store found, adding to PATH..."
        NIX_BIN=$(find /nix/store -type f -name "nix" | grep "/bin/nix$" | grep "nix-[0-9]" | sort -r | head -1)
        if [ -n "$NIX_BIN" ]; then
            NIX_DIR=$(dirname "$NIX_BIN")
            export PATH="$NIX_DIR:$PATH"
        fi
    fi

    # If still not available, run installation
    if ! command -v nix &> /dev/null; then
        echo "Installing Nix..."
        ./install-nix.sh

        # Add to PATH after installation
        NIX_BIN=$(find /nix/store -type f -name "nix" | grep "/bin/nix$" | grep "nix-[0-9]" | sort -r | head -1)
        if [ -n "$NIX_BIN" ]; then
            NIX_DIR=$(dirname "$NIX_BIN")
            export PATH="$NIX_DIR:$PATH"
        fi
    fi
fi

# Verify Nix is now available
if ! command -v nix &> /dev/null; then
    echo "Error: Nix installation failed"
    exit 1
fi

# Ensure Nix config exists with experimental features enabled
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
sandbox = false
build-users-group =
EOF

export NIX_CONF_DIR="$HOME/.config/nix"
echo "Nix version: $(nix --version)"

# Persist Nix environment to CLAUDE_ENV_FILE
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    # Add Nix to PATH
    NIX_BIN_DIR=$(dirname "$(command -v nix)")
    echo "export PATH=\"$NIX_BIN_DIR:\$PATH\"" >> "$CLAUDE_ENV_FILE"
    echo "export NIX_CONF_DIR=\"$HOME/.config/nix\"" >> "$CLAUDE_ENV_FILE"

    # Try to load nix develop environment (may fail in resource-constrained environments)
    echo "Loading nix develop environment..."
    if DEV_ENV=$(nix develop /home/user/vibed-nix --command bash -c 'export -p' 2>/dev/null); then
        # Capture environment before and after to get the diff
        ENV_BEFORE=$(export -p | sort)
        eval "$DEV_ENV"
        ENV_AFTER=$(export -p | sort)
        comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
        echo "  ✓ Dev environment loaded successfully"
    else
        echo "  ⚠ Could not load full dev environment (resource constraints)"
        echo "  You can manually run 'nix develop' to enter the dev shell"
    fi

    echo "Environment variables persisted to $CLAUDE_ENV_FILE"
fi

# Set up automatic nix develop entry
echo "Setting up automatic nix develop entry..."
mkdir -p ~/.config/claude-code
cat > ~/.config/claude-code/nix-auto-enter.sh << 'AUTOENTER'
# Auto-enter nix develop for vibed-nix project
if [ -z "$IN_NIX_SHELL" ] && [ "$PWD" = "/home/user/vibed-nix" ]; then
    # Only auto-enter if nix command is available
    if command -v nix &> /dev/null; then
        echo "Entering nix develop environment..."
        exec nix develop
    fi
fi
AUTOENTER

# Add to bashrc if not already present
if [ -f ~/.bashrc ]; then
    if ! grep -q "nix-auto-enter.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Auto-enter nix develop for vibed-nix" >> ~/.bashrc
        echo "source ~/.config/claude-code/nix-auto-enter.sh 2>/dev/null || true" >> ~/.bashrc
    fi
else
    cat > ~/.bashrc << 'BASHRC'
# Auto-enter nix develop for vibed-nix
source ~/.config/claude-code/nix-auto-enter.sh 2>/dev/null || true
BASHRC
fi

echo "✓ Nix is available and will auto-enter development shell!"
exit 0
