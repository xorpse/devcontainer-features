#!/bin/sh
set -e

if ! command -v bash >/dev/null 2>&1; then
    apk add --no-cache bash
fi
