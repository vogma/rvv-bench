#include <stddef.h>

static const size_t varint_sizes[] = {
    1024, 2048, 4096, 8192, 16384, 32768, 65536,
    131072, 262144, 524288, 1048576, 2097152, 4194304
};
#define VARINT_NUM_SIZES (sizeof(varint_sizes) / sizeof(varint_sizes[0]))

static inline size_t varint_next_size(size_t c) {
    for (size_t i = 0; i < VARINT_NUM_SIZES; ++i) {
        if (varint_sizes[i] > c)
            return varint_sizes[i];
    }
    return varint_sizes[VARINT_NUM_SIZES - 1] + 1; /* end iteration */
}

#define BENCH_NEXT(c) varint_next_size(c)
#include "bench.h"

#ifdef __riscv_vector
#include <riscv_vector.h>
#endif

// source https://chromium.googlesource.com/external/github.com/google/protobuf/%2B/refs/heads/master/src/google/protobuf/io/coded_stream.cc#366
inline __attribute__((always_inline)) size_t ReadVarint32FromArray(const uint8_t *buffer, uint32_t *value)
{
    size_t bytes_processed = 0;
    const uint8_t *ptr = buffer;
    uint32_t first = *ptr++;

    if (first < 128)
    {
        *value = first;
        return 1;
    }

    uint32_t b;
    uint32_t result = first - 0x80;

    b = *ptr++;
    result += b << 7;
    if (!(b & 0x80))
    {
        bytes_processed = 2;
        goto done;
    }
    result -= 0x80 << 7;
    b = *ptr++;
    result += b << 14;
    if (!(b & 0x80))
    {
        bytes_processed = 3;
        goto done;
    }
    result -= 0x80 << 14;
    b = *ptr++;
    result += b << 21;
    if (!(b & 0x80))
    {
        bytes_processed = 4;
        goto done;
    }
    result -= 0x80 << 21;
    b = *ptr++;
    result += b << 28;
    if (!(b & 0x80))
    {
        bytes_processed = 5;
        goto done;
    }
done:
    *value = result;
    return bytes_processed;
}

size_t varint_decode_scalar(const uint8_t *input, size_t length, uint32_t *output)
{
    uint32_t *out = output;
    while (length > 0)
    {
        // size_t bytes_processed = read_int(input, output);
        size_t bytes_processed = ReadVarint32FromArray(input, out);

        // printf("length: %d out: %u\n", length, output);

        length -= bytes_processed;
        input += bytes_processed;
        out++;
    }
    return out - output;
}

/**
 * Number of varints that will be processed in the current loop iteration.
 */
static inline __attribute__((always_inline)) uint8_t getNumberOfVarints(vbool8_t varint_mask, size_t vl)
{
    return __riscv_vcpop_m_b8(varint_mask, vl);
}

/**
 * input: uint8_t pointer to the start of the compressed varints
 * output: decompressed 32-bit integers
 * length: size of the varints in bytes
 * returns: size_t number of decompressed integers
 */
