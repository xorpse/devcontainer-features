#!/bin/bash
set -e

source dev-container-features-test-lib

check "user devcontainer exists" id -u devcontainer
check "user uid is 1001" bash -c "test $(id -u devcontainer) -eq 1001"
check "user gid is 1001" bash -c "test $(id -g devcontainer) -eq 1001"
check "user has sudo" bash -c "cat /etc/sudoers.d/devcontainer | grep 'NOPASSWD:ALL'"

reportResults
