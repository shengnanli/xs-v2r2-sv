MODULE = DCache

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_DCache_core（含替换器/perf 的 struct/enum/function/genvar）+ pkg。
# 一堆 include（ports/nets/regs/glue/inst/perf）与核同目录，经 +incdir 找到。
RTL_SRCS     = $(RTL_DIR)/memblock/dcache_pkg.sv \
               $(RTL_DIR)/memblock/DCache.sv
# FM impl 侧顶层 wrapper（golden 同名 DCache，透传到可读核）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/DCache_wrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

# golden DCache.sv 例化 30+ 子模块；子模块本身用黑盒 stub 隔离（UT 两侧共用）。
GOLDEN_SRCS  = $(GOLDEN_RTL)/DCache.sv $(RTL_DIR)/memblock/dcache_stub.sv

FM_VARIANTS  = DCache
FM_REF_DEPS_DCache = ../../rtl/memblock/dcache_stub.sv

include ../../../scripts/ut_common.mk

VCS += +incdir+$(RTL_DIR)/memblock
VCS += +define+SYNTHESIS

# ----------------------------------------------------------------------------
# 本层 FM 走 fmbb：ref/impl 两侧都读入显式端口方向的 dcache_stub.sv（统一黑盒边界），
# identity 配对，并对替换器 state_vec / perf 流水寄存器逐项 set_user_match。
# 共享 `make fm`（impl 侧不读 stub，黑盒边界对不齐）不适用本层。
# ----------------------------------------------------------------------------
STUB = $(abspath $(RTL_DIR)/memblock/dcache_stub.sv)
.PHONY: fmbb
fmbb:
	@mkdir -p fm_work/DCache
	@echo "=== FM(bb): DCache ==="
	FM_TOP=DCache \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/DCache.sv) $(STUB)" \
	FM_IMPL_SRCS="$(abspath $(RTL_DIR)/memblock/dcache_pkg.sv $(RTL_DIR)/memblock/DCache.sv $(RTL_DIR)/memblock/DCache_wrapper.sv) $(STUB)" \
	FM_MERGE_DUP=false \
	fm_shell -64 -work_path fm_work/DCache -file $(abspath fm_eq_bb.tcl) \
	    > fm_work/DCache/fm.log 2>&1; \
	grep -E "^FM_RESULT|^PINNED" fm_work/DCache/fm.log; \
	grep -q "^FM_RESULT: Verification SUCCEEDED" fm_work/DCache/fm.log
