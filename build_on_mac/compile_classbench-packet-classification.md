# Compile ClassBench on an M1 Mac

This builds the classic IPv4 `db_generator` and `trace_generator` used by the
network-packet-classification workflow. It compiles the checked-in sources with
Apple Clang in C++26 mode through `build_on_mac/Makefile` and writes both
executables outside the submodule. The warning fixes are made directly in the
ClassBench submodule sources. Rosetta, CMake, Ruby, and downloads of the original
ClassBench sources are not needed.

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

The compiler must accept `-std=c++26`; Apple Clang 17.0.0 on this Mac does.
If your compiler rejects that option, update Xcode/its command-line tools or
select a compatible Clang with `make CXX=/path/to/clang++`.

## 2. Compile both generators

Run this entire block from the parent repository:

```sh
make -C build_on_mac -j4 classbench

file build_on_mac/build/classbench/db_generator \
     build_on_mac/build/classbench/trace_generator
```

Both files should report `Mach-O 64-bit executable arm64`. Re-run `make` after
changing sources. Object files and header dependencies are stored under
`build_on_mac/build/`, so unchanged files do not need recompiling. Run
`make -C build_on_mac -j4` without a target to build both projects; that also
requires the network project's OpenMP dependency.

The Makefile uses `-arch arm64 -std=c++26 -O2` and omits the trace makefile's
unsupported `-pg` flag. C++26 mode enables the compiler's implemented features;
it does not guarantee complete C++26 support (see
[Clang's implementation status](https://clang.llvm.org/cxx_status.html)).
The ClassBench source fixes correct array deallocation, make diagnostic message
parameters `const char*`, explicitly test the command-line option terminator,
and read all 33 source-prefix entries in a full prefix-distribution row.
The trace parser now uses an automatic buffer that is released on early return.
No warning-suppression flags are used.

The separate `classbench-ng/` directory is a Ruby frontend with an upstream
download/patch build process. It is not needed for this classic IPv4 workflow;
the commands above do not build its IPv6/OpenFlow backend. Its default `make`
also assumes GNU tools such as `sed -i` and `date --rfc-3339`, so it is not a
drop-in macOS build command.

## 3. Run and verify

Continue with [run_classbench-packet-classification.md](run_classbench-packet-classification.md).

Verified against submodule base commit `016c1fe` plus the local source fixes,
macOS 15.7.1 on ARM64, and Apple Clang 17.0.0 with `-std=c++26`. Both projects
rebuilt with `-Werror` and no diagnostics under the current build flags. ACL1,
FW1, and IPC1 generation and network analysis passed, with sampled packets
checked against their generating rules. Generated counts can vary.

To repeat the warning check and focused memory/parser regressions from the
parent repository:

```sh
make -C build_on_mac -B -j4 CXXFLAGS='-O2 -Werror'
sh classbench-packet-classification/tests/run_warning_regressions.sh
```

The regression script uses AddressSanitizer and UndefinedBehaviorSanitizer.
See [the test README](../classbench-packet-classification/tests/README.md) for
coverage. This checks the reported warning causes, not every legacy code path.

The parent `.gitignore` covers `build_on_mac/build/`, `data/`, `INFO/`, and
`logs/`. Parent ignore rules do not extend into Git submodules; keeping outputs
here keeps generated files out of submodule status and preserves tracked sample
datasets. Source fixes inside a submodule must be committed in that submodule;
then the parent repository can commit the updated submodule reference.

## Clean and rebuild

From `build_on_mac`, use `make clean` to delete binaries, objects, and dependency
files, then `make -j4 classbench` to rebuild. `make clean-data` deletes `data/`
and `logs/`; `make clean-all` deletes `build/`, `data/`, and `logs/`. All three
keep the guides, submodules, and `INFO/` reports. Run cleanup and build as
separate commands, not together in one parallel `make` invocation.

If you change compiler/flag variables such as `CXX` or `CXXFLAGS`, clean before
rebuilding. Run `make help` for the available targets. Compiler output appears
in the terminal unless you redirect it to a log.
