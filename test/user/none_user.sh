#!/bin/bash
set -e

source dev-container-features-test-lib
check "no extra user created" bash -c "! id -u vscode 2>/dev/null"

reportResults
