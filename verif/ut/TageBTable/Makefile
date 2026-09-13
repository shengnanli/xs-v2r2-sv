MODULE = TageBTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/TageBTable.sv
TB_SRCS = tb.sv

# golden 编译闭包: TageBTable + 两类子模块各自的闭包
#   FoldedSRAMTemplate_20 -> SplittedSRAMTemplate_23 -> SRAMTemplate_64
#                         -> sram_array_1p256x8m2s1h0l1b_bp_tage_bt -> array_4 -> array_4_ext
#                         (+ MbistClockGateCell / ClockGate)
#   WrBypass_32           -> IndexableCAMTemplate_32, data_mem_8x4
# UT 双例化时子模块两侧共用同一份 golden 定义, 只有 TageBTable 本体被替换。
GOLDEN_SRCS = $(GOLDEN_RTL)/TageBTable.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SRAMTemplate_64.sv \
              $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
              $(GOLDEN_RTL)/array_4.sv \
              $(GOLDEN_RTL)/array_4_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/WrBypass_32.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
              $(GOLDEN_RTL)/data_mem_8x4.sv

# FM 侧: ref = golden TageBTable + 下面这些依赖; impl = 本文件的 wrapper。
# 两个子模块 FoldedSRAMTemplate_20 / WrBypass_32 都是**各自独立的已签核 target**
# (FoldedSRAMTemplate_20 = WORKING_PASS, WrBypass_32 = REVALIDATED_PASS), 因此
# 按 docs 的 assembly 契约做对称同名黑盒是被审核过的边界, depends_on 见下。
# 预期的对称黑盒边界 (共 6 个对象, 全是已签核 child target, 无新增黑盒类别):
#   impl: u_core/g_bank[0].bt  u_core/g_bank[1].bt   -> FoldedSRAMTemplate_20
#         u_core/wrbypass                            -> WrBypass_32
#   ref : bt_0  bt_1                                 -> FoldedSRAMTemplate_20
#         wrbypass                                   -> WrBypass_32
# verif/allow/TageBTable.json 需由 scripts/declare_allow.py 从真实 black_boxes.rpt 生成,
# 本 canary **没有跑 FM** (机器 FM 并发已满, 按分工由 main 统一安排), 所以该文件尚不存在,
# FM_ALLOWLIST 也还没定过数。上面这几行是给跑 FM 的人对账用的预期值, 不是已验证的结论。
FM_REF_DEPS_TageBTable =
FM_MODE = assembly
FM_VARIANTS = TageBTable

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
