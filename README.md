# RISC-V Vector benchmark

A collection of RISC-V Vector (RVV) benchmarks to help developers write portably performant RVV code.

Benchmark results can be found at: https://camel-cdr.github.io/rvv-bench-results

## Benchmarks ([./bench/](./bench/))

Contains a bunch of benchmark of different implementations of certain algorithms.

## Instruction cycle count ([./instructions/](./instructions/))

Measures the cycle count of RVV instructions by unrolling and looping over the given instruction repeatedly.

## Quick start

**The easiest way to run the benchmarks is using the `./bench-all.sh` script.**

## Getting started for developers

Start by configuring [./config.mk](./config.mk) and [./run.sh](./run.sh).

To get access to the cycle performance counter on Linux, `/proc/sys/kernel/perf_user_access` and `/proc/sys/kernel/perf_event_paranoid` need to be configured.

`perf_event_paranoid` should have a value <=2.

`perf_user_access` should be set to "2" and `-DUSE_PERF_EVENT` appended to the `CFLAGS` in [./config.mk](./config.mk). If this doesn't work, set `perf_user_access` to "1" and use `-DUSE_PERF_EVENT_SLOW`.

You can adjust the benchmark runtime and precision by modifying the config.h files in each directory.

### Running benchmarks ([./bench/](./bench/))

To run the benchmarks, first look through ([./bench/config.h](./bench/config.h)) and adjust it to your processor (e.g. set `HAS_E64`). If it takes too long to execute, try lowering `MAX_MEM`, which is used to scale the benchmark, and play around with the other constants until it executes in a reasonable amount of time and gives a relatively smooth graph.

Now you can just run the benchmarks using `make run` in the ([./bench/](./bench/)) directory, or `make` to just build the executables.

### Measuring cycle count ([./instructions/](./instructions/))

To run the cycle count measurement, first configure [instructions/rvv/config.h](instructions/rvv/config.h) to your processor.

Now you can run the measurement using `make run` in the ([./instructions/rvv/](./instructions/rvv/)) directory, or `make` to just build the executables.

For XTheadVector use the ([./instructions/xtheadvector/](./instructions/xtheadvector/)) directory instead. (this isn't maintained anymore)

## Contributing

Here are some suggestions of things that still need to be done.

* contribute a measurement of a new CPU to: https://github.com/camel-cdr/rvv-bench-results \
  You can just create an issue with a single json file, which contains all concatenated [./bench/](./bench/) results. (after proper setup, `make run > out.json` should do the trick). \
* implement non memory bound benchmarks
* implement more benchmarks
* better cycle count measurements: throughput vs latency (also: can we figure out the execution port configuration?)
* cycle count for load/stores
* cycle count for vsetvl

## License

This repository is licensed under the MIT [LICENSE](LICENSE).

