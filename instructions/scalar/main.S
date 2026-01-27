#include "config.h"

#define t7 s3
#define t8 s4
#define t9 s5

#define ft7 fs3
#define ft8 fs4
#define ft9 fs5

#if __riscv_xlen == 32
#define IF64(...)
#define lx lw
#define sx sw
#else
#define IF64(...) __VA_ARGS__
#define lx ld
#define sx sd
#endif

#if __riscv_flen == 32
#define flx flw
#define fsx flw
#elif __riscv_flen == 64
#define flx fld
#define fsx fsd
#endif

#if __riscv_flen == 64
#define IF_F64(...) __VA_ARGS__
#else
#define IF_F64(...)
#endif

#if __riscv_v_elen_fp == 64
#define IF_VF64(...) __VA_ARGS__
#else
#define IF_VF64(...)
#endif

.macro m_nop
.endm

#define bench s0
#define ptr s1

.macro m_t9or31
ori t9, t9, 31
.endm

.macro m_t9or63
ori t9, t9, 63
.endm

.macro m_t9or1
ori t9, t9, 1
.endm

.macro m_f1and1
fsgnj.s
.endm

.macro m_f1ne0
fmv.x.w a0, fa1
ori a0, a0, 1
fmv.w.x fa1, a0
.endm

.macro m_f1abs
fabs.s  fa1,fa1
.endm

.macro m_d1ne0
fmv.x.d a0, fa1
ori a0, a0, 1
fmv.d.x fa1, a0
.endm

.macro m_d1abs
fabs.d  fa1,fa1
.endm


.macro m_benchmarks_all f

	# I
	\f      bench_add,   m_nop, add   ,, t8, t9
	IF64(\f bench_addw,  m_nop, addw  ,, t8, t9)
	\f      bench_addi,  m_nop, addi  ,, t8, 13
	IF64(\f bench_addiw, m_nop, addiw ,, t8, 13)
	\f      bench_sub,   m_nop, sub   ,, t8, t9
	IF64(\f bench_subw,  m_nop, subw  ,, t8, t9)
	\f      bench_lui,   m_nop, lui   ,, 13
	\f      bench_auipc, m_nop, auipc ,, 13

	\f bench_xor,  m_nop, xor  ,, t8, t9
	\f bench_xori, m_nop, xori ,, t8, 13
	\f bench_or,   m_nop, or   ,, t8, t9
	\f bench_ori,  m_nop, ori  ,, t8, 13
	\f bench_and,  m_nop, and  ,, t8, t9
	\f bench_andi, m_nop, andi ,, t8, 13

	\f bench_slt,   m_nop, slt   ,, t8, t9
	\f bench_slti,  m_nop, slti  ,, t8, 13
	\f bench_sltu,  m_nop, sltu  ,, t8, t9
	\f bench_sltiu, m_nop, sltiu ,, t8, 13

	\f      bench_sll,   m_t9or63, sll   ,, t8, t9
	IF64(\f bench_sllw,  m_t9or31, sllw  ,, t8, t9)
	\f      bench_slli,  m_t9or63, slli  ,, t8, 13
	IF64(\f bench_slliw, m_t9or31, slliw ,, t8, 13)
	\f      bench_srl,   m_t9or63, srl   ,, t8, t9
	IF64(\f bench_srlw,  m_t9or31, srlw  ,, t8, t9)
	\f      bench_srli,  m_t9or63, srli  ,, t8, 13
	IF64(\f bench_srliw, m_t9or31, srliw ,, t8, 13)
	\f      bench_sra,   m_t9or63, sra   ,, t8, t9
	IF64(\f bench_sraw,  m_t9or31, sraw  ,, t8, t9)
	\f      bench_srai,  m_t9or63, srai  ,, t8, 13
	IF64(\f bench_sraiw, m_t9or31, sraiw ,, t8, 13)

	\f      bench_lb,  m_nop, lb  ,, 13(ptr)
	\f      bench_lh,  m_nop, lh  ,, 13(ptr)
	\f      bench_lw,  m_nop, lw  ,, 13(ptr)
	IF64(\f bench_ld,  m_nop, ld  ,, 13(ptr))
	\f      bench_lbu, m_nop, lbu ,, 13(ptr)
	\f      bench_lhu, m_nop, lhu ,, 13(ptr)
	IF64(\f bench_lwu, m_nop, lwu ,, 13(ptr))

	\f      bench_sb, m_nop, sb ,, 13(ptr)
	\f      bench_sh, m_nop, sh ,, 13(ptr)
	\f      bench_sw, m_nop, sw ,, 13(ptr)
	IF64(\f bench_sd, m_nop, sd ,, 13(ptr))


	# M
