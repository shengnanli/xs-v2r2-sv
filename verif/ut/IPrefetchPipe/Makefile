# IPrefetchPipe —— ICache 预取流水（iTLB/meta 预查 + 写 WayLookup + 向 MissUnit 发预取）
#
# 子模块只有一个：Arbiter2_ICacheMissReq（两口 miss 请求的固定优先级仲裁）。
# 它是本工程已签核的可读重写件（xs_FixedPriorityArbiter_core 家族），放在
# RTL_GOLDEN_DEPS：不 derive、不改名，golden IPrefetchPipe 与派生出的
# IPrefetchPipe_xs 例化的是**同一份**定义，UT 两侧对称；FM 侧 ref 走 golden 的
# Arbiter2_ICacheMissReq.sv（FM_REF_DEPS），impl 走这份可读件，两侧都完整
# elaborate、无黑盒（同 ICacheMissUnit 的做法）。
MODULE = IPrefetchPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/IPrefetchPipe.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IPrefetchPipe.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/frontend/Arbiter2_ICacheMissReq.sv

FM_VARIANTS = IPrefetchPipe
FM_REF_DEPS_IPrefetchPipe = Arbiter2_ICacheMissReq.sv

# 端口顺序也当硬闸（wrapper 与 golden 端口表逐位同序）
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2（Scala assert 的落地），
# 两侧统一定义 SYNTHESIS，把断言段与随机初值段一起关掉。
VCS += +define+SYNTHESIS

# 两档 initreg：编译期打开机制，运行期 +vcs+initreg+random（默认）或 +0（run-initreg0）。
# 本模块无复位寄存器有 4 类（RegNext(s0_fire) / RegNext(s1_need_meta&&ready) /
# RegNext(s1_real_fire) / PMP 结果保持寄存器），golden 与重写各自随机初值不同，
# 但它们全部在进入比对窗口前被写定或被 valid 门控，两档都必须 errors=0。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
