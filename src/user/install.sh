#!/bin/sh
set -e

USERNAME="${USERNAME:-"automatic"}"
USER_UID="${USERUID:-"automatic"}"
USER_GID="${USERGID:-"automatic"}"
SUDO="${SUDO:-"true"}"

if [ "$USERNAME" = "none" ]; then
    exit 0
fi

if [ "$USERNAME" = "automatic" ]; then
    USERNAME="vscode"
fi

if [ "$USER_UID" = "automatic" ]; then
    USER_UID=1000
fi

if [ "$USER_GID" = "automatic" ]; then
    USER_GID=1000
fi

if id -u "$USERNAME" >/dev/null 2>&1; then
    echo "User '$USERNAME' already exists, skipping."
    exit 0
fi

if ! command -v useradd >/dev/null 2>&1; then
    apk add --no-cache shadow
fi

GROUP_NAME="$(awk -F: -v gid="$USER_GID" '$3 == gid { print $1 }' /etc/group)"
if [ -z "$GROUP_NAME" ]; then
    groupadd -g "$USER_GID" "$USERNAME"
    GROUP_NAME="$USERNAME"
fi

useradd -m -s /bin/sh -u "$USER_UID" -g "$GROUP_NAME" "$USERNAME"

if [ "$SUDO" = "true" ]; then
    apk add --no-cache sudo
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME
fi

echo "Created user '$USERNAME' (uid=$USER_UID, gid=$USER_GID)."
