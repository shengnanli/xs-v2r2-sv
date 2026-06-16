MODULE = DCacheWrapper

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_DCacheWrapper_core（含 perf 流水 struct/enum/function/genvar）。
# 两个 include（端口表 / 内层互联）与核同目录，VCS 经 +incdir 找到。
RTL_SRCS     = $(RTL_DIR)/memblock/DCacheWrapper.sv
# WRAPPER_SRCS 同时供 FM impl 侧读入：顶层 wrapper + DCache 黑盒声明（显式端口方向）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/DCacheWrapper_wrapper.sv \
               $(RTL_DIR)/memblock/dcache_blackbox.sv
TB_SRCS      = variants_xs.sv tb.sv

# 内层 DCache 黑盒桩：UT 两侧（golden 顶层 + _xs）共用。
# DCache 巨型且依赖上百子模块，无法整树编译；用桩隔离，只验证包装层互联 + perf 流水。
GOLDEN_SRCS = $(GOLDEN_RTL)/DCacheWrapper.sv dcache_stub.sv

FM_VARIANTS = DCacheWrapper
# FM 两侧都读入 dcache_blackbox.sv（显式端口方向的空 DCache），使内层黑盒边界对齐，
# 消除 firtool 黑盒「unknown direction」对个别 perf 路造成的假阳性。
# 两侧 DCache 均为同名同向黑盒，FM 只比对包装层互联 + perf 2 级流水的签名等价。
FM_REF_DEPS_DCacheWrapper =

include ../../../scripts/ut_common.mk

# 让 VCS 找到与可读核同目录的 include（端口表 / 内层互联连接）。
VCS += +incdir+$(RTL_DIR)/memblock

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# ----------------------------------------------------------------------------
# 自定义 FM 目标：本层 FM 需要在 ref 与 impl 两侧都读入显式端口方向的 DCache 黑盒
# （dcache_blackbox.sv），否则 firtool 黑盒「unknown direction」会让 ref/impl 侧把
# 黑盒 perf 输出按拓扑配对，个别 perf 路（如 event 0/10）成对错配而假性 fail。
# 共享 fm-% 规则的 ref 侧固定取 $(GOLDEN_RTL)/$*.sv，无法注入本地黑盒，故这里
# 直接调用 fm_eq.tcl，两侧 srcs 各自带上黑盒（不改任何共享脚本）。
BBOX = $(abspath $(RTL_DIR)/memblock/dcache_blackbox.sv)
# 本层 FM 走 fmbb（两侧带黑盒 + identity 配对 + 已知假阳性放行）。
# 注意：共享 ut_common.mk 的 `make fm` 不适用本层（ref 侧固定取 golden，无法注入
# 本地黑盒；且无假阳性放行）。本层 FM 用 `make fmbb`。
.PHONY: fmbb
fmbb:
	@mkdir -p fm_work/DCacheWrapper
	@echo "=== FM(bb): DCacheWrapper ==="
	FM_TOP=DCacheWrapper \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/DCacheWrapper.sv) $(BBOX)" \
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS)) $(abspath $(RTL_DIR)/memblock/DCacheWrapper_wrapper.sv) $(BBOX)" \
	FM_MERGE_DUP=false \
	fm_shell -64 -work_path fm_work/DCacheWrapper -file $(abspath fm_eq_bb.tcl) \
	    > fm_work/DCacheWrapper/fm.log 2>&1; \
	grep -E "^FM_RESULT" fm_work/DCacheWrapper/fm.log; \
	grep -q "^FM_RESULT: Verification SUCCEEDED" fm_work/DCacheWrapper/fm.log
