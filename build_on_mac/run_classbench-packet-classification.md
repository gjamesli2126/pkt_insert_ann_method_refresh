# Run ClassBench on an M1 Mac

First follow [compile_classbench-packet-classification.md](compile_classbench-packet-classification.md).
Run the commands below from the **parent repository**, not from the submodule:

```sh
cd ~/Documents/pkt_insert_ann_method_refresh
mkdir -p build_on_mac/data build_on_mac/logs
```

## 1. Generate a small IPv4 ruleset

```sh
build_on_mac/build/classbench/db_generator \
  -bc classbench-packet-classification/parameter_files/acl1_seed \
  1000 2 0.5 -0.1 build_on_mac/data/acl1_1000.txt \
  > build_on_mac/logs/generate_rules.log 2>&1

tail -n 10 build_on_mac/logs/generate_rules.log
wc -l build_on_mac/data/acl1_1000.txt
```

The arguments select address scaling (`-b`), a custom seed (`-c`), a target of
1,000 rules, smoothness `2`, address scope `0.5`, application/port scope `-0.1`,
and the output filename. Redundant rules are removed, so the actual rule count
can be lower than requested. The smoke run produced 953 rules.

Other included seeds are `acl2_seed` through `acl5_seed`, `fw1_seed` through
`fw5_seed`, and `ipc1_seed`/`ipc2_seed`. To try a larger set, change the count
and output filename together. Start with 1,000 rules before larger experiments.
The checked-in code has fixed capacities, including `MAXFILTERS=130000`; these
instructions do not establish safe operation for arbitrary sizes or seeds.

The upstream `run.sh` tries to set a Linux-style stack limit. The direct command
above does not need that change for the tested small run.

## 2. Generate the matching packet trace

```sh
build_on_mac/build/classbench/trace_generator \
  1 0 10 build_on_mac/data/acl1_1000.txt \
  > build_on_mac/logs/generate_trace.log 2>&1

cat build_on_mac/logs/generate_trace.log
wc -l build_on_mac/data/acl1_1000.txt \
      build_on_mac/data/acl1_1000.txt_trace
```

The arguments are Pareto parameters `a=1`, `b=0` (no burst locality), trace scale
`10`, and the input ruleset. The tool appends `_trace` to that input path. With
these parameters, the tested 953-rule set produced 9,530 packet rows. Positive
`b` values introduce bursts, which can overshoot the requested trace threshold.

This checkout produces seven tab-separated fields per packet: source address,
destination address, source port, destination port, protocol, flags, and the
generating filter index. Keep this format for the network program, which reads
the first five fields and skips the last two. The generating filter index is
not necessarily the highest-priority matching rule.

## 3. Use the data in the other submodule

Follow the generated-data example in
[run_network-packet-classification.md](run_network-packet-classification.md).
There is no need to copy files into either submodule.

The ruleset, trace, and logs are ignored by the parent `.gitignore`. Repeating
the commands overwrites these output files; choose a new filename and log path
to preserve an earlier experiment. If an output is missing or empty, inspect
its log before continuing.
