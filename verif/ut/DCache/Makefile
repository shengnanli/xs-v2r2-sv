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

# golden DCache.sv 例化 30+ 子模块。分两类边界(codex_0037 硬边界):
#   (1) 10 个已证 305 SIGNOFF_PASS 子(BankedDataArray/L1CohMetaArray/L1FlagMetaArray/
#       L1FlagMetaArray_1/DuplicatedTagArray/LoadPipe/MainPipe/MissQueue/ProbeQueue/
#       WritebackQueue) → assembly 黑盒(dcache_bb_stub.sv 两侧同读, depends_on 断言等价)。
#   (2) 非 305 逻辑 glue 子(CtrlUnit/Arbiter*/TreeArbiter/MissReadyGen/PrefetcherMonitor/
#       FDPrefetcherMonitor/BloomFilter/CounterFilter/L1PrefetchSourceArray/**StorePipe**)
#       → 两侧 elaborate 真 golden 逻辑(GLUE_GOLDEN), 不黑盒。StorePipe(1 输入/0 输出/0 寄存器,
#       trivially elaboratable) 亦在此列, 不作 empty_blackbox。
BB_STUB      = $(RTL_DIR)/memblock/dcache_bb_stub.sv
GLUE_GOLDEN  = $(GOLDEN_RTL)/CtrlUnit.sv \
               $(GOLDEN_RTL)/Queue1_RegMapperInput_4.sv \
               $(GOLDEN_RTL)/L1PrefetchSourceArray.sv \
               $(GOLDEN_RTL)/PrefetcherMonitor.sv \
               $(GOLDEN_RTL)/FDPrefetcherMonitor.sv \
               $(GOLDEN_RTL)/BloomFilter.sv \
               $(GOLDEN_RTL)/CounterFilter.sv \
               $(GOLDEN_RTL)/Arbiter1_TagWriteReq.sv \
               $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReq.sv \
               $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReqCtrl.sv \
               $(GOLDEN_RTL)/TreeArbiter.sv \
               $(GOLDEN_RTL)/MissReadyGen.sv \
               $(GOLDEN_RTL)/StorePipe.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/DCache.sv $(BB_STUB) $(GLUE_GOLDEN)

FM_VARIANTS  = DCache
FM_REF_DEPS_DCache = ../../rtl/memblock/dcache_bb_stub.sv

include ../../../scripts/ut_common.mk

VCS += +incdir+$(RTL_DIR)/memblock
VCS += +define+SYNTHESIS

# ----------------------------------------------------------------------------
# 本层 FM 走 fmbb (codex_0037 硬边界: 只黑盒 305 子, 非 305 逻辑子含 StorePipe 两侧 elaborate)。
#   黑盒边界 = 仅 10 个已证 305 SIGNOFF_PASS 子(dcache_bb_stub.sv, ref/impl 两侧同读,
#     显式端口方向, identity 配对; depends_on 断言其等价, FM 报 e=Empty design module)。
#   glue 逻辑子(CtrlUnit/Arbiter*/TreeArbiter/MissReadyGen/PrefetcherMonitor/
#     FDPrefetcherMonitor/BloomFilter/CounterFilter/L1PrefetchSourceArray/**StorePipe**)
#     的真 golden RTL(GLUE_GOLDEN) 两侧 elaborate, 参与 live-logic 等价证明。
#   StorePipe(golden = 1输入/0输出/0寄存器 的空设计)两侧 elaborate 后 FM 报 e=Empty
#     (非 u=Unresolved 黑盒), DCache 等价不依赖任何 StorePipe 输出——真非 live/vacuous
#     golden 事实单列(不给 DCache 假绿)。
#   替换器 state_vec / perf 流水寄存器逐项 set_user_match; REG(assert RegNext, SYNTHESIS
#     下消费者编译掉)为对称 matched-unread 死位, 经 vmucp(runner FM_VERIFY_MATCHED_UNREAD_
#     COMPARE_POINTS=true)让 FM 实际双射比较→passing。
# ----------------------------------------------------------------------------
BB_STUB_ABS  = $(abspath $(BB_STUB))
GLUE_ABS     = $(abspath $(GLUE_GOLDEN))
.PHONY: fmbb
fmbb:
	@[ -n "$$FM_SIDECAR_OUT" ] || { echo "ERROR($(MODULE)): fmbb 须经 sidecar runner"; exit 1; }
	@mkdir -p fm_work/DCache
	@echo "=== FM(bb): DCache ==="
	FM_TOP=DCache \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/DCache.sv) $(BB_STUB_ABS) $(GLUE_ABS)" \
	FM_IMPL_SRCS="$(abspath $(RTL_DIR)/memblock/dcache_pkg.sv $(RTL_DIR)/memblock/DCache.sv $(RTL_DIR)/memblock/DCache_wrapper.sv) $(BB_STUB_ABS) $(GLUE_ABS)" \
	FM_MERGE_DUP=false \
	XSSV_HOME=$(XSSV_HOME) FM_RUN_ID=$$FM_RUN_ID \
	fm_shell -64 -work_path fm_work/DCache -file $(abspath fm_eq_bb.tcl) \
	    > fm_work/DCache/fm.log 2>&1; \
	rc=$$?; echo $$rc > "$$FM_SIDECAR_OUT/fm_shell.rc"; \
	grep -E "^FM_RESULT" fm_work/DCache/fm.log || true
