#!/bin/bash

ACTION="$1"

if [[ "$(id -u)" != "0" ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Full package list from original script
PACKAGES="bash nodejs npm python3 gcc make git curl neovim musl-dev util-linux coreutils findutils grep gawk sed diffutils procps-ng iputils net-tools shadow sudo openssh wget tar bzip2 xz zip unzip htop tmux rsync cronie bc less iproute2 lsof iptables bind-tools tcpdump openssl gnupg postgresql-client btrfs-progs ntfs-3g docker docker-cli-compose nginx"

# Services to optionally start (won't auto-start to save RAM)
SERVICES="docker nginx sshd crond"

start_service() {
    local SERVICE="$1"
    service "$SERVICE" start || true
}

stop_service() {
    local SERVICE="$1"
    service "$SERVICE" stop || true
}

if [[ "$ACTION" == "add" ]]; then
    set -e

    echo "Installing full server environment..."
    apk update
    apk add --no-cache $PACKAGES

    # Install Rust if not present
    if ! command -v rustc >/dev/null 2>&1; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        export PATH="/root/.cargo/bin:$PATH"
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc
    fi

    # Disable services at boot to minimize RAM usage
    for SVC in $SERVICES; do
        rc-update del "$SVC" default 2>/dev/null || true
        stop_service "$SVC"
    done

    echo "Server bootstrap complete."
    echo "Installed versions:"
    bash --version | head -1
    node --version
    npm --version
    python3 --version
    gcc --version | head -1
    git --version
    rustc --version
    docker --version || echo "Docker CLI only"
    nginx -v || echo "Nginx installed"

    echo
    echo "Services are installed but not started to minimize RAM usage."
    echo "Start them manually as needed:"
    echo "  service docker start"
    echo "  service nginx start"
    echo "  service sshd start"
    echo "  service crond start"

elif [[ "$ACTION" == "del" ]]; then
    set +e

    echo "Restoring minimal environment..."

    # Stop services if running
    for SVC in $SERVICES; do
        stop_service "$SVC"
        rc-update del "$SVC" default 2>/dev/null || true
    done

    # Remove all installed packages
    apk del --no-cache $PACKAGES

    # Remove Rust
    rm -rf /root/.cargo /root/.rustup

    echo "Environment restored to minimal scratch."
else
    echo "Usage: $0 [add|del]"
fi
