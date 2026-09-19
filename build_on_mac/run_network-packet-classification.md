# Run network-packet-classification on an M1 Mac

First follow [compile_network-packet-classification.md](compile_network-packet-classification.md).

## 1. Run the bundled small dataset

This example does not require generating ClassBench data. Run the complete
block, adapting the first path if your checkout is elsewhere:

```sh
cd ~/Documents/pkt_insert_ann_method_refresh
mkdir -p build_on_mac/INFO build_on_mac/logs
cd build_on_mac/build/network

OMP_NUM_THREADS=4 ./m \
  -r ../../../network-packet-classification/classbench_set/ipv4-ruleset/acl1_1k \
  -p ../../../network-packet-classification/classbench_set/ipv4-trace/acl1_1k_trace \
  -t > ../../logs/run_bundled.log 2>&1

cat ../../logs/run_bundled.log
ls -lh ../../INFO
```

The smoke run loaded **953 rules and 11,069 packets**, then printed `pSize_one`
and `pSize_max`. `OMP_NUM_THREADS=4` limits any enabled OpenMP regions to four
threads; the default `P15` analysis itself is serial.

The working directory is required: the code writes reports to `../../INFO`
relative to the process's current directory, not relative to the executable.
Running from `build_on_mac/build/network` directs them to `build_on_mac/INFO`.
Create that directory first; some output streams do not report open failures.

## 2. Run freshly generated ClassBench data

Generate the files using
[run_classbench-packet-classification.md](run_classbench-packet-classification.md),
then run this complete block:

```sh
cd ~/Documents/pkt_insert_ann_method_refresh
mkdir -p build_on_mac/INFO build_on_mac/logs
cd build_on_mac/build/network

OMP_NUM_THREADS=4 ./m \
  -r ../../data/acl1_1000.txt \
  -p ../../data/acl1_1000.txt_trace \
  -t > ../../logs/run_generated.log 2>&1

cat ../../logs/run_generated.log
ls -lh ../../INFO
```

The generated-data smoke run loaded **953 rules and 9,530 packets** and exited
successfully. Your generated rule count can vary. Check the printed counts
against `wc -l` for your input files.

## Arguments and outputs

| Argument | Meaning |
| --- | --- |
| `-r FILE` | Load a ClassBench IPv4 ruleset. |
| `-p FILE` | Load its packet trace. Use the seven-column format produced by this checkout. |
| `-t` | Write dumps of the loaded rules and packets. Put it after `-r` and `-p`, because options are processed in order. |

The current `analyDataset` source defines `P15` in `main.cpp`. It groups rules
whose source prefix length is at least 15 by their first 15 source-address bits
and writes `build_on_mac/INFO/Prefix15Uniq.txt`. With `-t`, it also writes
`loadRule5D_test.txt` and `loadPacket5D_test.txt` there. These dumps help inspect
input loading; `-t` is not a packet-classification correctness test.

This default build does not produce `EquivalentPri.txt`. The upstream
`EquivalentPri_plot.py` needs the separate `LAYER` analysis enabled and a new
build/run; it is not part of this tested workflow. The `-h` option currently
prints a placeholder banner, so use the argument table above.

The reports use fixed filenames and are overwritten on each run. For separate
experiments, copy `build_on_mac/INFO` to a named directory under the ignored
`build_on_mac/data/` before running again. All outputs here are ignored, and
the bundled sample data in the submodules remains unchanged.