size_t varint_decode_rvv(const uint8_t *input, size_t length, uint32_t *output)
{
    size_t processed = 0;

    size_t vl;

    while (length > 0)
    {
        vl = __riscv_vsetvl_e8m1(length);

        vuint8m1_t data_vec_u8 = __riscv_vle8_v_u8m1(input, vl);

        vbool8_t termination_mask = __riscv_vmsge_vx_i8m1_b8(__riscv_vreinterpret_v_u8m1_i8m1(data_vec_u8), 0, vl);

        uint8_t number_of_varints = getNumberOfVarints(termination_mask, vl);

        // fast path. no continuation bits set
        if (number_of_varints == vl)
        {
            // expand every byte to 32-bit lane and save to memory
            __riscv_vse32_v_u32m4(output, __riscv_vzext_vf4_u32m4(data_vec_u8, vl), vl);
            input += vl;
            length -= vl;
            output += vl;
            processed += vl;
        }
        else
        {

            // inspired by https://github.com/camel-cdr/rvv-bench/blob/main/vector-utf/8toN_gather.c
            vuint8m1_t v1 = __riscv_vslide1down_vx_u8m1(data_vec_u8, 0, vl);
            vuint8m1_t v2 = __riscv_vslide1down_vx_u8m1(v1, 0, vl);
            vuint8m1_t v3 = __riscv_vslide1down_vx_u8m1(v2, 0, vl);
            vuint8m1_t v4 = __riscv_vslide1down_vx_u8m1(v3, 0, vl);

            // every byte after a termination byte is as first byte
            vuint8m1_t v_prev = __riscv_vslide1up(data_vec_u8, 0, vl);
            vbool8_t m_first_bytes = __riscv_vmsleu_vx_u8m1_b8(v_prev, 0x7F, vl);

            // compress the slided input data vectors with the first_byte mask. That way we get the second, third, fourth and fifth byte after each first byte.
            vuint8m1_t first_bytes = __riscv_vcompress_vm_u8m1(data_vec_u8, m_first_bytes, vl);
            vuint8m1_t second_bytes = __riscv_vcompress_vm_u8m1(v1, m_first_bytes, vl);
            vuint8m1_t third_bytes = __riscv_vcompress_vm_u8m1(v2, m_first_bytes, vl);
            vuint8m1_t fourth_bytes = __riscv_vcompress_vm_u8m1(v3, m_first_bytes, vl);
            vuint8m1_t fifth_bytes = __riscv_vcompress_vm_u8m1(v4, m_first_bytes, vl);

            vbool8_t m_second_bytes = __riscv_vmsgtu_vx_u8m1_b8(first_bytes, 0x7F, vl);
            vbool8_t m_third_bytes = __riscv_vmand_mm_b8(m_second_bytes, __riscv_vmsgtu_vx_u8m1_b8(second_bytes, 0x7F, vl), vl);
            vbool8_t m_fourth_bytes = __riscv_vmand_mm_b8(m_third_bytes, __riscv_vmsgtu_vx_u8m1_b8(third_bytes, 0x7F, vl), vl);
            vbool8_t m_fifth_bytes = __riscv_vmand_mm_b8(m_fourth_bytes, __riscv_vmsgtu_vx_u8m1_b8(fourth_bytes, 0x7F, vl), vl);

            // Compute byte counts for each varint length (reused for early-exit checks)
            // Use number_of_varints as vl to exclude any incomplete varint at the end
            size_t count2 = __riscv_vcpop_m_b8(m_second_bytes, number_of_varints);

            // Total bytes = sum of bytes per varint
            size_t number_of_bytes = number_of_varints + count2;

            // remove continuation bits (bit 7) from payload bytes
            vuint8m1_t b1 = __riscv_vand_vx_u8m1(first_bytes, 0x7F, number_of_varints);
            vuint8m1_t b2 = __riscv_vand_vx_u8m1(second_bytes, 0x7F, number_of_varints);

            // Build result in 32-bit
            // b1: bits 0-6
            vuint32m4_t result32 = __riscv_vzext_vf4_u32m4(b1, number_of_varints);

            // b2: bits 7-13 (shift by 7)
            result32 = __riscv_vadd_vv_u32m4_mu(m_second_bytes, result32, result32,
                                                __riscv_vsll_vx_u32m4(__riscv_vzext_vf4_u32m4(b2, number_of_varints), 7, number_of_varints),
                                                number_of_varints);

            size_t count3 = __riscv_vcpop_m_b8(m_third_bytes, number_of_varints);
            // Only process 3+ byte varints if any exist
            if (count3 > 0)
            {
                number_of_bytes += count3;
                vuint8m1_t b3 = __riscv_vand_vx_u8m1(third_bytes, 0x7F, number_of_varints);

                // b3: bits 14-20 (shift by 14)
                result32 = __riscv_vadd_vv_u32m4_mu(m_third_bytes, result32, result32,
                                                    __riscv_vsll_vx_u32m4(__riscv_vzext_vf4_u32m4(b3, number_of_varints), 14, number_of_varints),
                                                    number_of_varints);

                size_t count4 = __riscv_vcpop_m_b8(m_fourth_bytes, number_of_varints);
                // Only process 4+ byte varints if any exist
                if (count4 > 0)
                {
                    number_of_bytes += count4;
                    vuint8m1_t b4 = __riscv_vand_vx_u8m1(fourth_bytes, 0x7F, number_of_varints);

                    // b4: bits 21-27 (shift by 21)
                    result32 = __riscv_vadd_vv_u32m4_mu(m_fourth_bytes, result32, result32,
                                                        __riscv_vsll_vx_u32m4(__riscv_vzext_vf4_u32m4(b4, number_of_varints), 21, number_of_varints),
                                                        number_of_varints);

                    size_t count5 = __riscv_vcpop_m_b8(m_fifth_bytes, number_of_varints);
                    // Only process 5 byte varints if any exist
                    if (count5 > 0)
                    {
                        number_of_bytes += count5;
                        vuint8m1_t b5 = __riscv_vand_vx_u8m1(fifth_bytes, 0x7F, number_of_varints);

                        // b5: bits 28-31 (shift by 28)
                        result32 = __riscv_vadd_vv_u32m4_mu(m_fifth_bytes, result32, result32,
                                                            __riscv_vsll_vx_u32m4(__riscv_vzext_vf4_u32m4(b5, number_of_varints), 28, number_of_varints),
                                                            number_of_varints);
                    }
                }
            }

            // Store decoded varints
            __riscv_vse32_v_u32m4(output, result32, number_of_varints);

            // loop bookkeeping
            input += number_of_bytes;
            length -= number_of_bytes;
            output += number_of_varints;
            processed += number_of_varints;
        }
    }
    return processed;
}


#define IMPLS(f) \
    f(scalar) \
    f(rvv)

typedef size_t Func(const uint8_t *input, size_t length, uint32_t *output);

#define DECLARE(f) extern Func varint_decode_##f;
IMPLS(DECLARE)

