#!/bin/bash
set -e

INSTALL_ZSH="${INSTALLZSH:-"true"}"
CONFIGURE_ZSH_AS_DEFAULT_SHELL="${CONFIGUREZSHASDEFAULTSHELL:-"false"}"
INSTALL_OH_MY_ZSH="${INSTALLOHMYZSH:-"true"}"
INSTALL_OH_MY_ZSH_CONFIG="${INSTALLOHMYZSHCONFIG:-"true"}"
UPGRADE_PACKAGES="${UPGRADEPACKAGES:-"true"}"
USERNAME="${USERNAME:-"automatic"}"
USER_UID="${USERUID:-"automatic"}"
USER_GID="${USERGID:-"automatic"}"
SUDO="${SUDO:-"true"}"
INSTALL_SSL="${INSTALLSSL:-"true"}"

MARKER_FILE="/usr/local/etc/dev-container-features/common"
FEATURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load markers to see which steps have already run
if [ -f "${MARKER_FILE}" ]; then
    echo "Marker file found:"
    cat "${MARKER_FILE}"
    source "${MARKER_FILE}"
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# ---------------------------------------------------------------------------
# Install packages
# ---------------------------------------------------------------------------
if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
    if [ "${UPGRADE_PACKAGES}" = "true" ]; then
        apk upgrade --no-cache
    fi

    # glibc and locale support
    apk add --no-cache \
        glibc \
        glibc-locale-posix \
        || true

    # GNU/POSIX utilities — replace busybox with full implementations
    apk add --no-cache \
        coreutils \
        findutils \
        grep \
        sed \
        gawk \
        diffutils \
        patch \
        file \
        util-linux \
        gzip \
        bzip2 \
        xz

    # Common CLI utilities
    apk add --no-cache \
        bash-completion \
        ca-certificates-bundle \
        curl \
        git \
        gnupg \
        htop \
        jq \
        less \
        lsof \
        man-db \
        nano \
        net-tools \
        openssh-client \
        procps \
        psmisc \
        rsync \
        shadow \
        strace \
        sudo \
        unzip \
        vim \
        wget \
        zip

    if [ "${INSTALL_SSL}" = "true" ]; then
        apk add --no-cache openssl || true
    fi

    if [ "${INSTALL_ZSH}" = "true" ] && ! command -v zsh >/dev/null 2>&1; then
        apk add --no-cache zsh
    fi

    PACKAGES_ALREADY_INSTALLED="true"
fi

# ---------------------------------------------------------------------------
# User setup
# ---------------------------------------------------------------------------
if [ "${USERNAME}" = "automatic" ]; then
    if [ "${_REMOTE_USER}" != "root" ] && [ "${_REMOTE_USER}" != "0" ] && [ -n "${_REMOTE_USER}" ] && ! echo "${_REMOTE_USER}" | grep -qE '^[0-9]+$'; then
        USERNAME="${_REMOTE_USER}"
    else
        USERNAME=""
        POSSIBLE_USERS=("devcontainer" "vscode" "node" "codespace" "$(awk -v val=1000 -F: '$3==val{print $1}' /etc/passwd 2>/dev/null)")
        for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
            if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
                USERNAME="${CURRENT_USER}"
                break
            fi
        done
        if [ -z "${USERNAME}" ]; then
            USERNAME="vscode"
        fi
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME="root"
    USER_UID=0
    USER_GID=0
fi

# Create or update non-root user to match UID/GID
group_name="${USERNAME}"
if id -u ${USERNAME} >/dev/null 2>&1; then
    if [ "${USER_GID}" != "automatic" ] && [ "${USER_GID}" != "$(id -g ${USERNAME})" ]; then
        group_name="$(id -gn ${USERNAME})"
        groupmod --gid ${USER_GID} ${group_name}
        usermod --gid ${USER_GID} ${USERNAME}
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "${USER_UID}" != "$(id -u ${USERNAME})" ]; then
        usermod --uid ${USER_UID} ${USERNAME}
    fi
else
    if [ "${USER_GID}" = "automatic" ]; then
        groupadd ${USERNAME}
    else
        groupadd --gid ${USER_GID} ${USERNAME}
    fi
    if [ "${USER_UID}" = "automatic" ]; then
        useradd -s /bin/bash --gid ${USERNAME} -m ${USERNAME}
    else
        useradd -s /bin/bash --uid ${USER_UID} --gid ${USERNAME} -m ${USERNAME}
    fi
fi

# Sudo
if [ "${USERNAME}" != "root" ] && [ "${SUDO}" = "true" ] && [ "${EXISTING_NON_ROOT_USER}" != "${USERNAME}" ]; then
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}
    chmod 0440 /etc/sudoers.d/${USERNAME}
    EXISTING_NON_ROOT_USER="${USERNAME}"
fi

# ---------------------------------------------------------------------------
# Shell customization
# ---------------------------------------------------------------------------
if [ "${USERNAME}" = "root" ]; then
    user_home="/root"
else
    user_home="$(awk -F: -v u="${USERNAME}" '$1==u{print $6}' /etc/passwd 2>/dev/null)"
    if [ -z "${user_home}" ]; then
        user_home="/home/${USERNAME}"
    fi
    if [ ! -d "${user_home}" ]; then
        mkdir -p "${user_home}"
        chown ${USERNAME}:${group_name} "${user_home}"
    fi
fi

