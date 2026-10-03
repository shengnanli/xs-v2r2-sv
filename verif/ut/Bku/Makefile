MODULE = Bku

RTL_DIR = ../../../rtl
# 单文件规范：package bku_pkg + xs_Bku_core + golden 同名 wrapper 都在 Bku.sv 里
RTL_SRCS = $(RTL_DIR)/backend/Bku.sv \
           $(RTL_DIR)/backend/BlockCipherModule.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# Bku 的四个运算子块（+ CryptoModule 下的两个实现叶子）。G1 与 G0 逐字一致
# （已用 cmp 核对），不是本轮重写目标：两侧同源 elaborate，不黑盒、不改名，
# UT 里 golden Bku 与 Bku_xs 各例化自己的一份。
#
# ★2026-10-03（agent/misc-core）：BlockCipherModule 有了重写件（rtl/backend/BlockCipherModule.sv，单独签核），
# 改为两侧白盒：ref = golden，impl = 重写件（RTL_SRCS）。其余 5 个仍两侧同源 golden（RTL_GOLDEN_DEPS）。
#   FM：impl 容器里 golden CryptoModule 例化的 BlockCipherModule 解析到重写件 —— 真对比。
#   UT：CryptoModule 是两侧共用的 golden 定义，它例化的 BlockCipherModule 在两侧都解析到 golden 那份
#       （重写件被 derive 改名成 BlockCipherModule_xs，没人例化它）。所以 Bku 的 UT 测不到重写件，
#       重写件的 UT 在 verif/ut/BlockCipherModule；本层的替换由 FM 兜底。
BKU_SHARED = CountModule.sv ClmulModule.sv MiscModule.sv CryptoModule.sv HashModule.sv
BKU_LEAVES = $(BKU_SHARED) BlockCipherModule.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Bku.sv $(GOLDEN_RTL)/BlockCipherModule.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(BKU_SHARED))

FM_VARIANTS = Bku
FM_REF_DEPS_Bku = $(BKU_LEAVES)

# 注（G0 那一轮的经验，本轮未复验）：上一轮 Bku 的 FM 需要 FM_MERGE_DUP=false，
# 因为 funcReg 在顶层与四个子块里各有一份同值副本，合并 pass 会在 u_core 层次
# 边界两侧做不对称折叠。本轮两侧都白盒同源例化 golden 子块，情况已不同，故先用
# 默认值 true；若 FM 出现 funcReg 相关 unmatched，把下一行打开再跑：
# FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 头部的 initial 随机化块靠 SYNTHESIS 关掉（两侧寄存器一致地起 X）
VCS += +define+SYNTHESIS
