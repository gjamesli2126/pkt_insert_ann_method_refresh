# Compile network-packet-classification on an M1 Mac

This builds the executable `m` from the same six source files listed in the
submodule's CMake files. The direct Apple Clang command supplies native macOS
flags and leaves the submodule unchanged.

## 1. Install prerequisites

Install Apple's command-line tools if `xcrun --find clang++` fails:

```sh
xcode-select --install
```

Finish the installer before compiling. See Apple's
[command-line tools instructions](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/).

Install native Apple Silicon [Homebrew](https://brew.sh/) if `brew` is missing,
then install the [OpenMP runtime](https://formulae.brew.sh/formula/libomp):

```sh
brew install libomp
```

Homebrew normally lives at `/opt/homebrew` on Apple Silicon. This guide discovers
the library path with `brew --prefix libomp`; use an ARM64 installation, not an
Intel Homebrew installation running under Rosetta. CMake and Homebrew LLVM/GCC
are not required for this build.

## 2. Compile

Run this block from the **parent repository**. Adapt the first path if needed:

```sh
cd ~/Documents/pkt_insert_ann_method_refresh
git submodule update --init --recursive
uname -m
xcrun clang++ --version

mkdir -p build_on_mac/build/network
MAC_LIBOMP_PREFIX="$(brew --prefix libomp)"

xcrun clang++ -arch arm64 -std=c++17 -O3 \
  -Xpreprocessor -fopenmp \
  -I"$MAC_LIBOMP_PREFIX/include" \
  -Inetwork-packet-classification/io \
  -Inetwork-packet-classification/lib \
  network-packet-classification/main.cpp \
  network-packet-classification/io/input.cpp \
  network-packet-classification/io/inputFile_test.cpp \
  network-packet-classification/lib/equivalentPri.cpp \
  network-packet-classification/lib/checkCovered_one.cpp \
  network-packet-classification/lib/hyperrectangleCoverChecker.cpp \
  -L"$MAC_LIBOMP_PREFIX/lib" \
  -Wl,-rpath,"$MAC_LIBOMP_PREFIX/lib" -lomp \
  -o build_on_mac/build/network/m

file build_on_mac/build/network/m
otool -L build_on_mac/build/network/m
```

`uname -m` should print `arm64`, `file` should show an ARM64 Mach-O executable,
and `otool` should list `libomp.dylib`. Re-run the compiler command after source
changes. The binary needs the installed OpenMP runtime when it runs.

## Why use these flags?

The checked-in CMake configuration unconditionally adds `-fpermissive`,
`-fopenmp`, `-gstabs`, and `-Wl,--stack=999999999999`. That combination is not
compatible with Apple Clang and the macOS linker. Simply running the README's
`cmake`/`make` commands does not fix those platform assumptions.

The command above uses C++17, passes OpenMP through Apple's frontend with
`-Xpreprocessor -fopenmp`, and explicitly supplies the runtime headers and
library. It uses the normal macOS stack size, which worked for the tested
default analysis mode. The embedded library search path avoids needing
`DYLD_LIBRARY_PATH`.

If `omp.h` is missing, check `brew --prefix libomp` and rerun the full block so
`MAC_LIBOMP_PREFIX` is set. Architecture mismatch errors usually mean the
OpenMP installation is Intel rather than ARM64.

## Run and verified configuration

Continue with [run_network-packet-classification.md](run_network-packet-classification.md).

Verified with submodule commit `7b3f1b9` (`analyDataset`), macOS 15.7.1 on ARM64,
Apple Clang 17.0.0, and Homebrew libomp 23.1.1. The executable compiled without
diagnostics and completed runs using both the bundled `acl1_1k` dataset and
newly generated ClassBench data. This verifies the current default `P15` mode;
the other compile-time analysis modes were not tested.

All build and run outputs in these guides are under the parent repository's
ignored `build_on_mac/build/`, `data/`, `INFO/`, and `logs/` directories.
