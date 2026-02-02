.POSIX:
.SUFFIXES:
.SUFFIXES: .c

include ../config.mk

EXECS=memcpy memset memreverse utf8_count strlen mergelines mandelbrot chacha20 poly1305 ascii_to_utf16 ascii_to_utf32 byteswap LUT4 LUT6 hist base64_encode trans8x8e8 trans8x8e16 varint_decode

all: ${EXECS}

memcpy: memcpy.S
memset: memset.S
memreverse: memreverse.S
utf8_count: utf8_count.S
strlen: strlen.S
mergelines: mergelines.S
mandelbrot: mandelbrot.S
chacha20: chacha20.S
poly1305: poly1305.S
ascii_to_utf16: ascii_to_utf16.S
ascii_to_utf32: ascii_to_utf32.S
byteswap: byteswap.S
LUT4: LUT4.S
LUT6: LUT6.S
hist: hist.S
base64_encode: base64_encode.S
trans8x8e8: trans8x8e8.S
trans8x8e16: trans8x8e16.S

${EXECS}: config.h bench.h template.S ../config.mk

.c:
	${CC} ${CFLAGS} -o $@ $< -DINC=$@.S template.S

varint_decode: varint_decode.c
	${CC} ${CFLAGS} -o $@ $<

clean:
	rm -f ${EXECS}

run: all
	for i in ${EXECS}; do ../run.sh ./$$i || { printf "\n\n\033[0;31mFAILED\033[0m\n\n"; exit 1; } ; done



