# Compile network-packet-classification on an M1 Mac

This builds the executable `m` from the same six source files listed in the
submodule's CMake files. `build_on_mac/Makefile` supplies native macOS flags,
uses Apple Clang in C++26 mode, and leaves the submodule unchanged.

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

Homebrew normally lives at `/opt/homebrew` on Apple Silicon. The Makefile discovers
the library path with `brew --prefix libomp`; use an ARM64 installation, not an
Intel Homebrew installation running under Rosetta. CMake and Homebrew LLVM/GCC
are not required for this build.

The compiler must accept `-std=c++26`; Apple Clang 17.0.0 on this Mac does.
If your compiler rejects that option, update Xcode/its command-line tools or
select a compatible Clang with `make CXX=/path/to/clang++`.

## 2. Compile

Run this block from the **parent repository**. Adapt the first path if needed:

```sh
cd ~/Documents/pkt_insert_ann_method_refresh
git submodule update --init --recursive
uname -m
xcrun clang++ --version

make -C build_on_mac -j4 network

file build_on_mac/build/network/m
otool -L build_on_mac/build/network/m
```

`uname -m` should print `arm64`, `file` should show an ARM64 Mach-O executable,
and `otool` should list `libomp.dylib`. Re-run `make` after source changes;
it tracks objects and header dependencies and recompiles only affected files.
Run `make -C build_on_mac -j4` without a target to build both projects.
The binary needs the installed OpenMP runtime when it runs.

## Why use these flags?

The checked-in CMake configuration unconditionally adds `-fpermissive`,
`-fopenmp`, `-gstabs`, and `-Wl,--stack=999999999999`. That combination is not
compatible with Apple Clang and the macOS linker. Simply running the README's
`cmake`/`make` commands does not fix those platform assumptions.

The Makefile uses `-arch arm64 -std=c++26 -O2`, passes OpenMP through Apple's frontend with
`-Xpreprocessor -fopenmp`, and explicitly supplies the runtime headers and
library. It uses the normal macOS stack size, which worked for the tested
default analysis mode. The embedded library search path avoids needing
`DYLD_LIBRARY_PATH`.

C++26 mode enables the compiler's implemented features; it does not guarantee
complete C++26 support. See [Clang's implementation status](https://clang.llvm.org/cxx_status.html).

If `omp.h` is missing, check `brew --prefix libomp`. For a custom installation,
pass `LIBOMP_PREFIX=/path/to/libomp` to `make`. Architecture mismatch errors usually mean the
OpenMP installation is Intel rather than ARM64.

## Run and verified configuration

Continue with [run_network-packet-classification.md](run_network-packet-classification.md).

Verified with submodule commit `7b3f1b9` (`analyDataset`), macOS 15.7.1 on ARM64,
Apple Clang 17.0.0 with `-std=c++26`, and Homebrew libomp 23.1.1. The executable compiled without
diagnostics and completed runs using both the bundled `acl1_1k` dataset and
newly generated ClassBench data. This verifies the current default `P15` mode;
the other compile-time analysis modes were not tested.

All build and run outputs in these guides are under the parent repository's
ignored `build_on_mac/build/`, `data/`, `INFO/`, and `logs/` directories.

## Clean and rebuild

From `build_on_mac`, use `make clean` to delete binaries, objects, and dependency
files, then `make -j4 network` to rebuild. `make clean-data` deletes `data/`
and `logs/`; `make clean-all` deletes `build/`, `data/`, and `logs/`. All three
keep the guides, submodules, and `INFO/` reports. Run cleanup and build as
separate commands, not together in one parallel `make` invocation.

If you change compiler/flag variables such as `CXX`, `CXXFLAGS`, or
`LIBOMP_PREFIX`, clean before rebuilding. Run `make help` for the available
targets. Compiler output appears in the terminal unless redirected to a log.
