#!/bin/bash
set -e

source dev-container-features-test-lib

check "coreutils installed" ls --version
check "findutils installed" find --version
check "gnu grep installed" grep --version
check "gnu sed installed" sed --version
check "gnu awk installed" awk --version
check "curl installed" curl --version
check "git installed" git --version
check "jq installed" jq --version
check "vim installed" vim --version
check "wget installed" wget --version
check "zsh installed" zsh --version
check "oh-my-zsh installed" test -d /home/vscode/.oh-my-zsh
check "zsh theme installed" test -f /home/vscode/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
check "bash is default shell" bash -c "grep '^vscode:' /etc/passwd | grep -q /bin/bash"
check "sudo works" sudo -n true
check "devcontainer-info exists" command -v devcontainer-info
check "marker file exists" test -f /usr/local/etc/dev-container-features/common

reportResults
