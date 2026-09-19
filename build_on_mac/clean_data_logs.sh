#!/bin/sh
# Remove generated datasets and logs; keep binaries, INFO reports, and guides.
# Paths are relative to this script, so it can be run from any working directory.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

rm -rf -- "$script_dir/data" "$script_dir/logs"

printf 'Removed data/ and logs/ under %s\n' "$script_dir"
