#!/bin/sh
set -e

VERSION="${VERSION:-"stable"}"

FEATURE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -n "${_REMOTE_USER}" ] && [ "${_REMOTE_USER}" != "root" ] && [ "${_REMOTE_USER}" != "0" ] && ! echo "${_REMOTE_USER}" | grep -qE '^[0-9]+$'; then
    USERNAME="${_REMOTE_USER}"
else
    USERNAME=""
    for CURRENT_USER in vscode node codespace $(awk -v val=1000 -F: '$3==val{print $1}' /etc/passwd 2>/dev/null); do
        if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
            USERNAME="${CURRENT_USER}"
            break
        fi
    done
fi

if [ -n "${USERNAME}" ]; then
    USER_HOME="$(eval echo "~${USERNAME}")"
else
    USERNAME="root"
    USER_HOME="/root"
fi

curl -sfL https://direnv.net/install.sh | bash
apk add --no-cache nodejs npm

BOB_LOCAL_BIN="${USER_HOME}/.local/bin"
BOB_BIN_DIR="${USER_HOME}/.local/share/bob/bin"
BOB_NVIM_BIN_DIR="${USER_HOME}/.local/share/bob/nvim-bin"

if [ "${USERNAME}" = "root" ]; then
    curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
    export PATH="${BOB_LOCAL_BIN}:${BOB_BIN_DIR}:${PATH}"
    bob use "${VERSION}"
else
    su - "${USERNAME}" -c "
        curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
        export PATH=\"${BOB_LOCAL_BIN}:${BOB_BIN_DIR}:\${PATH}\"
        bob use \"${VERSION}\"
    "
fi

ln -sf "${BOB_LOCAL_BIN}/bob" /usr/local/bin/bob
ln -sf "${BOB_NVIM_BIN_DIR}/nvim" /usr/local/bin/nvim

NVIM_CONFIG_DIR="${USER_HOME}/.config/nvim"
mkdir -p "${NVIM_CONFIG_DIR}"
cp -r "${FEATURE_DIR}/config/." "${NVIM_CONFIG_DIR}/"

if [ "${USERNAME}" != "root" ]; then
    GROUP_NAME="$(id -gn "${USERNAME}")"
    chown -R "${USERNAME}:${GROUP_NAME}" "${NVIM_CONFIG_DIR}"
    chown -R "${USERNAME}:${GROUP_NAME}" "${USER_HOME}/.local"
fi

NVIM_BIN="${BOB_NVIM_BIN_DIR}/nvim"

if [ "${USERNAME}" = "root" ]; then
    "${FEATURE_DIR}/sync.sh" "${NVIM_BIN}" "${FEATURE_DIR}/sync.lua"
else
    su - "${USERNAME}" -c "
        export PATH=\"${BOB_LOCAL_BIN}:${BOB_BIN_DIR}:${BOB_NVIM_BIN_DIR}:\${PATH}\"
        '${FEATURE_DIR}/sync.sh' '${NVIM_BIN}' '${FEATURE_DIR}/sync.lua'
    "
fi

echo "Neovim (${VERSION}) installed via bob. Configuration deployed to ${NVIM_CONFIG_DIR}."
