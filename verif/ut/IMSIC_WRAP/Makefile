MODULE = IMSIC_WRAP

# IMSIC_WRAP（CSR 里包 IMSIC 的直通壳；ChiselAIA IMSIC_WRAP，本配置无 TEE 扩展，0 行逻辑）。
# golden 唯一 child IMSIC 已签核（PROVEN_DIRECT, rtl/uncore/IMSIC.sv），按规范两侧白盒：
# ref = golden IMSIC_WRAP + golden IMSIC 闭包；impl = 重写 IMSIC_WRAP + 重写 IMSIC/IntFile/IMSICGateWay。
# IMSICGateWay 内 3 级异步复位同步链（AsyncResetSynchronizer*）与 verif/ut/IMSIC 同样做法：
# 两侧同源 elaborate（RTL_GOLDEN_DEPS + FM_REF_DEPS），无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/IMSICGateWay.sv \
           $(RTL_DIR)/uncore/IntFile.sv \
           $(RTL_DIR)/uncore/IMSIC.sv \
           $(RTL_DIR)/backend/IMSIC_WRAP.sv
TB_SRCS  = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                  $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IMSIC_WRAP.sv \
              $(GOLDEN_RTL)/IMSIC.sv \
              $(GOLDEN_RTL)/IntFile.sv \
              $(GOLDEN_RTL)/IMSICGateWay.sv
FM_VARIANTS = IMSIC_WRAP
FM_REF_DEPS_IMSIC_WRAP = IMSIC.sv IntFile.sv IMSICGateWay.sv \
                         AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                         AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

# 关 merge_dup：fm_predict 的模型只在 false 下严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 不复位寄存器（各文件 rdata 打拍 ×9、illegal 打拍）在 +random 档两侧初值不同，
# 它们在复位撤销后第一拍就被写成确定值；tb 从复位撤销后第 2 拍起比对（见 tb.sv 文件头）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
