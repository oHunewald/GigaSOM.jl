# Benchmarks

Performance benchmarks for GigaSOM training, mapping and embedding. Every
change to the compute path should come with a benchmark run so it can be
compared with the previous stage.

## Running

From the repository root:

```sh
julia --project=benchmark -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
julia --project=benchmark benchmark/run.jl --label <name> [--suite quick|default|large] [--workers 1,8]
```

Results go to `benchmark/results/<name>.json`. Compare two runs with:

```sh
julia --project=benchmark benchmark/compare.jl 00-baseline <name>
```

## What is measured

The data is synthetic and cytometry-like: a mixture of 25 Gaussian
populations, generated from a fixed seed, so every run sees identical input.
For each case and worker count the harness records:

| Field | Meaning |
|---|---|
| `train_per_epoch_s` | `trainGigaSOM` wall time divided by the number of epochs |
| `map_s` | `mapToGigaSOM` wall time, fastest of 3 runs |
| `embed_s` | `embedGigaSOM` wall time, fastest of 3 runs |
| `quantization_error` | mean distance from each cell to its best-matching codebook vector after training |

The quantization error is a quality check. A faster implementation should
reproduce it to within floating-point noise. A switch to `Float32` may shift
it slightly, but not materially.

A small warm-up problem runs first for each worker count, so JIT compilation
is excluded from the timings. Workers are started with one thread each.

## Suites

| Suite | Cases (cells × markers, SOM size, epochs) |
|---|---|
| `quick` | 100k × 30, 10×10, 3 |
| `default` | 100k × 30, 10×10, 5; 1M × 40, 20×20, 5 |
| `large` | 1M × 40, 20×20, 5; 5M × 40, 32×32, 5 |

## Result history

Result files are numbered by stage (`00-baseline`, `01-...`) and committed,
so the history of the optimisation work stays in the repository.
