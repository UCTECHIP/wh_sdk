// See LICENSE for license details.
#include "smp.h"
#include "csr.h"
#include "mmu.h"

#define CLINT_CTRL_ADDR CLINT_BASE
        .section .init
        .globl _start
        .type _start,@function

_start:
        .cfi_startproc
        .cfi_undefined ra
.option push
.option norelax
        la gp, __global_pointer$
.option pop
        la sp, _sp

        la  tp, _end + 63
        and tp, tp, -64

#if defined(ENABLE_SMP)
        smp_pause(t0, t1)
#endif

//#ifdef ON_BOARD
//#if defined(ENABLE_DCACHE)
//        li a0, MSTATUS_DD
//        csrrc x0, mstatus, a0
//#else
//        li a0, MSTATUS_DD
//        csrs mstatus, a0
//#endif
//#endif

        /* Load data section */
        la a0, _data_lma
        la a1, _data
        la a2, _edata
        bgeu a1, a2, 2f
1:
#if __riscv_xlen == 32
        lw t0, (a0)
        sw t0, (a1)
        addi a0, a0, 4
        addi a1, a1, 4
        bltu a1, a2, 1b
#else
        ld t0, (a0)
        addi a0, a0, 8
        sd t0, (a1)
        addi a1, a1, 8
        bltu a1, a2, 1b
#endif
2:

        /* Clear bss section */
        la a0, __bss_start
        la a1, _end
        bgeu a0, a1, 2f
1:
#if __riscv_xlen == 32
        sw zero, (a0)
        addi a0, a0, 4
        bltu a0, a1, 1b
#else
        sd zero, (a0)
        addi a0, a0, 8
        bltu a0, a1, 1b
#endif
2:

        /* Call global constructors */
        la a0, __libc_fini_array
        call atexit
        call __libc_init_array

#if defined(ENABLE_ROCC)
        /* Enable ROCC */
        li t0, MSTATUS_XS
        csrs mstatus, t0
#endif

#if __riscv_vector
       li t0, MSTATUS_VS
       csrs mstatus, t0
#endif

#ifndef __riscv_float_abi_soft
        /* Enable FPU */
        li t0, MSTATUS_FS
        csrs mstatus, t0
        csrr t1, mstatus
        and t1, t1, t0
        beqz t1, 1f
        fssr x0
1:
#endif

#if defined(ENABLE_SMP)
        smp_resume(t0, t1)

        csrr a0, mhartid
        li t0, 1
        beq a0, t0, 2f  // hart 1
        li t0, 2
        beq a0, t0, 3f  // hart 2
        li t0, 3
        beq a0, t0, 4f  // hart 3
#endif

        auipc ra, 0
        addi sp, sp, -16
#if __riscv_xlen == 32
        sw ra, 8(sp)
#else
        sd ra, 8(sp)
#endif

        /* argc = argv = 0 */
        li a0, 0
        li a1, 0
        call main
        tail exit
1:
        j 1b

#if defined(ENABLE_SMP)
     ####### hart-1 ########
2:
        la t0, trap_entry
        csrw mtvec, t0

        csrr a0, mhartid
        la t1, _sp
        slli t0, a0, 12    ## stack size = 4KB
        sub sp, t1, t0

        auipc ra, 0
        addi sp, sp, -16
#if __riscv_xlen == 32
        sw ra, 8(sp)
#else
        sd ra, 8(sp)
#endif

        call secondary_main
        tail exit

1:
        j 1b

     ####### hart-2 ########
3:
        la t0, trap_entry
        csrw mtvec, t0

        csrr a0, mhartid
        la t1, _sp
        slli t0, a0, 12   ## stack size = 4KB
        sub sp, t1, t0

        auipc ra, 0
        addi sp, sp, -16
#if __riscv_xlen == 32
        sw ra, 8(sp)
#else
        sd ra, 8(sp)
#endif

        call thirdly_main
        tail exit

1:
        j 1b

     ####### hart-3 ########
4:
        la t0, trap_entry
        csrw mtvec, t0

        csrr a0, mhartid
        la t1, _sp
        slli t0, a0, 12   ## stack size = 4KB
        sub sp, t1, t0

        auipc ra, 0
        addi sp, sp, -16
#if __riscv_xlen == 32
        sw ra, 8(sp)
#else
        sd ra, 8(sp)
#endif

        call fourthly_main
        tail exit

1:
        j 1b


#endif
        .cfi_endproc

#ifdef ON_SPIKE
        .section ".tdata.begin"
        .globl _tdata_begin
_tdata_begin:

        .section ".tdata.end"
        .globl _tdata_end 
_tdata_end:

        .section ".tbss.end"
        .globl _tbss_end
_tbss_end:


        .section ".tohost","aw",@progbits
        .align 6
        .globl tohost
tohost: .dword 0
        .align 6
        .globl fromhost
fromhost: .dword 0 
#endif
         
         .section .text
         .globl secondary_main
         .weak secondary_main
secondary_main:
1:
         j 1b

         .globl thirdly_main
         .weak thirdly_main
thirdly_main:
1:
         j 1b


         .globl fourthly_main
         .weak fourthly_main
fourthly_main:
1:
         j 1b


