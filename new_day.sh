#!/usr/bin/env bash
# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Variables
DAY_NAME=$1
INPUT_DAY_FOLDER="inputs/day-$DAY_NAME"
ZIG_FOLDER="zig"

# Make input files
mkdir "$INPUT_DAY_FOLDER"
touch "$INPUT_DAY_FOLDER/simple.txt"
touch "$INPUT_DAY_FOLDER/full.txt"
echo "Input files created"

# Make Zig files
cp "$ZIG_FOLDER/day01.zig" "$ZIG_FOLDER/day$DAY_NAME.zig"
# cp "$ZIG_FOLDER/day-boilerplate.zig" "$ZIG_FOLDER/Day$DAY_NAME.zig"
# touch "$ZIG_FOLDER/Day$DAY_NAME.zig"
echo "Zig files created"
