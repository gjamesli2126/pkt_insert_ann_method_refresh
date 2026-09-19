# Compile ClassBench on an M1 Mac

This builds the classic IPv4 `db_generator` and `trace_generator` used by the
network-packet-classification workflow. It compiles the checked-in sources with
Apple Clang and writes both executables outside the submodule. No source patches,
Rosetta, CMake, Ruby, or downloads of the original ClassBench sources are needed.

## 1. Prepare the tools and checkout

Install Apple's command-line tools if `xcrun --find clang++` fails:

```sh
xcode-select --install
```

Finish the installer before continuing. See Apple's
[command-line tools instructions](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/).

Open Terminal in the **parent repository**, the directory containing
`build_on_mac` and both submodules. For this checkout:

```sh
cd ~/Documents/pkt_insert_ann_method_refresh
git submodule update --init --recursive
uname -m
xcrun clang++ --version
```

`uname -m` should print `arm64`. Use a native Terminal session if it prints
`x86_64`. Adapt the `cd` path if you cloned elsewhere.

## 2. Compile both generators

Run this entire block from the parent repository:

```sh
mkdir -p build_on_mac/build/classbench

xcrun clang++ -arch arm64 -std=c++98 -O2 \
  classbench-packet-classification/db_generator/*.cc \
  -o build_on_mac/build/classbench/db_generator

xcrun clang++ -arch arm64 -std=c++98 -O2 \
  classbench-packet-classification/trace_generator/*.cc \
  -o build_on_mac/build/classbench/trace_generator

file build_on_mac/build/classbench/db_generator \
     build_on_mac/build/classbench/trace_generator
```

Both files should report `Mach-O 64-bit executable arm64`. Re-run the compile
commands after changing sources; these commands rebuild the whole executable.

The direct commands use C++98 for this legacy code and omit the trace makefile's
`-pg` profiling flag, which Apple Clang does not support on ARM64. The upstream
code emits warnings, including mismatched `new[]`/`delete` and writable string
literals; they did not prevent the tested builds and small runs from completing.

The separate `classbench-ng/` directory is a Ruby frontend with an upstream
download/patch build process. It is not needed for this classic IPv4 workflow;
the commands above do not build its IPv6/OpenFlow backend. Its default `make`
also assumes GNU tools such as `sed -i` and `date --rfc-3339`, so it is not a
drop-in macOS build command.

## 3. Run and verify

Continue with [run_classbench-packet-classification.md](run_classbench-packet-classification.md).

Verified with submodule commit `016c1fe`, macOS 15.7.1 on ARM64, and Apple Clang
17.0.0. Both generators compiled, and an ACL1 request for 1,000 rules produced
953 rules and a 9,530-packet trace in the smoke run. Generated counts can vary.

The parent `.gitignore` covers `build_on_mac/build/`, `data/`, `INFO/`, and
`logs/`. Parent ignore rules do not extend into Git submodules; keeping outputs
here leaves both submodules clean and preserves their tracked sample datasets.
