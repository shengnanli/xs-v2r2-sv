MODULE = Slice

# L2 Slice 家族（CoupledL2 tl2chi 的一个 slice）：Slice / Slice_1 / Slice_2 / Slice_3。
# 可读核 xs_Slice_core（rtl/uncore/Slice.sv，参数 SLICE_ID）+ 四个 golden 同名 wrapper
# （Slice 在同文件，Slice_1..3 为生成的薄文件；wrapper 里放本变体的 Directory_N / DataStorage_N /
# L2Slice_N）。连线区由 scripts/gen_l2_slice.py 生成（--check 进 gate）。
#
# child 处置 = **两侧白盒**：golden 闭包里每个 child 在 docs/coverage_three_axis.tsv 都是
# PROVEN_DIRECT（或 PROVEN_IN_CONE 的 golden 复用件），ref 读 golden 同名件，impl 读本仓重写件；
# 两侧共读同一份 golden 文件的只有：存储宏行为模型（ram_* / sram_array_* / array_N）、ClockGate、
# 以及 TXREQ/TXRSP 内部的 Queue16_CHIREQ / Queue16_CHIRSP（与 TXREQ/TXRSP 自身签核时相同）。
# 厂商 SRAM 叶子 array_*_ext 两侧都不给 = 对称黑盒（verif/vendor_boundary.tsv 已审定），
# 故走 assembly 模式 + verif/allow/Slice*.json 逐对象声明。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/uncore_common_pkg.sv \
           $(RTL_DIR)/uncore/Slice.sv $(RTL_DIR)/uncore/Slice_1.sv \
           $(RTL_DIR)/uncore/Slice_2.sv $(RTL_DIR)/uncore/Slice_3.sv \
           $(RTL_DIR)/uncore/SinkA.sv \
           $(RTL_DIR)/uncore/SinkC.sv $(RTL_DIR)/common/RRArbiterInit.sv $(RTL_DIR)/common/RRArbiterInit_16.sv \
           $(RTL_DIR)/uncore/GrantBuffer.sv $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_GrantQueueTask.sv $(RTL_DIR)/uncore/Queue16_GrantQueueData.sv \
           $(RTL_DIR)/uncore/Queue10_GrantBuffer_Anon.sv \
           $(RTL_DIR)/uncore/TXREQ.sv $(RTL_DIR)/uncore/TXRSP.sv \
           $(RTL_DIR)/uncore/TXDAT.sv $(RTL_DIR)/uncore/Queue16_TaskBundle.sv $(RTL_DIR)/uncore/Queue16_DSBeat.sv \
           $(RTL_DIR)/uncore/RXSNP.sv $(RTL_DIR)/uncore/Queue2_CHISNP.sv \
           $(RTL_DIR)/uncore/RXDAT.sv $(RTL_DIR)/uncore/RXRSP.sv \
           $(RTL_DIR)/uncore/MSHRBuffer.sv $(RTL_DIR)/uncore/MSHRBuffer_1.sv \
           $(RTL_DIR)/uncore/RequestArb.sv \
           $(RTL_DIR)/uncore/MainPipe_1.sv $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/uncore/Arbiter3_CHIREQ.sv $(RTL_DIR)/uncore/Arbiter3_TaskBundle.sv \
           $(RTL_DIR)/uncore/Arbiter3_TaskWithData.sv $(RTL_DIR)/uncore/CustomL1Hint.sv \
           $(RTL_DIR)/uncore/Queue16_HintQueueEntry.sv $(RTL_DIR)/uncore/Queue4_HintQueueEntry.sv \
           $(RTL_DIR)/uncore/RequestBuffer.sv $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/FastArbiter_2.sv $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/uncore/Queue1_ChosenQBundle.sv \
           $(RTL_DIR)/uncore/MSHRCtl.sv $(RTL_DIR)/uncore/MSHR.sv \
           $(RTL_DIR)/uncore/FastArbiter_3.sv $(RTL_DIR)/uncore/FastArbiter_4.sv \
           $(RTL_DIR)/uncore/FastArbiter_5.sv $(RTL_DIR)/uncore/FastArbiter_6.sv \
           $(RTL_DIR)/uncore/FastArbiter_7.sv $(RTL_DIR)/uncore/SourceB.sv \
           $(RTL_DIR)/uncore/MSHRSelector.sv \
           $(RTL_DIR)/uncore/xs_Directory_core.sv \
           $(RTL_DIR)/uncore/Directory.sv $(RTL_DIR)/uncore/Directory_1.sv \
           $(RTL_DIR)/uncore/Directory_2.sv $(RTL_DIR)/uncore/Directory_3.sv \
           $(RTL_DIR)/uncore/SplittedSRAM_3.sv $(RTL_DIR)/uncore/SplittedSRAM_4.sv \
           $(RTL_DIR)/uncore/SplittedSRAM_5.sv $(RTL_DIR)/uncore/SplittedSRAM_6.sv \
           $(RTL_DIR)/uncore/L2Directory.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/L2Directory_1.sv $(RTL_DIR)/dft/L2Directory_2.sv $(RTL_DIR)/dft/L2Directory_3.sv \
           $(RTL_DIR)/uncore/xs_DataStorage_core.sv \
           $(RTL_DIR)/uncore/DataStorage.sv $(RTL_DIR)/uncore/DataStorage_1.sv \
           $(RTL_DIR)/uncore/DataStorage_2.sv $(RTL_DIR)/uncore/DataStorage_3.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM.sv $(RTL_DIR)/uncore/GatedSplittedSRAM_1.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM_2.sv $(RTL_DIR)/uncore/GatedSplittedSRAM_3.sv \
           $(RTL_DIR)/common/MbistClockGateCell_93.sv $(RTL_DIR)/common/ClockMux.sv \
           $(RTL_DIR)/dft/xs_mbist_hold_leaf_core.sv \
           $(RTL_DIR)/dft/L2DataStorage.sv $(RTL_DIR)/dft/L2DataStorage_1.sv \
           $(RTL_DIR)/dft/L2DataStorage_2.sv $(RTL_DIR)/dft/L2DataStorage_3.sv \
           $(RTL_DIR)/dft/L2Slice.sv $(RTL_DIR)/dft/L2Slice_1.sv \
           $(RTL_DIR)/dft/L2Slice_2.sv $(RTL_DIR)/dft/L2Slice_3.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_148.sv $(RTL_DIR)/common/SRAMTemplate_150.sv \
           $(RTL_DIR)/common/SRAMTemplate_152.sv $(RTL_DIR)/common/SRAMTemplate_153.sv \
           $(RTL_DIR)/common/SRAMTemplate_154.sv $(RTL_DIR)/common/SRAMTemplate_155.sv \
           $(RTL_DIR)/common/SRAMTemplate_159.sv $(RTL_DIR)/common/SRAMTemplate_162.sv \
           $(RTL_DIR)/common/SRAMTemplate_163.sv $(RTL_DIR)/common/SRAMTemplate_164.sv \
           $(RTL_DIR)/common/SRAMTemplate_165.sv $(RTL_DIR)/common/SRAMTemplate_166.sv \
           $(RTL_DIR)/common/SRAMTemplate_178.sv $(RTL_DIR)/common/SRAMTemplate_181.sv \
           $(RTL_DIR)/common/SRAMTemplate_185.sv $(RTL_DIR)/common/SRAMTemplate_186.sv \
           $(RTL_DIR)/common/SRAMTemplate_187.sv

