RISCV_ARCH := rv32imafcv
RISCV_ABI  := ilp32f
MEM_BASE   := 0x40000000
MEM_SIZE   := 2M
DTIM       := 0
DTIM_BASE  := 0x80000000
DTIM_SIZE  := 4K
CLK_FRQ    := 48000000
PLIC_BASE  := 0x3C000000
CLINT_BASE := 0x32000000
MMIO_BASE  := 0x10000000
INT_NUM    := 16
DCACHE_EN  := 0
CORE_NUM   := 1
CEII_EN    := 0
VARCH      := vlen:128,elen:64,slen:128
RTC_FRQ    := 1562500
