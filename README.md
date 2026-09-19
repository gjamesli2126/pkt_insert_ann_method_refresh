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