# 两侧共读的 golden 文件（存储宏行为模型 / 时钟门控 / TXREQ、TXRSP 内的 Queue16_CHI*）
SHARED_GOLDEN = Queue16_CHIREQ.sv Queue16_CHIRSP.sv \
                ram_16x137.sv ram_16x62.sv ram_16x67.sv ram_data_16x256.sv ram_16x25.sv \
                ram_2x98.sv ram_16x11.sv ram_4x11.sv \
                ClockGate.sv \
                sram_array_1p512x76m19s1h0l1b_l2_tag.sv sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
                sram_array_1p512x16m16s1h0l1b_l2_repl.sv sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
                sram_array_1p4096x137m137s1h1l2b_l2_dat.sv \
                array_14.sv array_15.sv array_16.sv array_17.sv array_18.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(filter-out ClockGate.sv,$(SHARED_GOLDEN))) $(XSSV_HOME)/rtl/common/ClockGate.sv
# 厂商 SRAM 叶子：UT 两侧共用（仿真需要行为），FM 两侧都不给（对称黑盒）
VENDOR_EXT = array_14_ext.v array_15_ext.v array_16_ext.v array_17_ext.v array_18_ext.v
TB_SRCS  = tb.sv

# golden 闭包（FM ref 侧；字面文件名。四变体共用部分 + 各变体的目录 / 数据阵列 / MBIST 子树）。
# ram_10x89.sv 与 array_*_ext.v 故意不在这里：两侧对称黑盒（见文件头与 verif/allow/Slice*.json）。
SLICE_COMMON_DEPS = MbistClockGateCell_93.sv ClockGate.sv ClockMux.sv \
                    sram_array_1p4096x137m137s1h1l2b_l2_dat.sv array_18.sv \
                    sram_array_1p512x104m13s1h0l1b_l2_meta.sv array_15.sv \
                    sram_array_1p512x16m16s1h0l1b_l2_repl.sv array_16.sv \
                    sram_array_1p512x8m1s1h0l1b_l2_orgb.sv array_17.sv \
                    sram_array_1p512x76m19s1h0l1b_l2_tag.sv array_14.sv GrantBuffer.sv \
                    Queue10_GrantBuffer_Anon.sv Queue16_GrantQueueData.sv ram_data_16x256.sv \
                    Queue16_GrantQueueTask.sv ram_16x25.sv MSHRBuffer.sv MSHRBuffer_1.sv MSHRCtl.sv \
                    FastArbiter_3.sv FastArbiter_4.sv FastArbiter_6.sv FastArbiter_7.sv MSHR.sv \
                    MSHRSelector.sv SourceB.sv FastArbiter_5.sv MainPipe_1.sv Arbiter3_CHIREQ.sv \
                    Arbiter3_TaskBundle.sv Arbiter3_TaskWithData.sv CustomL1Hint.sv \
                    Queue16_HintQueueEntry.sv ram_16x11.sv Queue4_HintQueueEntry.sv ram_4x11.sv \
                    RXDAT.sv RXRSP.sv RXSNP.sv Queue2_CHISNP.sv ram_2x98.sv RequestArb.sv \
                    RequestBuffer.sv FastArbiter_2.sv Queue1_ChosenQBundle.sv SinkA.sv SinkC.sv \
                    RRArbiterInit_16.sv TXDAT.sv Queue16_DSBeat.sv Queue16_TaskBundle.sv \
                    ram_16x67.sv TXREQ.sv Queue16_CHIREQ.sv ram_16x137.sv TXRSP.sv Queue16_CHIRSP.sv \
                    ram_16x62.sv
