# ICacheMissUnit —— ICache 未命中处理单元（MSHR 阵列 + TileLink refill）
#
# 本目标只重写"父层胶水"：MSHR 阵列的连线、去重、发射顺序、回填状态机、
# DiffTest 探针。19 种子模块（14 个 ICacheMSHR 变体 + 2 个 DeMultiplexer +
# MuxBundle + Arbiter5_MSHRAcquire + FIFOReg）都是本工程已有的可读重写件，
# 本层直接例化。
#
# ★ 子模块放 RTL_GOLDEN_DEPS，不放 GOLDEN_SRCS ★
#   RTL_GOLDEN_DEPS 里的文件不 derive、不改名，于是 golden 的 ICacheMissUnit
#   与派生出来的 ICacheMissUnit_xs **例化的是同一批子模块定义**，两侧建模对称。
#   放 GOLDEN_SRCS 只会喂给 golden 一侧 —— 那正是本轮 SNXbar/RNXbar 踩的坑
#   （impl 侧读不到子模块被当黑盒，FM 出现上千个 unmatched）。
#   这里同源的那一份取**重写件**：这样 UT 验的是"整棵可读子树 vs golden 父层"，
#   与最终进芯片的形态一致。
#
# ★ 集成者可一键切换的取舍（改 RTL_GOLDEN_DEPS 里的路径前缀，别的都不用动）★
#   现状 $(RTL_DIR)/frontend/… ：UT 两侧同源用**可读子树**；FM 则是
#       ref = golden 父 + golden 子闭包，impl = 可读父 + 可读子闭包 ——
#       整棵子树一起证，与进芯片的形态一致，但任一子模块的残留问题会算到本目标头上。
#   改成 $(GOLDEN_RTL)/…（Ftq 的写法）：UT/FM 两侧都用 golden 子模块，
#       证明范围收窄成"只验父层胶水"，与 CONVENTIONS「非本目标的子模块两侧同名配对」
#       的口径一致。两种都对称、都不会出现 SNXbar 那种单侧黑盒；选哪个由集成者定。
#   实测：本 UT 在"可读子树"模式下 seed 1/7/42 各 200k 拍 errors=0。
#   golden 子模块模式**未实测**（FM/heavy 冻结期没跑），切换前请自己跑一遍。
MODULE = ICacheMissUnit

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheMissUnit.sv
TB_SRCS  = tb.sv

# golden 顶层（被比对的 ref）——只有它，子模块由下面的可读件提供
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMissUnit.sv

# 19 种子模块的可读实现 + 它们共享的参数化核（两侧同源 elaborate）
RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/xs_ICacheMSHR_core.sv \
  $(RTL_DIR)/frontend/ICacheMSHR.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_1.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_2.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_3.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_4.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_5.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_6.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_7.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_8.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_9.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_10.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_11.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_12.sv \
  $(RTL_DIR)/frontend/ICacheMSHR_13.sv \
  $(RTL_DIR)/frontend/xs_DeMultiplexer_core.sv \
  $(RTL_DIR)/frontend/DeMultiplexer.sv \
  $(RTL_DIR)/frontend/DeMultiplexer_1.sv \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/frontend/Arbiter5_MSHRAcquire.sv \
  $(RTL_DIR)/frontend/MuxBundle.sv \
  $(RTL_DIR)/frontend/FIFOReg.sv

FM_VARIANTS = ICacheMissUnit
# FM 侧 ref 依赖 = golden 的同一批子模块（ref 侧走 golden 闭包，impl 侧走
# RTL_GOLDEN_DEPS 的可读闭包，两侧都完整 elaborate，无黑盒）
FM_REF_DEPS_ICacheMissUnit = \
  DeMultiplexer.sv DeMultiplexer_1.sv MuxBundle.sv Arbiter5_MSHRAcquire.sv FIFOReg.sv \
  ICacheMSHR.sv ICacheMSHR_1.sv ICacheMSHR_2.sv ICacheMSHR_3.sv ICacheMSHR_4.sv \
  ICacheMSHR_5.sv ICacheMSHR_6.sv ICacheMSHR_7.sv ICacheMSHR_8.sv ICacheMSHR_9.sv \
  ICacheMSHR_10.sv ICacheMSHR_11.sv ICacheMSHR_12.sv ICacheMSHR_13.sv

# 端口顺序也当硬闸（本 wrapper 与 golden 端口表逐位同序）
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2（Scala assert 的落地），
# 编译期就报未定义函数；同 Ftq/Fence/PreDecode 先例，两侧统一定义 SYNTHESIS，
# 把断言段与随机初值段一起关掉（有复位的寄存器 time 0 由异步复位清零，
# 无复位的 last_fire_r/id_r 第一个 posedge 就被写定，所以本 UT 实测零 X）。
VCS += +define+SYNTHESIS