#if __riscv_m
	\f      bench_mul,    m_nop,   mul    ,, t8, t9
	\f      bench_mulh,   m_nop,   mulh   ,, t8, t9
	\f      bench_mulhsu, m_nop,   mulhsu ,, t8, t9
	\f      bench_mulhu,  m_nop,   mulhu  ,, t8, t9
	IF64(\f bench_mulw,   m_nop,   mulw   ,, t8, t9)
	\f      bench_div,    m_t9or1, div    ,, t8, t9
	IF64(\f bench_divw,   m_t9or1, divw   ,, t8, t9)
	\f      bench_divu,   m_t9or1, divu   ,, t8, t9
	IF64(\f bench_divuw,  m_t9or1, divuw  ,, t8, t9)
	\f      bench_rem,    m_t9or1, rem    ,, t8, t9
	IF64(\f bench_remw,   m_t9or1, remw   ,, t8, t9)
	\f      bench_remu,   m_t9or1, remu   ,, t8, t9
	IF64(\f bench_remuw,  m_t9or1, remuw  ,, t8, t9)
#endif

	# A
#if __riscv_a
	\f      bench_lrw,      m_nop, lr.w      ,, (ptr)
	IF64(\f bench_lrd,      m_nop, lr.d      ,, (ptr))
	\f      bench_scw,      m_nop, sc.w      ,, t8, (ptr)
	IF64(\f bench_scd,      m_nop, sc.d      ,, t8, (ptr))
	\f      bench_amoswapw, m_nop, amoswap.w ,, t8, (ptr)
	IF64(\f bench_amoswapd, m_nop, amoswap.d ,, t8, (ptr))
	\f      bench_amoaddw,  m_nop, amoadd.w  ,, t8, (ptr)
	IF64(\f bench_amoaddd,  m_nop, amoadd.d  ,, t8, (ptr))
	\f      bench_amoxorw,  m_nop, amoxor.w  ,, t8, (ptr)
	IF64(\f bench_amoxord,  m_nop, amoxor.d  ,, t8, (ptr))
	\f      bench_amoandw,  m_nop, amoand.w  ,, t8, (ptr)
	IF64(\f bench_amoandd,  m_nop, amoand.d  ,, t8, (ptr))
	\f      bench_amoorw,   m_nop, amoor.w   ,, t8, (ptr)
	IF64(\f bench_amoord,   m_nop, amoor.d   ,, t8, (ptr))
	\f      bench_amominw,  m_nop, amomin.w  ,, t8, (ptr)
	IF64(\f bench_amomind,  m_nop, amomin.d  ,, t8, (ptr))
	\f      bench_amomaxw,  m_nop, amomax.w  ,, t8, (ptr)
	IF64(\f bench_amomaxd,  m_nop, amomax.d  ,, t8, (ptr))
	\f      bench_amominuw, m_nop, amominu.w ,, t8, (ptr)
	IF64(\f bench_amominud, m_nop, amominu.d ,, t8, (ptr))
	\f      bench_amomaxuw, m_nop, amomaxu.w ,, t8, (ptr)
	IF64(\f bench_amomaxud, m_nop, amomaxu.d ,, t8, (ptr))
#endif


	# F
