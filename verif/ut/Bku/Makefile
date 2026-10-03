MODULE = Bku

RTL_DIR = ../../../rtl
# 单文件规范：package bku_pkg + xs_Bku_core + golden 同名 wrapper 都在 Bku.sv 里
RTL_SRCS = $(RTL_DIR)/backend/Bku.sv \
           $(RTL_DIR)/backend/BlockCipherModule.sv \
           $(RTL_DIR)/backend/CountModule.sv \
           $(RTL_DIR)/backend/ClmulModule.sv \
           $(RTL_DIR)/backend/MiscModule.sv \
           $(RTL_DIR)/backend/HashModule.sv
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
#
# ★同日合 main 后（agent/fpu-parents 签了 CountModule / ClmulModule / MiscModule / HashModule，
#   evidence/f696c5c84a6d/*）：这四个也改两侧白盒（impl = RTL_SRCS 里的重写件）。只剩 CryptoModule 两侧同源 golden。
#   UT 里 Bku_xs 直接例化的 count/clmul/misc 解析到重写件（derive 同步改名）；HashModule 与 BlockCipherModule
#   挂在两侧共用的 golden CryptoModule 下，UT 里两侧都是 golden，由 FM 兜底。
BKU_REWRITTEN = BlockCipherModule.sv CountModule.sv ClmulModule.sv MiscModule.sv HashModule.sv
BKU_SHARED = CryptoModule.sv
BKU_LEAVES = $(BKU_SHARED) $(BKU_REWRITTEN)
GOLDEN_SRCS = $(GOLDEN_RTL)/Bku.sv $(addprefix $(GOLDEN_RTL)/,$(BKU_REWRITTEN))
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(BKU_SHARED))

FM_VARIANTS = Bku
# FM_MERGE_DUP = false（2026-10-03，agent/misc-core）：★加强不是放宽★——FM 逐个比寄存器、不先合并
# 功能相同的寄存器，比较点只会更多；同时让 fm_predict 的 passing 模型适用（merge 打开时模型不成立）。
FM_MERGE_DUP = false
FM_REF_DEPS_Bku = $(BKU_LEAVES)

# vmucp：Bku 已在白名单上（verif/fm_target_config/Bku.tcl，20 个 funcReg 死位的对称双射，2026-09-14 依据）。
# 那份 receipt 产生时 vmucp 不需要 Makefile 开；现行 fm_eq.tcl 要 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true
# 才开（2026-10-03 本 lane 第一次正式跑没开 ⇒ native SUCCEEDED、unread 20、validator PARTIAL，
# evidence/a757ff84032a/Bku 留作记录）。standing rule 第 3 条：开了以后 passing 必须正好 +20。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# 注：G0 那一轮 Bku 的 FM 需要 FM_MERGE_DUP=false（funcReg 在顶层与四个子块各有同值副本，合并 pass
# 会在 u_core 层次边界两侧做不对称折叠）。本轮起上面已固定为 false。

include ../../../scripts/ut_common.mk

# golden 头部的 initial 随机化块靠 SYNTHESIS 关掉（两侧寄存器一致地起 X）
VCS += +define+SYNTHESIS
