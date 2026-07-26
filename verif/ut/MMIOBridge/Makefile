MODULE = MMIOBridge

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_MMIOBridge_core(顶层分配/仲裁/路由 glue 重写, 11 子模块按 golden 名例化)。
RTL_SRCS = $(RTL_DIR)/l2/MMIOBridge.sv
# FM impl 侧: golden 同名扁平端口包装 + 8 MMIOBridgeEntry(_2/_4)两侧 elaborate
# (逻辑 child 非黑盒)。3 绿仲裁器不列 → impl 侧亦 unresolved → 对称黑盒。
WRAPPER_SRCS = $(RTL_DIR)/l2/MMIOBridge_wrapper.sv \
               $(GOLDEN_RTL)/MMIOBridgeEntry.sv \
               $(GOLDEN_RTL)/MMIOBridgeEntry_2.sv \
               $(GOLDEN_RTL)/MMIOBridgeEntry_4.sv

# golden 顶层 + 全部子模块(8 条目 3 变体 + 3 仲裁器, 无厂商宏)。
GOLDEN_SRCS = $(GOLDEN_RTL)/MMIOBridge.sv \
              $(GOLDEN_RTL)/MMIOBridgeEntry.sv \
              $(GOLDEN_RTL)/MMIOBridgeEntry_2.sv \
              $(GOLDEN_RTL)/MMIOBridgeEntry_4.sv \
              $(GOLDEN_RTL)/RRArbiterInit_11.sv \
              $(GOLDEN_RTL)/Arbiter8_CHIDAT.sv \
              $(GOLDEN_RTL)/Arbiter8_TLBundleD.sv
# UT 变体: impl 顶层改名 MMIOBridge_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 assembly。3 绿 AUX 仲裁器(txreqArb=RRArbiterInit_11 / mmio_txdat_arb=
# Arbiter8_CHIDAT / mmio_channel_D_arb=Arbiter8_TLBundleD)两侧 unresolved →
# hdlin_unresolved_modules=black_box 对称边界(assembly depends_on; allow/MMIOBridge.json)。
# 8 MMIOBridgeEntry(_2/_4)两侧 elaborate golden RTL(逻辑 child, 非黑盒, ref==impl 同源;
# 待独立 signoff 后 MMIOBridge 全子树绿)。
FM_VARIANTS = MMIOBridge
FM_MODE = assembly
FM_REF_DEPS_MMIOBridge = MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv
FM_INTERFACE_ONLY = 1

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
VCS += -assert disable
