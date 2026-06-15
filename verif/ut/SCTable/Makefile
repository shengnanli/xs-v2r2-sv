MODULE = SCTable

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

include sram_deps.mk

# ---------------------------------------------------------------------------
# 参数化可读核（UT 编译 + FM impl 都用）：
#   - SCTable.sv : xs_SCTable_core + xs_MbistPipeSc_core
# UT 中 xs_SCTable_core 例化的 SRAMTemplate_66 / WrBypass_33 直接复用 golden 同名
# 子模块（与 FauFTB 共享 golden FauFTBWay 同理；这些子模块已各自单独 UT+FM 验证通过）。
# ---------------------------------------------------------------------------
RTL_SRCS = $(RTL_DIR)/frontend/SCTable.sv

# FM impl 侧包装层 + 重写子模块（FM ref 与 impl 分两遍 read，同名不冲突）。
#   - SCTable_wrapper.sv         : golden 同名 SCTable/_1/_2/_3（核 xs_SCTable_core）
#   - SRAMTemplate_2p_variants   : 重写 SRAMTemplate_66（核 + 厂商 SRAM 黑盒）
#   - WrBypass + IndexableCAM    : 重写 WrBypass_33（核 + xs_IndexableCAM + PlruReplacer）
WRAPPER_SRCS = $(RTL_DIR)/frontend/SCTable_wrapper.sv \
               $(RTL_DIR)/common/SRAMTemplate_2p_core.sv \
               $(RTL_DIR)/common/SRAMTemplate_2p_variants.sv \
               $(RTL_DIR)/common/IndexableCAM.sv \
               $(RTL_DIR)/common/PlruReplacer.sv \
               $(RTL_DIR)/frontend/WrBypass.sv \
               $(RTL_DIR)/frontend/WrBypass_variants.sv \
               $(MACRO_FM)

# UT 双例化比对：golden 4 变体 + 其全部子模块（含可仿真 SRAM 宏链）。
#   tb 例化 golden SCTable* 与 SCTable*_xs；后者核例化这里提供的 golden
#   SRAMTemplate_66 / WrBypass_33 / 但 MBIST 用核内 xs_MbistPipeSc_core。
GOLDEN_SRCS = $(GOLDEN_RTL)/SCTable.sv $(GOLDEN_RTL)/SCTable_1.sv \
              $(GOLDEN_RTL)/SCTable_2.sv $(GOLDEN_RTL)/SCTable_3.sv \
              $(GOLDEN_RTL)/MbistPipeSc.sv $(GOLDEN_RTL)/MbistPipeSc_1.sv \
              $(GOLDEN_RTL)/MbistPipeSc_2.sv $(GOLDEN_RTL)/MbistPipeSc_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_66.sv \
              $(GOLDEN_RTL)/WrBypass_33.sv $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv \
              $(GOLDEN_RTL)/data_mem_16x12.sv \
              $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# 每个变体做一次 FM：ref = golden 变体 + 其子模块依赖。
FM_VARIANTS = SCTable SCTable_1 SCTable_2 SCTable_3
SC_DEPS = SRAMTemplate_66.sv sram_array_2p256x24m6s1h0l1b_bp_sc.sv array_5.sv \
          MbistClockGateCell.sv ClockGate.sv \
          WrBypass_33.sv IndexableCAMTemplate_33.sv data_mem_16x12.sv
FM_REF_DEPS_SCTable   = $(SC_DEPS) MbistPipeSc.sv
FM_REF_DEPS_SCTable_1 = $(SC_DEPS) MbistPipeSc_1.sv
FM_REF_DEPS_SCTable_2 = $(SC_DEPS) MbistPipeSc_2.sv
FM_REF_DEPS_SCTable_3 = $(SC_DEPS) MbistPipeSc_3.sv

include ../../../scripts/ut_common.mk

# golden SRAMTemplate_66 / SCTable 含 `ifndef SYNTHESIS 的运行时断言（同址读写冲突、
# GHistDiff 等）与随机初始化 initial。UT 仅逐拍比对功能输出端口，激励已保证读/写不同拍
# （见 tb），定义 SYNTHESIS 屏蔽断言块并让两侧均从复位态出发，正合比对所需。
VCS += +define+SYNTHESIS
