#!/bin/bash
set -e

source dev-container-features-test-lib

check "user testuser exists" id -u testuser
check "user uid is 1002" bash -c "test $(id -u testuser) -eq 1002"
check "user gid is 1002" bash -c "test $(id -g testuser) -eq 1002"
check "sudoers file does not exist" bash -c "! test -f /etc/sudoers.d/testuser"

reportResults
