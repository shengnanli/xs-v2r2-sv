MODULE = DecodeUnit

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 译码表包（pkg 必须先编译）
RTL_SRCS = $(RTL_DIR)/backend/decodeunit_pkg.sv \
           $(RTL_DIR)/backend/DecodeUnit.sv

TB_SRCS  = tb.sv

# golden 顶层 DecodeUnit + 黑盒子模块（FPDecoder / UopInfoGen 及其查表子模块）
GOLDEN_SRCS = $(GOLDEN_RTL)/DecodeUnit.sv \
              $(GOLDEN_RTL)/FPDecoder.sv \
              $(GOLDEN_RTL)/UopInfoGen.sv \
              $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv \
              $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv

# FM：golden DecodeUnit vs 可读 wrapper（黑盒 FPDecoder/UopInfoGen）
# WRAPPER_SRCS 进 FM impl 读入但不进 UT 编译，因此把 FPDecoder/UopInfoGen 及其
# 子表也列入此处：让 impl 侧也拿到这两个子模块「定义」，FM 黑盒时端口方向已知
# （否则 impl 侧仅凭例化推断出 86 个未知方向黑盒引脚，导致比对 INCONCLUSIVE）。
# 两侧用同一份 golden 子模块定义做黑盒，等价比对只验可读核+wrapper 的组合逻辑。
WRAPPER_SRCS = $(RTL_DIR)/backend/DecodeUnit_wrapper.sv \
               $(GOLDEN_RTL)/FPDecoder.sv \
               $(GOLDEN_RTL)/UopInfoGen.sv \
               $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv \
               $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv
FM_VARIANTS  = DecodeUnit
FM_REF_DEPS_DecodeUnit = FPDecoder.sv UopInfoGen.sv \
                         strdiedLSNumOfUopTable.sv indexedLSNumOfUopTable.sv

include ../../../scripts/ut_common.mk

# svh 头文件搜索路径 + golden 子模块需 SYNTHESIS 关随机化
VCS += +incdir+$(RTL_DIR)/backend +incdir+. +define+SYNTHESIS
