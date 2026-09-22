# ICacheMainPipe —— ICache 取指主流水（FTQ 请求 → data SRAM/MSHR 取数 → 回 IFU）
#
# 子模块只有一个：Arbiter2_ICacheMissReq（两口 miss 请求的固定优先级仲裁），
# 是本工程已签核的可读重写件，放 RTL_GOLDEN_DEPS：不 derive、不改名，golden
# ICacheMainPipe 与派生出的 ICacheMainPipe_xs 例化同一份定义，UT 两侧对称；FM 侧
# ref 走 golden 的 Arbiter2_ICacheMissReq.sv（FM_REF_DEPS），impl 走这份可读件，
# 两侧都完整 elaborate、无黑盒（同 ICacheMissUnit / IPrefetchPipe 的做法）。
MODULE = ICacheMainPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheMainPipe.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMainPipe.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/frontend/Arbiter2_ICacheMissReq.sv

FM_VARIANTS = ICacheMainPipe
FM_REF_DEPS_ICacheMainPipe = Arbiter2_ICacheMissReq.sv

# 端口顺序也当硬闸（wrapper 与 golden 端口表逐位同序）
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS，
# 把断言段与随机初值段一起关掉。
VCS += +define+SYNTHESIS

# 两档 initreg：编译期打开机制，运行期 +vcs+initreg+random（默认）或 +0（run-initreg0）。
# 本模块的无复位寄存器里，PMP 结果保持寄存器（golden s2_pmp_exception_r_* /
# s2_pmp_mmio_r_*）直接可见于 io_fetch_resp_bits_pmp_mmio_* 与 io_perfInfo_except_0，
# 在第一次 s1 fire 之前两侧各自的随机初值会不同 —— 这与重写无关。tb 用一段确定性
# 暖机（复位后先让一次命中取指走完 s0/s1/s2）把它们写定，之后才开比对窗口，
# 所以两档都必须 errors=0。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
