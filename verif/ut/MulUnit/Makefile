MODULE = MulUnit

RTL_DIR = ../../../rtl
# 单文件规范：package mulunit_pkg + xs_MulUnit_core + golden 同名 wrapper 同在一个文件
RTL_SRCS = $(RTL_DIR)/backend/MulUnit.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# 乘法阵列及其压缩单元。G1 与 G0 逐字一致（已用 cmp 核对），不是本轮重写目标：
# 两侧同源 elaborate，不黑盒、不改名，UT 里 golden MulUnit 与 MulUnit_xs
# 各例化自己的一份。ArrayMulDataModule 24372 行（989×C53 + 293×C22 + 84×C32），
# 编译较慢是正常的。
MUL_LEAVES = ArrayMulDataModule.sv C22.sv C32.sv C53.sv CSA3_2.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MulUnit.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(MUL_LEAVES))

FM_VARIANTS = MulUnit
FM_REF_DEPS_MulUnit = $(MUL_LEAVES)

# 注（G0 那一轮的经验，本轮未复验）：上一轮 MulUnit 的 FM 用了 FM_MERGE_DUP=false，
# 当时阵列在 impl 侧是未解析黑盒、ref 侧是白盒，合并 pass 两侧不对称。本轮两侧
# 都白盒同源例化 golden 阵列，情况已不同，故先用默认值 true；若 FM 出现阵列内部
# 寄存器 unmatched，把下一行打开再跑：
# FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 头部的 initial 随机化块靠 SYNTHESIS 关掉（两侧寄存器一致地起 X）
VCS += +define+SYNTHESIS
