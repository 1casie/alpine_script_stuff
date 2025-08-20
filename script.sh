#!/bin/sh

ACTION="$1"
USER="$(whoami)"

if [ "$ACTION" = "install" ]; then
    set -e
    apk update
    apk add --no-cache bash nodejs npm python3 gcc make git curl neovim musl-dev util-linux

    # Change shell to bash
    chsh -s /bin/bash "$USER"

    # Install pm2
    npm install -g pm2

    # Install rustup (and Rust toolchain)
    if ! command -v rustc >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Activate rust for the session
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    echo "Setup complete."
    echo "Versions:"
    bash --version | head -1
    node --version
    npm --version
    pm2 --version
    python3 --version
    gcc --version | head -1
    git --version
    nvim --version | head -1
    rustc --version

elif [ "$ACTION" = "reset" ]; then
    set +e
    # Stop and uninstall PM2
    if command -v pm2 >/dev/null 2>&1; then
        pm2 kill
        npm uninstall -g pm2
    fi
    # Remove rustup and cargo
    rm -rf $HOME/.cargo $HOME/.rustup

    # Remove all installed packages
    apk del --no-cache bash nodejs npm python3 gcc make git curl neovim musl-dev

    # Restore shell to ash
    chsh -s /bin/ash "$USER"

    echo "Environment reset to scratch."
else
    echo "Usage: sh $0 [install|reset]"
fi