# Restore user RC files from skeleton if they don't exist or are empty
possible_rc_files=(".bashrc" ".profile")
[[ "${INSTALL_OH_MY_ZSH_CONFIG}" == "true" ]] && possible_rc_files+=('.zshrc')
[[ "${INSTALL_ZSH}" == "true" ]] && possible_rc_files+=('.zprofile')
for rc_file in "${possible_rc_files[@]}"; do
    if [ -f "/etc/skel/${rc_file}" ]; then
        if [ ! -e "${user_home}/${rc_file}" ] || [ ! -s "${user_home}/${rc_file}" ]; then
            cp "/etc/skel/${rc_file}" "${user_home}/${rc_file}"
            chown ${USERNAME}:${group_name} "${user_home}/${rc_file}"
        fi
    fi
done

# Add RC snippet and custom bash prompt
if [ "${RC_SNIPPET_ALREADY_ADDED}" != "true" ]; then
    global_rc_path="/etc/bash/bashrc"
    mkdir -p /etc/bash
    cat "${FEATURE_DIR}/scripts/rc_snippet.sh" >> "${global_rc_path}"
    cat "${FEATURE_DIR}/scripts/bash_theme_snippet.sh" >> "${user_home}/.bashrc"
    if [ "${USERNAME}" != "root" ]; then
        cat "${FEATURE_DIR}/scripts/bash_theme_snippet.sh" >> "/root/.bashrc"
        chown ${USERNAME}:${group_name} "${user_home}/.bashrc"
    fi
    RC_SNIPPET_ALREADY_ADDED="true"
fi

# Zsh configuration
if [ "${INSTALL_ZSH}" = "true" ]; then
    if [ ! -f "${user_home}/.zprofile" ]; then
        touch "${user_home}/.zprofile"
        echo 'source $HOME/.profile' >> "${user_home}/.zprofile"
        chown ${USERNAME}:${group_name} "${user_home}/.zprofile"
    fi

    if [ "${ZSH_ALREADY_INSTALLED}" != "true" ]; then
        global_rc_path="/etc/zsh/zshrc"
        mkdir -p /etc/zsh
        cat "${FEATURE_DIR}/scripts/rc_snippet.sh" >> "${global_rc_path}"
        ZSH_ALREADY_INSTALLED="true"
    fi

    if [[ "${CONFIGURE_ZSH_AS_DEFAULT_SHELL}" == "true" ]]; then
        usermod -s /bin/zsh ${USERNAME}
    fi

    # Oh My Zsh
    if [ "${INSTALL_OH_MY_ZSH}" = "true" ]; then
        user_rc_file="${user_home}/.zshrc"
        oh_my_install_dir="${user_home}/.oh-my-zsh"
        template_path="${oh_my_install_dir}/templates/zshrc.zsh-template"
        if [ ! -d "${oh_my_install_dir}" ]; then
            umask g-w,o-w
            mkdir -p ${oh_my_install_dir}
            git clone --depth=1 \
                -c core.eol=lf \
                -c core.autocrlf=false \
                -c fsck.zeroPaddedFilemode=ignore \
                -c fetch.fsck.zeroPaddedFilemode=ignore \
                -c receive.fsck.zeroPaddedFilemode=ignore \
                "https://github.com/ohmyzsh/ohmyzsh" "${oh_my_install_dir}" 2>&1

            cd "${oh_my_install_dir}"
            git repack -a -d -f --depth=1 --window=1
        fi

        # Add devcontainers theme
        mkdir -p ${oh_my_install_dir}/custom/themes
        cp -f "${FEATURE_DIR}/scripts/devcontainers.zsh-theme" "${oh_my_install_dir}/custom/themes/devcontainers.zsh-theme"
        ln -sf "${oh_my_install_dir}/custom/themes/devcontainers.zsh-theme" "${oh_my_install_dir}/custom/themes/codespaces.zsh-theme"

        # Add devcontainer .zshrc template
        if [ "${INSTALL_OH_MY_ZSH_CONFIG}" = "true" ]; then
            if ! [ -f "${template_path}" ] || ! grep -qF "$(head -n 1 "${template_path}")" "${user_rc_file}" 2>/dev/null; then
                echo -e "$(cat "${template_path}")\nzstyle ':omz:update' mode disabled" > ${user_rc_file}
            fi
            sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="devcontainers"/g' ${user_rc_file}
        fi

        # Copy to root / fix ownership
        if [ "${USERNAME}" != "root" ]; then
            copy_to_user_files=("${oh_my_install_dir}")
            [ -f "${user_rc_file}" ] && copy_to_user_files+=("${user_rc_file}")
            cp -rf "${copy_to_user_files[@]}" /root
            chown -R ${USERNAME}:${group_name} "${copy_to_user_files[@]}"
        fi
    fi
fi

# Ensure .config directory
user_config_dir="${user_home}/.config"
if [ ! -d "${user_config_dir}" ]; then
    mkdir -p "${user_config_dir}"
    chown ${USERNAME}:${group_name} "${user_config_dir}"
fi

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
mkdir -p /usr/local/bin
cp -f "${FEATURE_DIR}/bin/code" /usr/local/bin/
chmod +rx /usr/local/bin/code

cp -f "${FEATURE_DIR}/bin/devcontainer-info" /usr/local/bin/
chmod +rx /usr/local/bin/devcontainer-info

# ---------------------------------------------------------------------------
# Marker file
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    LOCALE_ALREADY_SET=${LOCALE_ALREADY_SET}\n\
    EXISTING_NON_ROOT_USER=${EXISTING_NON_ROOT_USER}\n\
    RC_SNIPPET_ALREADY_ADDED=${RC_SNIPPET_ALREADY_ADDED}\n\
    ZSH_ALREADY_INSTALLED=${ZSH_ALREADY_INSTALLED}" > "${MARKER_FILE}"

echo "Done!"