FM_REF_DEPS_Slice = DataStorage.sv GatedSplittedSRAM.sv SRAMTemplate_155.sv L2DataStorage.sv \
                    Directory.sv L2Directory.sv SRAMTemplate_152.sv SRAMTemplate_153.sv \
                    SRAMTemplate_154.sv SplittedSRAM_3.sv SRAMTemplate_148.sv SRAMTemplate_150.sv \
                    L2Slice.sv $(SLICE_COMMON_DEPS)
FM_REF_DEPS_Slice_1 = DataStorage_1.sv GatedSplittedSRAM_1.sv SRAMTemplate_166.sv L2DataStorage_1.sv \
                      Directory_1.sv L2Directory_1.sv SRAMTemplate_163.sv SRAMTemplate_164.sv \
                      SRAMTemplate_165.sv SplittedSRAM_4.sv SRAMTemplate_159.sv SRAMTemplate_162.sv \
                      L2Slice_1.sv $(SLICE_COMMON_DEPS)
FM_REF_DEPS_Slice_2 = DataStorage_2.sv GatedSplittedSRAM_2.sv SRAMTemplate_166.sv \
                      SRAMTemplate_178.sv L2DataStorage_2.sv Directory_2.sv L2Directory_2.sv \
                      SRAMTemplate_163.sv SRAMTemplate_164.sv SRAMTemplate_165.sv SplittedSRAM_5.sv \
                      SRAMTemplate_162.sv L2Slice_2.sv $(SLICE_COMMON_DEPS)
FM_REF_DEPS_Slice_3 = DataStorage_3.sv GatedSplittedSRAM_3.sv SRAMTemplate_178.sv L2DataStorage_3.sv \
                      Directory_3.sv L2Directory_3.sv SRAMTemplate_185.sv SRAMTemplate_186.sv \
                      SRAMTemplate_187.sv SplittedSRAM_6.sv SRAMTemplate_181.sv L2Slice_3.sv \
                      $(SLICE_COMMON_DEPS)

# UT golden 侧：四个变体 + 四份闭包的并集 + 两侧共用的仿真行为（ram_10x89 / 厂商叶子）
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,Slice.sv Slice_1.sv Slice_2.sv Slice_3.sv \
                $(sort $(FM_REF_DEPS_Slice) $(FM_REF_DEPS_Slice_1) $(FM_REF_DEPS_Slice_2) $(FM_REF_DEPS_Slice_3)) \
                ram_10x89.sv $(VENDOR_EXT))

FM_VARIANTS = Slice Slice_1 Slice_2 Slice_3

# FM_MERGE_DUP = false（模型严格适用）。为什么不取默认 true：闭包里 golden 有多处"同方程的重复寄存器"
# （GrantBuffer / RequestBuffer 的 REG_k 与 enable_REG_k、CustomL1Hint 队列等），merge 在两侧合掉的代表不同，
# 实测 Slice_1 诊断跑（diag5，merge=true）failing 1242 / unmatched unread 20+20；merge=false 的 diag4 只剩
# Directory 那 7 个点（见下）。
# 曾经的代价：Directory 的 7 块 SRAM（xs_SRAMTemplate_core 非 MCP 形态）各有一个 golden 没有、与 respReg 同方程的
# rdata_last_REG，merge=false 下成每变体 7 个 impl-only unread。codex 0206 D1 已在共享核里消除（holdRead 关时不生成），
# 见 docs/lanes/sramcore-d1d2d3_prereg.md。
FM_MERGE_DUP = false

# assembly：黑盒只许 = 厂商 SRAM 叶子 array_14..18_ext + codex 0202 审定的 ram_10x89（两侧对称）
FM_MODE = assembly
FM_ALLOWLIST ?= 24

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/Slice*.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
INITREG  ?= random
# RANDOMIZE_MEM_INIT：只影响厂商 SRAM 叶子 array_*_ext 的存储体初值（firtool 模块的随机初始化
# 还要求未定义 SYNTHESIS，这里定义了，故不受影响）。不加则 tag / 数据阵列读出全 X，见 tb.sv 文件头。
VCS      += +define+SYNTHESIS +define+RANDOMIZE_MEM_INIT +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen_tb.py
gencheck:
	python3 gen_tb.py --check
	python3 ../../../scripts/gen_l2_slice.py --check
