#!/bin/sh

ACTION="$1"

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

if [ "$ACTION" = "install" ]; then
    set -e
    apk update
    apk add --no-cache bash nodejs npm python3 gcc make git curl micro musl-dev util-linux coreutils findutils grep gawk sed diffutils procps-ng iputils net-tools shadow sudo openssh wget tar bzip2 xz zip unzip htop tmux rsync cronie bc less iproute2 lsof iptables bind-tools tcpdump openssl gnupg postgresql-client btrfs-progs ntfs-3g docker docker-cli-compose nginx

    # Change shell to bash for root
    chsh -s /bin/bash root

    # Install pm2
    npm install -g pm2

    # Install rustup (and Rust toolchain)
    if ! command -v rustc >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Activate rust for the session
        export PATH="/root/.cargo/bin:$PATH"
    fi

    # Persist rust path
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc

    # Configure services
    rc-update add docker default
    service docker start || true

    rc-update add sshd default
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A
    fi
    service sshd start || true

    rc-update add crond default
    service crond start || true

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
    docker --version
    docker compose version
    echo "Relogin to apply shell changes."

elif [ "$ACTION" = "restore" ]; then
    set +e
    # Stop and uninstall PM2
    if command -v pm2 >/dev/null 2>&1; then
        pm2 kill
        npm uninstall -g pm2
    fi
    # Remove rustup and cargo
    rm -rf /root/.cargo /root/.rustup
    rm -f /root/.bashrc

    # Stop services
    service crond stop || true
    rc-update del crond default
    service sshd stop || true
    rc-update del sshd default
    service docker stop || true
    rc-update del docker default

    # Remove all installed packages
    apk del --no-cache bash nodejs npm python3 gcc make git curl micro musl-dev util-linux coreutils findutils grep gawk sed diffutils procps-ng iputils net-tools shadow sudo openssh wget tar bzip2 xz zip unzip htop tmux rsync cronie bc less iproute2 lsof iptables bind-tools tcpdump openssl gnupg postgresql-client btrfs-progs ntfs-3g docker docker-cli-compose nginx

    # Restore shell to ash
    chsh -s /bin/ash root

    echo "Environment restored to scratch."
else
    echo "Usage: sh $0 [install|restore]"
fi
