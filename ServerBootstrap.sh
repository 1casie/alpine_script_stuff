#!/bin/bash

ACTION="$1"

if [[ "$(id -u)" != "0" ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Minimal necessary packages for a PHP + Node.js + Nginx server
PACKAGES="bash nodejs npm python3 gcc make git curl micro musl-dev coreutils findutils grep sed util-linux \
tar bzip2 xz zip unzip less iproute2 lsof openssh openssl gnupg docker-cli-compose nginx php php-fpm"

# Services to optionally start
SERVICES="docker nginx php-fpm sshd crond"

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

    echo "Installing minimal server environment..."
    apk update
    apk add --no-cache $PACKAGES

    # Change shell to bash for root
    chsh -s /bin/bash root

    # Install Rust if not present
    if ! command -v rustc >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        export PATH="/root/.cargo/bin:$PATH"
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc
    fi

    # Disable all services at boot to save RAM
    for SVC in $SERVICES; do
        rc-update del "$SVC" default 2>/dev/null || true
        stop_service "$SVC"
    done

    echo "Server bootstrap complete. Installed versions:"
    bash --version | head -1
    node --version
    npm --version
    python3 --version
    gcc --version | head -1
    git --version
    php -v
    rustc --version
    docker --version || echo "Docker CLI only"
    nginx -v || echo "Nginx installed"

    echo
    echo "Services are installed but not started to minimize RAM usage."
    echo "Start them manually as needed, e.g.:"
    echo "  service php-fpm start"
    echo "  service nginx start"
    echo "  service docker start"

elif [[ "$ACTION" == "del" ]]; then
    set +e

    echo "Restoring minimal environment..."

    # Stop services if running
    for SVC in $SERVICES; do
        stop_service "$SVC"
        rc-update del "$SVC" default 2>/dev/null || true
    done

    # Remove installed packages
    apk del --no-cache $PACKAGES

    # Remove Rust
    rm -rf /root/.cargo /root/.rustup

    # Restore shell to ash
    chsh -s /bin/ash root

    echo "Environment fully restored to minimal scratch."
else
    echo "Usage: $0 [add|del]"
fi
