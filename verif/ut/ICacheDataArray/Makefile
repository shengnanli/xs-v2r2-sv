MODULE = ICacheDataArray

RTL_DIR = ../../../rtl
# 子模块 SRAMTemplateWithFixedWidth×4（agent/fe-mem-misc）、其下 SRAMTemplate_{4,8,16,32} 与 MbistPipeIcacheDataWay0..3
# 均已独立签核，两侧白盒：ref 读 golden、impl 读重写件；厂商宏链 sram_array_*_icsh_dat / array_0 两侧同读。
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_8.sv \
           $(RTL_DIR)/common/SRAMTemplate_16.sv \
           $(RTL_DIR)/common/SRAMTemplate_32.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_4.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_12.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_28.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay0.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay1.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay2.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay3.sv \
           $(RTL_DIR)/frontend/ICacheDataArray.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/array_0.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv

FM_SRAM_ELAB = SRAMTemplateWithFixedWidth.sv                 SRAMTemplateWithFixedWidth_4.sv                 SRAMTemplateWithFixedWidth_12.sv                 SRAMTemplateWithFixedWidth_28.sv                 SRAMTemplate_4.sv SRAMTemplate_8.sv SRAMTemplate_16.sv SRAMTemplate_32.sv                 sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_MBIST_ELAB = MbistPipeIcacheDataWay0.sv MbistPipeIcacheDataWay1.sv                  MbistPipeIcacheDataWay2.sv MbistPipeIcacheDataWay3.sv
FM_ELAB = SRAMTemplateWithFixedWidth.sv                 SRAMTemplateWithFixedWidth_4.sv                 SRAMTemplateWithFixedWidth_12.sv                 SRAMTemplateWithFixedWidth_28.sv                 SRAMTemplate_4.sv SRAMTemplate_8.sv SRAMTemplate_16.sv SRAMTemplate_32.sv                 sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv MbistPipeIcacheDataWay0.sv MbistPipeIcacheDataWay1.sv                  MbistPipeIcacheDataWay2.sv MbistPipeIcacheDataWay3.sv
FM_REF_DEPS_ICacheDataArray = SRAMTemplateWithFixedWidth.sv                 SRAMTemplateWithFixedWidth_4.sv                 SRAMTemplateWithFixedWidth_12.sv                 SRAMTemplateWithFixedWidth_28.sv                 SRAMTemplate_4.sv SRAMTemplate_8.sv SRAMTemplate_16.sv SRAMTemplate_32.sv                 sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv MbistPipeIcacheDataWay0.sv MbistPipeIcacheDataWay1.sv                  MbistPipeIcacheDataWay2.sv MbistPipeIcacheDataWay3.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheDataArray.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_4.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_12.sv \
              $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_28.sv \
              $(GOLDEN_RTL)/SRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_8.sv \
              $(GOLDEN_RTL)/SRAMTemplate_16.sv \
              $(GOLDEN_RTL)/SRAMTemplate_32.sv \
              $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
              $(GOLDEN_RTL)/array_0.sv \
              $(GOLDEN_RTL)/array_0_ext.v \
              $(GOLDEN_RTL)/MbistPipeIcacheDataWay0.sv \
              $(GOLDEN_RTL)/MbistPipeIcacheDataWay1.sv \
              $(GOLDEN_RTL)/MbistPipeIcacheDataWay2.sv \
              $(GOLDEN_RTL)/MbistPipeIcacheDataWay3.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = dataArrays_0_0, dataArrays_0_1, dataArrays_0_2, dataArrays_0_3, dataArrays_0_4, dataArrays_0_5…
FM_MODE = assembly
FM_ALLOWLIST ?= 32
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = ICacheDataArray

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
# 必须在 include 之后 append（ut_common.mk 用 := 定义 VCS）。
# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
