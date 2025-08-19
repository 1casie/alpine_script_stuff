#!/bin/sh

ACTION="$1"

if [ "$ACTION" = "install" ]; then
    apk update
    apk add --no-cache bash nodejs npm
    chsh -s /bin/bash "$(whoami)"
    npm install -g pm2
    echo "Setup complete."
elif [ "$ACTION" = "reset" ]; then
    if command -v pm2 >/dev/null 2>&1; then
        pm2 kill
    fi
    npm uninstall -g pm2 2>/dev/null
    apk del --no-cache pm2 nodejs npm bash
    chsh -s /bin/ash "$(whoami)"
    echo "Environment reset to scratch."
else
    echo "Usage: sh $0 [install|reset]"
fi
