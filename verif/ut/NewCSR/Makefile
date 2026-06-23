MODULE = NewCSR

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_NewCSR_core（CSR 地址译码/写fanout/读mux/特权态机/trap仲裁/输出mux/副作用，
# 用 newcsr_pkg 的 enum/struct/function/genvar 表达）+ pkg + 机械互联 svh。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_pkg.sv \
               $(RTL_DIR)/backend/NewCSR.sv
# FM impl 侧顶层 wrapper（golden 同名 NewCSR，透传到可读核）。
WRAPPER_SRCS = $(RTL_DIR)/backend/NewCSR_wrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

# golden NewCSR.sv 例化 312 子模块；子模块本身用黑盒 stub 隔离（UT 两侧共用）。
GOLDEN_SRCS  = $(GOLDEN_RTL)/NewCSR.sv $(RTL_DIR)/backend/newcsr_stub.sv

FM_VARIANTS  = NewCSR
FM_REF_DEPS_NewCSR = ../../rtl/backend/newcsr_stub.sv

include ../../../scripts/ut_common.mk

VCS += +incdir+$(RTL_DIR)/backend
VCS += +define+SYNTHESIS

# ----------------------------------------------------------------------------
# 本层 FM 走 fmbb：ref/impl 两侧都读入显式端口方向的 newcsr_stub.sv（统一黑盒边界），
# identity 配对。共享 `make fm`（impl 侧不读 stub，黑盒边界对不齐）不适用本层。
# ----------------------------------------------------------------------------
STUB = $(abspath $(RTL_DIR)/backend/newcsr_stub.sv)
.PHONY: fmbb
fmbb:
	@mkdir -p fm_work/NewCSR
	@echo "=== FM(bb): NewCSR ==="
	FM_TOP=NewCSR \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/NewCSR.sv) $(STUB)" \
	FM_IMPL_SRCS="$(abspath $(RTL_DIR)/backend/newcsr_pkg.sv $(RTL_DIR)/backend/NewCSR.sv $(RTL_DIR)/backend/NewCSR_wrapper.sv) $(STUB)" \
	FM_MERGE_DUP=false \
	fm_shell -64 -work_path fm_work/NewCSR -file $(abspath fm_eq_bb.tcl) \
	    > fm_work/NewCSR/fm.log 2>&1; \
	grep -E "^FM_RESULT|^PINNED" fm_work/NewCSR/fm.log; \
	grep -q "^FM_RESULT: Verification SUCCEEDED" fm_work/NewCSR/fm.log
