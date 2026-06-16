MODULE = L2TLBWrapper

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_L2TLBWrapper_core（含 perf 流水 struct/enum/function/genvar）。
# 两个 include（端口表 / 内层互联）与核同目录，VCS 经 +incdir 找到。
RTL_SRCS     = $(RTL_DIR)/memblock/L2TLBWrapper.sv
# WRAPPER_SRCS 同时供 FM impl 侧读入：顶层 wrapper + L2TLB 黑盒声明（显式端口方向）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TLBWrapper_wrapper.sv \
               $(RTL_DIR)/memblock/l2tlb_blackbox.sv
TB_SRCS      = variants_xs.sv tb.sv

# 内层 L2TLB 黑盒桩：UT 两侧（golden 顶层 + _xs）共用。
# L2TLB 巨型且依赖上百子模块，无法整树编译；用桩隔离，只验证包装层互联 + perf 流水。
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TLBWrapper.sv l2tlb_stub.sv

FM_VARIANTS = L2TLBWrapper
FM_REF_DEPS_L2TLBWrapper =

include ../../../scripts/ut_common.mk

# 让 VCS 找到与可读核同目录的 include（端口表 / 内层互联连接）。
VCS += +incdir+$(RTL_DIR)/memblock

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# ----------------------------------------------------------------------------
# 自定义 FM 目标：本层 FM 需要在 ref 与 impl 两侧都读入显式端口方向的 L2TLB 黑盒
# （l2tlb_blackbox.sv），否则 firtool 黑盒「unknown direction」会让 ref/impl 侧把
# 黑盒 perf 输出按拓扑配对，个别 perf 路成对错配而假性 fail。
# 共享 fm-% 规则的 ref 侧固定取 $(GOLDEN_RTL)/$*.sv，无法注入本地黑盒，故这里
# 直接调用 fm_eq_bb.tcl，两侧 srcs 各自带上黑盒（不改任何共享脚本）。
BBOX = $(abspath $(RTL_DIR)/memblock/l2tlb_blackbox.sv)
.PHONY: fmbb
fmbb:
	@mkdir -p fm_work/L2TLBWrapper
	@echo "=== FM(bb): L2TLBWrapper ==="
	FM_TOP=L2TLBWrapper \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/L2TLBWrapper.sv) $(BBOX)" \
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS)) $(abspath $(RTL_DIR)/memblock/L2TLBWrapper_wrapper.sv) $(BBOX)" \
	FM_MERGE_DUP=false \
	fm_shell -64 -work_path fm_work/L2TLBWrapper -file $(abspath fm_eq_bb.tcl) \
	    > fm_work/L2TLBWrapper/fm.log 2>&1; \
	grep -E "^FM_RESULT" fm_work/L2TLBWrapper/fm.log; \
	grep -q "^FM_RESULT: Verification SUCCEEDED" fm_work/L2TLBWrapper/fm.log
