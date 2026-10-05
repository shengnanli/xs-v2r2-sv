MODULE = ExeUnit_5

# ExeUnit_5：执行单元外壳 —— brh / jmp / i2f(IntToFP_3) / VSetRiWi / VSetRiWvf / i2v(IntFPToVec)；i2f 门控，inPipe 2 级。
# wrapper rtl/backend/ExeUnit_5.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（rewrite 优先，逐模块查 docs/coverage_three_axis.tsv，全部 PROVEN_*）：
#   RTL_SRCS        —— 已签核重写件（含本 lane 的叶子），两侧白盒：impl 读重写件、ref 读 golden；
#   RTL_GOLDEN_DEPS —— 无重写件的 PROVEN_IN_CONE 件两侧同读 golden；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/backend_common_pkg.sv \
           $(RTL_DIR)/backend/ExeUnit_5.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_5.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/backend/BranchUnit.sv \
           $(RTL_DIR)/backend/BranchModule.sv \
           $(RTL_DIR)/backend/AddrAddModule.sv \
           $(RTL_DIR)/backend/JumpUnit.sv \
           $(RTL_DIR)/backend/JumpDataModule.sv \
           $(RTL_DIR)/backend/IntToFP_3.sv \
           $(RTL_DIR)/backend/IntToFPDataModule.sv \
           $(RTL_DIR)/backend/IntToFP.sv \
           $(RTL_DIR)/backend/IntToFP_prenorm.sv \
           $(RTL_DIR)/backend/LZA.sv \
           $(RTL_DIR)/common/CLZ.sv \
           $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/backend/IntToFP_postnorm.sv \
           $(RTL_DIR)/backend/RoundingUnit.sv \
           $(RTL_DIR)/backend/IntToFP_1.sv \
           $(RTL_DIR)/backend/IntToFP_postnorm_1.sv \
           $(RTL_DIR)/backend/RoundingUnit_1.sv \
           $(RTL_DIR)/backend/IntToFP_2.sv \
           $(RTL_DIR)/backend/IntToFP_postnorm_2.sv \
           $(RTL_DIR)/backend/RoundingUnit_2.sv \
           $(RTL_DIR)/backend/VSetRiWi.sv \
           $(RTL_DIR)/backend/VSetRiWvf.sv \
           $(RTL_DIR)/backend/IntFPToVec.sv \
           $(RTL_DIR)/backend/FliHTable.sv \
           $(RTL_DIR)/backend/FliSTable.sv \
           $(RTL_DIR)/backend/FliDTable.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_5.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_5))

FM_VARIANTS = ExeUnit_5
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_5 = \
                        BranchUnit.sv \
                        BranchModule.sv \
                        SubModule.sv \
                        AddrAddModule.sv \
                        JumpUnit.sv \
                        JumpDataModule.sv \
                        IntToFP_3.sv \
                        IntToFPDataModule.sv \
                        IntToFP.sv \
                        IntToFP_prenorm.sv \
                        LZA.sv \
                        CLZ.sv \
                        IntToFP_postnorm.sv \
                        RoundingUnit.sv \
                        IntToFP_1.sv \
                        IntToFP_postnorm_1.sv \
                        RoundingUnit_1.sv \
                        IntToFP_2.sv \
                        IntToFP_postnorm_2.sv \
                        RoundingUnit_2.sv \
                        VSetRiWi.sv \
                        VsetModule.sv \
                        VSetRiWvf.sv \
                        IntFPToVec.sv \
                        FliHTable.sv \
                        FliSTable.sv \
                        FliDTable.sv \
                        ClockGate.sv \
                        Dispatcher_5.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
