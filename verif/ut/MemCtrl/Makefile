MODULE = MemCtrl

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/MemCtrl_core.sv
# 包装层 + 两侧同源例化的 golden 子模块(SSIT/WaitTable + SSIT 的 SyncDataModuleTemplate)。
# SSIT/WaitTable 均为纯寄存器逻辑(无厂商 SRAM 宏), 故 FM 两侧真 elaborate 同一份 golden 源
# => 完整对称子树(既非 interface_only 黑盒, 也无 dont_verify)。
# UT 侧同样例化真 golden 体做逐拍比对。
# SSIT 子树完整闭包:
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
# golden 侧完整闭包(相对 GOLDEN_RTL): SSIT/WaitTable + SyncDataModuleTemplate + DataModule 叶子。
FM_REF_DEPS_MemCtrl = SSIT.sv WaitTable.sv \
                      SyncDataModuleTemplate__1024entry.sv SyncDataModuleTemplate__1024entry_1.sv \
                      DataModule__64entry.sv DataModule__64entry_16.sv
# signoff-strict(默认): SSIT/WaitTable 两侧真 elaborate。它们的读路径在此 config 下被
# firtool 裁成 cone-dead(SSIT 读输出不出 MemCtrl 边界)→ 大量写不读的内部寄存器成为
# **对称 matched-unread**(ref==impl 完美双射, 因两侧读同一份 golden 源)。
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM **实际比较**这些对称死寄存器证等价
# (非 waiver: true 是要求 FM 证明更多)→ 0 unread clean strict SUCCEEDED。
# 须 main 把 MemCtrl 加入 fm_eq.tcl / run_signoff_target.sh 白名单(见 docs/backend/MemCtrl.md)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
