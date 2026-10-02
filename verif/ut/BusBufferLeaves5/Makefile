MODULE = BusBufferLeaves5

# 族 G：5 个总线缓冲叶（prereg 族 G）。两个亚族各一个共享核：
#   xs_SpillRegister_core（两级 skid buffer）：SpillRegister / _2 / _6
#   xs_Repeater_core（TL 握手 repeat）       ：Repeater_1 / Repeater_2
# 薄文件由 scripts/gen_busbuffer_leaves5.py 从 golden 机械生成（--check 幂等，
# 生成前对 golden 做逐字模板校验，fail-closed）。
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/xs_SpillRegister_core.sv \
           $(RTL_DIR)/uncore/xs_Repeater_core.sv \
           $(RTL_DIR)/uncore/SpillRegister.sv \
           $(RTL_DIR)/uncore/SpillRegister_2.sv \
           $(RTL_DIR)/uncore/SpillRegister_6.sv \
           $(RTL_DIR)/uncore/Repeater_1.sv \
           $(RTL_DIR)/uncore/Repeater_2.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SpillRegister.sv \
              $(GOLDEN_RTL)/SpillRegister_2.sv \
              $(GOLDEN_RTL)/SpillRegister_6.sv \
              $(GOLDEN_RTL)/Repeater_1.sv \
              $(GOLDEN_RTL)/Repeater_2.sv
FM_VARIANTS = SpillRegister SpillRegister_2 SpillRegister_6 Repeater_1 Repeater_2

# 端口表由生成器逐字取自 golden（含顺序），顺序不一致也算失败。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# payload 寄存器按 golden 不复位：双例化 UT 只能用常量初值档 ——
# +vcs+initreg+random 会给两个实例各摇各的 payload 初值，空缓冲读 out/deq bits
# 必不等（与重写无关）。编译期 +vcs+initreg+random 只是打开机制，取值由 SIM_ARGS
# 在运行期选 +0（CONVENTIONS 2026-09-17 更正的用法；W-2024.09-SP1 已废弃编译期
# +vcs+initreg+0，别把取值放编译期）。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
