#!/bin/bash
set -e

source dev-container-features-test-lib

check "zsh installed" zsh --version
check "zsh is default shell" bash -c "grep '^vscode:' /etc/passwd | grep -q /bin/zsh"
check "oh-my-zsh installed" test -d /home/vscode/.oh-my-zsh

reportResults
