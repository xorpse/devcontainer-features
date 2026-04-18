#!/bin/bash
set -e

source dev-container-features-test-lib
check "user vscode exists" id -u vscode
check "user uid is 1000" bash -c "test $(id -u vscode) -eq 1000"
check "user gid is 1000" bash -c "test $(id -g vscode) -eq 1000"
check "user has sudo" bash -c "cat /etc/sudoers.d/vscode | grep 'NOPASSWD:ALL'"

reportResults
