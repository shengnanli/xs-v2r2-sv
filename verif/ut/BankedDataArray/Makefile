# BankedDataArray —— DCache 数据阵列（8 bank × 4 路 SRAM + 读冲突仲裁 + 整行读 + 写打拍 + SECDED + MBIST 穿线）。
# 子模块处置（两侧白盒，ref 读 golden 同名件、impl 读本仓重写件）：
#   DataSRAMBank / _1 / _2 / _4（本 lane，verif/ut/DataSRAMBank）、
#   SRAMTemplate_84/86/88/92/100（PROVEN_DIRECT）、MbistPipeDCacheData（PROVEN_DIRECT，rtl/dft + xs_mbist_pipe_core）；
#   其下 sram_array_1p256x72m72s1h0l1b_dcsh_dat / array_7 / MbistClockGateCell / ClockGate 两侧同源；
#   唯一黑盒 = 厂商 SRAM 叶子 array_7_ext ×32（vendor_boundary 已审定），逐条声明在 verif/allow/BankedDataArray.json。
# wrapper 的端口表与例化区由 scripts/gen_bankeddataarray.py 生成（--check）。
MODULE = BankedDataArray

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_84.sv \
           $(RTL_DIR)/common/SRAMTemplate_86.sv \
           $(RTL_DIR)/common/SRAMTemplate_88.sv \
           $(RTL_DIR)/common/SRAMTemplate_92.sv \
           $(RTL_DIR)/common/SRAMTemplate_100.sv \
           $(RTL_DIR)/memblock/DataSRAMBank.sv \
           $(RTL_DIR)/memblock/DataSRAMBank_1.sv \
           $(RTL_DIR)/memblock/DataSRAMBank_2.sv \
           $(RTL_DIR)/memblock/DataSRAMBank_4.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeDCacheData.sv \
           $(RTL_DIR)/memblock/BankedDataArray.sv
TB_SRCS  = tb.sv

SRAM_DEPS = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SRAM_DEPS))
BDA_CHILDREN = DataSRAMBank.sv DataSRAMBank_1.sv DataSRAMBank_2.sv DataSRAMBank_4.sv \
               SRAMTemplate_84.sv SRAMTemplate_86.sv SRAMTemplate_88.sv SRAMTemplate_92.sv SRAMTemplate_100.sv \
               MbistPipeDCacheData.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/BankedDataArray.sv $(addprefix $(GOLDEN_RTL)/,$(BDA_CHILDREN)) \
              $(RTL_GOLDEN_DEPS) $(GOLDEN_RTL)/array_7_ext.v

FM_VARIANTS = BankedDataArray
FM_REF_DEPS_BankedDataArray = $(BDA_CHILDREN) $(SRAM_DEPS)
FM_MODE = assembly
PORTLINT_ORDER = fail

# vmucp（加强不是放宽）：2358 个两侧对称死位（断言寄存器、SRAM 的 MBIST 回读寄存器、MBIST 地址打拍），
# 由 fm_pins_pre.tcl 钉成 matched 后真比较；依据见 verif/fm_target_config/BankedDataArray.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_bankeddataarray.py --check
