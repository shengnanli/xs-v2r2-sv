MODULE = MulUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核内例化 golden 同名 ArrayMulDataModule 黑盒）
RTL_SRCS = $(RTL_DIR)/backend/mulunit_pkg.sv \
           $(RTL_DIR)/backend/MulUnit.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 乘法阵列黑盒 ArrayMulDataModule 及其叶子单元 C22/C32/C53。
# UT 双例化两侧共用同一份阵列实现，比对只检验 wrapper 的译码/符号扩展/流水/结果选择。
GOLDEN_SRCS = $(GOLDEN_RTL)/MulUnit.sv \
              $(GOLDEN_RTL)/ArrayMulDataModule.sv \
              $(GOLDEN_RTL)/C22.sv $(GOLDEN_RTL)/C32.sv $(GOLDEN_RTL)/C53.sv \
              $(GOLDEN_RTL)/CSA3_2.sv

# FM：golden 顶层 MulUnit vs 手写同名 wrapper（→ 可读核）。乘法阵列 ArrayMulDataModule
# 在两侧都不提供 RTL，让 FM 按 hdlin_unresolved_modules=black_box 当作未解析黑盒
# （两侧同名同端口的黑盒，其输出作为黑盒输出按名配对）。这样 FM 只比对 wrapper 的
# 译码/符号扩展/流水/结果选择逻辑，不进入阵列内部（阵列内部多级流水寄存器在
# wrapper/u_core 层次边界两侧会被不对称地常量传播，读入反而失配）。
WRAPPER_SRCS = $(RTL_DIR)/backend/MulUnit_wrapper.sv \
               $(GOLDEN_RTL)/ArrayMulDataModule.sv \
               $(GOLDEN_RTL)/C22.sv $(GOLDEN_RTL)/C32.sv $(GOLDEN_RTL)/C53.sv \
               $(GOLDEN_RTL)/CSA3_2.sv
FM_VARIANTS = MulUnit
FM_REF_DEPS_MulUnit = ArrayMulDataModule.sv C22.sv C32.sv C53.sv CSA3_2.sv

# 关闭 FM 的“合并同值重复寄存器”pass：阵列黑盒 ArrayMulDataModule 在两侧分别处于
# golden 顶层 / 手写 wrapper→u_core 层次下，合并 pass 会在 u_core 边界两侧做不对称的
# 常量传播（阵列内部 “Constrained 1X” 死寄存器被一侧折叠、另一侧保留），把同源黑盒
# 误判为不等价。关掉合并后两侧黑盒按名一一配对即可干净比对。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 等非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
