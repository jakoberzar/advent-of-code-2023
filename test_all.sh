#!/usr/bin/env bash
# Strict mode
set -euo pipefail
IFS=$'\n\t'

for i in $(find zig -type f -print); do
    echo "Testing $i"
    $(zig test $i)
    echo ""
done
