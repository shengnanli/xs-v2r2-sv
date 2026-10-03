MODULE = AtomicsUnit

# AtomicsUnit（原子访存执行单元，9 状态串行状态机）。golden 自包含，无子模块实例，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/AtomicsUnit.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AtomicsUnit.sv
FM_VARIANTS = AtomicsUnit

# 关 merge_dup：fm_predict 的模型（闭包寄存器位 + 顶层 output 位）只在它关掉时严格适用（加强不是放宽）
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：62 个 unread 点全是两侧对称死位，依据与六条证据见 verif/fm_target_config/AtomicsUnit.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 不复位寄存器（uop/rs1/操作数/paddr/resp/tdata/difftest 打拍）在 +random 档两侧初值不同，
# tb 先跑一段把它们全部写过一遍（暖机）再开始比对，见 tb.sv 文件头。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
