WARN=-Wall -Wextra -Wno-unused-function -Wno-unused-parameter

# native build, adjust -march= to match your platform
CC=cc
CFLAGS=-march=rv64gcv -O3 ${WARN} -DUSE_PERF_EVENT

# full cross compilation toolchain
#CC=riscv64-linux-gnu-gcc
#CFLAGS=-march=rv64gcv -O3 ${WARN}

# freestanding using any recent clang build
#CC=clang
#CFLAGS=--target=riscv64 -march=rv64gcv_zba_zbb_zbs -O3 ${WARN} -nostdlib -fno-builtin -ffreestanding
#CFLAGS=--target=riscv32 -march=rv32gc_zve32f_zba_zbb_zbs -O3 ${WARN} -nostdlib -fno-builtin -ffreestanding


# CFLAGS defines:
# -DUSE_PERF_EVENT:      use perf_event with kernel.perf_user_access=2
# -DUSE_PERF_EVENT_SLOW: use perf_event with kernel.perf_user_access=1 (slower)
# -DCUSTOM_HOST: define for a custom hosted enviroment and implement the
#                unimplemented functions under `#ifdef CUSTOM_HOST` in ./nolibc.h

