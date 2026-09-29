MODULE = GrantBuffer

# GrantBuffer（L2 slice 的 TileLink D 通道出口）与其 child 队列。
#   GrantBuffer               可读核 xs_GrantBuffer_core 手写；类型 / wrapper / fm_pins_pre.tcl 由 scripts/gen_l2_grantbuf.py 生成
#   Queue10_GrantBuffer_Anon  共享核 xs_ChiselQueue_core + gen_l2_queues.py 薄文件（本 lane 新增）
#   Queue16_GrantQueueTask / Queue16_GrantQueueData 已在 verif/ut/L2Queues 签核，这里两侧白盒同进
# 存储是 golden 的 ram_<D>x<W> 行为级叶子。ram_16x25 / ram_data_16x256（2 的幂）按 codex 0151 D60 两侧同源
# inline elaborate（RTL_GOLDEN_DEPS + FM_REF_DEPS）。
# ★ram_10x89 例外：深度 10 非 2 的幂（4 位地址，10..15 越界），inline 必触发 FMR_ELAB-147 -> set_top FM-156★
#   codex 0202 单条批准，已按精确 module 名 + golden sha256 7cdc3e1c… 登记为 APPROVED_MEMORY_MACRO_MODEL
#   （verif/vendor_boundary.tsv 表尾；parent 对照 verif/ram_model_parents.tsv）。照 L2TlbMissQueue / RenameTableWrapper
#   先例走 regimeA —— FM 两侧**对称黑盒**：ram_10x89.sv 既不进 FM_REF_DEPS 也不进 RTL_GOLDEN_DEPS（后者进 FM impl
#   文件集），只进 GOLDEN_SRCS 供 VCS 行为仿真（golden 与重写两侧例化同一份定义）。黑盒对象逐条声明在
#   verif/allow/<target>.json（两侧各恰好 1 个 ram_ext）。
#   M3（父级不依赖越界地址）：ref 侧 audit_ram_memory_model.py 机器 PASS；impl 侧指针在共享核 xs_ChiselQueue_core
#   里，脚本报 MANUAL，按 codex 0202 以人工复核结论入表（enq/deq 复位 0、唯一更新 next_ptr、p==9 回 0 ⇒ ∈[0,9]）。
#   ★入表不等于转绿：两个目标的绿灯只来自各自 clean native FM 结果本身★
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/GrantBuffer.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_GrantQueueTask.sv $(RTL_DIR)/uncore/Queue16_GrantQueueData.sv \
           $(RTL_DIR)/uncore/Queue10_GrantBuffer_Anon.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_16x25.sv $(GOLDEN_RTL)/ram_data_16x256.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/GrantBuffer.sv $(GOLDEN_RTL)/Queue16_GrantQueueTask.sv \
              $(GOLDEN_RTL)/Queue16_GrantQueueData.sv $(GOLDEN_RTL)/Queue10_GrantBuffer_Anon.sv \
              $(GOLDEN_RTL)/ram_10x89.sv
FM_VARIANTS = Queue10_GrantBuffer_Anon GrantBuffer
# ram_10x89 故意不在两个 FM_REF_DEPS 里（两侧对称黑盒，见文件头）
FM_REF_DEPS_Queue10_GrantBuffer_Anon =
FM_REF_DEPS_GrantBuffer = Queue16_GrantQueueTask.sv Queue16_GrantQueueData.sv Queue10_GrantBuffer_Anon.sv \
                          ram_16x25.sv ram_data_16x256.sv
FM_MERGE_DUP = false
# assembly 模式 + 逐对象声明（verif/allow/GrantBuffer.json / Queue10_GrantBuffer_Anon.json）：黑盒只允许 ram_10x89 两侧各 1
FM_MODE = assembly
FM_ALLOWLIST ?= 1
# GrantBuffer 单独开 matched-unread 加强（1073 个对称死位，依据见 verif/fm_target_config/GrantBuffer.tcl）：
fm-GrantBuffer: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
