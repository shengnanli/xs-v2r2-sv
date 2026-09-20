MODULE = ArrayMulDataModule

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/C22.sv \
           $(RTL_DIR)/backend/CSA3_2.sv \
           $(RTL_DIR)/backend/C32.sv \
           $(RTL_DIR)/backend/C53.sv \
           $(RTL_DIR)/backend/ArrayMulDataModule.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/C22.sv $(GOLDEN_RTL)/CSA3_2.sv $(GOLDEN_RTL)/C32.sv \
              $(GOLDEN_RTL)/C53.sv $(GOLDEN_RTL)/ArrayMulDataModule.sv

# 五个 golden 顶层都在本 UT 里对位（乘法阵列 + 它的三个压缩器 + C53 的子实例 CSA3_2）
FM_VARIANTS = ArrayMulDataModule C22 C32 C53 CSA3_2
FM_REF_DEPS_ArrayMulDataModule = C22.sv C32.sv C53.sv CSA3_2.sv
FM_REF_DEPS_C53                = CSA3_2.sv

PORTLINT_ORDER = fail

# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false —— ★加强，不是放宽★
#
# 首跑（默认 merge_duplicated_registers=true）实测：
#   native SUCCEEDED / passing 2658 / failing 0 / aborted 0 / 无黑盒 / 无 dont_verify，
#   但 **32 个 unmatched（31 ref + 1 impl）** 卡住 strict 判定
#   （reason=strict_unmatched!=0）。
#
# 诊断（逐名对上，不是猜）：
#   31 个 ref 孤儿 = r_{1285,1348,1409,1468,1525,1580,1633,1684,1733,1780,1825,
#                      1868,1909,1948,1985,2020,2053,2084,2113,2140,2165,2188,
#                      2209,2228,2245,2260,2273,2284,2293,2300,2305}_reg
#   这**恰好**是 golden 里全部 31 条 `r_N <= io_regEnables_0 | r_N;`
#   （ArrayMulDataModule.sv L9008-9038）—— firtool 把部分积里的常数 1
#   （`Cat(1.U(1.W), ~s, pp_temp, t)` 的最高位）与 RegEnable 折叠出来的
#   **粘滞常数寄存器**，无复位，使能一到就永远是 1。复跑核对：
#     grep -cE '^\s+r_[0-9]+ <= io_regEnables_0 \| r_[0-9]+;' $(GOLDEN_RTL)/ArrayMulDataModule.sv  # 31
#   1 个 impl 孤儿 = u_core/pp_reg_reg[1285] —— FM 把 impl 侧这 31 位合并成了
#   **一个**幸存者，而且幸存者下标 1285 与 golden 第一个 r_1285 同号
#   （顺带独立佐证了本重写件 pp_reg 的打平下标与 golden r_N 逐个对齐）。
#   FM 自己给出的单元类型就是常数 DFF：ref 侧 DFF1X / impl 侧 DFF1。
#   即：ref 侧一个都不合并（31 个全留）、impl 侧合并成 1 个 ⇒ 31 ref 孤儿 + 1 impl 孤儿。
#
# 这不是 RTL 差异。同一形态 verif/ut/MulUnit 已有控制实验取证（见其 Makefile 与
# diag/）：拿与 golden **逐字节相同**的模块只套一层 u_core 当 impl 侧，两侧零逻辑
# 差异，FM 照样报出同样的不对称 —— 成因是「impl 侧多一层层次」触发的工具建模差异。
# 本目标的 impl 侧同样多一层 u_core。
#
# 处置 FM_MERGE_DUP=false：不黑盒、不跳点、不加白名单、不约束 ref，只是要求 FM
# **逐个而不是合并后**比这 31 个寄存器 —— 比默认更严。
# ★验收必须复验 passing 真的增加★：passing 不增就说明 FM 根本没去比，那是空转不算过。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# 编译期只负责"打开 initreg 机制"，取值在运行期由 +vcs+initreg+$(INITREG) 选。
# 两处都要给：只给编译期的 +0 会拒编，只给运行期会被静默忽略（Warning-[VICIU]）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
