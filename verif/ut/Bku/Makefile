MODULE = Bku

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型/函数包（四个子单元都在 Bku.sv 内）
RTL_SRCS = $(RTL_DIR)/backend/bku_pkg.sv \
           $(RTL_DIR)/backend/Bku.sv

# UT 用 impl 适配模块 Bku_xs（与 golden Bku 同端口、不同名）
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 Bku + 其全部叶子子模块（UT 双例化比对端口等价）
GOLDEN_SRCS = $(GOLDEN_RTL)/Bku.sv \
              $(GOLDEN_RTL)/CountModule.sv \
              $(GOLDEN_RTL)/ClmulModule.sv \
              $(GOLDEN_RTL)/MiscModule.sv \
              $(GOLDEN_RTL)/CryptoModule.sv \
              $(GOLDEN_RTL)/HashModule.sv \
              $(GOLDEN_RTL)/BlockCipherModule.sv

# FM：golden 顶层 Bku（含子模块）vs 手写同名 wrapper（→ 可读核）。
WRAPPER_SRCS = $(RTL_DIR)/backend/Bku_wrapper.sv
FM_VARIANTS = Bku
FM_REF_DEPS_Bku = CountModule.sv ClmulModule.sv MiscModule.sv \
                  CryptoModule.sv HashModule.sv BlockCipherModule.sv

# Bku 含多份同值 funcReg 副本（顶层 + 4 个子单元各一份）。开启“合并同值重复
# 寄存器”会把这些副本在 wrapper/u_core 层次边界两侧做不对称折叠，导致 funcReg
# 与下游 res_data 配不齐而误判失败；关闭后按名/签名逐份配对即可干净比对。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块的 FM/UT 编译需带 SYNTHESIS 关随机化初始块
VCS += +define+SYNTHESIS
