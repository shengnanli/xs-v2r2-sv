# 自动生成：verif/ut/SRAMTemplateNewForm/gen.py（G1 基线驱动）—— 勿手改
# G1 新形态 SRAMTemplate 九变体（掩码复制 / 分段 MBIST / 外置时钟门控 /
# 多周期宏 / 结构体数据口）。verif/ut/SRAMTemplate 覆盖其余变体，两边共用
# 同一个 rtl/common/xs_SRAMTemplate_core.sv。
MODULE = SRAMTemplateNewForm

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_128.sv \
           $(RTL_DIR)/common/SRAMTemplate_145.sv \
           $(RTL_DIR)/common/SRAMTemplate_146.sv \
           $(RTL_DIR)/common/SRAMTemplate_152.sv \
           $(RTL_DIR)/common/SRAMTemplate_155.sv \
           $(RTL_DIR)/common/SRAMTemplate_163.sv \
           $(RTL_DIR)/common/SRAMTemplate_166.sv \
           $(RTL_DIR)/common/SRAMTemplate_178.sv \
           $(RTL_DIR)/common/SRAMTemplate_185.sv
TB_SRCS = tb.sv

# 厂商 SRAM 宏链：golden 同源文件, 两侧同读(FM impl 侧经 RTL_GOLDEN_DEPS)。
# 宏内 array_*_ext 是 vendor 叶子(.v, FM 不读)⇒ 对称未解析黑盒。
# ClockGate 例外：impl 侧读本地重写签核件 rtl/common/ClockGate.sv（codex 0208），
# ref 侧 FM_REF_DEPS 仍是 golden ClockGate.sv。
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/array_10.sv \
                  $(GOLDEN_RTL)/array_12.sv \
                  $(GOLDEN_RTL)/array_13.sv \
                  $(GOLDEN_RTL)/array_15.sv \
                  $(GOLDEN_RTL)/array_18.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                  $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
                  $(GOLDEN_RTL)/sram_array_1p4096x137m137s1h1l2b_l2_dat.sv \
                  $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x104m13s1h0l1b_l2_meta.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate_128.sv \
              $(GOLDEN_RTL)/SRAMTemplate_145.sv \
              $(GOLDEN_RTL)/SRAMTemplate_146.sv \
              $(GOLDEN_RTL)/SRAMTemplate_152.sv \
              $(GOLDEN_RTL)/SRAMTemplate_155.sv \
              $(GOLDEN_RTL)/SRAMTemplate_163.sv \
              $(GOLDEN_RTL)/SRAMTemplate_166.sv \
              $(GOLDEN_RTL)/SRAMTemplate_178.sv \
              $(GOLDEN_RTL)/SRAMTemplate_185.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/array_10.sv \
              $(GOLDEN_RTL)/array_10_ext.v \
              $(GOLDEN_RTL)/array_12.sv \
              $(GOLDEN_RTL)/array_12_ext.v \
              $(GOLDEN_RTL)/array_13.sv \
              $(GOLDEN_RTL)/array_13_ext.v \
              $(GOLDEN_RTL)/array_15.sv \
              $(GOLDEN_RTL)/array_15_ext.v \
              $(GOLDEN_RTL)/array_18.sv \
              $(GOLDEN_RTL)/array_18_ext.v \
              $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
              $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
              $(GOLDEN_RTL)/sram_array_1p4096x137m137s1h1l2b_l2_dat.sv \
              $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
              $(GOLDEN_RTL)/sram_array_1p512x104m13s1h0l1b_l2_meta.sv

FM_REF_DEPS_SRAMTemplate_128 = sram_array_1p4x786m131s1h0l1b_ptw_l1.sv array_10.sv
FM_REF_DEPS_SRAMTemplate_145 = sram_array_1p32x148m74s1h0l1b_pftch_pht.sv array_12.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_146 = sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv array_13.sv
FM_REF_DEPS_SRAMTemplate_152 = sram_array_1p512x104m13s1h0l1b_l2_meta.sv array_15.sv
FM_REF_DEPS_SRAMTemplate_155 = sram_array_1p4096x137m137s1h1l2b_l2_dat.sv array_18.sv
FM_REF_DEPS_SRAMTemplate_163 = sram_array_1p512x104m13s1h0l1b_l2_meta.sv array_15.sv
FM_REF_DEPS_SRAMTemplate_166 = sram_array_1p4096x137m137s1h1l2b_l2_dat.sv array_18.sv
FM_REF_DEPS_SRAMTemplate_178 = sram_array_1p4096x137m137s1h1l2b_l2_dat.sv array_18.sv
FM_REF_DEPS_SRAMTemplate_185 = sram_array_1p512x104m13s1h0l1b_l2_meta.sv array_15.sv

# FM_MODE=assembly: 唯一抽象边界 = 厂商 SRAM 宏叶子 array_*_ext(.v 行为模型,
# 两侧同一文件, FM 不读 ⇒ 对称未解析黑盒)。
FM_MODE = assembly
FM_ALLOWLIST ?= 8
FM_VARIANTS = SRAMTemplate_128 SRAMTemplate_145 SRAMTemplate_146 SRAMTemplate_152 SRAMTemplate_155 SRAMTemplate_163 SRAMTemplate_166 SRAMTemplate_178 SRAMTemplate_185

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# codex 0219 §2：SRAMTemplate_146 唯一例化 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt → array_13 这两层包装；
# 它的 FM impl 侧改读本仓 rtl/common/ 的可读重写（ref 侧 FM_REF_DEPS 仍读 G1），两侧只把 array_13_ext
# 当 vendor 边界。只做 target-specific 替换：其余 8 个变体的 FM 输入不变；VCS UT 仍用上面的全集。
fm-SRAMTemplate_146: RTL_GOLDEN_DEPS := $(patsubst $(GOLDEN_RTL)/array_13.sv,$(XSSV_HOME)/rtl/common/array_13.sv,$(patsubst $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv,$(XSSV_HOME)/rtl/common/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv,$(RTL_GOLDEN_DEPS)))
