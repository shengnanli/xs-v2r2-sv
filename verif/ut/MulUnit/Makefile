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

# 2026-09-12 复验结论：本轮**确实**踩到了阵列内部寄存器 unmatched（29 个），
# 于是按上面这条注释的指示打开 FM_MERGE_DUP=false。取证见 diag/ 目录。
#
# 症状：signoff-strict 下 29(0) unmatched compare points + 1(0) unmatched unread，
#       全部是 mulDataModule/r_<N>_reg，且 ref 侧独有、impl 侧为 0。
# 根因：**不是** RTL 差异。ArrayMulDataModule.sv 两侧读的是同一个 golden 文件
#       （sha256 0a77831be1b0…），例化名两侧同为 mulDataModule。该文件里有且只有
#       31 个 `r_N <= io_regEnables_0 | r_N;`（第 9008-9038 行）——firtool 把
#       「常数 1 的部分积位 + regEnable」折叠成的粘滞常数寄存器，无复位，
#       Formality 判为 constant-1（report_potentially_constant_registers 报 DFF1）。
#       merge_duplicated_registers=true 时，FM 在 impl 侧把这 31 个合并成 1 个
#       （只剩 r_1285），ref 侧一个都不合并（31 个全留）：
#           ref  r:/WORK/MulUnit/mulDataModule       cells 5177, 31 个 r_N 全在
#           impl i:/WORK/MulUnit/u_core/mulDataModule cells 5147, 只剩 r_1285
#       31 - 1 = 30 个 ref 侧孤儿 = 29 unmatched compare + 1 unmatched unread。
# 控制实验（diag/diag_wrap_MulUnit.sv + diag_golden_MulUnit_inner.sv）：拿与 golden
#       **逐字节相同**的 MulUnit（只改模块声明名）套一层 u_core 空壳当 impl 侧，
#       两侧零逻辑差异，FM 报出**一模一样**的 29(0)/1(0) 和 5177/5147。
#       ⇒ 该不对称 100% 由「impl 侧多一层层次」触发的工具建模差异造成，与可读核无关。
# 处置：FM_MERGE_DUP=false。这是**加强**不是放宽——不黑盒、不跳点、不约束 ref，
#       只是要求 FM 逐个而不是合并后比：两侧 cells 都回到 5180、31 个寄存器全部
#       逐一配对，unmatched 29→0，passing 4535→4537。
FM_MERGE_DUP = false

# matched-unread 加强（vmucp）——★加强证明，不是 waiver★
# FM_MERGE_DUP=false 把 29 个 unmatched 清零之后，仍剩 7 个 matched-unread 卡住
# strict 判定(reason=strict_unread!=0)，全部在 mulDataModule 里：
#   r_2303_reg r_2304_reg r_2306_reg r_2558_reg r_2559_reg r_2560_reg r_2561_reg
# 它们是 ArrayMulDataModule.sv 的部分积/压缩器寄存器，送进 C22/C53 之后该位的
# 输出被后级丢弃，因此无观测路径。ArrayMulDataModule.sv 在 MUL_LEAVES 里，
# ref 与 impl 读的是**同一份 golden 文件**（RTL_GOLDEN_DEPS == FM_REF_DEPS_MulUnit），
# 两侧路径除 u_core 外逐字相同 —— FM 自己配成 matched_nc，ref 7 ↔ impl 7，
# 严格双射，非 matched_nc 的未读项为 0。打开本项让 FM **多证 7 个点**。
# 白名单在 verif/fm_target_config/<top>.tcl（依据就写在那份文件里），两处须同时生效。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 头部的 initial 随机化块靠 SYNTHESIS 关掉（两侧寄存器一致地起 X）
VCS += +define+SYNTHESIS
