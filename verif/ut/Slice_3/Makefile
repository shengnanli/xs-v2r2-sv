# 自动生成: scripts/gen_slice_variants.py + mk_slice_variant_full_mk.sh —— 勿手改
# Slice_3: TL2 direct-child shard 2 变体(assembly 父, 复用绿基线 Slice 核)。
MODULE = Slice_3

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读变体核(include 变体 svh)+ 共享类型包。
RTL_SRCS = $(RTL_DIR)/l2/slice_pkg.sv \
           $(RTL_DIR)/l2/slice_variants/Slice_3_core.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶 Slice_3.sv(全 80 叶子闭包见 golden_filelist.f)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Slice_3.sv

# FM 子模块边界(镜像绿基线 Slice, codex_0036 裁定):
#   ELAB_SRCS = 非 305 逻辑子(DataStorage_3/RequestBuffer/RXSNP/MSHRBuffer[_1])
#     + golden 递归闭包, 两侧同源 elaborate; 唯一 SRAM 黑盒 = 厂商 array_18_ext。
#   13 已证绿 305 子 + Directory_3(green-AUX)/L2Slice_3(green mbistPl) 黑盒
#     (两侧 unresolved -> hdlin_unresolved_modules=black_box 同名对称; allow/Slice_3.json)。
ELAB_SRCS = $(GOLDEN_RTL)/array_18.sv $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/ClockMux.sv $(GOLDEN_RTL)/DataStorage_3.sv $(GOLDEN_RTL)/FastArbiter_3.sv $(GOLDEN_RTL)/GatedSplittedSRAM_2.sv $(GOLDEN_RTL)/L2DataStorage_3.sv $(GOLDEN_RTL)/MbistClockGateCell_101.sv $(GOLDEN_RTL)/MSHRBuffer.sv $(GOLDEN_RTL)/MSHRBuffer_1.sv $(GOLDEN_RTL)/Queue1_ChosenQBundle.sv $(GOLDEN_RTL)/Queue2_CHISNP.sv $(GOLDEN_RTL)/ram_2x98.sv $(GOLDEN_RTL)/RequestBuffer.sv $(GOLDEN_RTL)/RXSNP.sv $(GOLDEN_RTL)/sram_array_1p4096x69m69s1h1l2b_l2_dat.sv $(GOLDEN_RTL)/SRAMTemplate_174.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/slice_variants/Slice_3_wrapper.sv $(ELAB_SRCS)
FM_VARIANTS = Slice_3
FM_REF_DEPS_Slice_3 = array_18.sv ClockGate.sv ClockMux.sv DataStorage_3.sv FastArbiter_3.sv GatedSplittedSRAM_2.sv L2DataStorage_3.sv MbistClockGateCell_101.sv MSHRBuffer.sv MSHRBuffer_1.sv Queue1_ChosenQBundle.sv Queue2_CHISNP.sv ram_2x98.sv RequestBuffer.sv RXSNP.sv sram_array_1p4096x69m69s1h1l2b_l2_dat.sv SRAMTemplate_174.sv

# 同基线: chosenQ 无 reset ram 常数折叠不对称, 关 merge 令寄存器按名对称保留逐位比对。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化, 处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2/slice_variants
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
