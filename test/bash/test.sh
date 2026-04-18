#!/bin/bash
set -e

source dev-container-features-test-lib
check "bash is installed" bash --version

reportResults