#define EXTRACT(f) { #f, &varint_decode_##f, 0 },
Impl impls[] = { IMPLS(EXTRACT) };

/* Global state */
uint32_t *dest;
uint8_t *srcv;
size_t last_count;

size_t vbyte_encode(const uint32_t *in, size_t length, uint8_t *bout)
{
    uint8_t *initbout = bout;
    for (size_t k = 0; k < length; ++k)
    {
        const uint32_t val = in[k];

        if (val < (1U << 7))
        {
            *bout = val & 0x7F;
            ++bout;
        }
        else if (val < (1U << 14))
        {
            *bout = (uint8_t)((val & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(val >> 7);
            ++bout;
        }
        else if (val < (1U << 21))
        {
            *bout = (uint8_t)((val & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(((val >> 7) & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(val >> 14);
            ++bout;
        }
        else if (val < (1U << 28))
        {
            *bout = (uint8_t)((val & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(((val >> 7) & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(((val >> 14) & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(val >> 21);
            ++bout;
        }
        else
        {
            *bout = (uint8_t)((val & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(((val >> 7) & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(((val >> 14) & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(((val >> 21) & 0x7F) | (1U << 7));
            ++bout;
            *bout = (uint8_t)(val >> 28);
            ++bout;
        }
    }
    return bout - initbout;
}

/* Random helper that respects an upper bound */
static inline uint32_t rand_in_range(uint32_t low, uint32_t high_exclusive)
{
    return low + (uint32_t)(bench_urand() % (high_exclusive - low));
}

/* Generate a value that will encode to exactly len bytes */
static inline uint32_t random_value_for_length(uint8_t len)
{
    switch (len)
    {
    case 1:
        return (uint32_t)(bench_urand() & 0x7F);
    case 2:
        return rand_in_range(1u << 7, 1u << 14);
    case 3:
        return rand_in_range(1u << 14, 1u << 21);
    case 4:
        return rand_in_range(1u << 21, 1u << 28);
    default: /* len == 5 */
        return ((uint32_t)bench_urand()) | (1u << 28);
    }
}

/* Pick a varint length according to the (possibly truncated) distribution */
static inline uint8_t pick_length(uint8_t max_len, const int weights[5])
{
    int total = 0;
    for (uint8_t i = 0; i < max_len; ++i)
        total += weights[i];

    uint32_t r = (uint32_t)(bench_urand() % total);
    int acc = 0;
    for (uint8_t i = 0; i < max_len; ++i)
    {
        acc += weights[i];
        if (r < (uint32_t)acc)
            return (uint8_t)(i + 1);
    }
    return max_len;
}

/* Generate valid, randomly ordered varint test data with a configurable length distribution. */
void init(void)
{
    /* Tune these percentages as desired; they must sum to 100. */
    const int dist_1byte = 40;
    const int dist_2byte = 25;
    const int dist_3byte = 15;
    const int dist_4byte = 10;
    const int dist_5byte = 10;
    const int weights[5] = {dist_1byte, dist_2byte, dist_3byte, dist_4byte, dist_5byte};

    uint8_t *p = mem;
    uint8_t *end = mem + MAX_MEM / 8;
    const size_t max_bytes = (size_t)(end - mem);

    /* Ensure every benchmarked prefix ends on a varint boundary. */
    size_t stop_idx = 0;
    size_t next_stop = varint_sizes[0];

    while (p < end)
    {
        size_t offset = (size_t)(p - mem);

        /* Advance to the next benchmark length if we've reached/passed it. */
        while (offset >= next_stop && stop_idx < VARINT_NUM_SIZES - 1) {
            ++stop_idx;
            next_stop = varint_sizes[stop_idx];
        }

        size_t space_to_end = (size_t)(end - p);
        size_t space_to_stop = (next_stop > offset && next_stop <= max_bytes) ? (next_stop - offset) : space_to_end;

        /* Limit the candidate length so we never cross a benchmark stop or the buffer end. */
        size_t max_len = 5;
        if (space_to_end < max_len)
            max_len = space_to_end;
        if (space_to_stop < max_len)
            max_len = space_to_stop;

        if (max_len == 0)
            break;

        uint8_t len = pick_length((uint8_t)max_len, weights);
        uint32_t value = random_value_for_length(len);

        size_t written = vbyte_encode(&value, 1, p);
        p += written;
    }
}

/* Checksum for validation */
ux checksum(size_t n) {
    ux sum = last_count;
    for (size_t i = 0; i < last_count && i < 1024; ++i)
        sum = uhash(sum) + dest[i];
    return sum;
}

/* Benchmark function */
BENCH_BEG(base) {
    srcv = mem;
    dest = (uint32_t*)(mem + MAX_MEM/8);  /* output after input region */
    TIME last_count = f(srcv, n, dest);
} BENCH_END

/* Register benchmark. N must be > largest size to include all test sizes. */
Bench benches[] = {
    BENCH(impls, varint_sizes[VARINT_NUM_SIZES - 1] + 1, "varint decode", bench_base),
}; BENCH_MAIN(benches)
