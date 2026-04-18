#!/bin/bash
set -e

source dev-container-features-test-lib

check "coreutils installed" ls --version
check "curl installed" curl --version
check "git installed" git --version
check "jq installed" jq --version
check "zsh not installed" bash -c "! command -v zsh"
check "no oh-my-zsh" bash -c "! test -d /home/vscode/.oh-my-zsh"
check "bash is default shell" bash -c "grep '^vscode:' /etc/passwd | grep -q /bin/bash"
check "marker file exists" test -f /usr/local/etc/dev-container-features/common

reportResults
