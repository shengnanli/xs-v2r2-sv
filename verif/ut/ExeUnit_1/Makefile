MODULE = ExeUnit_1

# ExeUnit_1：执行单元外壳 —— BranchUnit / JumpUnit（延迟 0、无门控、无 inPipe；各自一份 instrAddrTransType 打拍）。
# wrapper rtl/backend/ExeUnit_1.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（rewrite 优先，逐模块查 docs/coverage_three_axis.tsv，全部 PROVEN_*）：
#   RTL_SRCS        —— 已签核重写件（含本 lane 的叶子），两侧白盒：impl 读重写件、ref 读 golden；
#   RTL_GOLDEN_DEPS —— 无重写件的 PROVEN_IN_CONE 件两侧同读 golden。
# 无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExeUnit_1.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_1.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/backend/BranchUnit.sv \
           $(RTL_DIR)/backend/BranchModule.sv \
           $(RTL_DIR)/backend/AddrAddModule.sv \
           $(RTL_DIR)/backend/JumpUnit.sv \
           $(RTL_DIR)/backend/JumpDataModule.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_1.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_1))

FM_VARIANTS = ExeUnit_1
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_1 = \
                        BranchUnit.sv \
                        BranchModule.sv \
                        SubModule.sv \
                        AddrAddModule.sv \
                        JumpUnit.sv \
                        JumpDataModule.sv \
                        Dispatcher_1.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
