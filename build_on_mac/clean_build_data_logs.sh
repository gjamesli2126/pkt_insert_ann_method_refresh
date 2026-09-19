#!/bin/sh
# Remove compiled binaries, generated datasets, and logs; keep INFO and guides.
# Paths are relative to this script, so it can be run from any working directory.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

rm -rf -- "$script_dir/build" "$script_dir/data" "$script_dir/logs"

printf 'Removed build/, data/, and logs/ under %s\n' "$script_dir"
