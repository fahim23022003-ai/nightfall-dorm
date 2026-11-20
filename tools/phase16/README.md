# Phase 16 native viewport benchmarks

`measure_dense_active.gd` takes a native desktop Godot viewport through
120 sampled fixed-duration game steps after 24 warm-up steps. It stages the
same V2 Mansion geometry, paid building purchases, defenses, wallet, door
and Hunter for each preset and commit. The 15-role roster is topped up with
real paid Decoy Beacons to reach 24, 40 or 60 legal structures in a single
room. Every building center is checked against the actual camera viewport.
This is a prepared dense siege, with actual combat and no human playthrough.

The room, progression and actor event digests use exact serialized gameplay
values. Two RGBA framebuffer digests and the final actual viewport PNG
document the view without requiring image readback inside sample timing.
Settings changes can legitimately change pixels. The comparison checks
gameplay and geometry precisely and reports pixel equality separately.

Run with rendering capacity exclusive to the native benchmark. Set the
same software renderer, CPU allocation, display mode and worker count
on both revisions. The host's dummy Xorg display may report that V-Sync
cannot be changed. Record the actual renderer and hardware with the report.

```sh
LP_NUM_THREADS=2 taskset -c 0-3 python tools/phase16/run_matrix.py \
  /absolute/candidate /absolute/results --reference-project /absolute/baseline --display :86
python tools/phase16/compare_matrix.py /absolute/results/before /absolute/results/after \
  --output /absolute/results/paired.json
```

For an immutable baseline, archive the exact revision to a scratch directory,
add the benchmark script under `tools/phase16`, and run a headless editor
import there. Write its full commit hash to `source-sha.txt`. Use a separate
scratch copy for CPU diagnostics, apply `profile_spans.py` to that copy, and
run the same benchmark. Span parents include their nested costs. Timing
comparisons use the uninstrumented runs.
