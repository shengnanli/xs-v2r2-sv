MODULE = MemCtrl

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/MemCtrl_core.sv
# 包装层 + 两侧同源例化的 golden 子模块(SSIT/WaitTable + SSIT 的 SyncDataModuleTemplate)。
# FM assembly 模式下 SSIT/WaitTable 声明为对称黑盒(FM_INTERFACE_ONLY), 只证本层 glue;
# UT 侧则例化真 golden 体做逐拍比对。SyncDataModuleTemplate 仅 SSIT 体需要(UT 编译)。
# SSIT 子树完整闭包(UT 编译真体; FM assembly 黑盒不需要):
#   SSIT -> SyncDataModuleTemplate__1024entry{,_1} -> DataModule__64entry{,_16}
SSIT_CLOSURE = $(GOLDEN_RTL)/SSIT.sv $(GOLDEN_RTL)/WaitTable.sv \
               $(GOLDEN_RTL)/SyncDataModuleTemplate__1024entry.sv \
               $(GOLDEN_RTL)/SyncDataModuleTemplate__1024entry_1.sv \
               $(GOLDEN_RTL)/DataModule__64entry.sv \
               $(GOLDEN_RTL)/DataModule__64entry_16.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/MemCtrl_wrapper.sv $(SSIT_CLOSURE)
GOLDEN_SRCS = $(GOLDEN_RTL)/MemCtrl.sv $(SSIT_CLOSURE)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = MemCtrl
# golden 侧闭包(相对 GOLDEN_RTL)
FM_REF_DEPS_MemCtrl = SSIT.sv WaitTable.sv SyncDataModuleTemplate__1024entry.sv SyncDataModuleTemplate__1024entry_1.sv
# assembly: SSIT/WaitTable 对称黑盒(它们在此 config 下无观测输出=cone-dead 子树;
# 见 docs/backend/MemCtrl.md 的诚实定级)。本层只证 7 个更新流水寄存器 glue。
FM_MODE = assembly
FM_INTERFACE_ONLY = SSIT WaitTable

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
