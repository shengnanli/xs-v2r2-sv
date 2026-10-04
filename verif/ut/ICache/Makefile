# ICache —— 前端 L1 指令缓存顶层（本层：软件预取仲裁、错误上报、Meta/Data 读写仲裁、子模块互联）。
# 8 个直接子模块全部已独立签核（PROVEN_DIRECT），两侧白盒：ref 读 golden 闭包，impl 读本仓重写件闭包，
# 一直重写到厂商 SRAM 宏为止：
#   ICacheCtrlUnit / ICacheMainPipe(+Arbiter2_ICacheMissReq) / IPrefetchPipe / ICacheMissUnit(+MSHR×14 等) /
#   WayLookup / ICacheReplacer / ICacheMetaArray(+SplittedSRAMTemplate{,_1}+SRAMTemplate{,_2}+MbistPipeIcacheTag) /
#   ICacheDataArray(+SRAMTemplateWithFixedWidth×4+SRAMTemplate_{4,8,16,32}+MbistPipeIcacheDataWay0..3)。
# 两侧同读的 golden 叶子：厂商宏链 sram_array_*_icsh_{tag,dat} / array / array_0 与时钟门控单元
# MbistClockGateCell / ClockGate；唯一黑盒 = 宏内叶子 array_ext / array_0_ext（vendor_macro，见 verif/allow/ICache.json）。
MODULE = ICache

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/frontend/Arbiter2_ICacheMissReq.sv \
           $(RTL_DIR)/frontend/ICacheCtrlUnit.sv \
           $(RTL_DIR)/frontend/ICacheMainPipe.sv \
           $(RTL_DIR)/frontend/IPrefetchPipe.sv \
           $(RTL_DIR)/frontend/WayLookup.sv \
           $(RTL_DIR)/frontend/ICacheReplacer.sv \
           $(RTL_DIR)/frontend/xs_ICacheMSHR_core.sv \
           $(addprefix $(RTL_DIR)/frontend/,ICacheMSHR.sv ICacheMSHR_1.sv ICacheMSHR_2.sv ICacheMSHR_3.sv \
               ICacheMSHR_4.sv ICacheMSHR_5.sv ICacheMSHR_6.sv ICacheMSHR_7.sv ICacheMSHR_8.sv ICacheMSHR_9.sv \
               ICacheMSHR_10.sv ICacheMSHR_11.sv ICacheMSHR_12.sv ICacheMSHR_13.sv) \
           $(RTL_DIR)/frontend/xs_DeMultiplexer_core.sv \
           $(RTL_DIR)/frontend/DeMultiplexer.sv \
           $(RTL_DIR)/frontend/DeMultiplexer_1.sv \
           $(RTL_DIR)/frontend/Arbiter5_MSHRAcquire.sv \
           $(RTL_DIR)/frontend/MuxBundle.sv \
           $(RTL_DIR)/frontend/FIFOReg.sv \
           $(RTL_DIR)/frontend/ICacheMissUnit.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate.sv \
           $(RTL_DIR)/common/SRAMTemplate_2.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_1.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheTag.sv \
           $(RTL_DIR)/frontend/ICacheMetaArray.sv \
           $(RTL_DIR)/common/SRAMTemplate_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_8.sv \
           $(RTL_DIR)/common/SRAMTemplate_16.sv \
           $(RTL_DIR)/common/SRAMTemplate_32.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_4.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_12.sv \
           $(RTL_DIR)/frontend/SRAMTemplateWithFixedWidth_28.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay0.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay1.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay2.sv \
           $(RTL_DIR)/dft/MbistPipeIcacheDataWay3.sv \
           $(RTL_DIR)/frontend/ICacheDataArray.sv \
           $(RTL_DIR)/frontend/ICache.sv
TB_SRCS = tb.sv

# 两侧同读的 golden 叶子（厂商宏链 + 时钟门控单元）
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
                  $(GOLDEN_RTL)/array.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
                  $(GOLDEN_RTL)/array_0.sv

ICACHE_CHILDREN = ICacheCtrlUnit.sv Queue1_RegMapperInput_5.sv \
    ICacheMetaArray.sv SplittedSRAMTemplate.sv SplittedSRAMTemplate_1.sv SRAMTemplate.sv SRAMTemplate_2.sv \
    sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv MbistPipeIcacheTag.sv \
    ICacheDataArray.sv SRAMTemplateWithFixedWidth.sv SRAMTemplateWithFixedWidth_4.sv SRAMTemplateWithFixedWidth_12.sv \
    SRAMTemplateWithFixedWidth_28.sv SRAMTemplate_4.sv SRAMTemplate_8.sv SRAMTemplate_16.sv SRAMTemplate_32.sv \
    sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv \
    MbistPipeIcacheDataWay0.sv MbistPipeIcacheDataWay1.sv MbistPipeIcacheDataWay2.sv MbistPipeIcacheDataWay3.sv \
    ICacheMainPipe.sv Arbiter2_ICacheMissReq.sv ICacheMissUnit.sv DeMultiplexer.sv DeMultiplexer_1.sv MuxBundle.sv \
    Arbiter5_MSHRAcquire.sv FIFOReg.sv ICacheMSHR.sv ICacheMSHR_1.sv ICacheMSHR_2.sv ICacheMSHR_3.sv ICacheMSHR_4.sv \
    ICacheMSHR_5.sv ICacheMSHR_6.sv ICacheMSHR_7.sv ICacheMSHR_8.sv ICacheMSHR_9.sv ICacheMSHR_10.sv ICacheMSHR_11.sv \
    ICacheMSHR_12.sv ICacheMSHR_13.sv ICacheReplacer.sv IPrefetchPipe.sv WayLookup.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/ICache.sv $(addprefix $(GOLDEN_RTL)/,$(ICACHE_CHILDREN)) \
              $(GOLDEN_RTL)/array_ext.v $(GOLDEN_RTL)/array_0_ext.v
FM_REF_DEPS_ICache = $(ICACHE_CHILDREN)

FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = ICache
# 对称死位按 vmucp standing rule 加强，见 verif/fm_target_config/ICache.tcl；钉点由 scripts/gen_icache_pins.py 生成
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
# merge_dup 用工具默认（true）：与 8 个子模块各自单独签核时同口径（重写核把 golden 的若干份
# 恒等打拍寄存器合成一份，如 ICacheMainPipe 的 s1_datas_REG_0..6 -> s1_fire_q；关 merge 它们在 ref 侧无对家）。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
