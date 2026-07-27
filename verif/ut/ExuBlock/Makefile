MODULE = ExuBlock

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exublock_pkg.sv \
           $(RTL_DIR)/backend/ExuBlock.sv

TB_SRCS = variants_xs.sv tb.sv

# ExeUnit 各变体(功能单元实体)两侧 elaborate;其叶子 FU / glue 见下。
SUB_DEPS = $(GOLDEN_RTL)/ExeUnit.sv \
           $(GOLDEN_RTL)/ExeUnit_1.sv \
           $(GOLDEN_RTL)/ExeUnit_4.sv \
           $(GOLDEN_RTL)/ExeUnit_5.sv \
           $(GOLDEN_RTL)/ExeUnit_7.sv

# 非-305、无子叶的纯 glue/时钟门控/延迟链叶子 —— **两侧 elaborate**(白盒),
# 让 FM 真正逐位比对(不入黑盒、不入 assembly_depends)。ExeUnit(绿)先例同法。
#   ClockGate     : 集成时钟门控 latch cell(14 行, 0 子);
#   Dispatcher*   : 纯组合 in1ToN 分发路由(0 子);
#   DelayN_216/217: CSR 例外/robDeqPtr 打拍延迟链(0 子)。
#   IntFPToVec + Fli{H,S,D}Table: FP→vec 打包 + 三张 Float-Load-Immediate 纯组合 ROM(0 子);
#   VSetRiWvf + VsetModule       : vset 立即数(vl 计算)—— VsetModule 与绿 305 VSetRiWi 同款叶。
GLUE_LEAVES = $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/Dispatcher.sv \
              $(GOLDEN_RTL)/Dispatcher_1.sv \
              $(GOLDEN_RTL)/Dispatcher_4.sv \
              $(GOLDEN_RTL)/Dispatcher_5.sv \
              $(GOLDEN_RTL)/Dispatcher_7.sv \
              $(GOLDEN_RTL)/DelayN_216.sv \
              $(GOLDEN_RTL)/DelayN_217.sv \
              $(GOLDEN_RTL)/IntFPToVec.sv \
              $(GOLDEN_RTL)/FliHTable.sv \
              $(GOLDEN_RTL)/FliSTable.sv \
              $(GOLDEN_RTL)/FliDTable.sv \
              $(GOLDEN_RTL)/VSetRiWvf.sv \
              $(GOLDEN_RTL)/VsetModule.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ExuBlock.sv $(SUB_DEPS) $(GLUE_LEAVES)

# FM:impl 侧(wrapper→可读核)与 ref 侧在相同层次黑盒化 FU 叶(Alu/Mul/Bku/Brh/Jmp/
# Div/Fence/VSetRiWi=绿 305 target),CSR/IntToFP_3/IntFPToVec/VSetRiWvf 亦对称黑盒;
# glue 叶(ClockGate/Dispatcher*/DelayN)两侧同份 golden 定义 → 白盒逐位比对。
WRAPPER_SRCS = $(RTL_DIR)/backend/ExuBlock_wrapper.sv $(SUB_DEPS) $(GLUE_LEAVES)
FM_VARIANTS = ExuBlock
FM_REF_DEPS_ExuBlock = ExeUnit.sv ExeUnit_1.sv ExeUnit_4.sv ExeUnit_5.sv ExeUnit_7.sv \
                       ClockGate.sv Dispatcher.sv Dispatcher_1.sv Dispatcher_4.sv \
                       Dispatcher_5.sv Dispatcher_7.sv DelayN_216.sv DelayN_217.sv \
                       IntFPToVec.sv FliHTable.sv FliSTable.sv FliDTable.sv \
                       VSetRiWvf.sv VsetModule.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# ExeUnit 黑盒内例化更深的 golden 叶子(Alu/CSR/Dispatcher/...),用 -y 库目录自动解析。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
