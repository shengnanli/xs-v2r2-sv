MODULE = IMSIC

# IMSIC（per-hart AIA 中断控制器）。golden 直接 child：IntFile ×9（本 lane 重写签核）+ IMSICGateWay
# （本仓已签核，PROVEN_DIRECT）；IMSICGateWay 内的 3 级异步复位同步链（AsyncResetSynchronizer*）
# 不是厂商宏也不是独立目标，与 verif/ut/IMSICGateWay 同样做法：两侧同源 elaborate（RTL_GOLDEN_DEPS +
# FM_REF_DEPS），无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/IMSICGateWay.sv \
           $(RTL_DIR)/uncore/IntFile.sv \
           $(RTL_DIR)/uncore/IMSIC.sv
TB_SRCS  = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                  $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IMSIC.sv \
              $(GOLDEN_RTL)/IntFile.sv \
              $(GOLDEN_RTL)/IMSICGateWay.sv
FM_VARIANTS = IMSIC
FM_REF_DEPS_IMSIC = IntFile.sv IMSICGateWay.sv \
                    AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                    AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

# 关 merge_dup：fm_predict 的模型只在 false 下严格适用；加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 不复位寄存器（各文件 rdata 打拍 ×9、illegal 打拍）在 +random 档两侧初值不同，
# 它们在复位撤销后第一拍就被写成确定值；tb 从复位撤销后第 2 拍起比对（见 tb.sv 文件头）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
