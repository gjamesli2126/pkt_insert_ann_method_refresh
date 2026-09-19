# pkt_insert_ann_method_refresh
This would required classbench-packet-classification &amp; network-packet-classification in the same dir.

This repo will only commit patches and apply on: https://github.com/JiaChangGit/classbench-packet-classification, https://github.com/JiaChangGit/network-packet-classification.
Becasue keeping 2 modfied folders inside this repo is stupid.
I should make the 2 folder as it is, and I'll track only the patch.
Or maybe using submodules?

## Build and run on an Apple Silicon Mac

- ClassBench: [compile](build_on_mac/compile_classbench-packet-classification.md) and [run](build_on_mac/run_classbench-packet-classification.md).
- Network packet classification: [compile](build_on_mac/compile_network-packet-classification.md) and [run](build_on_mac/run_network-packet-classification.md).

These guides keep binaries, generated datasets, and reports under ignored directories in `build_on_mac`.

After installing the prerequisites in the compile guides, build both projects
with the [Makefile](build_on_mac/Makefile):

```sh
cd build_on_mac
make -j4
```

The Makefile uses Apple Clang with `-std=c++26` for ARM64. It tracks source and
header changes for incremental builds. The tested Apple Clang 17.0.0 accepts
this flag; C++26 feature coverage still depends on the compiler. Use
`make classbench` or `make network` to build just one project. From the parent
repository, use `make -C build_on_mac -j4` instead.

### Clean generated files

From `build_on_mac`, choose a cleanup target:

| Command | Deletes | Keeps |
| --- | --- | --- |
| `make clean` | `build/`: executables, objects, dependency files | Data, logs, reports, guides |
| `make clean-data` | `data/` and `logs/` | Build, reports, guides |
| `make clean-all` | `build/`, `data/`, and `logs/` | Reports and guides |

All cleanup targets keep the submodule sources and `INFO/` reports. Run cleanup
and compilation as separate commands. After changing `CXX`, `CXXFLAGS`,
`CPPFLAGS`, `LDFLAGS`, `LDLIBS`, or `LIBOMP_PREFIX`, run `make clean` before
rebuilding. `make help` lists the targets.

The two broader cleanup targets call these scripts, which also work directly
from the parent repository:

```sh
# Delete generated datasets and logs; keep compiled binaries.
./build_on_mac/clean_data_logs.sh

# Delete compiled binaries, generated datasets, and logs.
./build_on_mac/clean_build_data_logs.sh
```

Both scripts remove the named directories under `build_on_mac`, including any
saved experiments in `data/`. They keep `INFO/` reports, the Markdown guides,
and both submodules. The scripts locate their own directory, so you can also
run them from inside `build_on_mac` with `./clean_data_logs.sh` or
`./clean_build_data_logs.sh`. Missing output directories are harmless.
Follow the compile/run guides to recreate the directories and outputs afterward.

### When are logs created?

The run guides save console output and errors using shell redirection:

```sh
command > path/to/file.log 2>&1
```

The shell creates or overwrites the log when the command starts, even if the
command fails or prints nothing. Its parent directory must already exist.
`>` saves normal output, and `2>&1` sends errors to the same file. Without this
redirection, output appears in the terminal.

| Log in `build_on_mac/logs/` | Created when |
| --- | --- |
| `generate_rules.log` | Running the documented `db_generator` command. |
| `generate_trace.log` | Running the documented `trace_generator` command. |
| `run_bundled.log` | Running `m` with the bundled sample data. |
| `run_generated.log` | Running `m` with newly generated data. |

The `compile_*.log` files from the initial build verification were created by
redirecting compiler output in the same way. The Makefile prints compiler
output directly to the terminal, so following the compile guides does not recreate
those logs. Files in `INFO/` are analysis reports written by the program itself.
