#!/bin/sh
# used by `make run` to run executables

# native execution
./$@

# emulation with qemu
#qemu-riscv64-static -cpu rv64,b=on,v=on,vlen=256,rvv_ta_all_1s=on,rvv_ma_all_1s=on $@
#qemu-riscv32-static -cpu rv32,zve32f=on,vext_spec=v1.0,vlen=256,rvv_ta_all_1s=on,rvv_ma_all_1s=on,zfh=true,zvfh=true $@
