#!/bin/sh
set -e

USERNAME="${USERNAME:-"automatic"}"
USER_UID="${USERUID:-"automatic"}"
USER_GID="${USERGID:-"automatic"}"
SUDO="${SUDO:-"true"}"

if [ "$USERNAME" = "none" ]; then
    exit 0
fi

if [ "$USERNAME" = "auto" ] || [ "$USERNAME" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS="vscode node codespace $(awk -v val=1000 -F: '$3==val{print $1}' /etc/passwd 2>/dev/null)"
    for CURRENT_USER in $POSSIBLE_USERS; do
        if id -u "$CURRENT_USER" >/dev/null 2>&1; then
            USERNAME="$CURRENT_USER"
            break
        fi
    done
    if [ -z "$USERNAME" ]; then
        USERNAME="vscode"
    fi
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
