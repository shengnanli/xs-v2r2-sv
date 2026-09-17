
MODULE = TLBFA

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBFA_core.sv \
           $(RTL_DIR)/memblock/TLBFA.sv \
           $(RTL_DIR)/memblock/TLBFA_1.sv \
           $(RTL_DIR)/memblock/TLBFA_2.sv \
           $(RTL_DIR)/memblock/TLBFA_3.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBFA.sv $(GOLDEN_RTL)/TLBFA_1.sv \
              $(GOLDEN_RTL)/TLBFA_2.sv $(GOLDEN_RTL)/TLBFA_3.sv

# 四个变体都是自足叶子：golden 侧 0 子模块、0 厂商宏，故无 FM_REF_DEPS_*。
FM_VARIANTS = TLBFA TLBFA_1 TLBFA_2 TLBFA_3

include ../../../scripts/ut_common.mk

# ★必须在 include 之后★：ut_common.mk 用的是 `VCS := vcs ...`（简单赋值），
# 写在前面会被整根覆盖掉（本 UT 第一次就这么踩了一脚：SYNTHESIS 没生效，
# golden 的断言块里未定义的 xs_assert_v2 当场 4 个 Error-[IND]）。
#
# golden 里 `ifndef SYNTHESIS 的两块东西必须关掉，口径才与 FM 一致：
#   1) XSError("refill, duplicate with existing entries") 断言块调用未定义的
#      xs_assert_v2；本 UT 的激励**故意**会写重复项（那是制造多命中的唯一办法），
#      不关掉它会满屏断言。
#   2) initial 随机化块；关掉后两侧无复位寄存器一致地起 X，再由 +vcs+initreg 统一给值。
#
VCS += +define+SYNTHESIS +vcs+initreg+random

# ★上电初值两轮都要跑★：本模块 golden 有 7948~8227 位寄存器**不复位**
# （只有 48 个 v 位带复位，见 reset_domain_check.py），只跑一种初值等于没验复位域。
#   make run SEED=1            # 随机上电值（编译期默认）
#   make INITREG=0 run SEED=1  # 全 0 上电值
# 不需要重新编译：initreg 的**取值**是运行期 plusarg，编译行上那个 +vcs+initreg+random
# 只是打开这套机制。照 CONVENTIONS.md 的字面把 +vcs+initreg+0 写到编译行上会当场拒编：
#   Error-[OBSL_OPT_E] Obsolete option 'vcs+initreg+0' used. Please use
#   +vcs+initreg+random at compile time and choose either 0|1|random|<seed>
#   at runtime using +vcs+initreg.        （VCS W-2024.09-SP1 实测）
# 仓库里其它 UT 用的也是运行期写法（SIM_ARGS += +vcs+initreg+0），这里只是把它参数化，
# 好让两轮都能从同一个 simv 跑出来。
INITREG ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
