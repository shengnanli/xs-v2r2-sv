MODULE = ExeUnit

# ExeUnit：执行单元外壳 —— Alu / MulUnit / Bku 三个整数 FU（Mul、Bku 门控），inPipe 2 级。
# wrapper rtl/backend/ExeUnit.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（rewrite 优先，逐模块查 docs/coverage_three_axis.tsv，全部 PROVEN_*）：
#   RTL_SRCS        —— 已签核重写件（含本 lane 的叶子），两侧白盒：impl 读重写件、ref 读 golden；
#   RTL_GOLDEN_DEPS —— 无重写件的 PROVEN_IN_CONE 件两侧同读 golden；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/alu_pkg.sv \
           $(RTL_DIR)/backend/ExeUnit.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/backend/Alu.sv \
           $(RTL_DIR)/backend/MulUnit.sv \
           $(RTL_DIR)/backend/ArrayMulDataModule.sv \
           $(RTL_DIR)/backend/C53.sv \
           $(RTL_DIR)/backend/CSA3_2.sv \
           $(RTL_DIR)/backend/C22.sv \
           $(RTL_DIR)/backend/Bku.sv \
           $(RTL_DIR)/backend/CountModule.sv \
           $(RTL_DIR)/backend/ClmulModule.sv \
           $(RTL_DIR)/backend/MiscModule.sv \
           $(RTL_DIR)/backend/HashModule.sv \
           $(RTL_DIR)/backend/BlockCipherModule.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/CryptoModule.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit))

FM_VARIANTS = ExeUnit
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit = \
                      Alu.sv \
                      AluDataModule.sv \
                      LeftShiftModule.sv \
                      RightShiftModule.sv \
                      AddModule.sv \
                      SubModule.sv \
                      LeftShiftWordModule.sv \
                      RightShiftWordModule.sv \
                      ShiftResultSelect.sv \
                      MiscResultSelect.sv \
                      ConditionalZeroModule.sv \
                      WordResultSelect.sv \
                      AluResSel.sv \
                      MulUnit.sv \
                      ArrayMulDataModule.sv \
                      C22.sv \
                      C32.sv \
                      C53.sv \
                      CSA3_2.sv \
                      Bku.sv \
                      CountModule.sv \
                      ClmulModule.sv \
                      MiscModule.sv \
                      CryptoModule.sv \
                      HashModule.sv \
                      BlockCipherModule.sv \
                      ClockGate.sv \
                      Dispatcher.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：子 FU 内两侧对称死位，依据见 verif/fm_target_config/ExeUnit.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