#if __riscv_f
	\f bench_fmvwx,     m_nop, fmv.w.x   ,f, t8
	\f bench_fmvxw,     m_nop, fmv.x.w   ,,  fa1
	\f bench_fcvt_w_s,  m_nop, fcvt.w.s  ,, fa1
	\f bench_fcvt_wu_s, m_nop, fcvt.wu.s ,, fa1
	\f bench_fcvt_s_w,  m_nop, fcvt.s.w  ,f, t8
	\f bench_fcvt_s_wu, m_nop, fcvt.s.wu ,f, t8
	IF64(\f bench_fcvt_l_s,  m_nop, fcvt.l.s  ,, fa1)
	IF64(\f bench_fcvt_lu_s, m_nop, fcvt.lu.s ,, fa1)
	IF64(\f bench_fcvt_s_l,  m_nop, fcvt.s.l  ,f, t8)
	IF64(\f bench_fcvt_s_lu, m_nop, fcvt.s.lu ,f, t8)

	\f bench_flw, m_nop, flw ,f, 13(ptr)
	\f bench_fsw, m_nop, fsw ,f, 13(ptr)

	\f bench_fadds,   m_nop,   fadd.s   ,f, fa1, fa2
	\f bench_fsubs,   m_nop,   fsub.s   ,f, fa1, fa2
	\f bench_fmuls,   m_nop,   fmul.s   ,f, fa1, fa2
	\f bench_fdivs,   m_f1ne0, fdiv.s   ,f, fa1, fa2
	\f bench_fsqrts,  m_f1abs, fsqrt.s  ,f, fa1
	\f bench_fmadds,  m_nop,   fmadd.s  ,f, fa1, fa2, fa3
	\f bench_fmsubs,  m_nop,   fmsub.s  ,f, fa1, fa2, fa3
	\f bench_fnmsubs, m_nop,   fnmsub.s ,f, fa1, fa2, fa3
	\f bench_fnmadds, m_nop,   fnmadd.s ,f, fa1, fa2, fa3

	\f bench_fsgnjs,  m_nop, fsgnj.s  ,f, fa1, fa2
	\f bench_fsgnjns, m_nop, fsgnjn.s ,f, fa1, fa2
	\f bench_fsgnjxs, m_nop, fsgnjx.s ,f, fa1, fa2
	\f bench_fmins, m_nop, fmin.s ,f, fa1, fa2
	\f bench_fmaxs, m_nop, fmax.s ,f, fa1, fa2

	\f bench_feqs,    m_nop, feq.s    ,, fa1, fa2
	\f bench_flts,    m_nop, flt.s    ,, fa1, fa2
	\f bench_fles,    m_nop, fle.s    ,, fa1, fa2
	\f bench_fclasss, m_nop, fclass.s ,, fa1
#endif

	# D
#if __riscv_d && __riscv_xlen != 32
	\f bench_fmvdx,   m_nop, fmv.d.x   ,f, t8
	\f bench_fmvxd,   m_nop, fmv.x.d   ,,  fa1
	\f bench_fcvtwd,  m_nop, fcvt.w.d  ,,  fa1
	\f bench_fcvtwud, m_nop, fcvt.wu.d ,,  fa1
	\f bench_fcvtdw,  m_nop, fcvt.d.w  ,f, t8
	\f bench_fcvtdwu, m_nop, fcvt.d.wu ,f, t8
	\f bench_fcvtld,  m_nop, fcvt.l.d  ,,  fa1
	\f bench_fcvtlud, m_nop, fcvt.lu.d ,,  fa1
	\f bench_fcvtdl,  m_nop, fcvt.d.l  ,f, t8
	\f bench_fcvtdlu, m_nop, fcvt.d.lu ,f, t8

	\f bench_fld, m_nop, fld ,f, 13(ptr)
	\f bench_fsd, m_nop, fsd ,f, 13(ptr)

	\f bench_faddd,   m_nop,   fadd.d   ,f, fa1, fa2
	\f bench_fsubd,   m_nop,   fsub.d   ,f, fa1, fa2
	\f bench_fmuld,   m_nop,   fmul.d   ,f, fa1, fa2
	\f bench_fdivd,   m_d1ne0, fdiv.d   ,f, fa1, fa2
	\f bench_fsqrtd,  m_d1abs, fsqrt.d  ,f, fa1
	\f bench_fmaddd,  m_nop,   fmadd.d  ,f, fa1, fa2, fa3
	\f bench_fmsubd,  m_nop,   fmsub.d  ,f, fa1, fa2, fa3
	\f bench_fnmsubd, m_nop,   fnmsub.d ,f, fa1, fa2, fa3
	\f bench_fnmaddd, m_nop,   fnmadd.d ,f, fa1, fa2, fa3

	\f bench_fsgnjd,  m_nop, fsgnj.d  ,f, fa1, fa2
	\f bench_fsgnjnd, m_nop, fsgnjn.d ,f, fa1, fa2
	\f bench_fsgnjxd, m_nop, fsgnjx.d ,f, fa1, fa2
	\f bench_fmind, m_nop, fmin.d ,f, fa1, fa2
	\f bench_fmaxd, m_nop, fmax.d ,f, fa1, fa2

	\f bench_feqd,    m_nop, feq.d    ,, fa1, fa2
	\f bench_fltd,    m_nop, flt.d    ,, fa1, fa2
	\f bench_fled,    m_nop, fle.d    ,, fa1, fa2
	\f bench_fclassd, m_nop, fclass.d ,, fa1
