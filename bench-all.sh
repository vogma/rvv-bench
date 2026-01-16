#!/bin/sh

perf_user_access=$(cat /proc/sys/kernel/perf_user_access)

if [ "x$perf_user_access" != "x2" ]
then
	echo "kernel.perf_user_access=$perf_user_access, should be 2"
	echo "Please manually execute: sudo sysctl kernel.perf_user_access=2"
	printf 'Press Enter to continue...'; read dummy; echo
fi

perf_event_paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
if [ "$perf_event_paranoid" -gt "2" ]
then
	echo "kernel.perf_event_paranoid=$perf_event_paranoid, should be <=2"
	echo "Please manually execute: sudo sysctl kernel.perf_event_paranoid=2"
	printf 'Press Enter to continue...'; read dummy; echo
fi

echo "Please configure config.mk and run.sh for your environment."
echo "The instructions are in the files."
printf 'Press Enter to start the benchmarks...'; read dummy; echo

mkdir out
make -C bench run -j$(nproc) | tee out/bench.log
make -C instructions/rvv run | tee out/rvv.log
make -C instructions/scalar run  | tee out/scalar.log
make -C single uarch && ./run.sh ./single/uarch | tee out/uarch.log
make -C single veclibm && ./run.sh ./single/veclibm | tee out/veclibm.log

printf "\n\nBenchmarks complete, output is saved in ./out/*.log\n"
