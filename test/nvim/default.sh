#!/bin/bash
set -e

source dev-container-features-test-lib

check "bob is installed" bash -lc "command -v bob"
check "nvim is installed" bash -lc "command -v nvim"
check "nvim config exists" test -f /home/vscode/.config/nvim/init.lua

reportResults
