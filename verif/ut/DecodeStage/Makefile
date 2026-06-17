MODULE = DecodeStage

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 类型包（核通过 `include 引入端口表 / 拆装 / 实例 / RAT / stall / perf）
RTL_SRCS = $(RTL_DIR)/backend/decodestage_pkg.sv \
           $(RTL_DIR)/backend/DecodeStage.sv

TB_SRCS  = tb.sv

# golden DecodeStage 例化 DecodeUnit×6 / DecodeUnitComp / VTypeGen 及其传递闭包。
# UT 双例化两侧（u_g 用 golden 顶层；u_i 用可读核，可读核内部同样例化这批 golden 子
# 模块）共用这同一批 golden 定义（全部黑盒，等价比对只验本层 glue）。
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/DecodeUnit.sv \
  $(GOLDEN_RTL)/DecodeUnitComp.sv \
  $(GOLDEN_RTL)/VTypeGen.sv \
  $(GOLDEN_RTL)/FPDecoder.sv \
  $(GOLDEN_RTL)/UopInfoGen.sv \
  $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv \
  $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv \
  $(GOLDEN_RTL)/VecExceptionGen.sv \
  $(GOLDEN_RTL)/VsetModule.sv \
  $(GOLDEN_RTL)/indexedLSUopTable_1.sv $(GOLDEN_RTL)/indexedLSUopTable_2.sv \
  $(GOLDEN_RTL)/indexedLSUopTable_3.sv $(GOLDEN_RTL)/indexedLSUopTable_4.sv \
  $(GOLDEN_RTL)/indexedLSUopTable_5.sv $(GOLDEN_RTL)/indexedLSUopTable_6.sv \
  $(GOLDEN_RTL)/indexedLSUopTable_7.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DecodeStage.sv $(GOLDEN_SUBS)

# FM：golden 顶层 DecodeStage vs 可读同名 wrapper(-> 可读核 + pkg)。
# 两侧都读入同一批 golden 子模块定义，使 ref/impl 把子模块实化为同一份：子模块内部
# 逐位等价自动配对，FM 真正验证的是本层 glue（路由 / 握手 / fusion / 输出修正 /
# RAT / trapInstInfo / perf）相对真实子模块输出是否等价。
WRAPPER_SRCS = $(RTL_DIR)/backend/DecodeStage_wrapper.sv $(GOLDEN_SUBS)
FM_VARIANTS  = DecodeStage
FM_REF_DEPS_DecodeStage = DecodeUnit.sv DecodeUnitComp.sv VTypeGen.sv \
  FPDecoder.sv UopInfoGen.sv strdiedLSNumOfUopTable.sv indexedLSNumOfUopTable.sv \
  VecExceptionGen.sv VsetModule.sv \
  indexedLSUopTable_1.sv indexedLSUopTable_2.sv indexedLSUopTable_3.sv \
  indexedLSUopTable_4.sv indexedLSUopTable_5.sv indexedLSUopTable_6.sv \
  indexedLSUopTable_7.sv

# 子模块含大量同构表项寄存器，关掉合并同值重复寄存器 pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert（非综合）；关随机化以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/backend 下的 .svh
VCS += +incdir+$(RTL_DIR)/backend +incdir+.