#endif


#if __riscv_zba
	IF64(\f bench_adduw,    m_nop, add.uw    ,, t8, t9)
	\f      bench_sh1add,   m_nop, sh1add    ,, t8, t9
	IF64(\f bench_sh1adduw, m_nop, sh1add.uw ,, t8, t9)
	\f      bench_sh2add,   m_nop, sh2add    ,, t8, t9
	IF64(\f bench_sh2adduw, m_nop, sh2add.uw ,, t8, t9)
	\f      bench_sh3add,   m_nop, sh3add    ,, t8, t9
	IF64(\f bench_sh3adduw, m_nop, sh3add.uw ,, t8, t9)
	IF64(\f bench_slliuw,   m_nop, slli.uw   ,, t8, 13)
	IF64(\f bench_zextw,    m_nop, zext.w    ,, t8)
#endif

#if __riscv_zbb
	\f bench_andn, m_nop, andn ,, t8, t9
	\f bench_orn,  m_nop, orn  ,, t8, t9
	\f bench_xnor, m_nop, xnor ,, t8, t9

	\f      bench_clz,  m_nop, clz  ,, t8
	IF64(\f bench_clzw, m_nop, clzw ,, t8)
	\f      bench_ctz,  m_nop, ctz  ,, t8
	IF64(\f bench_ctzw, m_nop, ctzw ,, t8)

	\f bench_cpop,  m_nop, cpop  ,, t8
	IF64(\f bench_cpopw, m_nop, cpopw ,, t8)

	\f bench_max,  m_nop, max  ,, t8, t9
	\f bench_maxu, m_nop, maxu ,, t8, t9
	\f bench_min,  m_nop, min  ,, t8, t9
	\f bench_minu, m_nop, minu ,, t8, t9

	\f bench_sextb, m_nop, sext.b ,, t8
	\f bench_sexth, m_nop, sext.h ,, t8
	\f bench_zexth, m_nop, zext.h ,, t8

	\f      bench_rol,   m_t9or63, rol   ,, t8, t9
	IF64(\f bench_rolw,  m_t9or31, rolw  ,, t8, t9)
	\f      bench_ror,   m_t9or63, ror   ,, t8, t9
	\f      bench_rori,  m_nop,    rori  ,, t8, 13
	IF64(\f bench_roriw, m_nop,    roriw ,, t8, 13)
	IF64(\f bench_rorw,  m_t9or31, rorw  ,, t8, t9)

	\f bench_orc,  m_nop, orc.b ,, t8
	\f bench_rev8, m_nop, rev8  ,, t8
#endif

#if __riscv_zbc
	\f bench_clmul,  m_nop, clmul  ,, t8, t9
	\f bench_clmulh, m_nop, clmulh ,, t8, t9
	\f bench_clmulr, m_nop, clmulr ,, t8, t9
#endif

#if __riscv_zbs
	\f bench_bclr,  m_nop, bclr  ,, t8, t9
	\f bench_bclri, m_nop, bclri ,, t8, 13
	\f bench_bext,  m_nop, bext  ,, t8, t9
	\f bench_bexti, m_nop, bexti ,, t8, 13
	\f bench_binv,  m_nop, binv  ,, t8, t9
	\f bench_binvi, m_nop, binvi ,, t8, 13
	\f bench_bset,  m_nop, bset  ,, t8, t9
	\f bench_bseti, m_nop, bseti ,, t8, 13
#endif

#if __riscv_zbc
	\f bench_clmul,  m_nop, clmul  ,, t8, t9
	\f bench_clmulh, m_nop, clmulh ,, t8, t9
	\f bench_clmulr, m_nop, clmulr ,, t8, t9
