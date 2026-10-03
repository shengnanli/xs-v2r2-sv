MODULE = FMA

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FMA.sv \
           $(RTL_DIR)/backend/FloatFMA.sv \
           $(RTL_DIR)/backend/BoothEncoderF64F32F16.sv \
           $(RTL_DIR)/backend/CSA_Nto2With3to2MainPipeline.sv \
           $(RTL_DIR)/backend/CSA3to2.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FloatFMA 子树（2026-10-03 起，agent/misc-core）：两侧白盒，ref = golden，impl = 本仓重写件
#   FloatFMA / BoothEncoderF64F32F16 / CSA_Nto2With3to2MainPipeline（本 lane 重写签核）、CSA3to2（PROVEN_DIRECT）；
#   孙辈 CSA4to2 本仓无重写件：两侧同源 golden 原件（RTL_GOLDEN_DEPS），不设黑盒。
#   FloatFMA 子树的寄存器名两侧不同，由 fm_pins_pre.tcl 钉上（scripts/gen_fma_pins.py 生成）。
# 此前（7a881579 的 receipt）这 5 个文件两侧同源 elaborate；那一轮记下的 G0->G1 差异：firtool 把
#   {|io_fp_a[62:52], io_fp_a[51:0]} 提成了具名 wire fp_a_significand_f64，纯 CSE，逻辑不变。
FMA_LEAVES = FloatFMA.sv BoothEncoderF64F32F16.sv \
             CSA_Nto2With3to2MainPipeline.sv CSA4to2.sv CSA3to2.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FMA.sv $(GOLDEN_RTL)/FloatFMA.sv $(GOLDEN_RTL)/BoothEncoderF64F32F16.sv \
              $(GOLDEN_RTL)/CSA_Nto2With3to2MainPipeline.sv $(GOLDEN_RTL)/CSA3to2.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/CSA4to2.sv

FM_VARIANTS = FMA
# FM_MERGE_DUP = false（2026-10-03，agent/misc-core）：★加强不是放宽★——FM 逐个比寄存器、不先合并
# 功能相同的寄存器，比较点只会更多；同时让 fm_predict 的 passing 模型适用（merge 打开时模型不成立）。
FM_MERGE_DUP = false
FM_REF_DEPS_FMA = $(FMA_LEAVES)

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS
