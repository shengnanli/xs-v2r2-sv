MODULE = LoadQueueReplay

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LoadQueueReplay.sv
TB_SRCS  = tb.sv

# UT 侧需要三个子模块的真实定义（两侧共用同一份，即"同一个黑盒"）。
#  放 GOLDEN_SRCS 而不是 RTL_GOLDEN_DEPS：后者会被并进 FM_IMPL_SRCS，那样 ref 侧
#  黑盒、impl 侧却有定义，两边不对称。FM 要的是**两侧都不给定义**（matched blackbox）。
#  LqVAddrModule 自己还要 DelayN_13 / DelayNWithValid_152 / _155。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueReplay.sv \
              $(GOLDEN_RTL)/LqVAddrModule.sv \
              $(GOLDEN_RTL)/FreeList_5.sv \
              $(GOLDEN_RTL)/AgeDetector_38.sv \
              $(GOLDEN_RTL)/DelayN_13.sv \
              $(GOLDEN_RTL)/DelayNWithValid_152.sv \
              $(GOLDEN_RTL)/DelayNWithValid_155.sv

# FM：ref 侧只给 golden LoadQueueReplay.sv，三个子模块两侧都不给定义 →
#  matched blackbox pair（LqVAddrModule / FreeList_5 / AgeDetector_38 ×3，共 5 个实例）。
#  黑盒边界审核：FreeList_5 是已独立签核目标（FM SUCCEEDED p724 f0 um0 @aad807db4fb6）；
#  LqVAddrModule 与 AgeDetector_38 当前 REWRITTEN/UNPROVEN ⇒ 本目标转绿是**条件绿**，
#  依赖这两个目标各自签核。★不是无条件通过，见 docs 里的依赖声明。★
FM_REF_DEPS_LoadQueueReplay =
FM_VARIANTS = LoadQueueReplay

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块会调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