#endif

.endm

.data

#if __riscv_xlen == 32
#define defptr .word
#else
#define defptr .dword
#endif

.balign 8
.global benchmarks
benchmarks:
.macro gen_function_pointers name setup code:vararg
	defptr \name
.endm
m_benchmarks_all gen_function_pointers
defptr 0 # zero termination


.macro gen_strings name setup instr arg1 args:vararg
	.string "\instr \arg1\()t0, \args"
.endm

.balign 8
.global benchmark_names
benchmark_names:
m_benchmarks_all gen_strings


.balign 8
u64_cycle:
.dword 0

.text
.balign 8

.macro m_gen_benchname name setup instr arg1 args:vararg
	\name:
		\setup
		li a0, WARMUP
	1:
		\instr \arg1\()t0, \args
		\instr \arg1\()t1, \args
		\instr \arg1\()t2, \args
		\instr \arg1\()t3, \args
		\instr \arg1\()t4, \args
		\instr \arg1\()t5, \args
		\instr \arg1\()t6, \args
		\instr \arg1\()t7, \args
		addi a0, a0, -1
		bnez a0, 1b
#if defined(USE_PERF_EVENT_SLOW)
		ld a0, nolibc_perf_event_fd
		la a1, u64_cycle
		li a2, 8
		li a7, 63
		ecall
		ld a3, u64_cycle
#elif defined(READ_MCYCLE)
		csrr a3, mcycle
#else
		csrr a3, cycle
#endif
		li a0, LOOP
	1:
	.rept UNROLL
		\instr \arg1\()t0, \args
		\instr \arg1\()t1, \args
		\instr \arg1\()t2, \args
		\instr \arg1\()t3, \args
		\instr \arg1\()t4, \args
		\instr \arg1\()t5, \args
		\instr \arg1\()t6, \args
		\instr \arg1\()t7, \args
	.endr
		addi a0, a0, -1
		bnez a0, 1b
#if defined(USE_PERF_EVENT_SLOW)
		ld a0, nolibc_perf_event_fd
		la a1, u64_cycle
		li a2, 8
		li a7, 63
		ecall
		ld a0, u64_cycle
#elif defined(READ_MCYCLE)
		csrr a0, mcycle
#else
		csrr a0, cycle
#endif
		sub a0, a0, a3
	ret
.endm

m_benchmarks_all m_gen_benchname


randomize:
#if __riscv_xlen == 32
	li a1, 0x85ebca6b
	li a2, 0xc2b2ae35
#else
	li a1, 0xa0761d6485ebca6b
	li a2, 0x78bd642fc2b2ae35
#endif

	# fill t* & ft* with wyhash
	.macro randomize_reg x xs:vararg
		add a0, a0, a1
		xor a5, a0, a2
		mulh a6, a0, a5
		mulhu a7, a0, a5
		xor \x, a6, a7
		and a5, \x, a4 # zero upper f16/f32/f64 exponent bit
#if __riscv_flen == 64 && __riscv_xlen == 64
		fmv.d.x f\()\x, a5
#else
		fmv.w.x f\()\x, a5
#endif
		.ifnb \xs
			randomize_reg \xs
		.endif
	.endm
	randomize_reg t0, t1, t2, t3, t4, t5, t6, t7, t8, t9
	ret

# u64 f(u64 (*bench)(), void *ptr, u64 seed)
.global run_bench
run_bench:
	addi sp, sp, -80
	sx ra, 8(sp)
	sx bench, 16(sp)
	sx ptr, 24(sp)
	sx t7, 32(sp)
	sx t8, 40(sp)
	sx t9, 48(sp)
#if __riscv_f
	fsx ft7, 56(sp)
	fsx ft8, 64(sp)
	fsx ft9, 72(sp)
#endif

	mv bench, a0
	mv ptr, a1
	mv a0, a2 # seed
	call randomize
	jalr bench

	lx ra, 8(sp)
	lx bench, 16(sp)
	lx ptr, 24(sp)
	lx t7, 32(sp)
	lx t8, 40(sp)
	lx t9, 48(sp)
#if __riscv_f
	flx ft7, 56(sp)
	flx ft8, 64(sp)
	flx ft9, 72(sp)
#endif
	addi sp, sp, 80
	ret
