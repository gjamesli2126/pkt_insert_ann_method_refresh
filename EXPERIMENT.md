# Experiment summary: multi-probe grid

## What we tried

Take a grid-based approximate-nearest-neighbour algorithm
([MultiProbeANN](https://github.com/weiz345/MultiProbeANN)) and use it for
5-tuple packet classification instead.

It works, and the result is **exact** — it always returns the same rule a
full linear scan would. Nothing approximate is left.

## How

Four changes to the original:

- **Sparse, not dense.** A dense 5-D grid needs `splits^5` cells (33M at 32
  splits). Only cells that actually hold rules are stored, in a hash map.
- **Boxes, not points.** A rule is a 5-D rectangle, so each rule is copied
  into every cell it overlaps. That copying is what makes it exact: the
  packet's own cell must contain every rule that matches it.
- **One shift per rule, not one grid.** Wildcards break a single grid
  (`fw1_100k` wildcards 78% of source ports). Each rule instead picks a
  coarseness per field until it fits in at most 4 cells. Rules with matching
  settings share a grid; a packet checks one cell in each grid.
- **PCA dropped.** It mixes 32-bit IPs with an 8-bit protocol, and tilted
  boxes no longer line up with cells.

## Results

Apple Silicon, `clang -O2 -std=c++26 -arch arm64`, single threaded, bundled
ClassBench sets.

| | acl1_1k | acl1_100k | fw1_100k |
| --- | --- | --- | --- |
| rules | 953 | 99,833 | 96,376 |
| build time | 0.34 ms | 14.2 ms | 13.4 ms |
| grids checked per packet | 14 | 16 | 23 |
| rule copies | 1.031x | 1.017x | 1.003x |
| index size | 0.07 MiB | 8.69 MiB | 8.02 MiB |
| throughput | 5.06 Mpps | 14.63 Mpps | 4.00 Mpps |
| latency | 198 ns | 68 ns | 250 ns |
| wrong answers | 0 | 0 | 0 |

Updates at 100k rules: about 0.45 ms to insert, 0.4 ms to remove, no rebuild.

`acl1_1k` throughput is not comparable — the trace is too small.

## What we learned

- **Almost no duplication.** Rule copies stay at 1.0x–1.03x. This was the main
  risk going in, and it did not happen.
- **Fewer grids beats finer grids.** Splitting more finely doubled the grid
  count and the copying, and the number of rules actually examined barely
  moved. Every extra grid costs a lookup on every packet.
- **Except for the tail.** The finer setting cut `fw1_100k`'s worst case from
  184 rules examined to 75. Worth switching to if p99 latency matters more
  than average throughput.
- **`fw1` is the hard case.** Its wildcards push rules into coarse, crowded
  grids — biggest cell holds 94 rules against acl1's 13. Hence 4.0 Mpps
  versus 14.6.
- **The test suite earned its keep.** It caught a real bug: a wildcard rule's
  width computed as `0xFFFFFFFF - 0 + 1`, which overflows to zero in 32 bits.
  The rule was filed into no cells at all and silently never matched. Width
  arithmetic is 64-bit now.

## Reproducing

```sh
make -C build_on_mac        # build
make -C build_on_mac test   # 250 correctness checks
```

Numbers come from the `ANN_GRID` block in
`network-packet-classification/main.cpp`. Full design notes:
[docs/multiProbeGrid.md](network-packet-classification/docs/multiProbeGrid.md).
